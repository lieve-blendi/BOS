-- Carrot shell
Carrot = {}

Carrot.cmds = {}

Carrot.name = "Carrot Shell"
Carrot.version = "0.1"

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

function Carrot:processString(str)
    
end

return Carrot