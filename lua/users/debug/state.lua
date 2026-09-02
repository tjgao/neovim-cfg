local M = {}

local STATE = {
    initialized = false,
    js_enabled = false,
}

function M.is_initialized()
    return STATE.initialized
end

function M.set_initialized(value)
    STATE.initialized = value == true
end

function M.set_js_enabled(value)
    STATE.js_enabled = value == true
end

return M
