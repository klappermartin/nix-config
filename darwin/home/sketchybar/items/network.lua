local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

-- Module-level state for delta calculation (no state file needed)
local prev_tx, prev_rx, prev_time
local pending = false

local function format_bytes(bytes)
  if bytes < 1000 then
    return string.format("%4dB", math.floor(bytes))
  elseif bytes < 1000000 then
    return string.format("%4dK", math.floor(bytes / 1000))
  else
    return string.format("%4.1fM", bytes / 1000000)
  end
end

local network = sbar.add("item", "network", {
  position = "right",
  width = 120,
  update_freq = 2,
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 12.0,
    },
    color = colors.white,
    string = icons.network.up .. "   0B " .. icons.network.down .. "   0B",
  },
})

network:subscribe({ "routine", "forced", "system_woke" }, function(env)
  if env.SENDER == "system_woke" then prev_tx, prev_rx, prev_time = nil, nil, nil end
  if pending then return end
  pending = true
  local command = "/usr/sbin/netstat -ibn | /usr/bin/awk -v now=\"$(/bin/date +%s)\" "
    .. "'/Link#/ && $1==\"" .. settings.network_interface .. "\" {print $7, $10, now; exit}'"
  sbar.exec(command, function(result)
    pending = false
    local rx_str, tx_str, time_str = (result or ""):match("(%d+)%s+(%d+)%s+(%d+)")
    if not rx_str then
      prev_tx, prev_rx, prev_time = nil, nil, nil
      network:set({ label = { string = icons.network.up .. "   -- " .. icons.network.down .. "   --" } })
      return
    end

    local tx, rx, now = tonumber(tx_str), tonumber(rx_str), tonumber(time_str)

    local tx_delta = 0
    local rx_delta = 0

    if prev_time and now > prev_time then
      local elapsed = now - prev_time
      if tx >= prev_tx then tx_delta = (tx - prev_tx) / elapsed end
      if rx >= prev_rx then rx_delta = (rx - prev_rx) / elapsed end
    elseif prev_time and now == prev_time then
      -- Keep the previous sample for a later nonzero interval.
      return
    end

    prev_tx = tx
    prev_rx = rx
    prev_time = now

    network:set({
      label = {
        string = icons.network.up .. format_bytes(tx_delta) .. " " .. icons.network.down .. format_bytes(rx_delta),
      },
    })
  end)
end)
