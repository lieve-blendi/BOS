--act like this is not just modified SnowBoot
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
    if not gpu then
        error("No graphics card available")
    end
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
    local booted = false
    while true do
        local width, height = boot_invoke(gpu, "getResolution")
        boot_invoke(gpu, "fill", 1, 1, width, height, " ")
        local fs = {}
        local txt = {}
        for fileSys in component.list("filesystem") do
            local proxy = component.proxy(fileSys)
            if computer.tmpAddress() ~= fileSys and proxy.exists("/init.lua") then
                table.insert(fs, fileSys)
                local proxy = component.proxy(fileSys)
                local label = proxy.getLabel()
                local usedspace = math.floor((proxy.spaceUsed()/1024/1024)*100)/100
                local totalspace = math.floor((proxy.spaceTotal()/1024/1024)*100)/100
                if label then
                    table.insert(txt, "Drive: " .. label .. " (" .. fileSys .. ") - " .. usedspace .. "/" .. totalspace .. "MB used")
                else
                    table.insert(txt, "Drive: " .. fileSys .. " - " .. usedspace .. "/" .. totalspace .. "MB used")
                end
            end
        end
        if #fs == 1 then
            init, initreason = tryLoadFrom(fs[1])
            break
        end
        table.insert(txt, "Boot default drive")
        table.insert(txt, "Restart")
        boot_invoke(gpu, "set", 1, 1, "CloudBoot v0.1 (Based off of SnowBoot v0.1)")
        boot_invoke(gpu, "set", 1, 2, "Click a drive to boot into it!")
        for i, t in ipairs(txt) do
            boot_invoke(gpu, "set", 1, i+3, t)
        end
        local id, btn, x, y = computer.pullSignal()
        if id == "touch" then
            if y > 3 and y <= (#txt+3) then
                local i = y-3

                for ind, f in ipairs(fs) do
                    if ind == i then
                        init, initreason = tryLoadFrom(f)
                        booted = true
                    end
                end
                i = i - #fs
                if i == 1 then
                    init, initreason = tryLoadFrom(computer.getBootAddress())
                    booted = true
                elseif i == 2 then
                    computer.shutdown(true)
                    booted = true
                end
            end
        end
        if booted then break end
    end
end
if init then
    init()
else
    error("Failed to load OS: " .. initreason)
end