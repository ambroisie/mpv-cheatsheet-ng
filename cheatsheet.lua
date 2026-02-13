local assdraw = require("mp.assdraw")

local M = {}

M.shortcuts = {
    {
        category = "Navigation",
        shortcuts = {
            { keys = ", / .", effect = "Seek by frame" },
            { keys = "← / →", effect = "Seek by 5 seconds" },
            { keys = "↓ / ↑", effect = "Seek by 1 minute" },
            { keys = "[Shift] PGDWN / PGUP", effect = "Seek by 10 minutes" },
            { keys = "[Shift] ← / →", effect = "Seek by 1 second (exact)" },
            { keys = "[Shift] ↓ / ↑", effect = "Seek by 5 seconds (exact)" },
            { keys = "[Ctrl] ← / →", effect = "Seek by subtitle" },
            { keys = "[Shift] BACKSPACE", effect = "Undo last seek" },
            { keys = "[Ctrl+Shift] BACKSPACE", effect = "Mark current position" },
            { keys = "l", effect = "Set/clear A-B loop points" },
            { keys = "L", effect = "Toggle infinite looping" },
            { keys = "PGDWN / PGUP", effect = "Previous/next chapter" },
            { keys = "< / >", effect = "Go backward/forward in the playlist" },
            { keys = "ENTER", effect = "Go forward in the playlist" },
            { keys = "F8", effect = "Show playlist [UI]" },
        },
    },
    {
        category = "Playback",
        shortcuts = {
            { keys = "p / SPACE", effect = "Pause/unpause" },
            { keys = "[ / ]", effect = "Decrease/increase speed [10%]" },
            { keys = "{ / }", effect = "Halve/double speed" },
            { keys = "BACKSPACE", effect = "Reset speed" },
            { keys = "o / P", effect = "Show progress" },
            { keys = "O", effect = "Toggle progress" },
            { keys = "i / I", effect = "Show/toggle stats" },
        },
    },
    {
        category = "Subtitle",
        shortcuts = {
            { keys = "[Ctrl+Shift] ← / →", effect = "Adjust subtitle delay [subtitle]" },
            { keys = "[Shift] f / g", effect = "Adjust subtitle size [0.100]" },
            { keys = "z / Z", effect = "Adjust subtitle delay [0.1sec]" },
            { keys = "v", effect = "Toggle subtitle visibility" },
            { keys = "u", effect = "Toggle subtitle style overrides" },
            { keys = "V", effect = "Toggle subtitle VSFilter aspect compatibility mode" },
            { keys = "r / R", effect = "Move subtitles up/down" },
            { keys = "j / J", effect = "Cycle subtitle" },
            { keys = "F9", effect = "Show audio/subtitle list [UI]" },
        },
    },
    {
        category = "Audio",
        shortcuts = {
            { keys = "m", effect = "Mute sound" },
            { keys = "#", effect = "Cycle audio track" },
            { keys = "/ / *", effect = "Decrease/increase volume" },
            { keys = "9 / 0", effect = "Decrease/increase volume" },
            { keys = "[Ctrl] - / +", effect = "Decrease/increase audio delay [0.1sec]" },
            { keys = "F9", effect = "Show audio/subtitle list [UI]" },
        },
    },
    {
        category = "Video",
        shortcuts = {
            { keys = "_", effect = "Cycle video track" },
            { keys = "A", effect = "Cycle aspect ratio" },
            { keys = "d", effect = "Toggle deinterlacer" },
            { keys = "[Ctrl] h", effect = "Toggle hardware video decoding" },
            { keys = "w / W", effect = "Decrease/increase pan-and-scan range" },
            { keys = "[Alt] - / +", effect = "Zoom out/in" },
            { keys = "[Alt] ARROWS", effect = "Move the video rectangle" },
            { keys = "[Alt] BACKSPACE", effect = "Reset pan/zoom" },
            { keys = "1 / 2", effect = "Decrease/increase contrast" },
            { keys = "3 / 4", effect = "Decrease/increase brightness" },
            { keys = "5 / 6", effect = "Decrease/increase gamma" },
            { keys = "7 / 8", effect = "Decrease/increase saturation" },
        },
    },
    {
        category = "Application",
        shortcuts = {
            { keys = "q", effect = "Quit" },
            { keys = "Q", effect = "Save position and quit" },
            { keys = "s", effect = "Take a screenshot" },
            { keys = "S", effect = "Take a screenshot without subtitles" },
            { keys = "[Ctrl] s", effect = "Take a screenshot as rendered" },
        },
    },
    {
        category = "Window",
        shortcuts = {
            { keys = "f", effect = "Toggle fullscreen" },
            { keys = "[Command] f", effect = "Toggle fullscreen [macOS]" },
            { keys = "ESC", effect = "Exit fullscreen" },
            { keys = "T", effect = "Toggle stay-on-top" },
            { keys = "[Alt] 0", effect = "Resize window to 0.5x [macOS]" },
            { keys = "[Alt] 1", effect = "Reset window size [macOS]" },
            { keys = "[Alt] 2", effect = "Resize window to 2x [macOS]" },
        },
    },
    {
        category = "Multimedia keys",
        shortcuts = {
            { keys = "PAUSE", effect = "Pause" },
            { keys = "STOP", effect = "Quit" },
            { keys = "PREVIOUS / NEXT", effect = "Seek 1 minute" },
        },
    },
}

M._state = {
    active = false,
    start_line = 1,
    start_category = 1,
}

M._opts = {
    font = "monospace",
    font_size = 8,
    usage_font_size = 6,
}

local usage = {
    category = "usage",
    shortcuts = {
        {
            keys = "esc",
            effect = "close",
            callback = function()
                M._enable(false)
            end,
        },
        {
            keys = "?",
            effect = "close",
            callback = function()
                M._enable(false)
            end,
        },
        {
            keys = "j",
            effect = "next line",
            callback = function()
                M._state.start_line = M._state.start_line + 1
                M.render()
            end,
            options = "repeatable",
        },
        {
            keys = "k",
            effect = "prev line",
            callback = function()
                M._state.start_line = math.max(1, M._state.start_line - 1)
                M.render()
            end,
            options = "repeatable",
        },
        {
            keys = "n",
            effect = "next category",
            callback = function()
                M._state.start_category = math.min(#M.shortcuts, M._state.start_category + 1)
                M._state.start_line = 1
                M.render()
            end,
            options = "repeatable",
        },
        {
            keys = "p",
            effect = "prev category",
            callback = function()
                M._state.start_category = math.max(1, M._state.start_category - 1)
                M._state.start_line = 1
                M.render()
            end,
            options = "repeatable",
        },
    },
}

local WRAPPING = {
    SMART = 0,
    EOL = 1,
    NO_WORD = 2,
    SMART_WIDER = 3,
}

local ALIGNMENT = {
    BOTTOM_LEFT = 1,
    BOTTOM_CENTER = 2,
    BOTTOM_RIGHT = 3,
    MIDDLE_LEFT = 4,
    MIDDLE_CENTER = 5,
    MIDDLE_RIGHT = 6,
    TOP_LEFT = 7,
    TOP_CENTER = 8,
    TOP_RIGHT = 9,
}

local render_text = function(ass, text, opts)
    opts = opts or {}
    opts.line_alignment = opts.line_alignment or MIDDLE_CENTER
    opts.font = opts.font or M._opts.font
    opts.font_size = opts.font_size or M._opts.font_size
    opts.letter_spacing = opts.letter_spacing or 0

    opts.primary = opts.primary or {}
    opts.primary.alpha = opts.primary.alpha or "00"
    opts.primary.color = opts.primary.color or "ffffff"

    if opts.border then
        opts.border.size = opts.border.size or 0
        opts.border.alpha = opts.border.alpha or "00"
        opts.border.color = opts.border.color or "ffffff"
    end

    if opts.shadow then
        if type(opts.shadow.size) == "table" then
            opts.shadow.size.x = opts.shadow.size.x or 0
            opts.shadow.size.y = opts.shadow.size.y or 0
        end
        opts.shadow.alpha = opts.shadow.alpha or "00"
        opts.shadow.color = opts.shadow.color or "ffffff"
    end

    local tags = ""

    tags = tags .. "\\an" .. opts.line_alignment
    tags = tags .. "\\fn" .. opts.font
    tags = tags .. "\\fs" .. opts.font_size
    tags = tags .. "\\fsp" .. opts.letter_spacing
    if opts.wrap_style then
        tags = tags .. "\\q" .. opts.wrap_style
    end

    tags = tags .. ("\\1a&H" .. opts.primary.alpha .. "&")
    tags = tags .. ("\\1c&H" .. opts.primary.color .. "&")

    if opts.border then
        tags = tags .. "\\bord" .. opts.border.size
        tags = tags .. "\\3a&H" .. opts.border.alpha .. "&"
        tags = tags .. "\\3c&H" .. opts.border.color .. "&"
    end

    if opts.shadow then
        if type(opts.shadow.size) == "table" then
            tags = tags .. "\\xshad" .. opts.shadow.size.x
            tags = tags .. "\\yshad" .. opts.shadow.size.y
        else
            tags = tags .. "\\shad" .. opts.shadow.size
        end
        tags = tags .. "\\4a&H" .. opts.shadow.alpha .. "&"
        tags = tags .. "\\4c&H" .. opts.shadow.color .. "&"
    end

    ass:new_event()
    ass:append("{" .. tags .. "}" .. text)
end

local render_category = function(category)
    local lines = {}

    -- Bolden category name
    table.insert(lines, "{\\b1}" .. category.category .. "{\\b0}")

    local max_key_length = 0
    for _, shortcut in ipairs(category.shortcuts) do
        max_key_length = math.max(#shortcut.keys, max_key_length)
    end

    for _, shortcut in ipairs(category.shortcuts) do
        local padding = (" "):rep(max_key_length - #shortcut.keys)
        local line = shortcut.keys .. padding .. " " .. shortcut.effect
        local escaped = string.gsub(line, "([{}])", "\\%1")
        table.insert(lines, escaped)
    end

    return lines
end

M.render = function()
    local screen = mp.get_osd_size()
    if not M._state.active then
        mp.set_osd_ass(0, 0, "{}")
        return
    end

    local ass = assdraw.ass_new()

    local lines = {}

    for i = M._state.start_category, #M.shortcuts do
        category = M.shortcuts[i]
        for _, line in ipairs(render_category(category)) do
            table.insert(lines, line)
        end
        table.insert(lines, "")
    end

    local main_text = table.concat(lines, "\\N", M._state.start_line, #lines)
    render_text(ass, main_text, {
        line_alignment = ALIGNMENT.TOP_LEFT,
        wrap_style = WRAPPING.EOL,
        primary = { color = "eeeeee" },
        border = { color = "111111", size = 1 },
        shadow = { color = "111111", alpha = "99", size = { y = 1 } },
    })

    local side_lines = render_category(usage)

    local side_text = table.concat(side_lines, "\\N")
    render_text(ass, side_text, {
        font_size = M._opts.usage_font_size,
        line_alignment = ALIGNMENT.TOP_RIGHT,
    })

    mp.set_osd_ass(0, 0, ass.text)
end

M._update_bindings = function(bindings, enable)
    for i, binding in ipairs(bindings) do
        local name = "__cheatsheet_binding_" .. i
        if enable then
            mp.add_forced_key_binding(binding.keys, name, binding.callback, binding.options)
        else
            mp.remove_key_binding(name)
        end
    end
end

M._enable = function(active)
    if active == M._state.active then
        return
    end
    if active then
        M._state.active = true
        M._update_bindings(usage.shortcuts, true)
    else
        M._state.active = false
        M._update_bindings(usage.shortcuts, false)
    end
    M.render()
end

mp.add_key_binding("?", "cheatsheet-enable", function()
    M._enable(true)
end)

mp.observe_property("osd-width", "native", M.render)
mp.observe_property("osd-height", "native", M.render)

return M
