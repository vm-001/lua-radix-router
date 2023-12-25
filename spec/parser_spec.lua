require 'busted.runner'()

local Parser = require "radix-router.parser"

describe("parser", function()
  describe("default style", function()
    it("parse()", function()
      local tests = {
        [""] = { "" },
        ["{var}"] = { "{var}" },
        ["/{var}/end"] = { "/", "{var}", "/end" },
        ["/aa/{var}"] = { "/aa/", "{var}" },
        ["/aa/{var}/cc"] = { "/aa/", "{var}", "/cc" },
        ["/aa/{var1}/cc/{var2}"] = { "/aa/", "{var1}", "/cc/", "{var2}" },
        ["/user/profile.{format}"] = { "/user/profile.", "{format}" },
        ["/user/{filename}.{format}"] = { "/user/", "{filename}", ".", "{format}" },
        ["/aa/{name:[0-9]+}/{*suffix}"] = { "/aa/", "{name:[0-9]+}", "/", "{*suffix}" }
      }

      for path, expected_tokens in pairs(tests) do
        local parser = Parser.new("default")
        parser:update(path)
        local tokens = parser:parse()
        assert.same(expected_tokens, tokens)
      end
    end)
    it("params()", function()
      local tests = {
        [""] = { },
        ["{var}"] = { "var" },
        ["/aa/{var1}/cc/{var2}/{}/{*}"] = { "var1", "var2" },
        ["/aa/{name:[0-9]+}/{*suffix}"] = { "name", "suffix" }
      }

      for path, expected_params in pairs(tests) do
        local parser = Parser.new("default")
        parser:update(path)
        local params = parser:params()
        assert.same(expected_params, params)
      end
    end)
  end)
end)
