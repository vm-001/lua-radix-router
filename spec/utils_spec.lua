require 'busted.runner'()

local utils = require "radix-router.utils"

describe("utils", function()
  it("starts_with()", function()
    assert.is_true(utils.starts_with("/abc", "/"))
    assert.is_true(utils.starts_with("/abc", "/a"))
    assert.is_true(utils.starts_with("/abc", "/ab"))
    assert.is_true(utils.starts_with("/abc", "/abc"))

    assert.is_false(utils.starts_with("/abc", "/abcd"))
    assert.is_false(utils.starts_with("/abc", "/d"))
  end)
  it("lcp()", function()
    assert.equal(0, utils.lcp("/abc", ""))
    assert.equal(1, utils.lcp("/abc", "/"))
    assert.equal(2, utils.lcp("/abc", "/a"))
    assert.equal(4, utils.lcp("/abc", "/abc"))
    assert.equal(4, utils.lcp("/abc", "/abcd"))
    assert.equal(0, utils.lcp("", "/abcd"))
    assert.equal(0, utils.lcp("a", "c"))
  end)
end)
