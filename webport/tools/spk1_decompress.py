"""
SPK1 Decompressor - reverse-engineered from GSINTPACK::UNPACKOLD
in libpdandroid.so (ARM assembly at 0x0026d9e0)

Format: "SPK1" + uint32_le(decompressed_size) + compressed_data

Compressed data is a stream of commands:
  0x00: END
  0x01-0x3F (top 2 bits = 00): LITERAL - copy N bytes from stream
  0x40-0x7F (top 2 bits = 01): SHORT BACKREF (2 bytes total)
  0x80-0xBF (top 2 bits = 10): MEDIUM BACKREF (3 bytes total)
  0xC0-0xFF (top 2 bits = 11): LONG BACKREF (4 bytes total)
"""
import struct, zlib, sys

def decompress_spk1_old(data):
    """Decompress SPK1 'old' format (GSINTPACK::UNPACKOLD algorithm)"""
    out = bytearray()
    pos = 0
    
    while pos < len(data):
        cmd = data[pos]
        if cmd == 0:
            break
        
        top2 = cmd & 0xC0
        
        if top2 == 0x00:
            # LITERAL: copy cmd bytes from compressed stream
            count = cmd
            pos += 1
            out.extend(data[pos:pos+count])
            pos += count
            
        elif top2 == 0x40:
            # SHORT BACKREF: 2 bytes
            byte1 = data[pos + 1]
            length = ((cmd >> 2) & 0x0F) + 3
            offset = byte1 + ((cmd & 0x03) << 8) + 1
            pos += 2
            src_pos = len(out) - offset
            for i in range(length):
                out.append(out[src_pos + i])
                
        elif top2 == 0x80:
            # MEDIUM BACKREF: 3 bytes
            byte1 = data[pos + 1]
            byte2 = data[pos + 2]
            length = ((cmd & 0x3F) << 2) + (byte1 >> 6) + 4
            offset = byte2 + ((byte1 & 0x3F) << 8) + 1
            pos += 3
            src_pos = len(out) - offset
            for i in range(length):
                out.append(out[src_pos + i])
                
        elif top2 == 0xC0:
            # LONG BACKREF: 4 bytes
            byte1 = data[pos + 1]
            byte2 = data[pos + 2]
            byte3 = data[pos + 3]
            length = (byte1 >> 1) + ((cmd & 0x3F) << 7) + 5
            offset = byte3 + (byte2 << 8) + ((byte1 & 1) << 16) + 1
            pos += 4
            src_pos = len(out) - offset
            for i in range(length):
                out.append(out[src_pos + i])
    
    return bytes(out)


def decompress_spk1(filepath):
    """Decompress a file with SPK1 header. Tries zlib first, falls back to UNPACKOLD."""
    with open(filepath, 'rb') as f:
        data = f.read()
    
    if data[:4] != b'SPK1':
        return data  # Not compressed
    
    expected_size = struct.unpack('<I', data[4:8])[0]
    payload = data[8:]
    
    # Try zlib first
    try:
        result = zlib.decompress(payload)
        if len(result) == expected_size:
            return result
    except:
        pass
    
    # Use UNPACKOLD algorithm
    result = decompress_spk1_old(payload)
    
    if len(result) != expected_size:
        print(f"  WARNING: size mismatch! Expected {expected_size}, got {len(result)}", file=sys.stderr)
    
    return result


if __name__ == '__main__':
    import os
    
    # Test on common.xml (smallest file)
    test_file = '/tmp/vl/xml/common.xml'
    result = decompress_spk1(test_file)
    
    print(f"=== common.xml ===")
    print(f"Decompressed size: {len(result)} bytes")
    print(f"First 500 chars:")
    print(result[:500].decode('utf-8', errors='replace'))
    print(f"\n...\nLast 200 chars:")
    print(result[-200:].decode('utf-8', errors='replace'))
    
    # Test on a larger file
    print(f"\n\n=== newxmlloc1_en.xml ===")
    test_file2 = '/tmp/vl/xml/newxmlloc1_en.xml'
    result2 = decompress_spk1(test_file2)
    print(f"Decompressed size: {len(result2)} bytes")
    print(f"First 500 chars:")
    print(result2[:500].decode('utf-8', errors='replace'))
    
    # Test BSH file (zlib)
    import glob
    bsh_files = glob.glob('/tmp/vl/mdl/**/*.bsh', recursive=True)
    if bsh_files:
        print(f"\n\n=== {os.path.basename(bsh_files[0])} (BSH/zlib) ===")
        result3 = decompress_spk1(bsh_files[0])
        print(f"Decompressed size: {len(result3)} bytes")
