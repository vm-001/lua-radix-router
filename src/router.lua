--- Router the router engine
--
--

local Trie = require "radix-router.trie"
local Route = require "radix-router.route"
local Parser = require "radix-router.parser"
local Iterator = require "radix-router.iterator"
local utils = require "radix-router.utils"

local ipairs = ipairs

local Router = {}
local mt = { __index = Router }

local EMPTY = utils.readonly({})


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
    local routes = node.value
    if not routes then
      node.value = { [0] = 1, path_route }
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
end


--- new a Router instance
-- @tab routes
-- @tab options
function Router.new(routes, options)
  if routes ~= nil and type(routes) ~= "table" then
    return nil, "invalid argument: routes"
  end

  options = options or EMPTY
  routes = routes or EMPTY

  local self = {
    options = options,
    parser = Parser.new("default"),
    static = {},
    trie = Trie.new(),
    iterator = Iterator.new(),
  }

  local route_opts = {
    parser = self.parser
  }

  for i, route in ipairs(routes) do
    local route_t, err = Route.new(route, route_opts)
    if err then
      return nil, "invalid route(index " .. i .. "): " .. err
    end

    for _, path in ipairs(route.paths) do
      add_route(self, path, route_t)
    end
  end

  return setmetatable(self, mt)
end


local function find_route(routes, ctx, matched)
  if routes[0] == 1 then
    local route = routes[1][2]
    if route:is_match(ctx, matched) then
      return route, routes[1][1]
    end
    return nil, nil
  end

  for n = 1, routes[0] do
    local route = routes[n][2]
    if route:is_match(ctx, matched) then
      return route, routes[n][1]
    end
  end

  return nil, nil
end


--- return the handler of a Route that matches the path and ctx
-- @string path the path
-- @tab ctx the condition ctx
-- @tab params table to store the parameters
-- @tab matched table to store the matched condition
function Router:match(path, ctx, params, matched)
  ctx = ctx or EMPTY

  local matched_route, matched_path

  local routes = self.static[path]
  if routes then
    matched_route, matched_path = find_route(routes, ctx, matched)
    if matched_route then
      if matched then
        matched.path = matched_path
      end
      return matched_route.handler
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
        matched_route, matched_path = find_route(values[n], ctx, matched)
        if matched_route then
          if matched then
            matched.path = matched_path
          end
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
      self.parser:update(matched_path):bind_params(path, path_n, params)
    end
    return matched_route.handler
  end

  return nil
end


return Router
