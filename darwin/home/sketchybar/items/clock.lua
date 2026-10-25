local colors = require("colors")
local settings = require("settings")

local clock = sbar.add("item", "clock", {
  position = "right",
  width = 135,
  update_freq = 10,
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    color = colors.grey,
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    color = colors.white,
  },
  click_script = "open -a Calendar",
})

clock:subscribe({ "routine", "forced" }, function(env)
  clock:set({
    icon = { string = os.date("%a %d %b") },
    label = { string = os.date("%H:%M") },
  })
end)
