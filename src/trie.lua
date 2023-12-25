--- Trie
--
--

local utils = require "radix-router.utils"
local constants = require "radix-router.constatns"

local str_sub = string.sub
local lcp = utils.lcp
local type = type

local EMPTY = utils.readonly({})
local TOKEN_TYPES = constants.token_types
local TYPES = constants.node_types

local TrieNode = {}
local mt = { __index = TrieNode }


function TrieNode.new(o)
  o = o or EMPTY

  local self = {
    path = o.path,
    path_n = o.path and #o.path or 0,
    children = o.children,
    n = o.n or 0,
    type = o.type,
    value = o.value,
  }

  return setmetatable(self, mt)
end


function TrieNode:set(value, fn)
  if type(fn) == "function" then
    fn(self)
    return
  end
  self.value = value
end


local function insert(node, path, value, fn, parser)
  parser:update(path)
  local token, token_type = parser:next()
  while token do
    if token_type == TOKEN_TYPES.variable then
      node.type = TYPES.variable
      node.path_n = 0
    elseif token_type == TOKEN_TYPES.catchall then
      node.type = TYPES.catchall
      node.path_n = 0
    else
      node.type = TYPES.literal
      node.path = token
      node.path_n = #token
    end

    token, token_type = parser:next()
    if token then
      local child = TrieNode.new()
      node.n = node.n + 1
      if token_type == TOKEN_TYPES.literal then
        local char = str_sub(token, 1, 1)
        node.children = { [char] = child }
      else
        node.children = { [token_type] = child }
      end
      node = child
    end
  end

  node:set(value, fn)
end


local function split(node, path, prefix_n)
  local child = TrieNode.new({
    path = str_sub(node.path, prefix_n + 1),
    n = node.n,
    type = TYPES.literal,
    value = node.value,
    children = node.children,
  })

  -- update current node
  node.path = str_sub(path, 1, prefix_n)
  node.path_n = #node.path
  node.n = 1
  node.type = TYPES.literal
  node.value = nil
  node.children = { [str_sub(child.path, 1, 1)] = child }
end


function TrieNode:add(path, value, fn, parser)
  if not self.path and not self.type then
    -- insert to current empty node
    insert(self, path, value, fn, parser)
    return
  end

  local node = self
  local token, token_type
  while true do
    local common_prefix_n = lcp(node.path, path)

    if common_prefix_n < node.path_n then
      split(node, path, common_prefix_n)
    end

    if common_prefix_n < #path then
      if node.type == TYPES.variable then
        -- token must a variable
        path = str_sub(path, #token + 1)
        if #path == 0 then
          break
        end
      elseif node.type == TYPES.catchall then
        -- token must a catchall
        -- catchall node matches entire path
        break
      else
        path = str_sub(path, common_prefix_n + 1)
      end

      local child
      if node.children then
        local first_char = str_sub(path, 1, 1)
        if node.children[first_char] then
          -- found literal child
          child = node.children[first_char]
        else
          parser:update(path)
          token, token_type = parser:next() -- store the next token of path
          if node.children[token_type] then
            -- found either variable or catchall child
            child = node.children[token_type]
          end
        end
      end

      if child then
        node = child
      else
        child = TrieNode.new()
        node.n = node.n + 1
        insert(child, path, value, fn, parser)
        node.children = node.children or {}
        if child.type == TYPES.literal then
          local first_char = str_sub(path, 1, 1)
          node.children[first_char] = child
        else
          node.children[token_type] = child
        end
        return
      end
    else
      break
    end
  end

  node:set(value, fn)
end


return TrieNode
