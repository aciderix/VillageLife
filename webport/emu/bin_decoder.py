#!/usr/bin/env python3
"""
VillageLife .bin Sprite Decoder
===============================
Decodes proprietary .bin sprite files from the PlayDamic engine.

FORMAT:
  [4 bytes] uint32: header_size (offset to name table)
  [4 bytes] uint32: num_sprites
  [48 bytes × N] sprite entries:
    [0:4]   flags (bits 16-23 = palette_count, bits 8-15 = frame_count?)
    [4:8]   marker (0x0000FFFF, or 0xFFFF0000 for refs)
    [8:12]  version/sub-flags (0x00010001)
    [12:16] packed: width(low16) | height(high16)
    [16:20] x_offset (float)
    [20:24] y_offset (float)
    [24:28] data_offset (absolute file offset)
    [28:32] data_size (bytes)
    [32:48] additional fields

  PIXEL DATA at data_offset:
    [4 bytes] prefix (transparent color, 0x00000000 for none, 0xFFFFFF00 for mask)
    [N×4 bytes] palette entries (R, G, B, 0x00)
    [rest] zlib-compressed index data (1 byte per pixel)
    
  Index 0 = transparent, Index N maps to palette[N-1]
  
  Palette size = ((flags >> 16) & 0xFF):
    0x00 → 256 colors (overflow)
    0x01 → special mask sprite (no palette, zlib body = alpha)
    N    → N-1 colors

Requires: PIL/Pillow
"""
import struct, zlib, os

def parse_bin_header(data):
    """Parse .bin file header and return list of sprite entries"""
    header_size = struct.unpack('<I', data[:4])[0]
    num_sprites = struct.unpack('<I', data[4:8])[0]
    
    sprites = []
    for i in range(num_sprites):
        off = 8 + i * 0x30
        if off + 48 > len(data):
            break
        entry = data[off:off+48]
        fields = struct.unpack('<12I', entry)
        ox, oy = struct.unpack('<2f', entry[16:24])
        
        sprites.append({
            'index': i,
            'flags': fields[0],
            'marker': fields[1],
            'version': fields[2],
            'width': fields[3] & 0xFFFF,
            'height': (fields[3] >> 16) & 0xFFFF,
            'offset_x': round(ox, 2),
            'offset_y': round(oy, 2),
            'data_offset': fields[6],
            'data_size': fields[7],
            'fields_8_11': fields[8:12],
        })
    
    return {'header_size': header_size, 'num_sprites': num_sprites, 'sprites': sprites}

def get_palette_size(flags):
    nc = (flags >> 16) & 0xFF
    if nc == 0: return 256
    if nc == 1: return 0  # mask sprite
    return nc - 1

def decode_sprite_rgba(data, sprite):
    """Decode sprite pixel data to RGBA bytes. Returns (width, height, rgba_bytes) or None."""
    flags = sprite['flags']
    w, h = sprite['width'], sprite['height']
    doff, dsz = sprite['data_offset'], sprite['data_size']
    
    if dsz == 0 or doff + dsz > len(data) or w == 0 or h == 0:
        return None
    
    raw = data[doff:doff+dsz]
    if len(raw) < 8:
        return None
    
    nc = get_palette_size(flags)
    tp = w * h
    
    # Mask sprite (alpha-only, no palette)
    if nc == 0:
        body = raw[4:]
        if len(body) > 2 and body[0] == 0x78:
            try:
                dec = zlib.decompress(body)
                bpp = len(dec) // tp if tp > 0 else 0
                pixels = bytearray(tp * 4)
                if bpp >= 2:
                    for i in range(tp):
                        a = dec[i*2+1] if i*2+1 < len(dec) else 0
                        pixels[i*4+3] = a
                elif bpp == 1:
                    for i in range(min(len(dec), tp)):
                        v = dec[i]
                        pixels[i*4] = pixels[i*4+1] = pixels[i*4+2] = v
                        pixels[i*4+3] = 255
                return (w, h, bytes(pixels))
            except:
                pass
        return None
    
    # Normal palette + zlib indexed
    pal_end = 4 + nc * 4
    if pal_end >= len(raw):
        return None
    
    rest = raw[pal_end:]
    if len(rest) < 2 or rest[0] != 0x78:
        return None
    
    try:
        idx = zlib.decompress(rest)
    except:
        return None
    
    pal_data = raw[4:pal_end]
    pixels = bytearray(tp * 4)
    
    for i in range(min(len(idx), tp)):
        ci = idx[i]
        if ci > 0 and ci <= nc:
            po = (ci - 1) * 4
            pixels[i*4]   = pal_data[po]
            pixels[i*4+1] = pal_data[po+1]
            pixels[i*4+2] = pal_data[po+2]
            pixels[i*4+3] = 255
    
    return (w, h, bytes(pixels))

def decode_sprite_pil(data, sprite):
    """Decode sprite to PIL Image"""
    from PIL import Image
    result = decode_sprite_rgba(data, sprite)
    if result is None:
        return None
    w, h, rgba = result
    return Image.frombytes('RGBA', (w, h), rgba)

def decode_bin_file(filepath, output_dir=None, max_sprites=None):
    """Decode all sprites from a .bin file"""
    with open(filepath, 'rb') as f:
        data = f.read()
    
    info = parse_bin_header(data)
    results = []
    
    for sprite in info['sprites']:
        if max_sprites and len(results) >= max_sprites:
            break
        
        result = decode_sprite_rgba(data, sprite)
        if result:
            sprite['decoded'] = True
            results.append((sprite, result))
            
            if output_dir:
                from PIL import Image
                w, h, rgba = result
                img = Image.frombytes('RGBA', (w, h), rgba)
                base = os.path.basename(filepath).replace('.bin', '')
                img.save(f"{output_dir}/{base}_s{sprite['index']:03d}.png")
        else:
            sprite['decoded'] = False
    
    return info, results

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print("Usage: bin_decoder.py <file.bin> [output_dir]")
        sys.exit(1)
    
    filepath = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else '/tmp/decoded'
    os.makedirs(output_dir, exist_ok=True)
    
    info, results = decode_bin_file(filepath, output_dir)
    print(f"File: {filepath}")
    print(f"Sprites: {info['num_sprites']}, decoded: {len(results)}")
    for sprite, (w, h, _) in results:
        print(f"  s{sprite['index']:03d}: {w}x{h}")
