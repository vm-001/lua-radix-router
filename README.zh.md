# Lua-Radix-Router [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml) [![Coverage Status](https://coveralls.io/repos/github/vm-001/lua-radix-router/badge.svg)](https://coveralls.io/github/vm-001/lua-radix-router)

[English](README.md) | 中文 (Translated by ChatGPT)

---

Lua-radix-router 是一个用 Lua 编写的轻量级高性能路由器。

它支持使用 `{ }` 符号进行 OpenAPI 风格的变量路径和前缀匹配。

- `/users/{id}/profile-{year}.{format}`
- `/api/authn/{*path}`

还支持参数绑定。

该路由器设计用于高性能。使用高效匹配的压缩动态字典树（radix tree）。即使有数百万条路由和复杂的路径，匹配仍可在1纳秒内完成。

## 🔨 安装

通过 LuaRocks 安装：

```
luarocks install radix-router
```

## 📖 用法

```lua
local Router = require "radix-router"
local router, err = Router.new({
  {
    paths = { "/foo", "/foo/bar", "/html/index.html" },
    handler = "1" -- handler 可以是任何非nil的值。 (例如布尔值，表，函数)
  },
  {
    -- 变量路径
    paths = { "/users/{id}/profile-{year}.{format}" },
    handler = "2"
  },
  {
    -- 前缀路径
    paths = { "/api/authn/{*path}" },
    handler = "3"
  },
  {
    -- 方法
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

-- 参数绑定
local params = {}
router:match("/users/100/profile-2023.pdf", nil, params)
assert(params.year == "2023")
assert(params.format == "pdf")
```

## 📄 方法


### new

创建一个 radix 路由器实例。

```lua
local router, err = Router.new(routes)
```

**参数**

- **routes**(`table|nil`): the array-like Route table.



路由定义了其处理程序的匹配条件:

| 属性                      | 描述                                 |
| ----------------------------- |------------------------------------|
| `paths`  *required\**         | 匹配条件的路径列表。                         |
| `methods` *optional*          | 匹配条件的方法列表。                         |
| `handler` *required\**        | 当路由匹配时，`router:match()` 将返回处理程序的值。 |
| `priority` *optional*         | 在 radix 树节点冲突的情况下，路由的优先级。          |
| `expression` *optional* (TDB) | `expression` 使用表达式语言定义的匹配条件        |



### match

返回匹配路径和条件 ctx 的匹配路由的处理程序。

```lua
local handler = router:match(path, ctx, params)
```

**参数**

- **path**(`string`): 用于匹配的路径。
- **ctx**(`table|nil`): 用于匹配的可选条件 ctx。
- **params**(`table|nil`): 用于存储参数绑定结果的可选表。

## 🚀 基准测试

环境:

- Apple MacBook Pro(M1 Pro), 32GB
- LuaJIT 2.1.1700008891

```
$ make bench
```


<details>
<summary>测试结果</summary>

```
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

</details>