local result, reason = ""

do
	local handle, chunk = component.proxy(component.list("internet")() or error("You need an internet card to use NetworkBoot, please add one.")).request("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkInit.lua")

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

result, reason = load(result, "=installer")

if result then
	result, reason = xpcall(result, debug.traceback)

	if not result then
		error(reason)
	end
else
	error(reason)
end