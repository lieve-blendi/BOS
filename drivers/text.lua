local Text = {}

function Text.split(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
     if s ~= 1 or cap ~= "" then
    table.insert(Table,cap)
     end
     last_end = e+1
     s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
     cap = pString:sub(last_end)
     table.insert(Table, cap)
  end
  return Table
end

function Text.PatternReplace(string,pattern,replace)
  local occ = {}
  local occ2 = {}
  local s=string
  local p=pattern
  local b=1
  while true do
    local x,y=string.find(s,p,b,true)
    if x==nil then break end
    occ[#occ+1] = x
    occ2[#occ2+1] = y
    b=y+1
  end

  local newdata = ""
  local lastdata = 1

  for k,v in ipairs(occ) do
    newdata = newdata .. string.sub(string,lastdata,v-1)
    newdata = newdata .. replace
    lastdata = occ2[k]+1
  end
  if lastdata <= #string then
    newdata = newdata .. string.sub(string,lastdata,#string)
  end
  return newdata
end

function Text.PatternFunctionReplace(string,pattern,replacefunc)
  local occ = {}
  local occ2 = {}
  local s=string
  local p=pattern
  local b=1
  while true do
    local x,y=string.find(s,p,b,true)
    if x==nil then break end
    occ[#occ+1] = x
    occ2[#occ2+1] = y
    b=y+1
  end

  local newdata = ""
  local lastdata = 1

  for k,v in ipairs(occ) do
    newdata = newdata .. string.sub(string,lastdata,v-1)
    newdata = newdata .. replacefunc()
    lastdata = occ2[k]+1
  end
  if lastdata <= #string then
    newdata = newdata .. string.sub(string,lastdata,#string)
  end
  return newdata
end

function Text.startswith(string,pattern)
  return string.sub(string,1,#pattern) == pattern
end

function Text.endswith(string,pattern)
  return string.sub(string,-#pattern) == pattern
end

return Text