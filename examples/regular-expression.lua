local Router = require "radix-router"
local router, err = Router.new({
  {
    paths = { "/users/{id:\\d+}/profile-{year:\\d{4}}.{format:(html|pdf)}" },
    handler = "1"
  },
  {
    paths = { "/users/{uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}" },
    handler = "2"
  },
})
if not router then
  error("failed to create router: " .. err)
end

assert("1" == router:match("/users/100/profile-2024.pdf"))
assert("2", router:match("/users/00000000-0000-0000-0000-000000000000"))