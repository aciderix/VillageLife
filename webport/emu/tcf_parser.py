import struct
import zlib
import os

def parse_tcf(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()
    
    # Header: TCF1
    magic = data[0:4]
    print(f"Magic: {magic}")
    
    if magic != b'TCF1':
        print("Not a TCF1 file!")
        return
    
    # Parse header fields
    version = struct.unpack_from('<I', data, 4)[0]
    header_size = struct.unpack_from('<I', data, 8)[0]
    data_size = struct.unpack_from('<I', data, 12)[0]
    unknown1 = struct.unpack_from('<I', data, 16)[0]
    unknown2 = struct.unpack_from('<I', data, 20)[0]
    
    print(f"Version: {version}")
    print(f"Header size: {header_size} (0x{header_size:X})")
    print(f"Data size: {data_size} (0x{data_size:X})")
    print(f"Unknown1: {unknown1}")
    print(f"Unknown2: {unknown2}")
    
    # The data after the unknown fields seems to contain compressed data offset
    # Let's find all filenames in the header
    # TCF seems to have a FAT with filenames followed by SPK1-compressed data
    
    # Scan for all null-terminated strings in the header area
    # The header at 0x18 has: data_size again, then an offset, then filename strings
    
    offset = 24  # after 6 x 4-byte header fields
    
    # Read additional header fields
    total_data_size = struct.unpack_from('<I', data, 24)[0]
    first_entry_offset = struct.unpack_from('<I', data, 28)[0]
    
    print(f"Total data size: {total_data_size} (0x{total_data_size:X})")
    print(f"First entry offset: {first_entry_offset} (0x{first_entry_offset:X})")
    
    # Find all filename strings (they start right after the header values)
    # and SPK1 markers
    print(f"\n=== Scanning for filenames and SPK1 entries ===")
    
    # Find all SPK1 markers
    spk1_positions = []
    pos = 0
    while True:
        pos = data.find(b'SPK1', pos)
        if pos == -1:
            break
        spk1_positions.append(pos)
        pos += 4
    
    print(f"Found {len(spk1_positions)} SPK1 entries")
    
    # Find all null-terminated strings between the header and first SPK1
    if spk1_positions:
        first_spk1 = spk1_positions[0]
        # Extract strings from the FAT area
        fat_area = data[32:first_spk1]
        
        # Parse strings - they appear to be null-terminated
        strings = []
        i = 0
        current = b''
        while i < len(fat_area):
            if fat_area[i:i+1] == b'\x00':
                if current:
                    try:
                        s = current.decode('ascii')
                        if all(c.isprintable() or c == '/' for c in s):
                            strings.append(s)
                    except:
                        pass
                    current = b''
            else:
                current += fat_area[i:i+1]
            i += 1
        
        print(f"\nFound {len(strings)} filenames in FAT:")
        for s in strings[:30]:
            print(f"  {s}")
        if len(strings) > 30:
            print(f"  ... and {len(strings)-30} more")
    
    # Try to decompress the first SPK1 entry
    if spk1_positions:
        pos = spk1_positions[0]
        print(f"\n=== First SPK1 entry at offset 0x{pos:X} ===")
        
        # SPK1 header: 'SPK1' + 4 bytes compressed size
        spk1_magic = data[pos:pos+4]
        compressed_size = struct.unpack_from('<I', data, pos+4)[0]
        print(f"SPK1 compressed size: {compressed_size} bytes")
        
        # The compressed data follows (zlib)
        compressed_data = data[pos+8:pos+8+compressed_size]
        print(f"First compressed bytes: {compressed_data[:4].hex()}")
        
        try:
            decompressed = zlib.decompress(compressed_data)
            print(f"Decompressed size: {len(decompressed)} bytes")
            
            # Show first 200 chars if text-like
            try:
                text = decompressed[:500].decode('ascii', errors='replace')
                print(f"Content preview:\n{text[:500]}")
            except:
                print(f"Binary content: {decompressed[:64].hex()}")
        except Exception as e:
            print(f"Decompress error: {e}")
            # Try without zlib header
            try:
                decompressed = zlib.decompress(compressed_data, -15)
                print(f"Decompressed (raw deflate): {len(decompressed)} bytes")
            except Exception as e2:
                print(f"Also failed with raw deflate: {e2}")

parse_tcf('/tmp/vl-data/main.tcf')
