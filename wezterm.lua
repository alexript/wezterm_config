local wezterm = require 'wezterm'

local is_linux = wezterm.target_triple == "x86_64-unknown-linux-gnu"
local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

local mux = wezterm.mux
local config = {}

config.default_prog = { 'nu' }

config.color_scheme = 'Catppuccin Macchiato'

config.front_end = "WebGpu" -- windows on adreno 618 have no appropriate OpenGL support
-- Saftware, OpenGL, WebGpu
--
config.font_dirs = { 'fonts' }
config.font_locator = 'ConfigDirsOnly'
config.font = wezterm.font('DejaVuSansMono NF')
config.font_size = 14.0

config.default_cwd = "e:/Workspace"

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 24

config.window_decorations = "NONE"
config.window_padding = {
    left = 0,
    right = 0,
    top = 10,
    bottom = 1
}

-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
    local title = tab_info.tab_title
    -- if the tab title is explicitly set, take that
    if title and #title > 0 then
        return tab_info.tab_id .. ':' .. title
    end
    -- Otherwise, use the title from the active pane
    -- in that tab
    return tab_info.tab_id .. '@' .. tab_info.window_id --.active_pane.title
end

wezterm.on(
    'format-tab-title',
    function(tab, tabs, panes, config, hover, max_width)
        local edge_background = '#0b0022'
        local background = '#1E1E2E'
        local foreground = '#89DCEB'

        if tab.is_active then
            background = '#2b2042'
            foreground = '#74C7EC'
        elseif hover then
            background = '#3b3052'
            foreground = '#909090'
        end

        local edge_foreground = background

        local title = tab_title(tab)

        -- ensure that the titles fit in the available space,
        -- and that we have room for the edges.
        title = wezterm.truncate_right(title, max_width - 3)

        return {
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Text = ' ' .. title .. ' ' },
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = SOLID_RIGHT_ARROW },
        }
    end
)

wezterm.on('update-right-status', function(window, pane)
    -- Each element holds the text for a cell in a "powerline" style << fade
    local cells = {}

    -- Figure out the cwd and host of the current pane.
    -- This will pick up the hostname for the remote host if your
    -- shell is using OSC 7 on the remote host.
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
        cwd_uri = cwd_uri:sub(8)
        local slash = cwd_uri:find '/'
        local cwd = ''
        local hostname = ''
        if slash then
            hostname = cwd_uri:sub(1, slash - 1)
            -- Remove the domain name portion of the hostname
            local dot = hostname:find '[.]'
            if dot then
                hostname = hostname:sub(1, dot - 1)
            end
            -- and extract the cwd from the uri
            cwd = cwd_uri:sub(slash)

            if is_windows then
                cwd = cwd:gsub('/', '\\'):sub(2)
            end

            table.insert(cells, cwd)
            table.insert(cells, hostname)
        end
    end

    -- I like my date/time in this style: "Wed Mar 3 08:14"
    local date = wezterm.strftime '%a %b %-d %H:%M'
    table.insert(cells, date)

    -- An entry for each battery (typically 0 or 1 battery)
    for _, b in ipairs(wezterm.battery_info()) do
        table.insert(cells, string.format('%.0f%%', b.state_of_charge * 100))
    end

    -- Color palette for the backgrounds of each cell
    local colors = {
        '#3c1361',
        '#52307c',
        '#663a82',
        '#7c5295',
        '#b491c8',
    }

    -- Foreground color for the text across the fade
    local text_fg = '#c0c0c0'

    -- The elements to be formatted
    local elements = {}
    -- How many cells have been formatted
    local num_cells = 0

    -- Translate a cell into elements
    function push(text)
        local cell_no = num_cells + 1
        table.insert(elements, { Foreground = { Color = colors[cell_no] } })
        table.insert(elements, { Text = SOLID_LEFT_ARROW })
        table.insert(elements, { Foreground = { Color = text_fg } })
        table.insert(elements, { Background = { Color = colors[cell_no] } })
        table.insert(elements, { Text = ' ' .. text .. ' ' })
        num_cells = num_cells + 1
    end

    while #cells > 0 do
        local cell = table.remove(cells, 1)
        push(cell)
    end

    window:set_right_status(wezterm.format(elements))
end)

wezterm.on('window-config-reloaded', function(window, pane)
    window:toast_notification('wezterm', 'configuration reloaded!', nil, 4000)
end)


-- format window title
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
    local numtabs = ''
    if (#tabs > 1) then numtabs = '(' .. tostring(#tabs) .. ') ' end
    return numtabs .. tab.active_pane.title
end)

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config
