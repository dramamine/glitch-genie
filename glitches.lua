local utils = dofile("utils.lua")

local glitches = {}

local WRAM = {
	anim = 0x0002E,
	update_cg_ram = 0x00015, --"update CGRAM (0x200 bytes)"
	cgram_location_read = 0x2121,
  cgram_location_write = 0x2122,
  max_health = 0xF36C,
  health = 0xF36D,
  music = 0x012C,
  sfx1 = 0x012E,
  sfx2 = 0x012F,
}

local VRAM = {
  -- funspot = 0x1AA9
  funspot = 0x1000,
  health_start = 0xC0E8,
}

local w8 = memory.writebyte
local w16 = memory.write_u16_le
local r8 = memory.readbyte
local r16 = memory.readword
-- @TODO
-- memory.readbyterange
-- memory.writebyterange
-- memory.read_u16_be
-- memory.read_u16_le (8 - 32 range)
-- memory.write_u16_be


-- try once
-- print(memory.getmemorydomainlist())
-- Lua 5.1
-- "0": "WRAM"
-- "1": "CARTROM"
-- "2": "CARTRAM"
-- "3": "VRAM"
-- "4": "OAM"
-- "5": "CGRAM"
-- "6": "APURAM"
-- "7": "System Bus"


local bytes_to_fuck = 256
-- increment a bunch of VRAM data on BG2. right now, takes 2 rows of tiles
-- and increments all their values by 1.
--
-- @todo we could do more specific distorting for this stuff... i.e.
-- instead of just incrementing values, you could destructure the values
-- into its various parts (tile index, palette etc.) and only mess with
-- one part at a time.
-- 
-- location (hex) - memory location to start changing values
-- old (int) - old knob value 0-127
-- new (int) - new knob value 0-127
function horizontal_distorter(location, old, new)
  local diff = new - old
  if diff == 0 then return end
  memory.usememorydomain("VRAM")
  for i=0, bytes_to_fuck, 1 do
    orig_value = r8(location+i)
    w8(location+i, orig_value + diff)
  end
  -- print(string.format("done distorting %d %d", old, new))
end

-- main function to pick locations for horizontal_distorter function
-- old (int) - old knob value 0-127
-- new (int) - new knob value 0-127
-- knob (int) - knob index 21-28 or 41-48 @todo kinda hacky
function glitches.horizontal_distorter_v0(old, new, knob)  
  funspot_offset = 8 + (knob - 21)
  location = VRAM.funspot + (bytes_to_fuck * funspot_offset)
  horizontal_distorter(location, old, new)
end




function crossswapper()
  memory.usememorydomain("VRAM")
  -- print(memory)
  for i=0x1234, 0x2400, 0x4 do
    if (band(i, 0x400)) then
      first = memory.read_u16_le(i)
      second = memory.read_u16_le(i+0x2)
      third = memory.read_u16_le(i+0x40)
      fourth = memory.read_u16_le(i+0x42)

      memory.write_u16_le(i, fourth)
      memory.write_u16_le(i+0x2, third)
      memory.write_u16_le(i+0x40, second)
      memory.write_u16_le(i+0x42, first)
    end
  end
end

function glitches.crossswapper_v0(old, new)
  is_updated = utils.check_threshold(old, new)
  if is_updated == 1 then
    print('swappin')
    crossswapper()
  elseif is_updated == 0 then
    print('swappin')
    crossswapper()
  end
end

-- @todo unused?
function glitches.tileswapper()
  memory.usememorydomain("VRAM")  
  -- print(memory)
  for i=0x0000, 0x2000, 0x4 do
    first = memory.read_u16_le(i)
    second = memory.read_u16_le(i+0x2)

    memory.write_u16_le(i, second)
    memory.write_u16_le(i+0x2, first)
    -- a,b,c,d = r8(i), r8(i+0x1), r8(i+0x2), r8(i+0x3)
    -- print(string.format("read value: addr $%X 0x %X %X %X %X", i, a,b,c,d))
    -- print(string.format("another way: addr $%X 0x %X", i, memory.read_u16_le(i) ))

  end
end


-- max health distorter; needs some work as it doesn't update when reducing
-- the number of max hearts
function glitches.max_health_distorter(old, new)
  -- print("max health distorter called.")
  --  normalize to 20 hearts
  hearts = 1 + math.floor(new * 19 / 127)
  hex_hearts = 0x8 * hearts
  print(hex_hearts)
  memory.usememorydomain("WRAM")
  w8(WRAM.max_health, hex_hearts)
end

-- change the number of hearts the user has
function glitches.health_distorter(old, new)
  -- print("health distorter called.")
  memory.usememorydomain("WRAM")
  -- max hearts, in decimal form
  max_hearts = r8(WRAM.max_health)
  -- relate the 0-127 value to the number of max hearts
  hearts = 1 + math.floor(new * max_hearts / (129 * 4))
  hex_hearts = 0x4 * hearts

  w8(WRAM.health, hex_hearts)
end

-- distort the palette of HUD (which layer??)
function glitches.palette_distorter(old, new)
  diff = new - old
  memory.usememorydomain("CGRAM")
  for i=0x0001, 0x040, 0x2 do
    val = r8(i)
    updated = 0x0 + ((val + diff) % 128)
    -- print("updating", val, "to", updated)
    w8(i, updated)
  end
end


last_music = 0x0
function glitches.music_select_v0(old, new)
  music = 0x0 + 1 + math.floor(new * 64 / 127)
  if (music ~= last_music) then
    print(string.format("updating music to: %X", music))
    memory.usememorydomain("WRAM")
    w16(WRAM.music, music)
  end
end

last_sfx = 0x0
function glitches.sfx1_select_v0(old, new)
  sfx = 0x0 + 1 + math.floor(new * 0x3F / 127)
  if (sfx ~= last_sfx) then
    -- print(string.format("updating sfx to: %X", music))
    memory.usememorydomain("WRAM")
    w16(WRAM.sfx1, sfx)
  end
end

-- @todo unused now?
local orig_data
function glitches.distorter_v0(old, new)
  memory.usememorydomain("VRAM")
  if (old == 0) then
    orig_data = r8(VRAM.funspot)
    -- print(string.format("read value: 0x %X", orig_data))
  end
  if (new > 0) then
    updated_data = orig_data + new
    -- print(string.format("writing value: 0x %X", updated_data))
    for i=0, 64, 1 do
      w8(VRAM.funspot+i, orig_data + new)
    end

  end
  -- print(string.format("done distorting %d %d", old, new))
end

print("my glitches!:", glitches)
return glitches
