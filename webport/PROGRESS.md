# VillageLife Web Port — Progress

## Phase 1: Format Parsing via ARM Emulator

### ✅ Completed

#### 1. ARM Emulator Setup
- Unicorn Engine + LIEF emulator working
- `libpdandroid.so` loaded at 0x10000000
- All ELF relocations applied (ARM_RELATIVE, GLOB_DAT, JUMP_SLOT)
- Stubs for libc functions (malloc, memcpy, strlen, strcmp, etc.)
- Stack canary guard initialized

#### 2. Engine Subsystem Hooks
- **GSINTFILE**: BUILDGETSIZE, BUILDOPENREAD, BUILDREAD, BUILDCLOSE → Virtual filesystem
- **GSINTMEM**: MEMALLOC → heap allocator
- **GSINTPACK**: UNPACKZLIB, UNPACKANY → zlib decompress
- **Custom strcpy stub** at 0x2022c8 (inline string copy)
- **Slot table** at heap for file tracking (GSINTFILE slots)
- BSS globals initialized: slot table pointer at 0x1076D928

#### 3. .bin Format — FULLY DECODED ✅
- **LoadBINFile** (0x21C980) executes successfully via emulator
- Tested on 6 files: adult_female, adult_male, female_props, hen, wheat, tree

**Format specification:**
```
HEADER:
  [4B] uint32 header_size (offset to name table)
  [4B] uint32 num_sprites
  [48B × N] sprite entries

SPRITE ENTRY (48 bytes):
  [0:4]   flags
            bits 16-23: palette_count (0→256, 1→mask, N→N-1 colors)
            bits 8-15:  possibly frame_count for multi-frame sprites
  [4:8]   marker (0x0000FFFF)
  [8:12]  version (0x00010001)
  [12:16] packed: width(low16) | height(high16)
  [16:20] x_offset (float) — sprite anchor
  [20:24] y_offset (float) — sprite anchor
  [24:28] data_offset (absolute file offset)
  [28:32] data_size (bytes)
  [32:48] additional fields (refs, etc.)

PIXEL DATA (at data_offset):
  [4B] prefix (0x00000000 = normal, 0xFFFFFF00 = mask)
  [N×4B] palette (R, G, B, 0x00) — N = palette_count
  [rest] zlib-compressed indices (1 byte/pixel)
  
  Index 0 = transparent
  Index N = palette[N-1]
```

**Decoder**: `/agent/home/vl/emu/bin_decoder.py`

**Decoded samples** (in `/agent/home/vl/decoded/`):
- avatar_types_adult_female_s0.png — 73×131 avatar body ✅
- environment_decor_decor_tree_large_s1.png — 45×62 tree ✅
- environment_crops_wheat_s0.png — 320×184 wheat seeds ✅
- environment_critters_hen_s0.png — 93×78 (multi-frame, needs work)

#### 4. LoadANXFile — Partial
- LoadANXFile (0x21C140) partially executes
- Writes animation data to slot positions [4] and [6]
- Crashes during finalization (globals not fully initialized)
- The data IS written before crash — needs extraction

### 🔄 In Progress

#### 5. Multi-frame .bin sprites
- Sprites with flags `0x0702` (hen) have `data_size >> num_pixels`
- Likely: flag byte 0x07 = frame count, data contains 7 sub-frames
- Need to determine sub-frame header format

#### 6. .anx Animation Format
- File pairs: `*.bin` + `*.anx` (same base name)
- .anx contains animation definitions (frame sequences, timing)
- LoadANXFile uses same BUILDREAD I/O system
- Partially loaded — needs crash investigation

### ❌ Not Started
- .bsh/.bdl model parsing
- .t3g GUI scene graph parsing  
- Full sprite sheet extraction
- Web renderer integration
- GitHub push of results

## Files on Disk
- `/agent/home/vl/emu/arm_emulator.py` — Base emulator
- `/agent/home/vl/emu/bin_decoder.py` — BIN sprite decoder
- `/agent/home/vl/emu/game_decompressor.py` — Data decompressor
- `/agent/home/vl/emu/tcf_parser.py` — TCF parser
- `/agent/home/vl/symbols.txt` — 16,535 engine symbols
- `/agent/home/vl/repo_file_listing.txt` — Full repo file listing
- `/agent/home/vl/samples/bin/` — Sample .bin files (6 files)
- `/agent/home/vl/samples/anx/` — Sample .anx files
- `/agent/home/vl/decoded/` — Decoded PNG sprites
