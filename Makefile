build:
	luarocks make

test: build
	#busted spec/
	luajit spec/parser_spec.lua
	luajit spec/router_spec.lua
	luajit spec/utils_spec.lua

test-coverage:
	busted --coverage spec/

bench:
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/static-paths.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
	RADIX_ROUTER_ROUTES=1000000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-prefix.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/complex-variable.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable-binding.lua
	RADIX_ROUTER_TIMES=1000000 luajit benchmark/github-routes.lua
