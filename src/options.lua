--- Options Router options
--


local function options(opts)
  opts = opts or {}

  local default = {
    trailing_slash_match = false,
  }

  if opts.trailing_slash_match ~= nil then
    default.trailing_slash_match = opts.trailing_slash_match
  end

  return default
end


return {
  options = options,
}
