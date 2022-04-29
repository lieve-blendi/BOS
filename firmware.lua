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

    local bootDir = computer.getBootAddress()

    local Components = setmetatable({}, {
    __index = function(_, k)
        if componentsCache[k] == nil then
            local proxyAddr = bootDir
            if k ~= "filesystem" then
                proxyAddr = component.list(k)()
            end -- FileSystems need their drive address
            componentsCache[k] = component.proxy(proxyAddr)
        end

        return componentsCache[k]
    end
    }) -- Components table

    local FileSystem = {
        addr = bootDir,
        changeAddress = function(self, newAddress)
            self.addr = newAddress
            Components.filesystem = component.proxy(newAddress)
            self.open = Components.filesystem.open
            self.close = Components.filesystem.close
            self.read = Components.filesystem.read
        end,
        open = Components.filesystem.open,
        read = function(handle) return Components.filesystem.read(handle, math.huge) end,
        close = Components.filesystem.close,
        loadfile = function(self, file)
            local hdl, err = self.open(file, 'r')
            if not hdl then error(err) end
            local buffer = ''
            repeat
                local data, err_read = self.read(hdl)
                if not data and err_read then error(err_read) end
                buffer = buffer .. (data or '')
            until not data
            self.close(hdl)
            return load(buffer, '=' .. file, "bt", _G)()
        end,
    }

    while true do
        Components.gpu.set(1, 1, "Choose boot drive: ")

        local fs = {}

        for fileSys in computer.list("filesystem") do
            table.insert(fs, fileSys)
        end

        for i=1,#fs do
            Components.gpu.set(1, i+1, "> " .. fs[i])
        end

        if Components.keyboard.isKeyDown(0x1C) then
            FileSystem:changeAddress(Computer.getBootAddress())
            local init, reason = FileSystem:loadfile("init.lua")
            if not init then
                error("Failed to boot drive. Reason: " .. reason)
            end
        elseif Components.keyboard.isKeyDown(0x02) then
            Computer.setBootAddress(fs[1])
            FileSystem:changeAddress(fs[1])
            local init, reason = FileSystem:loadfile("init.lua")
            if not init then
                error("Failed to boot drive. Reason: " .. reason)
            end
        elseif Components.keyboard.isKeyDown(0x03) then
            Computer.setBootAddress(fs[2])
            FileSystem:changeAddress(fs[2])
            local init, reason = FileSystem:loadfile("init.lua")
            if not init then
                error("Failed to boot drive. Reason: " .. reason)
            end
        elseif Components.keyboard.isKeyDown(0x04) then
            Computer.setBootAddress(fs[3])
            FileSystem:changeAddress(fs[3])
            local init, reason = FileSystem:loadfile("init.lua")
            if not init then
                error("Failed to boot drive. Reason: " .. reason)
            end
        elseif Components.keyboard.isKeyDown(0x05) then
            Computer.setBootAddress(fs[4])
            FileSystem:changeAddress(fs[4])
            local init, reason = FileSystem:loadfile("init.lua")
            if not init then
                error("Failed to boot drive. Reason: " .. reason)
            end
        end
    end
end