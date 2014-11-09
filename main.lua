if not jit then error("Coudn't find LuaJIT") end
if not pcall(require,"ffi") then error("Couldn't find FFI") end

local love = love

io.stdout:setvbuf("no")

m68k = require("68k")

local cpu = m68k.make68k()

function love.load()
  -- cpu:load()
end

function love.update(dt)
  -- cpu:update()
  -- TODO
end

function love.draw()
  -- TODO
end