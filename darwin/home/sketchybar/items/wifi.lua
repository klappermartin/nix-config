local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local wifi = sbar.add("item", "wifi", {
  position = "right",
  width = 28,
  update_freq = 10,
  icon = {
    string = icons.wifi.off,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 15.0,
    },
    color = colors.grey,
  },
  label = { drawing = false },
})

local function update_wifi()
  sbar.exec("/usr/sbin/ipconfig getsummary " .. settings.network_interface .. " 2>/dev/null", function(result)
    if not result or result == "" then
      wifi:set({ icon = { string = icons.wifi.off, color = colors.grey } })
      return
    end

    local ssid = result:match("SSID%s*:%s*(.+)")
    if not ssid then
      wifi:set({ icon = { string = icons.wifi.off, color = colors.grey } })
      return
    end

    local rssi = tonumber(result:match("Signal Strength%s*:%s*(%-?%d+)"))
    local icon
    local color

    if not rssi then
      icon = icons.wifi.strength_4
      color = colors.blue
    elseif rssi > -50 then
      icon = icons.wifi.strength_4
      color = colors.blue
    elseif rssi > -60 then
      icon = icons.wifi.strength_3
      color = colors.blue
    elseif rssi > -70 then
      icon = icons.wifi.strength_2
      color = colors.yellow
    else
      icon = icons.wifi.strength_1
      color = colors.orange
    end

    wifi:set({ icon = { string = icon, color = color } })
  end)
end

wifi:subscribe({ "routine", "forced", "system_woke" }, function(env)
  update_wifi()
end)
