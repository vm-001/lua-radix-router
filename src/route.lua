--- Route a route defines the matching conditions of its handler.
--
--

local utils = require "radix-router.utils"
local bit = utils.is_luajit and require "bit"

local ipairs = ipairs
local str_byte = string.byte
local BYTE_SLASH = str_byte("/")
local is_luajit = utils.is_luajit

local METHODS = {}
do
  local methods = { "GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE", "PATCH" }
  for i, method in ipairs(methods) do
    if is_luajit then
      METHODS[method] = bit.lshift(1, i - 1)
    else
      METHODS[method] = true
    end
  end
end

local Route = {}
local mt = { __index = Route }


function Route.new(route, opts)
  if route.handler == nil then
    return nil, "handler must not be nil"
  end

  local self = {
    handler = route.handler,
    priority = route.priority,
  }

  -- route.paths
  for _, path in ipairs(route.paths) do
    if str_byte(path) ~= BYTE_SLASH then
      return nil, "path must start with /"
    end
  end

  -- route.methods
  if route.methods then
    local methods_bit = 0
    local methods = {}
    for _, method in ipairs(route.methods) do
      if not METHODS[method] then
        return nil, "invalid methond"
      end
      if is_luajit then
        methods_bit = bit.bor(methods_bit, METHODS[method])
      else
        methods[method] = true
      end
    end
    self.method = is_luajit and methods_bit or methods
  end

  return setmetatable(self, mt)
end


function Route:is_match(ctx)
  if self.method then
    local method = ctx.method
    if not method or METHODS[method] == nil then
      return false
    end
    if is_luajit then
      if bit.band(self.method, METHODS[method]) == 0 then
        return false
      end
    else
      if not self.method[method] then
        return false
      end
    end
  end

  return true
end


function Route:compare(other)
  return (self.priority or 0) > (other.priority or 0)
end


return Route
