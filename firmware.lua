-- Special BIOS
do
    local componentsCache = {}

    local component_invoke = component.invoke
    local function boot_invoke(address, method, ...)
        local result = table.pack(pcall(component_invoke, address, method, ...))
        if not result[1] then
        return nil, result[2]
        else
        return table.unpack(result, 2, result.n)
        end
    end

    -- backwards compatibility, may remove later
    local eeprom = component.list("eeprom")()
    computer.getBootAddress = function()
        return boot_invoke(eeprom, "getData")
    end
    computer.setBootAddress = function(address)
        return boot_invoke(eeprom, "setData", address)
    end

    local function boot(addr)
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
        return load(buffer, "=init")
    end

    do
        local screen = component.list("screen")()
        local gpu = component.list("gpu")()
        if gpu and screen then
          boot_invoke(gpu, "bind", screen)
        end
    end

    while true do
        Components.gpu.set(1, 1, "Choose boot drive: ")

        local fs = {}

        for fileSys in component.list("filesystem") do
            table.insert(fs, fileSys)
        end

        for i=1,#fs do
            Components.gpu.set(1, i+1, "> " .. fs[i])
        end

        local keyboard = component.list("keyboard")()

        if keyboard.isKeyDown(0x1C) then
            boot(computer.getBootAddress())
        elseif keyboard.isKeyDown(0x02) then
            boot(fs[1])
        elseif keyboard.isKeyDown(0x03) then
            boot(fs[2])
        elseif keyboard.isKeyDown(0x04) then
            boot(fs[3])
        elseif keyboard.isKeyDown(0x05) then
            boot(fs[4])
        end
    end
end