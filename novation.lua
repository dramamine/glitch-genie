-- initialize the library
local midi = require "luamidi"
-- print(_VERSION) -- Lua 5.1 expected

local debounce_time = 0.0
local bytes_to_fuck = 256

local WRAM = {
	anim = 0x0002E,
	update_cg_ram = 0x00015, --"update CGRAM (0x200 bytes)"
	cgram_location_read = 0x2121,
  cgram_location_write = 0x2122,
  max_health = 0xF36C,
  health = 0xF36D,
}

local VRAM = {
  -- funspot = 0x1AA9
  funspot = 0x1000,
  health_start = 0xC0E8,
}

local w8 = memory.writebyte
local w16 = memory.writeword
local r8 = memory.readbyte
local r16 = memory.readword
-- @TODO
-- memory.readbyterange
-- memory.writebyterange
-- memory.read_u16_be
-- memory.read_u16_le (8 - 32 range)
-- memory.write_u16_be


local animcycle = 0x0

-- try once
-- print(memory.getmemorydomainlist())
memory.usememorydomain("VRAM")

-- Lua 5.1
-- "0": "WRAM"
-- "1": "CARTROM"
-- "2": "CARTRAM"
-- "3": "VRAM"
-- "4": "OAM"
-- "5": "CGRAM"
-- "6": "APURAM"
-- "7": "System Bus"

-- look for available input ports
-- print("Midi Input Ports: ", midi.getinportcount())

local orig_data

function horizontal_distorter(location, old, new)
  local diff = new - old
  if diff == 0 then return end
  for i=0, 256, 1 do
    orig_value = r8(location+i)
    w8(location+i, orig_value + diff)
  end
  -- print(string.format("done distorting %d %d", old, new))
end

function tileswapper()
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

function band(thing, add)
  return thing > 0x1600 and thing < 0x2000
end

function crossswapper()
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


function distorter_v0(old, new)
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

local knobs = {
  [41] = {value = 0, cb = distorter_v0}

}

local knobs_data = {
  [41] = 0,
  [42] = 0,
  [43] = 0,
  [44] = 0,
  [45] = 0,
  [46] = 0,
  [47] = 0,
  [48] = 0,
  [21] = 0,
  [22] = 0,
  [23] = 0,
  [24] = 0,
  [25] = 0,
  [26] = 0,
  [27] = 0,
  [28] = 0
}

function max_health_distorter(old, new)
  print("max health distorter called.")
  --  normalize to 20 hearts
  hearts = 1 + math.floor(new * 19 / 127)
  hex_hearts = 0x8 * hearts
  print(hex_hearts)
  memory.usememorydomain("WRAM")
  w8(WRAM.max_health, hex_hearts)

end

function health_distorter(old, new)
  -- print("health distorter called.")
  memory.usememorydomain("WRAM")
  -- max hearts, in decimal form
  max_hearts = r8(WRAM.max_health)
  -- relate the 0-127 value to the number of max hearts
  hearts = 1 + math.floor(new * max_hearts / (129 * 4))
  hex_hearts = 0x4 * hearts

  w8(WRAM.health, hex_hearts)

  -- writing to these VRAM spots didn't seem effective
  -- memory.usememorydomain("VRAM")
  -- memory.write_u16_le(VRAM.health_start, 0x7F20)
  -- memory.write_u16_le(0xC138, 0x207F)
  -- memory.write_u16_le(0xC139, 0x207F)
  -- memory.write_u16_le(0xC13A, 0x207F)
  -- memory.write_u16_le(0xC13B, 0x207F)
  -- memory.write_u16_le(0xC17A, 0xA024)
  -- memory.write_u16_le(0xC17C, 0xA024)
end

function palette_distorter(old, new)
  diff = new - old
  memory.usememorydomain("CGRAM")
  for i=0x0001, 0x040, 0x2 do
    val = r8(i)
    updated = 0x0 + ((val + diff) % 128)
    -- print("updating", val, "to", updated)
    w8(i, updated)
  end
end

local knob_state = {
  [41] = {current = 0, new = 0, cb = palette_distorter},
  [42] = {current = 0, new = 0},
  [43] = {current = 0, new = 0},
  [44] = {current = 0, new = 0},
  [45] = {current = 0, new = 0},
  [46] = {current = 0, new = 0},
  [47] = {current = 0, new = 0, cb = health_distorter},
  [48] = {current = 0, new = 0, cb = max_health_distorter},
  [21] = {current = 0, new = 0},
  [22] = {current = 0, new = 0},
  [23] = {current = 0, new = 0},
  [24] = {current = 0, new = 0},
  [25] = {current = 0, new = 0},
  [26] = {current = 0, new = 0},
  [27] = {current = 0, new = 0},
  [28] = {current = 0, new = 0},
}

function update_knob_state()
  for key,value in pairs(knob_state) do
    if value.current ~= value.new and value.cb ~= nil then
      -- print("found an update to do:", key, value.current, value.new)
      knob_state[key].cb(value.current, value.new)
      knob_state[key].current = value.new
    end
  end
end

function update_knob_value(knob, value)
  -- if (knobs[knob] ~= nil) then
  --   knobs[knob].cb(knobs[knob].value, value)
  -- end
  

  local funspot_offset = 0
  -- horizontally distort on each knob
  if (knob >= 41) then
    funspot_offset = knob - 41
  else
    funspot_offset = 8 + (knob - 21)
  end
  location = VRAM.funspot + (bytes_to_fuck * funspot_offset)
  horizontal_distorter(location, knobs_data[knob], value)

  knobs_data[knob] = value
end

if midi.getinportcount() > 0 then
	-- table.foreach(midi.enumerateinports(), print)
	print( 'Receiving on device: ', luamidi.getInPortName(0))

local seconds = os.clock()
local framecounter = 0

	local a, b, c, d = nil
  while true do
    framecounter = framecounter + 1

    -- recive midi command from input-port 0
		-- command, note, velocity, delta-time-to-last-event (just ignore)
    a,b,c,d = midi.getMessage(0)
    
    while a ~= nil do
      -- look for an NoteON command
      if a == 152 and c == 127 then
        print('Note turned ON:	', a, b, c)
        if (b == 9) then
          tileswapper()
        elseif (b == 10) then
          crossswapper()
        end
      -- look for an NoteOFF command
      elseif a == 136 and c == 0 then
        print('Note turned OFF:', a, b, c)
      elseif a == 184 then -- knob turns
        -- 
        -- print("knob turn??", framecounter, a, b, c)
        knob_state[b].new = c
      else 
        print('Some other command:', a, b, c, d)
      end
      a,b,c,d = midi.getMessage(0)
    end


    -- should be running about 60 fps
    if (framecounter % 5 == 0) then
      update_knob_state()
    end

    emu.frameadvance()
	end
end

-- deinitialize library
midi.gc()