local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local spaces = {}

for i = 1, settings.space_count do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    position = "left",
    icon = {
      string = tostring(i),
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Bold"],
        size = 11.0,
      },
      color = colors.grey,
      padding_left = 5,
      padding_right = 5,
    },
    label = { drawing = false },
    background = {
      drawing = false,
      height = 20,
      corner_radius = 0,
    },
  })

  space:subscribe("space_change", function(env)
    local is_focused = env.SELECTED == "true"
    space:set({
      icon = {
        color = is_focused and colors.blue or colors.grey,
      },
      background = {
        drawing = is_focused,
        color = colors.bg1,
      },
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    sbar.exec("yabai -m space --focus " .. i)
  end)

  spaces[i] = space
end
