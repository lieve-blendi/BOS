local internetID = component.list("internet")()
if not internetID then
	local component_invoke = component.invoke
	local function boot_invoke(address, method, ...)
    	local result = table.pack(pcall(component_invoke, address, method, ...))
    	if not result[1] then
    		return nil, result[2]
    	else
    		return table.unpack(result, 2, result.n)
    	end
	end

	local function tryLoadFrom(addr)
		computer.setBootAddress(addr)
		gpu.setForeground(0xFFFFFF)
		gpu.setBackground(0x000000)
		gpu.fill(1, 1, w, h, " ")
		gpu.set(1, 1, "Booting in " .. addr .. "...")
		local handle, reason = boot_invoke(addr, "open", "/networkCache.lua")
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
		return load(buffer, "=localBIOS")
	end

	for fileSys in component.list("filesystem") do
		local init, initreason = tryLoadFrom(fileSys)

		if init then init() return end
	end
	error("No bootable medium found")
	return
end

local result, reason = ""
do
	local handle, chunk = component.proxy(internetID or error("You need an internet card to use NetworkBoot, please add one.")).request("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkInit.lua")

	while true do
		chunk = handle.read(math.huge)
		
		if chunk then
			result = result .. chunk
		else
			break
		end
	end

	handle.close()
end

result, reason = load(result, "=runner")

if result then
	result, reason = xpcall(result, debug.traceback)

	if not result then
		error(reason)
	end
else
	error(reason)
end