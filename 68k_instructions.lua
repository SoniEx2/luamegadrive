local function cycles(n)
  for i=1,n do
    coroutine.yield("cycle")
  end
end

return {
  cycles = cycles,
}