-- Carrot shell
Carrot = {}

Carrot.cmds = {}

Carrot.name = "Carrot Shell"
Carrot.version = "0.1"
Carrot.internet = Components.internet

function Carrot:bindCommand(command, callback)
    Carrot.cmds[command] = callback
end

function Carrot:dropCommand(command)
    Carrot.cmds[command] = nil
end

function Carrot:run(command, args)
    if type(Carrot.cmds[command]) == "function" then
        Carrot.cmds[command](args)
    else
        if type(DE.print) == "function" then
            DE.print("Command not found: " .. (command or "nil"))
        end
    end
end

function Carrot:ProcessCommand(cmd)
    local split = {}
    local currindex = 1
    local i = 0
    while i < #cmd do
        if split[currindex] == nil then split[currindex] = "" end
        i = i + 1
        local char = cmd:sub(i,i)
        if char == '"' then
            local found = false
            local foundpos = 0
            for j = i+1,#cmd do
                local char2 = cmd:sub(j,j)
                if char2 == '"' then
                    found = true
                    foundpos = j
                    break
                end
            end
            if not found then
                return 'unfinished " found'
            end
            if split[currindex] == nil then split[currindex] = "" end
            local spos,epos = i,foundpos
            if spos < epos-1 and epos > spos+1 then
                split[currindex] = split[currindex] .. string.sub(cmd,spos+1,epos-1)
            end
            i = foundpos
        elseif char == " " then
            currindex = currindex + 1
        else
            if split[currindex] == nil then split[currindex] = "" end
            split[currindex] = split[currindex] .. char
        end
    end
    return split -- returns command name + arguments
    -- when using this, check if its a string, if it is, thats an error message
end

Carrot:bindCommand("wget",function(args)
    local url = args[1]
    local file = args[2]

    if not url then
        if type(DE.print) == "function" then
            DE.print("Usage: wget <url> <file>")
        end
        return
    end
    if not file then
        if type(DE.print) == "function" then
            DE.print("Usage: wget <url> <file>")
        end
        return
    end

    if type(DE.print) == "function" then
        DE.print("Downloading " .. url .. " to " .. file .. "...")
    end

    local result = ""
    local handle = Carrot.internet.request(url)
    for chunk in handle do result = result .. chunk end

    FileSystem.write(file, result)
end)

Carrot:bindCommand("echo",function(args)
    if type(DE.print) == "function" then
        DE.print((table.concat or concat)(args," "))
    end
end)

return Carrot