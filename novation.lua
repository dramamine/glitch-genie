-- initialize the library
local midi = require "luamidi"

local debounce_time = 0.0
local bytes_to_fuck = 256

local WRAM = {
	anim = 0x0002E,
	update_cg_ram = 0x00015, --"update CGRAM (0x200 bytes)"
	cgram_location_read = 0x2121,
  cgram_location_write = 0x2122
}

local VRAM = {
  -- funspot = 0x1AA9
  funspot = 0x1000
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
print(memory.getmemorydomainlist())
memory.usememorydomain("VRAM")

-- look for available input ports
print("Midi Input Ports: ", midi.getinportcount())

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
	print()

local seconds = os.clock()

	local a, b, c, d = nil
	while true do
		-- recive midi command from input-port 0
		-- command, note, velocity, delta-time-to-last-event (just ignore)
    a,b,c,d = midi.getMessage(0)
		
		if a ~= nil then
			-- look for an NoteON command
			if a == 152 and c == 127 then
        print('Note turned ON:	', a, b, c)
        tileswapper()
			-- look for an NoteOFF command
			elseif a == 136 and c == 0 then
        print('Note turned OFF:', a, b, c)
      elseif a == 184 then
        -- crude debounce
        local current_seconds = os.clock()
        if current_seconds > (seconds + debounce_time) then
          update_knob_value(b, c)
          seconds = current_seconds
        end
      else 
        print('Some other command:', a, b, c, d)
			end
    end

    emu.frameadvance()
	end
end

-- deinitialize library
midi.gc()