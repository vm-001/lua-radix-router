# Lua-Radix-Router [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml) [![Coverage Status](https://coveralls.io/repos/github/vm-001/lua-radix-router/badge.svg)](https://coveralls.io/github/vm-001/lua-radix-router)

English | [中文](README.zh.md)

---

Lua-Radix-Router is a lightweight high-performance router, written in pure Lua. The router is easy to use, with only two methods, `Router.new()` and `Router:match()`. It can be integrated into different runtimes such as Lua application, LuaJIT, or OpenResty.



The router is designed for high performance. A compressing dynamic trie (radix tree) is used for efficient matching. Even with millions of routes containing complex paths, matching can still be done in 1 nanosecond. 

## 🔨 Features

- **Variables in path**: Syntax  `{varname}`. 
    - `/users/{id}/profile-{year}.{format}`:  multiple variables in one path segment is allowed
- **Prefix matching**: Syntax `{*varname}`.
    - `/api/authn/{*path}`

- **Variables binding**: The router automatically injects the binding result for you during matching.
- **Best performance**: The fastest router in Lua/LuaJIT. See [Benchmarks](#-Benchmarks).
- **OpenAPI friendly**: OpenAPI(Swagger) fully compatible.
- **Trailing slash match**: You can make the Router to ignore the trailing slash by setting `trailing_slash_match` to true. For example, /foo/ to match the existing /foo, /foo to match the existing /foo/.

**Features in the roadmap**:

- Expression condition: defines custom matching conditions by using expression language.
- Regex in variable

## 📖 Getting started

Install radix-router via LuaRocks:

```
luarocks install radix-router
```

Or from source

```
make build
```

Get started by an example:

```lua
local Router = require "radix-router"
local router, err = Router.new({
  { -- static path
    paths = { "/foo", "/foo/bar", "/html/index.html" },
    handler = "1" -- handler can be any non-nil value. (e.g. boolean, table, function)
  },
  { -- variable path
    paths = { "/users/{id}/profile-{year}.{format}" },
    handler = "2"
  },
  { -- prefix path
    paths = { "/api/authn/{*path}" },
    handler = "3"
  },
  { -- methods condition
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

-- variable binding
local params = {}
router:match("/users/100/profile-2023.pdf", nil, params)
assert(params.year == "2023")
assert(params.format == "pdf")
```

For more usage samples, please refer to the `/samples` directory.

## 📄 Methods

### new

Creates a radix router instance.

```lua
local router, err = Router.new(routes, opts)
```

**Parameters**

- **routes** (`table|nil`): the array-like Route table.

- **opts** (table|nil): the object-like Options table.

    The available options are as follow

    | NAME                 | DESCRIPTION                  | DEFAULT |
    | -------------------- | ---------------------------- | ------- |
    | trailing_slash_match | Enables trailing slash match | false   |

    

Route defines the matching conditions for its handler.

| PROPERTY                      | DESCRIPTION                                                                                                                                                                              |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `paths`</br> *required\**    | A list of paths that match the Route.</br>                                                                                                                                               |
| `methods`</br> *optional*     | A list of HTTP methods that match the Route. </br>                                                                                                                                       |
| `hosts`</br> *optional*            | A list of hostnames that match the Route. Note that the value is case-sensitive. Wildcard hostnames are supported. For example, `*.foo.com` can match with `a.foo.com` or `a.b.foo.com`. | 
| `handler`</br> *required\**        | The value of handler will be returned by `router:match()` when the route is matched.                                                                                                     |
| `priority`</br> *optional*         | The priority of the route in case of radix tree node conflict.                                                                                                                           |
| `expression`</br> *optional* (TDB) | The `expression` defines a customized matching condition by using expression language.                                                                                                   |



### match

Return the handler of a matched route that matches the path and condition ctx.

```lua
local handler = router:match(path, ctx, params, matched)
```

**Parameters**

- **path**(`string`): the path to use for matching.
- **ctx**(`table|nil`): the optional condition ctx to use for matching.
- **params**(`table|nil`): the optional table to use for storing the parameters binding result.
- **matched**(`table|nil`): the optional table to use for storing the matched conditions.

## 🚀 Benchmarks

#### Usage

To run the benchmark

```$ make bench
$ make build
$ make bench
```

#### Environments

- Apple MacBook Pro(M1 Pro), 32GB 
- LuaJIT 2.1.1700008891

#### Results

| TEST CASE               | Router number | nanoseconds / op | QPS        | RSS          |
| ----------------------- |---------------|------------------|------------|--------------|
| static path             | 100000        | 0.0129826        | 77,026,173 | 65.25 MB     |
| simple variable         | 100000        | 0.0802077        | 12,467,630 | 147.52 MB    |
| simple variable         | 1000000       | 0.084604         | 11,819,772 | 1381.47 MB   |
| simple prefix           | 100000        | 0.0713651        | 14,012,451 | 147.47 MB    |
| complex variable        | 100000        | 0.914117         | 1,093,951  | 180.30 MB    |
| simple variable binding | 100000        | 0.21054          | 4,749,691  | 147.28 MB    |
| github                  | 609           | 0.375829         | 2,660,784  | 2.72 MB      |

<details>
<summary>Expand output</summary>

```
RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/static-paths.lua
========== static path ==========
routes  :	100000
times   :	10000000
elapsed :	0.129826 s
QPS     :	77026173
ns/op   :	0.0129826 ns
path    :	/50000
handler :	50000
Memory  :	65.25 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
========== variable ==========
routes  :	100000
times   :	10000000
elapsed :	0.802077 s
QPS     :	12467630
ns/op   :	0.0802077 ns
path    :	/1/foo
handler :	1
Memory  :	147.52 MB

RADIX_ROUTER_ROUTES=1000000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
========== variable ==========
routes  :       1000000
times   :       10000000
elapsed :       0.84604 s
QPS     :       11819772
ns/op   :       0.084604 ns
path    :       /1/foo
handler :       1
Memory  :       1381.47 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-prefix.lua
========== prefix ==========
routes  :	100000
times   :	10000000
elapsed :	0.713651 s
QPS     :	14012451
ns/op   :	0.0713651 ns
path    :	/1/a
handler :	1
Memory  :	147.47 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/complex-variable.lua
========== variable ==========
routes  :	100000
times   :	1000000
elapsed :	0.914117 s
QPS     :	1093951
ns/op   :	0.914117 ns
path    :	/aa/bb/cc/dd/ee/ff/gg/hh/ii/jj/kk/ll/mm/nn/oo/pp/qq/rr/ss/tt/uu/vv/ww/xx/yy/zz50000
handler :	50000
Memory  :	180.30 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable-binding.lua
========== variable ==========
routes  :	100000
times   :	10000000
elapsed :	2.1054 s
QPS     :	4749691
ns/op   :	0.21054 ns
path    :	/1/foo
handler :	1
params : name = foo
Memory  :	147.28 MB

RADIX_ROUTER_TIMES=1000000 luajit benchmark/github-routes.lua
========== github apis ==========
routes  :	609
times   :	1000000
elapsed :	0.375829 s
QPS     :	2660784
ns/op   :	0.375829 ns
path    :	/repos/vm-001/lua-radix-router/import
handler :	/repos/{owner}/{repo}/import
Memory  :	2.72 MB
```

</details>


## License
