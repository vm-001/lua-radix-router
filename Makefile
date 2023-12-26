build:
	luarocks make

test:
	busted spec/

test-coverage:
	busted --coverage spec/

bench:
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/static-paths.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-prefix.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=1000000 luajit benchmark/complex-variable.lua
	RADIX_ROUTER_ROUTES=100000 RADIX_ROUTER_TIMES=10000000 luajit benchmark/simple-variable-binding.lua
	RADIX_ROUTER_TIMES=1000000 luajit benchmark/github-routes.lua
