# Lua-radix-router [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml) [![Coverage Status](https://coveralls.io/repos/github/vm-001/lua-radix-router/badge.svg)](https://coveralls.io/github/vm-001/lua-radix-router)

Lua-radix-router is a lightweight high-performance router written in Lua.

It supports OpenAPI style variables path and prefix matching by using the `{ }` symbol. 

-   `/users/{id}/profile-{year}.{format}`
-   `/api/authn/{*path}`

Parameter binding is also supported.

The router is designed for high performance. A compressing dynamic trie (radix tree) is used for efficient matching. Even with millions of routes and complex paths, matching can still be done in 1 nanosecond. 

## 🔨 Installation

Install via LuaRocks:

```
luarocks install radix-router
```

## 📖 Usage

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

## 📄 Methods

### new
Creates a radix router instance.

```lua
local router, err = Router.new(routes)
```

**Parameters**

- **routes**(`table|nil`): the array-like Route table.



Route defines the matching conditions for its handler.

| PROPERTY                      | DESCRIPTION                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| `paths`  *required\**         | The path list of matching condition.                         |
| `methods` *optional*          | The method list of matching condition.                       |
| `handler` *required\**        | The value of handler will be returned by `router:match()` when the route is matched. |
| `priority` *optional*         | The priority of the route in case of radix tree node conflict. |
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

## 🚀 Benchmarks

Environments:

- Apple MacBook Pro(M1 Pro), 32GB 
- LuaJIT 2.1.1700008891

```
$ make bench

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/static-paths.lua
========== static path ==========
routes  :       100000
times   :       10000000
elapsed :       0.120372 s
QPS     :       83075798
ns/op   :       0.0120372 ns
path    :       /50000
handler :       50000

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
========== variable ==========
routes  :       100000
times   :       10000000
elapsed :       0.823292 s
QPS     :       12146358
ns/op   :       0.0823292 ns
path    :       /1/foo
handler :       1

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-prefix.lua
========== prefix ==========
routes  :       100000
times   :       10000000
elapsed :       0.726753 s
QPS     :       13759833
ns/op   :       0.0726753 ns
path    :       /1/a
handler :       1

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/complex-variable.lua
========== variable ==========
routes  :       100000
times   :       1000000
elapsed :       0.922157 s
QPS     :       1084414
ns/op   :       0.922157 ns
path    :       /aa/bb/cc/dd/ee/ff/gg/hh/ii/jj/kk/ll/mm/nn/oo/pp/qq/rr/ss/tt/uu/vv/ww/xx/yy/zz50000
handler :       50000

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable-binding.lua
========== variable ==========
routes  :       100000
times   :       10000000
elapsed :       2.183163 s
QPS     :       4580510
ns/op   :       0.2183163 ns
path    :       /1/foo
handler :       1
params : name = foo

RADIX_ROUTER_TIMES=1000000 luajit benchmark/github-routes.lua
========== github apis ==========
routes  :       609
times   :       1000000
elapsed :       0.384233 s
QPS     :       2602587
ns/op   :       0.384233 ns
path    :       /repos/vm-001/lua-radix-router/import
handler :       /repos/{owner}/{repo}/import

```

## License
