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
    local gpuc = component.proxy(gpu)
    while true do
        local width, height = gpuc.getResolution()
        gpuc.fill(1, 1, width, height, " ")
        local fs = {}
        local txt = {}
        for fileSys in component.list("filesystem") do
            if computer.tmpAddress() ~= fileSys then
                table.insert(fs, fileSys)
                local label = component.proxy(fs[i]).getLabel()
                if label then
                    table.insert(txt, "Drive: " .. label .. " (" .. fileSys .. ")")
                else
                    table.insert(txt, "Drive: " .. fileSys)
                end
            end
        end

        -- if #fs == 1 then
        --     init, initreason = tryLoadFrom(fs[1])
        --     break
        -- end

        table.insert(txt, "Boot default drive")
        table.insert(txt, "Restart")

        gpuc.setForeground(0x000000)
        gpuc.setBackground(0xFFFFFF)
        gpuc.set(1, 1, "SnowBoot v0.1")
        local memTxt = "Memory Usage: " .. tostring(math.floor((computer.totalMemory() - computer.freeMemory()) / computer.totalMemory()*1000 + 0.5)/10) .. "%"
        gpuc.set(width-#memTxt, 1, memTxt)

        gpuc.setForeground(0xFFFFFF)
        gpuc.setBackground(0x000000)
        local id, btn, x, y = computer.pullSIgnal()

        if id == "touch" then
            -- Mouse clicked
            if x > 1 and x <= (#txt+1) then
                local i = x-1

                for ind, f in ipairs(fs) do
                    if ind == i then
                        init, initreason = tryLoadFrom(f)
                    end
                end
                i = i - #fs
                if i == 1 then
                    tryLoadFrom(computer.getBootAddress())
                elseif i == 2 then
                    computer.shutdown(true)
                end
            end
        end
    end
end
if init then
    init()
else
    error("Failed to load OS: " .. initreason)
end