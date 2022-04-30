local function tryLoadFrom(addr)
    if not addr then return end
    boot_invoke(gpu, "fill", 1, 1, width, height)
    boot_invoke(gpu, "set", 1, 1, "Booting " .. addr .. "...")
    computer.setBootAddress(addr)
    local handle, reason = boot_invoke(addr, "open", "/init.lua")
    if not handle then
        return nil, reason
    end
    local buffer = ""
    repeat
        local data, reason = boot_invoke(addr, "read", handle, math.huge)
        if not data and reason then
            return nil, reason
        end
        buffer = buffer .. (data or "")
    until not data
    boot_invoke(addr, "close", handle)
    return load(buffer, "=init")
end

tryLoadFrom(computer.getBootAddress())