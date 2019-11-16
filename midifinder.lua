-- initialize the library
local midi = require "luamidi"

-- look for available input ports
print("Midi Input Ports: ", midi.getinportcount())

if midi.getinportcount() > 0 then
	table.foreach(midi.enumerateinports(), print)
	print( 'Receiving on device: ', luamidi.getInPortName(0))
	print()

	local a, b, c, d = nil
	while true do
		-- recive midi command from input-port 0
		-- command, note, velocity, delta-time-to-last-event (just ignore)
		a,b,c,d = midi.getMessage(0)
		
		if a ~= nil then
			-- look for an NoteON command
			if a == 144 then
				print('Note turned ON:	', a, b, c, d)
			-- look for an NoteOFF command
			elseif a == 128 then
        print('Note turned OFF:', a, b, c, d)
      else 
        print('Some other command:', a, b, c, d)
			end
		end
	end
end

-- deinitialize library
midi.gc()