-- Boot stuff

OS = {}
OS.name = "BOS"
OS.version = "0.0.1"

local componentsCache = {}

local bootDir = computer.getBootAddress()

Components = setmetatable({}, {
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

local width, height = Components.gpu.getResolution()

FileSystem = {
  addr = bootDir,
  changeAddress = function(self, newAddress)
    self.addr = newAddress
    Components.filesystem = component.proxy(newAddress)
  end,
  open = Components.filesystem.open,
  read = function(handle) return Components.filesystem.read(handle, math.huge) end,
  write = Components.filesystem.write,
  close = Components.filesystem.close,
  list = function(dir) return Components.filesystem.list(dir or '/') end,
  mkdir = Components.filesystem.makeDirectory,
  rename = Components.filesystem.rename,
  remove = Components.filesystem.remove,
  readfile = function(self, file)
    local hdl, err = self.open(file, 'r')
    if not hdl then error(err) end
    local buffer = ''
    repeat
      local data, err_read = self.read(hdl)
      if not data and err_read then error(err_read) end
      buffer = buffer .. (data or '')
    until not data
    self.close(hdl)
    return buffer
  end,
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

DriverStore = {}

local driverCache = {}

Drivers = setmetatable({}, {
  __index = function(t, k)
    if not driverCache[k] then driverCache[k] = FileSystem:loadfile("/drivers/" .. k .. ".lua") end 
    if not DriverStore[k] then DriverStore[k] = {} end
    return driverCache[k]
  end
})

local shellCache = {}

Shells = setmetatable({}, {
  __index = function(t, k)
    if shellCache[k] == nil then
      shellCache[k] = FileSystem:loadfile("/shells/" .. k .. ".lua")
    end
    return shellCache[k]
  end
})



local deskCache = {}

Desktops = setmetatable({}, {
  __index = function(t, k)
    if deskCache[k] == nil then
      deskCache[k] = FileSystem:loadfile("/desktops/" .. k .. ".lua")
    end
    return deskCache[k]
  end
})

function SetDesktopEnvironment(de)
  DE = de
end

function SetShell(sh)
  SH = sh
end

function error(err)
  Components.gpu.setForeground(0xFFFFFF)
  Components.gpu.setBackground(0x000000)
  Components.gpu.fill(1, 1, width, height, " ")

  local gpu = Components.gpu

  gpu.set(1, 1, "BOS Error Screen")
  gpu.set(1, 3, tostring(err) .. "_")

  repeat
    local e, addr, char, code = computer.pullSignal()
  until e == 'keydown' and code == 28
  computer.shutdown(true)
end

SetDesktopEnvironment(Desktops.Turtle)

SetShell(Shells.Carrot)

DE:load()

while true do
  if DE then
    local signal = {computer.pullSignal(0.01)}
    if signal[1] ~= nil then DE:processSignal(signal) end 
    DE:show()
  end
end

