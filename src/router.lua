--- Radix-Router is a lightweight high-performance and radix tree based router matching library.
--
-- @module radix-router

local Trie = require "radix-router.trie"
local Route = require "radix-router.route"
local Parser = require "radix-router.parser"
local Iterator = require "radix-router.iterator"
local Options = require "radix-router.options"
local Matcher = require "radix-router.matcher"
local utils = require "radix-router.utils"
local constants = require "radix-router.constants"

local ipairs = ipairs
local str_byte = string.byte
local str_sub = string.sub
local idx = constants.node_indexs
local regex_test = utils.regex_test

local BYTE_SLASH = str_byte("/")
local EMPTY = utils.readonly({})

local Router = {}
local mt = { __index = Router }


local function add_route(self, path, route)
  local path_route = { path, route }
  local is_dynamic = self.parser.is_dynamic(path)
  if not is_dynamic then
    -- static path
    local routes = self.static[path]
    if not routes then
      self.static[path] = { [0] = 1, path_route }
    else
      routes[0] = routes[0] + 1
      routes[routes[0]] = path_route
      table.sort(routes, function(o1, o2)
        local route1 = o1[2]
        local route2 = o2[2]
        return route1:compare(route2)
      end)
    end
    return
  end

  -- dynamic path
  self.trie:add(path, nil, function(node)
    local routes = node[idx.value]
    if not routes then
      node[idx.value] = { [0] = 1, path_route }
      return
    end
    routes[0] = routes[0] + 1
    routes[routes[0]] = path_route
    table.sort(routes, function(o1, o2)
      local route1 = o1[2]
      local route2 = o2[2]
      return route1:compare(route2)
    end)
  end, self.parser)

  if self.parser.contains_regex(path) then
    self.regexs[path] = self.parser:update(path):compile_regex()
  end
end


--- create a new router.
-- @tab[opt] routes a list-like table of routes
-- @tab[opt] opts options table
-- @return a new router, or nil
-- @return cannot create router error
-- @usage
-- local router, err = router.new({
--   {
--     paths = { "/hello-{word}" },
--     methods = { "GET" },
--     handler = "hello handler",
--   },
-- })
function Router.new(routes, opts)
  if routes ~= nil and type(routes) ~= "table" then
    return nil, "invalid args routes: routes must be table or nil"
  end

  local options, err = Options.options(opts)
  if not options then
    return nil, "invalid args opts: " .. err
  end

  local matcher, err = Matcher.new(options.matcher_names, options.matchers)
  if err then
    return nil, "invalid args opts: " .. err
  end

  local self = {
    options = options,
    parser = Parser.new("default"),
    static = {},
    regexs = {},
    regexs_cache = {},
    trie = Trie.new(),
    iterator = Iterator.new(options),
    matcher = matcher,
  }

  for i, route in ipairs(routes or EMPTY) do
    local ok, err = self.matcher:process(route)
    if not ok then
      return nil, "unable to process route(index " .. i .. "): " .. err
    end

    local route_t, err = Route.new(route)
    if err then
      return nil, "invalid route(index " .. i .. "): " .. err
    end

    for _, path in ipairs(route.paths) do
      add_route(self, path, route_t)
    end
  end

  return setmetatable(self, mt)
end


local function find_route(self, path, routes, ctx, matched, evaluate_regex)
  for n = 1, routes[0] do
    local route_path = routes[n][1]
    local route = routes[n][2]
    local regex_matched = true
    if evaluate_regex then
      local regex = self.regexs[route_path]
      if regex then
        regex_matched = regex_test(path, regex, self.regexs_cache)
      end
    end
    if regex_matched and self.matcher:match(route, ctx, matched) then
      if matched then
        matched.path = route_path
      end
      return route, route_path
    end
  end

  return nil
end


--- find a handler of route that matches the path and ctx.
-- @string path the request path
-- @tab[opt] ctx the request context
-- @tab[opt] params a table to store the parsed parameters
-- @tab[opt] matched a table to store the matched conditions, such as path, method and host
-- @return the handler of a route matches the path and ctx, or nil if not found
-- @usage
-- local params = {}
-- local matched = {}
-- local handler = router:match("/hello-world", { method = "GET" }, params, matched)
function Router:match(path, ctx, params, matched)
  ctx = ctx or EMPTY

  local trailing_slash_match = self.options.trailing_slash_match
  local matched_route, matched_path

  local routes = self.static[path]
  if routes then
    matched_route, matched_path = find_route(self, path, routes, ctx, matched)
    if matched_route then
      return matched_route.handler
    end
  end

  if trailing_slash_match then
    if str_byte(path, -1) == BYTE_SLASH then
      routes = self.static[str_sub(path, 1, -2)]
    else
      routes = self.static[path .. "/"]
    end
    if routes then
      matched_route, matched_path = find_route(self, path, routes, ctx, matched)
      if matched_route then
        return matched_route.handler
      end
    end
  end

  local path_n = #path
  local node = self.trie
  local state_path = path
  local state_path_n = path_n
  repeat
    local values, count = self.iterator:find(node, state_path, state_path_n)
    if values then
      for n = count, 1, -1 do
        matched_route, matched_path = find_route(self, path, values[n], ctx, matched, true)
        if matched_route then
          break
        end
      end
      if matched_route then
        break
      end
    end
    node, state_path, state_path_n = self.iterator:prev()
  until node == nil

  if matched_route then
    if params then
      self.parser:update(matched_path):bind_params(path, path_n, params, trailing_slash_match)
    end
    return matched_route.handler
  end

  return nil
end


return Router
