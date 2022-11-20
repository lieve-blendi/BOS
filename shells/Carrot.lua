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