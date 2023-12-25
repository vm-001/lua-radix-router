local fmt = string.format
local function timing(fn)
  local start_time = os.clock()
  fn()
  return os.clock() - start_time
end

local function print_result(result)
  print(fmt("========== %s ==========", result.title))
  print("routes  :", result.routes)
  print("times   :", result.times)
  print("elapsed :", result.elapsed .. " s")
  print("QPS     :", math.floor(result.times / result.elapsed))
  print("ns/op   :", result.elapsed * 1000 * 1000 / result.times .. " ns")
  print("path    :", result.benchmark_path)
  print("handler :", result.benchmark_handler)
  print()
end

return {
  timing = timing,
  print_result = print_result,
}
