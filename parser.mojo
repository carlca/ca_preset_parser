from presetparser import PresetParser
from sys.arg import argv
from os.path import dirname, join

fn main() raises:
   var args = argv()
   if len(args) == 0:
      print("Usage: mojo preset_parser <preset file>")
      return
   var app_dir = dirname(args[0])
   var filename = join(app_dir, args[1])
   var pp = presetparser.PresetParser()
   pp.process_preset(filename, False)   # 2nd param is debug flag
   print()
