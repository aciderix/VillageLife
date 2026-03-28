#!/usr/bin/env python3
"""Test: Decompress actual game data from main.tcf using ARM emulation"""
import struct, zlib, lief
from unicorn import *
from unicorn.arm_const import *

ELF_BASE = 0x10000000
STACK_BASE = 0x80000000
HEAP_BASE = 0x90000000
STUB_BASE = 0xF0000000

binary = lief.parse("/tmp/vl-libs/libpdandroid.so")
uc = Uc(UC_ARCH_ARM, UC_MODE_ARM)

# Map memory
uc.mem_map(STACK_BASE - 0x100000, 0x100000, UC_PROT_ALL)
uc.mem_map(HEAP_BASE, 0x4000000, UC_PROT_ALL)
uc.mem_map(STUB_BASE, 0x10000, UC_PROT_ALL)
uc.mem_map(0x20000000, 0x1000000, UC_PROT_ALL)  # Input buffer (16MB)
uc.mem_map(0x30000000, 0x2000000, UC_PROT_ALL)  # Output buffer (32MB)

# Load ELF
for seg in binary.segments:
    if seg.type == lief.ELF.Segment.TYPE.LOAD:
        vaddr = ELF_BASE + seg.virtual_address
        page_start = vaddr & ~0xFFF
        page_end = (vaddr + seg.virtual_size + 0xFFF) & ~0xFFF
        try: uc.mem_map(page_start, page_end - page_start, UC_PROT_ALL)
        except: pass
        uc.mem_write(vaddr, bytes(seg.content))

# Relocations
stub_names = {}
next_stub = 0
heap_ptr = HEAP_BASE + 0x1000

def get_stub(name):
    global next_stub
    addr = STUB_BASE + next_stub * 8
    uc.mem_write(addr, b'\x1E\xFF\x2F\xE1')
    stub_names[addr] = name
    next_stub += 1
    return addr

for reloc in binary.relocations:
    addr = ELF_BASE + reloc.address
    if reloc.type == lief.ELF.Relocation.TYPE.ARM_RELATIVE:
        try:
            old = struct.unpack('<I', bytes(uc.mem_read(addr, 4)))[0]
            uc.mem_write(addr, struct.pack('<I', (old + ELF_BASE) & 0xFFFFFFFF))
        except: pass
    elif reloc.type in (lief.ELF.Relocation.TYPE.ARM_GLOB_DAT, lief.ELF.Relocation.TYPE.ARM_JUMP_SLOT):
        if reloc.symbol and reloc.symbol.name:
            name = reloc.symbol.name
            if name == '__stack_chk_guard':
                ca = HEAP_BASE + 0x3FFFFF0
                uc.mem_write(ca, struct.pack('<I', 0xDEADBEEF))
                uc.mem_write(addr, struct.pack('<I', ca))
            else:
                uc.mem_write(addr, struct.pack('<I', get_stub(name)))

symbols = {sym.name: ELF_BASE + sym.address for sym in binary.exported_functions}

# Hook inflate wrapper
INFLATE_WRAPPER = ELF_BASE + 0x216514
uc.mem_write(INFLATE_WRAPPER, b'\x1E\xFF\x2F\xE1')

def hook_inflate(uc, address, size, user_data):
    if address != INFLATE_WRAPPER: return
    dest = uc.reg_read(UC_ARM_REG_R0)
    params = uc.reg_read(UC_ARM_REG_R1)
    src = uc.reg_read(UC_ARM_REG_R2)
    
    src_size = struct.unpack('<I', bytes(uc.mem_read(params, 4)))[0]
    compressed = bytes(uc.mem_read(src, src_size))
    
    try:
        decompressed = zlib.decompress(compressed)
        uc.mem_write(dest, decompressed)
        sp = uc.reg_read(UC_ARM_REG_SP)
        uc.mem_write(sp, struct.pack('<I', len(decompressed)))
        uc.reg_write(UC_ARM_REG_R0, len(decompressed))
    except:
        uc.reg_write(UC_ARM_REG_R0, 0)

uc.hook_add(UC_HOOK_CODE, hook_inflate, begin=INFLATE_WRAPPER, end=INFLATE_WRAPPER+4)

# Import stubs
def hook_stubs(uc, address, size, user_data):
    global heap_ptr
    if address not in stub_names: return
    name = stub_names[address]
    r0 = uc.reg_read(UC_ARM_REG_R0)
    r1 = uc.reg_read(UC_ARM_REG_R1)
    r2 = uc.reg_read(UC_ARM_REG_R2)
    
    if name == 'malloc':
        ptr = heap_ptr; heap_ptr += (max(r0,16)+15)&~15
        uc.reg_write(UC_ARM_REG_R0, ptr)
    elif name == 'free': pass
    elif name == 'calloc':
        total = max(r0*r1,16); ptr = heap_ptr; heap_ptr += (total+15)&~15
        uc.mem_write(ptr, b'\x00'*min(total,0x100000))
        uc.reg_write(UC_ARM_REG_R0, ptr)
    elif name in ('memcpy','memmove'):
        if 0<r2<0x10000000: uc.mem_write(r0, bytes(uc.mem_read(r1, r2)))
    elif name == 'memset':
        if 0<r2<0x10000000: uc.mem_write(r0, bytes([r1&0xFF])*r2)
    else:
        uc.reg_write(UC_ARM_REG_R0, 0)

uc.hook_add(UC_HOOK_CODE, hook_stubs, begin=STUB_BASE, end=STUB_BASE+0x10000)

stop_addr = STUB_BASE + 0xFE00
uc.mem_write(stop_addr, b'\x1E\xFF\x2F\xE1')

def call_func(name, r0=0, r1=0, r2=0, r3=0):
    addr = symbols[name]
    uc.reg_write(UC_ARM_REG_SP, STACK_BASE - 0x200)
    uc.reg_write(UC_ARM_REG_R0, r0)
    uc.reg_write(UC_ARM_REG_R1, r1)
    uc.reg_write(UC_ARM_REG_R2, r2)
    uc.reg_write(UC_ARM_REG_R3, r3)
    uc.reg_write(UC_ARM_REG_LR, stop_addr)
    uc.emu_start(addr, stop_addr, timeout=10000000)
    return uc.reg_read(UC_ARM_REG_R0)

# ====== TEST: Decompress REAL game data from main.tcf ======
print("=" * 60)
print("REAL TEST: Decompress gui/village.t3g from main.tcf")
print("=" * 60)

# Read main.tcf
with open('/tmp/vl-data/main.tcf', 'rb') as f:
    tcf_data = f.read()

# Find the SPK1 block (starts at offset 0x30 based on our earlier analysis)
spk1_offset = tcf_data.find(b'SPK1')
if spk1_offset < 0:
    print("No SPK1 found!")
    exit(1)

# SPK1 header: 'SPK1' + 4 bytes decompressed size
decompressed_size = struct.unpack_from('<I', tcf_data, spk1_offset + 4)[0]
# Compressed data starts after the 8-byte SPK1 header
compressed_data = tcf_data[spk1_offset + 8:]

print(f"SPK1 at offset 0x{spk1_offset:X}")
print(f"Decompressed size from header: {decompressed_size} bytes ({decompressed_size/1024/1024:.1f} MB)")
print(f"Compressed data: {len(compressed_data)} bytes ({len(compressed_data)/1024:.0f} KB)")
print(f"Zlib header: {compressed_data[:2].hex()}")

# Use Unicorn to decompress via UNPACKZLIB
# But first check if it fits in our buffer...
if len(compressed_data) > 0x1000000:  # 16MB limit
    print("Compressed data too large for buffer, using subset")
    compressed_data = compressed_data[:0xF00000]

uc.mem_write(0x20000000, compressed_data)
uc.mem_write(0x30000000, b'\x00' * min(decompressed_size + 4096, 0x2000000))

print(f"\nCalling UNPACKZLIB with {len(compressed_data)} bytes of real game data...")
try:
    result = call_func('_ZN9GSINTPACK10UNPACKZLIBEPhS0_y',
                        r0=0x20000000,       # src
                        r1=0x30000000,       # dest
                        r2=len(compressed_data),  # size_low
                        r3=0)                # size_high
    
    # Check how much was written
    output = bytes(uc.mem_read(0x30000000, min(decompressed_size, 0x2000000)))
    nz_end = len(output)
    while nz_end > 0 and output[nz_end-1] == 0:
        nz_end -= 1
    
    print(f"\n🎉 Decompressed {nz_end} bytes of gui/village.t3g!")
    
    # Save to file
    with open('/tmp/vl-data/village.t3g', 'wb') as f:
        f.write(output[:nz_end])
    
    # Analyze the content
    print(f"\nFirst 64 bytes: {output[:64].hex()}")
    
    # Check for readable strings
    text_parts = []
    current = b''
    for b in output[:min(nz_end, 100000)]:
        if 32 <= b < 127:
            current += bytes([b])
        else:
            if len(current) > 5:
                text_parts.append(current.decode())
            current = b''
    
    if text_parts:
        print(f"\nReadable strings found ({len(text_parts)} strings > 5 chars):")
        for s in text_parts[:20]:
            print(f"  '{s}'")
    
except UcError as e:
    pc = uc.reg_read(UC_ARM_REG_PC)
    print(f"\n❌ PC=0x{pc:08X}: {e}")
