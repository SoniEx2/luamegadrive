local ffi = require("ffi")

-- 68k state
ffi.cdef[[
typedef union m68k_ram_union {
  uint8_t *ub;
  int8_t *b;
  uint16_t *uw;
  int16_t *w;
  uint32_t *ul;
  int32_t *l;
} m68k_ram_union_t;

typedef union m68k_reg {
  uint8_t ub;
  int8_t b;
  uint16_t uw;
  int16_t w;
  uint32_t ul;
  int32_t l;
} m68k_reg_t;

typedef struct m68k_state {
  m68k_reg_t a_reg[8]; // address registers
  m68k_reg_t d_reg[8]; // data registers
  uint32_t pc; // program counter
  uint16_t sr; // status register (also condition code register)
  uint8_t *ram;
} m68k_state_t;

void *memcpy(void *dest, const void *src, size_t n);
void *malloc(size_t size);
void free(void *ptr);
]]

--local m68kVM = require("68k_instructions")

local bigendian = ffi.abi("be")

local _m68k = {}

function _m68k:load(program)
  -- make RAM
  self.RAM = ffi.gc(ffi.C.malloc(2^24), ffi.C.free)
  ffi.fill(self.RAM, 2^24)
  if program then
    ffi.C.memcpy(self.RAM, program, #program) -- no need to add 1 because .fill is already zeroing
  end

  self.state = ffi.new("m68k_state_t")
  self.state.ram = self.RAM
end

-- Setup endianness
if bigendian then
  function _m68k:access(addr, size)
    local n = bit.band(addr, 2^24-1) -- damn pointer arithmetic
    -- yes we have to split the next 3 lines
    -- otherwise we segfault
    local x = ffi.new("m68k_ram_union_t")
    x.ub = self.state.ram + n
    return x
  end
else
  function _m68k:access(addr, size)
    local n = (2^24-size) - bit.band(addr, 2^24-1)
    -- yes we have to split the next 3 lines
    -- otherwise we segfault
    local x = ffi.new("m68k_ram_union_t")
    x.ub = self.state.ram + n
    return x
  end
end

function _m68k:getlong(addr)
  return self:access(addr, 4).l[0]
end
function _m68k:getword(addr)
  return self:access(addr, 2).w[0]
end
function _m68k:getbyte(addr)
  return self:access(addr, 1).b[0]
end
function _m68k:getulong(addr)
  return self:access(addr, 4).ul[0]
end
function _m68k:getuword(addr)
  return self:access(addr, 2).uw[0]
end
function _m68k:getubyte(addr)
  return self:access(addr, 1).ub[0]
end

function _m68k:setlong(addr, value)
  self:access(addr, 4).l[0] = value
end
function _m68k:setword(addr, value)
  self:access(addr, 2).w[0] = value
end
function _m68k:setbyte(addr, value)
  self:access(addr, 1).b[0] = value
end
function _m68k:setulong(addr, value)
  self:access(addr, 4).ul[0] = value
end
function _m68k:setuword(addr, value)
  self:access(addr, 2).uw[0] = value
end
function _m68k:setubyte(addr, value)
  self:access(addr, 1).ub[0] = value
end

local function make68k()
  local m68k = {}

  for x,y in pairs(_m68k) do
    m68k[x] = y
  end

  m68k.bigendian = bigendian

  return m68k
end

--[[
local function ramtest()
  local m68k = make68k()
  m68k:load()
  for i = 0, 2^24-4 do
    local x = m68k:access(i, 4)
    assert(x.l[0] == 0, tostring(x.l[0]))
  end
  local x = m68k:access(3, 1)
  x.ub[0] = 128
  local x = m68k:access(0, 4)
  assert(x.l[0] == 0x00000080)
end

local function test()
  ramtest()
end

test()
print("Done")
--]]

return {make68k=make68k}