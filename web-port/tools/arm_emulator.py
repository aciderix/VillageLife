#!/usr/bin/env python3
"""Village Life ARM Emulator v3 — Hook internal inflate wrapper"""
import struct, zlib, lief
from unicorn import *
from unicorn.arm_const import *

ELF_BASE = 0x10000000
STACK_BASE = 0x80000000
HEAP_BASE = 0x90000000
STUB_BASE = 0xF0000000
INPUT_BASE = 0xA0000000
OUTPUT_BASE = 0xB0000000

binary = lief.parse("/tmp/vl-libs/libpdandroid.so")
uc = Uc(UC_ARCH_ARM, UC_MODE_ARM)

# Map memory
uc.mem_map(STACK_BASE - 0x100000, 0x100000, UC_PROT_ALL)
uc.mem_map(HEAP_BASE, 0x4000000, UC_PROT_ALL)  # 64MB heap
uc.mem_map(STUB_BASE, 0x10000, UC_PROT_ALL)
uc.mem_map(INPUT_BASE, 0x1000000, UC_PROT_ALL)
uc.mem_map(OUTPUT_BASE, 0x1000000, UC_PROT_ALL)

# Load ELF
for seg in binary.segments:
    if seg.type == lief.ELF.Segment.TYPE.LOAD:
        vaddr = ELF_BASE + seg.virtual_address
        page_start = vaddr & ~0xFFF
        page_end = (vaddr + seg.virtual_size + 0xFFF) & ~0xFFF
        try: uc.mem_map(page_start, page_end - page_start, UC_PROT_ALL)
        except: pass
        uc.mem_write(vaddr, bytes(seg.content))

# Process ALL relocations
stub_names = {}
next_stub = 0
heap_ptr = HEAP_BASE + 0x1000

def get_stub(name):
    global next_stub
    addr = STUB_BASE + next_stub * 8
    uc.mem_write(addr, b'\x1E\xFF\x2F\xE1')  # BX LR in ARM
    stub_names[addr] = name
    next_stub += 1
    return addr

for reloc in binary.relocations:
    addr = ELF_BASE + reloc.address
    if reloc.type == lief.ELF.Relocation.TYPE.ARM_RELATIVE:
        try:
            old_val = struct.unpack('<I', bytes(uc.mem_read(addr, 4)))[0]
            uc.mem_write(addr, struct.pack('<I', (old_val + ELF_BASE) & 0xFFFFFFFF))
        except: pass
    elif reloc.type in (lief.ELF.Relocation.TYPE.ARM_GLOB_DAT, lief.ELF.Relocation.TYPE.ARM_JUMP_SLOT):
        if reloc.symbol and reloc.symbol.name:
            name = reloc.symbol.name
            if name == '__stack_chk_guard':
                canary_addr = HEAP_BASE + 0x3FFFFF0
                uc.mem_write(canary_addr, struct.pack('<I', 0xDEADBEEF))
                uc.mem_write(addr, struct.pack('<I', canary_addr))
            else:
                stub = get_stub(name)
                uc.mem_write(addr, struct.pack('<I', stub))

# Symbols
symbols = {}
for sym in binary.exported_functions:
    symbols[sym.name] = ELF_BASE + sym.address

# ===== KEY: Hook the internal inflate wrapper at 0x216514 =====
# This function signature: wrapper(dest, &params_struct, src, max_dest_size)
# Where params_struct contains: [src_size_low, src_size_high, ...]
# We'll replace it entirely with Python zlib
INFLATE_WRAPPER = ELF_BASE + 0x216514
# Write BX LR at the wrapper entry point so it returns immediately
# We'll handle everything in our hook
uc.mem_write(INFLATE_WRAPPER, b'\x1E\xFF\x2F\xE1')  # BX LR

def hook_inflate_wrapper(uc, address, size, user_data):
    if address != INFLATE_WRAPPER:
        return
    
    # Args: R0=dest, R1=&params, R2=src, R3=max_dest_size
    dest = uc.reg_read(UC_ARM_REG_R0)
    params_ptr = uc.reg_read(UC_ARM_REG_R1)
    src = uc.reg_read(UC_ARM_REG_R2)
    max_size = uc.reg_read(UC_ARM_REG_R3)
    
    # Read src_size from params (first 8 bytes = uint64_t)
    src_size_low = struct.unpack('<I', bytes(uc.mem_read(params_ptr, 4)))[0]
    src_size_high = struct.unpack('<I', bytes(uc.mem_read(params_ptr + 4, 4)))[0]
    src_size = src_size_low | (src_size_high << 32)
    
    # Read compressed data
    compressed = bytes(uc.mem_read(src, src_size))
    
    try:
        decompressed = zlib.decompress(compressed)
        uc.mem_write(dest, decompressed)
        # Store decompressed size in params+8 (or wherever the caller reads it)
        # The caller reads from sp (after the function): ldr r0, [sp]
        # Let's store the size where the caller expects it
        sp = uc.reg_read(UC_ARM_REG_SP)
        uc.mem_write(sp, struct.pack('<I', len(decompressed)))
        uc.reg_write(UC_ARM_REG_R0, len(decompressed))
        print(f"  ✓ [inflate_wrapper] {src_size} -> {len(decompressed)} bytes")
    except Exception as e:
        print(f"  ✗ [inflate_wrapper] {e}")
        print(f"     src[0:8] = {compressed[:8].hex()}")
        uc.reg_write(UC_ARM_REG_R0, 0)

uc.hook_add(UC_HOOK_CODE, hook_inflate_wrapper, begin=INFLATE_WRAPPER, end=INFLATE_WRAPPER+4)

# Stub handler for imports
def hook_stubs(uc, address, size, user_data):
    global heap_ptr
    if address not in stub_names:
        return
    name = stub_names[address]
    r0 = uc.reg_read(UC_ARM_REG_R0)
    r1 = uc.reg_read(UC_ARM_REG_R1)
    r2 = uc.reg_read(UC_ARM_REG_R2)
    
    if name == 'malloc':
        ptr = heap_ptr
        heap_ptr += (max(r0,16) + 15) & ~15
        uc.reg_write(UC_ARM_REG_R0, ptr)
    elif name == 'free': pass
    elif name == 'calloc':
        total = max(r0 * r1, 16)
        ptr = heap_ptr
        heap_ptr += (total + 15) & ~15
        uc.mem_write(ptr, b'\x00' * min(total, 0x100000))
        uc.reg_write(UC_ARM_REG_R0, ptr)
    elif name in ('memcpy', 'memmove'):
        if 0 < r2 < 0x10000000:
            uc.mem_write(r0, bytes(uc.mem_read(r1, r2)))
    elif name == 'memset':
        if 0 < r2 < 0x10000000:
            uc.mem_write(r0, bytes([r1 & 0xFF]) * r2)
    elif name == '__stack_chk_fail':
        print("  ⚠ Stack check fail (ignored)")
    else:
        uc.reg_write(UC_ARM_REG_R0, 0)

uc.hook_add(UC_HOOK_CODE, hook_stubs, begin=STUB_BASE, end=STUB_BASE + 0x10000)

# ========== TEST 1: UNPACKZLIB ==========
print("="*60)
print("TEST 1: GSINTPACK::UNPACKZLIB")
print("="*60)

test_data = b"Hello Village Life! ARM emulation with Unicorn works!" * 20
compressed = zlib.compress(test_data)
print(f"Test: {len(test_data)} bytes -> {len(compressed)} compressed")

uc.mem_write(INPUT_BASE, compressed)
uc.mem_write(OUTPUT_BASE, b'\x00' * (len(test_data) + 4096))

addr = symbols['_ZN9GSINTPACK10UNPACKZLIBEPhS0_y']
stop_addr = STUB_BASE + 0xFE00
uc.mem_write(stop_addr, b'\x1E\xFF\x2F\xE1')

uc.reg_write(UC_ARM_REG_SP, STACK_BASE - 0x100)
uc.reg_write(UC_ARM_REG_R0, INPUT_BASE)
uc.reg_write(UC_ARM_REG_R1, OUTPUT_BASE)
uc.reg_write(UC_ARM_REG_R2, len(compressed))
uc.reg_write(UC_ARM_REG_R3, 0)
uc.reg_write(UC_ARM_REG_LR, stop_addr)

try:
    uc.emu_start(addr, stop_addr, timeout=10000000)
    result = uc.reg_read(UC_ARM_REG_R0)
    output = bytes(uc.mem_read(OUTPUT_BASE, len(test_data)))
    
    if output == test_data:
        print(f"\n🎉 SUCCESS! Decompressed {len(output)} bytes correctly!")
        print(f'   "{output[:60].decode()}..."')
    else:
        nz = sum(1 for b in output if b != 0)
        print(f"\nOutput: {nz} non-zero bytes, return={result}")
        if nz > 0:
            try: print(f"  Text: {output[:80].decode('ascii', errors='replace')}")
            except: print(f"  Hex: {output[:40].hex()}")
except UcError as e:
    pc = uc.reg_read(UC_ARM_REG_PC)
    print(f"\n❌ PC=0x{pc:08X}: {e}")

# ========== TEST 2: GSINTPARSE::GETHASH ==========
print("\n" + "="*60)
print("TEST 2: GSINTPARSE::GETHASH (string hash)")
print("="*60)

test_strings = [b"village\x00", b"building\x00", b"craft\x00", b"quest\x00"]
addr = symbols['_ZN10GSINTPARSE7GETHASHEPc']

for s in test_strings:
    uc.mem_write(INPUT_BASE, s)
    uc.reg_write(UC_ARM_REG_SP, STACK_BASE - 0x100)
    uc.reg_write(UC_ARM_REG_R0, INPUT_BASE)
    uc.reg_write(UC_ARM_REG_LR, stop_addr)
    
    try:
        uc.emu_start(addr, stop_addr, timeout=5000000)
        result = uc.reg_read(UC_ARM_REG_R0)
        print(f'  GETHASH("{s[:-1].decode()}") = 0x{result:08X}')
    except UcError as e:
        pc = uc.reg_read(UC_ARM_REG_PC)
        print(f'  GETHASH("{s[:-1].decode()}") ERROR at PC=0x{pc:08X}: {e}')
