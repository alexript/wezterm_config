local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = {}

config.color_scheme = 'Catppuccin Macchiato'

config.front_end = "WebGpu" -- windows on adreno 618 have no appropriate OpenGL support
-- Saftware, OpenGL, WebGpu
--
config.font_dirs = { 'fonts' }
config.font_locator = 'ConfigDirsOnly'
config.font = wezterm.font('DejaVuSansMono NF')
config.font_size = 14.0

config.default_cwd = "e:/Workspace"

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config
