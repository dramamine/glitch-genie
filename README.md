## Glitch Genie

### How To Run

- Run `EmuHawk.exe` and make sure the SNES core is set to `BSNES` - the `SNES9x` core does not support all the memory loactions we want to update.
- Load the ROM file `Legend of Zelda, The - A Link to the Past (USA).src`
  - Note that you can turn on Autoload (from the File -> Recent ROM menu) to save clicks
- Tools -> Lua Console
- Choose "Run script" and open `novation.lua` 

### MIDI controllers

I'm using a Novation LaunchControl which has these inputs
- knobs 21-28
- knobs 41-48
- buttons 9-12 (note on: 152, note off: 136)
- buttons 25-28

Can probably use other MIDI controllers by writing a script equivalent to `novation.lua`.

Use `midifinder.lua` to check on the status of MIDI devices.

### Save states
@todo: where is the best part of the game to drop the player? or, should we cycle through some spots when player hits 'reset'?

@todo: can we put text on the screen using lua scripting? i.e. "IDCLIP mode on" "IDCLIP mode off" for glitches that aren't clear

@todo: instead of `print`, can we write to a log file and avoid the issue of bad framerates when `print`ing?
