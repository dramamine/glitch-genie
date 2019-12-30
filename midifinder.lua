-- run this script to see the names of your MIDI devices.
-- this should work with all 5.x versions of Lua (i.e. you can run
-- it with BizHawk or independently)

-- initialize the library
local midi = require "luamidi"

-- look for available input ports
print("Midi Input Ports: ", midi.getinportcount())
print("Midi Input Ports: ", midi.enumerateinports())

if midi.getinportcount() > 0 then
	table.foreach(midi.enumerateinports(), print)
	print( 'Receiving on device: ', luamidi.getInPortName(0))
	print()

end

-- deinitialize library
midi.gc()
