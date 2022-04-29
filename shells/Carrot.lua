-- Carrot shell
Carrot = {}

Carrot.cmds = {}

function Carrot:bindCommand(command, callback)
    Carrot.cmds[command] = callback
end

function Carrot:dropCommand(command)
    Carrot.cmds[command] = nil
end

function Carrot:run(command, args)
    if type(Carrot.cmds[command]) == "function" then
        Carrot.cmds[command](args)
    end
end

function Carrot:processString(str)
    
end

return Carrot