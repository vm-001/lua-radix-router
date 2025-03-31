<p align="center">
    <img alt="special sponsor appwrite" src="./lua-radix-router.png" width="600">
</p>

# Lua-Radix-Router [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml) [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/examples.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/examples.yml) [![Coverage Status](https://coveralls.io/repos/github/vm-001/lua-radix-router/badge.svg)](https://coveralls.io/github/vm-001/lua-radix-router) ![Lua Versions](https://img.shields.io/badge/Lua-%205.2%20|%205.3%20|%205.4-blue.svg)

English | [中文](README.zh.md)



Lua-Radix-Router is a lightweight high-performance router library written in pure Lua. It's easy to use with only two exported functions, `Router.new()` and `router:match()`.

The router is optimized for high performance. It combines HashTable(O(1)) and Compressed Trie(or Radix Tree, O(m) where m is the length of path being searched) for efficient matching. Some of the utility functions have the LuaJIT version for better performance, and will automatically switch when running in LuaJIT. It also scales well even with long paths and a large number of routes.

The router can be run in different runtimes such as Lua, LuaJIT, or OpenResty.

This library is considered production ready.

## 🔨 Features

**Patterned path:** You can define named or unnamed patterns in path with pattern syntax "{}" and "{*}"

-   named variables: `/users/{id}/profile-{year}.{format}`, matches with /users/1/profile-2024.html.
-   named prefix: `/api/authn/{*path}`, matches with /api/authn/foo and /api/authn/foo/bar.

**Variable binding:** Stop manually parsing the URL, let the router injects the binding variables for you.

**Best performance:** The fastest router in Lua/LuaJIT and open-source API Gateways. See [Benchmarks](#-Benchmarks) and [Routing Benchmark](https://github.com/vm-001/gateways-routing-benchmark) in different API Gateways.

**OpenAPI friendly:** OpenAPI(Swagger) is fully compatible.

**Trailing slash match:** You can make the Router to ignore the trailing slash by setting `trailing_slash_match` to true. For example, /foo/ to match the existing /foo, /foo to match the existing /foo/.

**Custom Matcher:** The router has two efficient matchers built in, MethodMatcher(`method`) and HostMatcher(`host`). They can be disabled via `opts.matcher_names`. You can also add your custom matchers via `opts.matchers`. For example, an IpMatcher to evaluate whether the `ctx.ip` is matched with the `ips` of a route.

**Regex pattern:** You can define regex pattern in variables. a variable without regex pattern is treated as `[^/]+`.

- `/users/{uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}`
- `/users/{id:\\d+}/profile-{year:\\d{4}}.{format:(html|pdf)}`

**Features in the roadmap**:

- Expression condition: defines custom matching conditions by using expression language.

## 📖 Getting started

Install radix-router via LuaRocks:

```
luarocks install radix-router
```

Or from source

```
make install
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

For more usage samples, please refer to the [/examples](/examples) directory. For more use cases, please check out [lua-radix-router-use-cases](https://github.com/vm-001/lua-radix-router-use-cases).

## 📄 Methods

### new

Creates a radix router instance.

```lua
local router, err = Router.new(routes, opts)
```

**Parameters**

- **routes** (`table|nil`): the array-like Route table.

- **opts** (`table|nil`): the object-like Options table.

    The available options are as follow

    | NAME                 | TYPE    | DEFAULT           | DESCRIPTION                                         |
    | -------------------- | ------- | ----------------- | --------------------------------------------------- |
    | trailing_slash_match | boolean | false             | whether to enable the trailing slash match behavior |
    | matcher_names        | table   | {"method","host"} | enabled built-in macher list                        |
    | matchers             | table   | { }               | custom matcher list                                 |



Route defines the matching conditions for its handler.

| PROPERTY                      | DESCRIPTION                                                                                                                                                                              |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `paths`</br> *required\**    | A list of paths that match the Route.</br>                                                                                                                                               |
| `methods`</br> *optional*     | A list of HTTP methods that match the Route. </br>                                                                                                                                       |
| `hosts`</br> *optional*            | A list of hostnames that match the Route. Note that the value is case-sensitive. Wildcard hostnames are supported. For example, `*.foo.com` can match with `a.foo.com` or `a.b.foo.com`. |
| `handler`</br> *required\**        | The value of handler will be returned by `router:match()` when the route is matched.                                                                                                     |
| `priority`</br> *optional*         | The priority of the route in case of radix tree node conflict.                                                                                                                           |



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

## 📝 Examples

#### Regex pattern

Using regex to define the pattern of a variable. Note that at most one URL segment is evaluated when matching a variable's pattern, which means it's not allowed to define a pattern crossing multiple URL segments, for example, `{var:[/0-9a-z]+}`.

```lua
local Router = require "radix-router"
local router = Router.new({
  {
    paths = { "/users/{id:\\d+}/profile-{year:\\d{4}}.{format:(html|pdf)}" },
    handler = "1"
  },
  {
    paths = { "/users/{uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}" },
    handler = "2"
  },
})
assert("1" == router:match("/users/100/profile-2024.pdf"))
assert("2" == router:match("/users/00000000-0000-0000-0000-000000000000"))
```

## 🧠 Data Structure and Implementation

Inside the Router, it has a hash-like table to optimize the static path matching. Due to the LuaJIT optimization, static path matching is the fastest and has lower memory usage. (see [Benchmarks](#-Benchmarks))

The Router also has a tree structure for patterned path matching. The tree is basically a compact [prefix tree](https://en.wikipedia.org/wiki/Trie) (or [Radix Tree](https://en.wikipedia.org/wiki/Radix_tree)). The primary structure of Router is as follows:

```
{
  static<Table>   = {},
  trie<TrieNode>  = TrieNode.new(),
  ...
}

+--------+----------+------------------------------------+
| FIELD  |   TYPE   |                DESC                |
+--------+----------+------------------------------------+
| static | table    | a hash-like table for static paths |
| trie   | TrieNode | a radix tree for pattern paths     |
+--------+----------+------------------------------------+
```

TrieNode is an array-like table. Compared with the hash-like, it reduces memory usage by 20%. The data structure of TrieNode is:

```
{ <type>, <path>, <pathn>, <children>, <value> }

+-------+----------+------------------+
| INDEX |   NAME   |       TYPE       |
+-------+----------+------------------+
|     1 | type     | integer          |
|     2 | path     | string           |
|     3 | pathn    | integer          |
|     4 | children | hash-like table  |
|     5 | value    | array-like table |
+-------+----------+------------------+
```

Nodes with a common prefix share a common parent. Here is an example of what a Router with three routes could look like:

```lua
local router = Router.new({
  { -- <table 1>
    paths = { "/api/login" },
    handler = "1",
  }, { -- <table 2>
    paths = { "/people/{id}/profile" },
    handler = "2",
  }, { -- <table 3>
    paths = { "/search/{query}", "/src/{*filename}" },
    handler = "3"
  }
})
```




```
router.static = {
  [/api/login] = { *<table 1> }
}

              TrieNode.path       TrieNode.value
router.trie = /                   nil
              ├─people/           nil
              │ └─{wildcard}      nil
              │   └─/profile      { "/people/{id}/profile",  *<table 2> }
              └─s                 nil
               ├─earch/           nil
               │ └─{wildcard}     { "/search/{query}",       *<table 3> }
               └─rc/              nil
                 └─{catchall}     { "/src/{*filename}",      *<table 3> }
```

## 🔍 Troubleshooting


#### Could not find header file for PCRE2

```
Installing https://luarocks.org/lrexlib-pcre2-2.9.2-1.src.rock

Error: Failed installing dependency: https://luarocks.org/lrexlib-pcre2-2.9.2-1.src.rock - Could not find header file for PCRE2
```

Try manually install `lrexlib-pcre2` (on macOS).

```
$ brew install pcre2
$ ls /opt/homebrew/opt/pcre2/
$ luarocks install lrexlib-pcre2 PCRE2_DIR=/opt/homebrew/opt/pcre2
```


## 🚀 Benchmarks

#### Usage

To run the benchmark

```$ make bench
$ make install
$ make bench
```

#### Environments

- MacBook Pro(M4 Pro), 24GB
- LuaJIT 2.1.1731601260

#### Results

| test case               | route number | ns / op | OPS         | RSS         |
|-------------------------|--------------|---------|-------------|-------------|
| static path             | 100000       | 8.70    | 114,984,822 | 48.88 MB    |
| simple variable         | 100000       | 64.60   | 15,480,954  | 102.55 MB   |
| simple variable         | 1000000      | 54.78   | 18,257,670  | 976.17 MB   |
| simple prefix           | 100000       | 50.24   | 19,905,845  | 100.38 MB   |
| simple regex            | 100000       | 96.72   | 10,338,909  | 111.66 MB   |
| complex variable        | 100000       | 622.11  | 1,607,443   | 155.05 MB   |
| simple variable binding | 100000       | 123.16  | 8,119,565   | 100.36 MB   |
| github                  | 609          | 270.58  | 3,695,778   | 2.88 MB     |

<details>
<summary>Expand output</summary>

```
RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/static-paths.lua
========== static path ==========
routes  :       100000
times   :       10000000
elapsed :       0.086968 s
ns/op   :       8.6968 ns
OPS     :       114984822
path    :       /50000
handler :       50000
Memory  :       48.88 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
========== variable ==========
routes  :       100000
times   :       10000000
elapsed :       0.645955 s
ns/op   :       64.5955 ns
OPS     :       15480954
path    :       /1/foo
handler :       1
Memory  :       102.55 MB

RADIX_ROUTER_ROUTES=1000000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
========== variable ==========
routes  :       1000000
times   :       10000000
elapsed :       0.547715 s
ns/op   :       54.7715 ns
OPS     :       18257670
path    :       /1/foo
handler :       1
Memory  :       976.17 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-prefix.lua
========== prefix ==========
routes  :       100000
times   :       10000000
elapsed :       0.502365 s
ns/op   :       50.2365 ns
OPS     :       19905845
path    :       /1/a
handler :       1
Memory  :       100.38 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/simple-regex.lua
========== regex ==========
routes  :       100000
times   :       1000000
elapsed :       0.096722 s
ns/op   :       96.722 ns
OPS     :       10338909
path    :       /1/a
handler :       1
Memory  :       111.66 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/complex-variable.lua
========== variable ==========
routes  :       100000
times   :       1000000
elapsed :       0.622106 s
ns/op   :       622.106 ns
OPS     :       1607443
path    :       /aa/bb/cc/dd/ee/ff/gg/hh/ii/jj/kk/ll/mm/nn/oo/pp/qq/rr/ss/tt/uu/vv/ww/xx/yy/zz50000
handler :       50000
Memory  :       155.05 MB

RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable-binding.lua
========== variable ==========
routes  :       100000
times   :       10000000
elapsed :       1.231593 s
ns/op   :       123.1593 ns
OPS     :       8119565
path    :       /1/foo
handler :       1
params : name = foo
Memory  :       100.36 MB

RADIX_ROUTER_TIMES=1000000 luajit benchmark/github-routes.lua
========== github apis ==========
routes  :       609
times   :       1000000
elapsed :       0.270579 s
ns/op   :       270.579 ns
OPS     :       3695778
path    :       /repos/vm-001/lua-radix-router/import
handler :       /repos/{owner}/{repo}/import
Memory  :       2.88 MB

```

</details>


## License

BSD 2-Clause License

Copyright (c) 2024, Yusheng Li
