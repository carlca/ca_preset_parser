from presetparser import PresetParser
from std.sys.arg import argv
from std.os.path import dirname, join

def main() raises:
   var args = argv()
   if len(args) == 0:
      print("Usage: mojo preset_parser <preset file>")
      return
   var app_dir = dirname(args[0])
   var filename = join(app_dir, args[1])
   var pp = PresetParser()
   pp.process_preset(filename, False)   # 2nd param is debug flag
   print()
