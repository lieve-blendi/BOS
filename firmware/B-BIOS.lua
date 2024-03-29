-- Special BIOS
local init
local initreason
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
    local width, height = boot_invoke(gpu, "getResolution")

    if not gpu then
        error("No graphics card available")
    end
    local function tryLoadFrom(addr)
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

    boot_invoke(gpu, "fill", 1, 1, width, height)
    boot_invoke(gpu, "set", 1, 1, "Choose boot drive: ")

    local fs = {}

    for fileSys in component.list("filesystem") do
        if computer.tmpAddress() ~= fileSys then
            table.insert(fs, fileSys)
        end
    end

    for i=1,#fs do
        local label = component.proxy(fs[i]).getLabel()
        if label then
            boot_invoke(gpu, "set", 1, i+1, tostring(i) .. ". " .. label .. " (" .. fs[i] .. ")")
        else
            boot_invoke(gpu, "set", 1, i+1, tostring(i) .. ". " .. fs[i])
        end
    end

    boot_invoke(gpu, "set", 1, #fs+2, "Press keys 1-4 to boot")
    boot_invoke(gpu, "set", 1, #fs+3, "Press enter to boot to default drive")
    boot_invoke(gpu, "set", 1, #fs+4, "Press any other key to reboot")

    local e, addr, char, code
    
    repeat
        e, addr, char, code = computer.pullSignal()
    until e == "key_down"

    if code == 28 then
        init, initreason = tryLoadFrom(computer.getBootAddress())
    elseif code == 2 then
        init, initreason = tryLoadFrom(fs[1])
    elseif code == 3 then
        init, initreason = tryLoadFrom(fs[2])
    elseif code == 4 then
        init, initreason = tryLoadFrom(fs[3])
    elseif code == 5 then
        init, initreason = tryLoadFrom(fs[4])
    else
        computer.shutdown(true)
    end
end
if init then
    init()
else
    error("Failed to load OS: " .. initreason)
end