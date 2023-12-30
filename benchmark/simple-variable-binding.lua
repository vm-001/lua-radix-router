local Router = require "radix-router"
local utils = require "benchmark.utils"

local route_n = os.getenv("RADIX_ROUTER_ROUTES") or 1000 * 100
local times = os.getenv("RADIX_ROUTER_TIMES") or 1000 * 1000 * 10

local router
do
  local routes = {}
  for i = 1, route_n do
    routes[i] = { paths = { string.format("/%d/{name}", i) }, handler = i }
  end
  router = Router.new(routes)
end

local rss_mb = utils.get_rss()

local path = "/1/foo"
local params = {}

local elapsed = utils.timing(function()
  for _ = 1, times do
    router:match(path, nil, params)
  end
end)

utils.print_result({
  title = "variable",
  routes = route_n,
  times = times,
  elapsed = elapsed,
  benchmark_path = path,
  benchmark_handler = router:match(path),
  rss = rss_mb,
}, {
  { name = "params", value = string.format("name = " .. params.name) }
})
