-- Special BIOS
local init
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

    local screen = component.list("screen")()
    local gpu = component.list("gpu")()
    if gpu and screen then
        boot_invoke(gpu, "bind", screen)
    end

    if not gpu then
        error("No graphics card available")
    end
    local function tryLoadFrom(addr)
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
        init, reason = load(buffer, "=init")
    end

    local width, height = boot_invoke(gpu, "getResolution")
    boot_invoke(gpu, "fill", 1, 1, width, height)
    boot_invoke(gpu, "set", 1, 1, "Choose boot drive: ")

    local fs = {}

    for fileSys in component.list("filesystem") do
        table.insert(fs, fileSys)
    end

    for i=1,#fs do
        boot_invoke(gpu, "set", 1, i+1, tostring(i) .. ". " .. fs[i])
    end

    boot_invoke(gpu, "set", 1, #fs+2, "Press keys 1-4 to boot")
    boot_invoke(gpu, "set", 1, #fs+3, "Press enter to boot to default drive")
    boot_invoke(gpu, "set", 1, #fs+4, "Press any other key to reboot")

    local e, addr, char, code
    
    repeat
        e, addr, char, code = computer.pullSignal()
    until e == "key_down"

    if code == 28 then
        tryLoadFrom(computer.getBootAddress())
    elseif code == 2 then
        tryLoadFrom(fs[1])
    elseif code == 3 then
        tryLoadFrom(fs[2])
    elseif code == 4 then
        tryLoadFrom(fs[3])
    elseif code == 5 then
        tryLoadFrom(fs[4])
    else
        computer.shutdown(true)
    end
end
if not init then
    error("Failed to load OS: " .. reason)
end
init()