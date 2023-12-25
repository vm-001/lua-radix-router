# Lua-radix-router

Lua-radix-router is a lightweight high performance router for Lua/LuaJIT.


## Installation

Install via LuaRocks:

```
luarocks install radix-router
```

## Usage

```lua
local Router = require "radix-router"
local router, err = Router.new({
  {
    paths = { "/foo", "/foo/bar", "/html/index.html" },
    handler = "1" -- handler can be any non-nil value. (e.g. boolean, table, function)
  },
  {
    -- variable path
    paths = { "/users/{id}/profile-{year}.{format}" },
    handler = "2"
  },
  {
    -- prefix path
    paths = { "/api/authn/{*path}" },
    handler = "3"
  },
  {
    -- methods
    paths = { "/users/{id}" },
    methods = { "POST" },
    handler = "4"
  }
})
if not router then
  error("failed to create router: " .. err)
end

assert("1" == router:match("/html/index.html"))
assert("2" == router:match("/users/100/profile-2023.pdf"))
assert("3" == router:match("/api/authn/token/genreate"))
assert("4" == router:match("/users/100", { method = "POST" }))

-- parameter binding
local params = {}
router:match("/users/100/profile-2023.pdf", nil, params)
assert(params.year == "2023")
assert(params.format == "pdf")
```

## Methods

### new
Creates a radix router instance.

```lua
local router, err = Router.new(routes)
```

**Parameters**

- **routes **(`table|nil`): the array-like Route table.



Route defines the matching conditions for its handler.

| PROPERTY                      | DESCRIPTION                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| `paths`  *required\**         | The path list of matching condition.                         |
| `methods` *optional*          | The method list of matching condition.                       |
| `handler` *required\**        | The `handler` will be returned by `router:match()` when the route is matched. |
| `expression` *optional* (TDB) | The `expression` defines a customized matching condition by using expression language. |



### match

Return the handler of a matched route that matches the path and condition ctx.

```lua
local handler = router:match(path, ctx, params)
```

**Parameters**

- **path**(`string`): the path to use for matching.
- **ctx**(`table|nil`): the optional condition ctx to use for matching.
- **params**(`table|nil`): the optional table to use for storing the parameters binding result.

# Benchmarks
