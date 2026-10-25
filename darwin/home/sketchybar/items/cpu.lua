local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

-- Cache core count (fetched once at startup)
local core_count = 1
sbar.exec("sysctl -n machdep.cpu.thread_count", function(result)
  core_count = tonumber(result) or 1
end)

local cpu = sbar.add("item", "cpu", {
  position = "right",
  width = 62,
  update_freq = 1,
  icon = {
    string = icons.cpu,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    color = colors.blue,
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    color = colors.white,
  },
})

cpu:subscribe({ "routine", "forced" }, function(env)
  sbar.exec("ps -A -o %cpu | awk '{s+=$1} END {print s}'", function(result)
    local total = tonumber(result) or 0
    local percent = math.floor(total / core_count + 0.5)
    cpu:set({
      label = { string = string.format("%d%%", percent) },
    })
  end)
end)
