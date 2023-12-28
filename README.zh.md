# Lua-Radix-Router [![Build Status](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml/badge.svg)](https://github.com/vm-001/lua-radix-router/actions/workflows/test.yml) [![Coverage Status](https://coveralls.io/repos/github/vm-001/lua-radix-router/badge.svg)](https://coveralls.io/github/vm-001/lua-radix-router)

[English](README.md) | 中文 (Translated by ChatGPT)

---

Lua-Radix-Router 是一个轻量级高性能的路由器，用纯 Lua 编写。该路由器易于使用，只有两个方法，Router.new() 和 Router:match()。它可以集成到不同的运行时环境，如 Lua 应用程序、LuaJIT 或 OpenResty 中。

该路由器专为高性能而设计。采用了压缩动态 Trie（基数树）以实现高效匹配。即使有数百万个包含复杂路径的路由，匹配仍可在1纳秒内完成。

## 🔨 特性

- 变量路径：语法 `{varname}`。
  - `/users/{id}/profile-{year}.{format}`：允许在一个路径段中有多个变量

- 前缀匹配：语法 `{*varname}`
  - `/api/authn/{*path}`

- 变量绑定：路由器在匹配过程中会自动为您注入绑定结果。

- 最佳性能：Lua/LuaJIT 中最快的路由器。请参阅[性能基准](#-基准测试)。

- OpenAPI 友好：完全支持 OpenAPI。



**在路线图中的特性**：（start或创建issue来加速优先级）

- 尾部斜杠匹配：使 URL /foo/ 能够与 /foo 路径匹配。

- 表达式条件：通过使用表达式语言定义自定义匹配条件。

- 变量中的正则表达式


## 📖 入门

通过 LuaRocks 安装 radix-router：

```
luarocks install radix-router
```

通过示例开始：

```lua
local Router = require "radix-router"
local router, err = Router.new({
  { -- 静态路径
    paths = { "/foo", "/foo/bar", "/html/index.html" },
    handler = "1" -- 处理程序可以是任何非空值（例如布尔值、表、函数）
  },
  { -- 变量路径
    paths = { "/users/{id}/profile-{year}.{format}" },
    handler = "2"
  },
  { -- 前缀路径
    paths = { "/api/authn/{*path}" },
    handler = "3"
  },
  { -- 方法条件
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

-- 变量绑定
local params = {}
router:match("/users/100/profile-2023.pdf", nil, params)
assert(params.year == "2023")
assert(params.format == "pdf")
```

有关更多用法示例，请参阅 `/samples` 目录。

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

#### 用法

```
$ make build
$ make bench
```

#### 环境

- Apple MacBook Pro(M1 Pro), 32GB
- LuaJIT 2.1.1700008891

```
$ make bench
```

#### 数据

| TEST CASE               | Router number | nanoseconds / op | QPS        |
| ----------------------- | ------------- | ---------------- | ---------- |
| static path             | 100000        | 0.0120372        | 83,075,798 |
| simple variable         | 100000        | 0.0823292        | 12,146,358 |
| simple prefix           | 100000        | 0.0726753        | 13,759,833 |
| complex variable        | 100000        | 0.922157         | 1,084,414  |
| simple variable binding | 100000        | 0.2183163        | 4,580,510  |
| github                  | 609           | 0.384233         | 2,602,587  |



<details>
<summary>展开输出</summary>

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