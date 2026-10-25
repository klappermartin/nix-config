local host = require("host")

return {
  network_interface = host.network_interface,
  space_count = host.space_count,
  paddings = 3,
  group_paddings = 5,

  icons = "NerdFont",

  font = {
    text = "JetBrainsMonoNL Nerd Font",
    numbers = "JetBrainsMonoNL Nerd Font",
    style_map = {
      ["Regular"] = "Regular",
      ["Semibold"] = "Bold",
      ["Bold"] = "Bold",
      ["Heavy"] = "Bold",
      ["Black"] = "Bold",
    },
  },
}
