--- Route a route defines the matching conditions of its handler.
--
-- @module radix-router.route

local ipairs = ipairs
local str_byte = string.byte
local str_find = string.find
local BYTE_SLASH = str_byte("/")

local Route = {}
local mt = { __index = Route }


function Route.new(route)
  if route.handler == nil then
    return nil, "handler must not be nil"
  end

  for _, path in ipairs(route.paths) do
    if str_byte(path) ~= BYTE_SLASH then
      return nil, "path must starts with /"
    end
    local _, pattern_idx = str_find(path, "{%*[^}]*}")
    if pattern_idx ~= nil and pattern_idx ~= #path then
      return nil, "invalid prefix pattern"
    end
  end

  return setmetatable(route, mt)
end


function Route:compare(other)
  return (self.priority or 0) > (other.priority or 0)
end


return Route
