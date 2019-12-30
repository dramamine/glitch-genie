-- initialize the library
local midi = require "luamidi"
local glitches = dofile("glitches.lua")
local utils = dofile("utils.lua")
-- print(_VERSION) -- Lua 5.1 expected

-- look for available input ports
-- print("Midi Input Ports: ", midi.getinportcount())

-- @todo unused?
function band(thing, add)
  return thing > 0x1600 and thing < 0x2000
end

local knob_state = {
  [41] = {current = 0, new = 0, cb = glitches.palette_distorter},
  [42] = {current = 0, new = 0, cb = glitches.music_select_v0},
  [43] = {current = 0, new = 0, cb = glitches.sfx1_select_v0},
  [44] = {current = 0, new = 0},
  [45] = {current = 0, new = 0},
  [46] = {current = 0, new = 0},
  [47] = {current = 0, new = 0, cb = glitches.health_distorter},
  [48] = {current = 0, new = 0, cb = glitches.max_health_distorter},
  [21] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [22] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [23] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [24] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [25] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [26] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [27] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
  [28] = {current = 0, new = 0, cb = glitches.horizontal_distorter_v0},
}

function update_knob_state()
  for key,value in pairs(knob_state) do
    if value.current ~= value.new and value.cb ~= nil then
      -- print("found an update to do:", key, value.current, value.new)
      knob_state[key].cb(value.current, value.new, key)
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

midi_id = 6

if midi.getinportcount() > 0 then
	-- table.foreach(midi.enumerateinports(), print)
	print( 'Receiving on device!: ', luamidi.getInPortName(midi_id))

local seconds = os.clock()
local framecounter = 0

	local a, b, c, d = nil
  while true do
    framecounter = framecounter + 1

    -- recive midi command from input-port 0
		-- command, note, velocity, delta-time-to-last-event (just ignore)
    a,b,c,d = midi.getMessage(midi_id)

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
