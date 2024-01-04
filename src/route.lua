--- Route a route defines the matching conditions of its handler.
--
--

local utils = require "radix-router.utils"
local bit = utils.is_luajit and require "bit"

local ipairs = ipairs
local str_byte = string.byte
local starts_with = utils.starts_with
local ends_with = utils.ends_with

local BYTE_SLASH = str_byte("/")
local BYTE_ASTERISK = str_byte("*")
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


function Route.new(route, _)
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

  -- route.hosts
  if route.hosts then
    local hosts = { [0] = 0 }
    for _, host in ipairs(route.hosts) do
      local host_n = #host
      local wildcard_n = 0
      for n = 1, host_n do
        if str_byte(host, n) == BYTE_ASTERISK then
          wildcard_n = wildcard_n + 1
        end
      end
      if wildcard_n > 1 then
        return nil, "invalid host"
      elseif wildcard_n == 1 then
        local n = hosts[0] + 1
        hosts[0] = n
        hosts[n] = host -- wildcard host
      else
        hosts[host] = true
      end
    end
    self.hosts = hosts
  end

  return setmetatable(self, mt)
end


function Route:is_match(ctx, matched)
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

    if matched then
      matched.method = method
    end
  end

  if self.hosts then
    local host = ctx.host
    if not host then
      return false
    end
    if not self.hosts[host] then
      if self.hosts[0] == 0 then
        return false
      end

      local wildcard_match = false
      local host_n = #host
      local wildcard_host, wildcard_host_n
      for i = 1, self.hosts[0] do
        wildcard_host = self.hosts[i]
        wildcard_host_n = #wildcard_host
        if host_n >= wildcard_host_n then
          if str_byte(wildcard_host) == BYTE_ASTERISK then
            -- case *.example.com
            if ends_with(host, wildcard_host, host_n, wildcard_host_n, 1) then
              wildcard_match = true
              break
            end
          else
            -- case example.*
            if starts_with(host, wildcard_host, host_n, wildcard_host_n - 1) then
              wildcard_match = true
              break
            end
          end
        end
      end
      if not wildcard_match then
        return false
      end
      if matched then
        matched.host = wildcard_host
      end
    else
      if matched then
        matched.host = host
      end
    end
  end

  return true
end


function Route:compare(other)
  return (self.priority or 0) > (other.priority or 0)
end


return Route
