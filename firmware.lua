-- Special BIOS
do
    local component_invoke = component.invoke
    local function boot_invoke(address, method, ...)
        local result = table.pack(pcall(component_invoke, address, method, ...))
        if not result[1] then
        return nil, result[2]
        else
        return table.unpack(result, 2, result.n)
        end
    end

    local eeprom = component.list("eeprom")()
    computer.getBootAddress = function()
        return boot_invoke(eeprom, "getData")
    end
    computer.setBootAddress = function(address)
        return boot_invoke(eeprom, "setData", address)
    end

    local function boot(addr)
        local width, height = boot_invoke(gpu, "getResolution")
        boot_invoke(gpu, "fill", 1, 1, width, height)
        boot_invoke(gpu, "set", 1, 1, "Booting " .. addr .. "...")
        computer.setBootAddress(addr)
        local handle, reason = boot_invoke(address, "open", "/init.lua")
        if not handle then
            return nil, reason
        end
        local buffer = ""
        repeat
            local data, reason = boot_invoke(address, "read", handle, math.huge)
            if not data and reason then
                return nil, reason
            end
            buffer = buffer .. (data or "")
        until not data
        boot_invoke(address, "close", handle)
        local init, reason = load(buffer, "=init")
        if not init then
            error("Failed to load OS: " .. reason)
        end
        init()
    end

    local screen = component.list("screen")()
    local gpu = component.list("gpu")()
    if gpu and screen then
        boot_invoke(gpu, "bind", screen)
    end

    if not gpu then
        error("No graphics card available")
    end

    while true do
        local width, height = boot_invoke(gpu, "getResolution")
        boot_invoke(gpu, "fill", 1, 1, width, height)
        boot_invoke(gpu, "set", 1, 1, "Choose boot drive: ")

        local fs = {}

        for fileSys in component.list("filesystem") do
            table.insert(fs, fileSys)
        end

        for i=1,#fs do
            boot_invoke(gpu, "set", 1, i+1, ">" .. fs[i])
        end

        local e, addr, char, code = computer.pullSignal()

        if e == "key_down" then
            if code == 28 then
                boot_invoke(gpu, "set", 1, 1, "You got mail")
                boot(computer.getBootAddress())
            elseif code == 2 then
                boot(fs[1])
            elseif code == 3 then
                boot(fs[2])
            elseif code == 4 then
                boot(fs[3])
            elseif code == 5 then
                boot(fs[4])
            end
        end
    end
end