comptime Bytes = List[Byte]

@fieldwise_init
struct ReadResult(Boolable, Writable, Movable):
   var pos: Int

   var size: Int
   var data: Bytes

   def __bool__(self) -> Bool:
      return self.size > 0

   def write_to(self, mut writer: Some[Writer]):
      var data = String()
      for b in self.data:
         data.write(b, " ")
      var written = String(
         "pos: ", self.pos, ", ",
         "size: ", self.size, ", ",
         "data: [", String(data[byte=:-1]) if data else "", "]"
      )    
      writer.write(written)


struct PresetParser:
   var debug: Bool

   def __init__(out self):
      self.debug = False

   def process_preset(mut self, file_name: String, debug: Bool = False) raises:
      self.debug = debug
      var pos: Int = 0x36

      var f = open(file_name, "r")
      while True:
         var result = self.read_key_and_value(f, pos)
         pos = result.pos
         if result.size == 0: break
      f.close()

   def read_key_and_value(self, f: FileHandle, mut pos: Int) raises -> ReadResult:
      var skips = self.get_skip_size(f, pos)
      if self.debug:
         self.get_skip_size_debug(f, pos)
         print(skips, "skips")
      pos += skips

      var result = self.read_next_size_and_chunk(f, pos)
      pos = result.pos
      _ = result.size
      print(String("[{}] ").format(PresetParser.vec_to_string(result.data)), end="")

      skips = self.get_skip_size(f, pos)
      if self.debug:
         self.get_skip_size_debug(f, pos)
         print(skips, "skips")
      pos += skips

      result = self.read_next_size_and_chunk(f, pos)
      print(PresetParser.vec_to_string(result.data))

      return ReadResult(result.pos, result.size, Bytes())

   def get_skip_size(self, f: FileHandle, mut pos: Int) raises -> Int:
      var result = self.read_from_file(f, pos, 32, True)
      for i in range(len(result.data)):
         if result.data[i] >= 0x20 and (i == 5 or i == 8 or i == 13):
            return i - 4
      return 1

   def get_skip_size_debug(self, f: FileHandle, mut pos: Int) raises:
      var result = self.read_from_file(f, pos, 32, True)
      print("")
      for b in range(len(result.data)):
         print(String("{0} ").format(self.byte_to_hex(UInt8(b))), end="")
      print()
      for b in range(len(result.data)):
         if result.data[b] >= 0x31:
            print(String(".{0}.").format(chr(result.data[b].__int__())), end="")
         else:
            print("   ", end="")
      print()

   def byte_to_hex(self, b: Byte) -> String:
      var s = hex(b.__int__(), prefix="")  # String
      # For a single byte, hex() will produce 1–2 chars; pad if needed
      if s.__len__() == 1:
         return "0" + s
      return s

   def read_next_size_and_chunk(self, f: FileHandle, mut pos: Int) raises -> ReadResult:
      var int_chunk = self.read_int_chunk(f, pos)
      if not int_chunk:
         return ReadResult(pos, 0, Bytes())
      return self.read_from_file(f, int_chunk.pos, int_chunk.size, True)

   def read_int_chunk(self, f: FileHandle, mut pos: Int) raises -> ReadResult:
      var new_read = self.read_from_file(f, pos, 4, True)
      if not new_read.data:
         return ReadResult(0, 0, Bytes())
      pos = new_read.pos
      var size: UInt32 = 0
      for i in range(4):
         size |= new_read.data[i].cast[DType.uint32]() << UInt32(((3 - i) * 8))
      return ReadResult(pos, Int(size), Bytes())

   @staticmethod
   def print_byte_vector(data: Bytes) raises:
      for i in range(len(data)):
         print(String("{0:02x} ").format(data[i]), end="")
      print()

   @staticmethod
   def read_from_file(f: FileHandle, pos: Int, size: Int, advance: Bool) raises -> ReadResult:
      try:
         _ = f.seek(UInt64(pos))
      except:
         return ReadResult(0, 0, Bytes())
      var data: Bytes = f.read_bytes(size)
      return ReadResult(pos + size if advance else 0, size, data^)

   @staticmethod
   def vec_to_string(data: Bytes) -> String:
      var result = String()
      for i in range(len(data)):
         if data[i] == 0x00:
            break
         result += chr(data[i].__int__())
      return result
