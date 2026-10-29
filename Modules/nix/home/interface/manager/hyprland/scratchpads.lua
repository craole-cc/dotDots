-- Window tags preserve scratchpad ownership when a window leaves its workspace.
local scratchpads = { slots = {}, subscriptions = {} }
local tag_prefix = "dotdots-scratchpad-"

local function owner_tag(name)
    return tag_prefix .. name
end

local function has_tag(window, tag)
    for _, existing in ipairs(window.tags or {}) do
        if existing == tag then
            return true
        end
    end
    return false
end

local function remember(window, name)
    local tag = owner_tag(name)
    local selector = "address:" .. window.address
    for _, existing in ipairs(window.tags or {}) do
        if existing:sub(1, #tag_prefix) == tag_prefix and existing ~= tag then
            hl.dispatch(hl.dsp.window.tag({ window = selector, tag = "-" .. existing }))
        end
    end
    if not has_tag(window, tag) then
        hl.dispatch(hl.dsp.window.tag({ window = selector, tag = "+" .. tag }))
    end
    local slot = scratchpads.slots[name]
    if slot then
        slot.pending = false
        if slot.timer then
            slot.timer:set_enabled(false)
            slot.timer = nil
        end
    end
end

local function scan()
    for _, window in ipairs(hl.get_windows()) do
        local workspace = window.workspace
        if window.mapped and workspace then
            local name = workspace.name:match("^special:(.+)$")
            if name and scratchpads.slots[name] then
                remember(window, name)
            end
        end
    end
end

local function find_window(name, resident)
    local best = nil
    for _, window in ipairs(hl.get_windows()) do
        local workspace = window.workspace
        local matches = resident
            and workspace and workspace.name == "special:" .. name
            or not resident and has_tag(window, owner_tag(name))
        if window.mapped and matches then
            if best == nil or window.focus_history_id < best.focus_history_id then
                best = window
            end
        end
    end
    return best
end

local function show(name)
    local active = hl.get_active_special_workspace()
    if active == nil or active.name ~= "special:" .. name then
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
    end
end

function scratchpads.register(name, command)
    if scratchpads.slots[name] == nil then
        scratchpads.slots[name] = { command = command, pending = false }
    end
    scan()
end

function scratchpads.send(name)
    local window = hl.get_active_window()
    if window == nil or scratchpads.slots[name] == nil then
        return
    end
    remember(window, name)
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. name }))
end

function scratchpads.toggle(name)
    local slot = scratchpads.slots[name]
    if slot == nil then
        return
    end
    scan()
    if find_window(name, true) then
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        return
    end

    local owned = find_window(name, false)
    if owned then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. owned.address }))
        hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. name }))
        show(name)
        hl.dispatch(hl.dsp.focus({ window = "address:" .. owned.address }))
        return
    end

    if slot.pending then
        show(name)
        return
    end
    slot.pending = true
    slot.timer = hl.timer(function()
        slot.pending = false
        slot.timer = nil
    end, { timeout = 15000, type = "oneshot" })
    show(name)
    hl.exec_cmd(slot.command, { workspace = "special:" .. name })
end

function scratchpads.stop()
    for _, subscription in ipairs(scratchpads.subscriptions) do
        subscription:remove()
    end
    for _, slot in pairs(scratchpads.slots) do
        if slot.timer then
            slot.timer:set_enabled(false)
        end
    end
end

for _, event in ipairs({ "window.open", "window.move_to_workspace" }) do
    table.insert(scratchpads.subscriptions, hl.on(event, scan))
end

return scratchpads
