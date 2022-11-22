do local a={"/boot/kernel/pipes","/OS.lua","/init.lua"}local b=component;local c=computer;local d=b.invoke;local function e(f,g,...)local h=table.pack(pcall(d,f,g,...))if not h[1]then return nil,h[2]else return table.unpack(h,2,h.n)end end;local function i(j)local k=b.proxy(j)for l,m in ipairs(a)do if k.exists(m)then return m end end end;local function n(o)local p=b.list("internet")()if not p then return end;local q=b.proxy(p)local r,s=q.request(o)local h=""while true do s=r.read(math.huge)if s then h=h..s else break end end;r.close()return h end;local function t(u)local v=b.proxy(u)local w=v.list("/")for x,m in ipairs(w)do v.remove(m)end;v.setLabel(nil)end;local y=b.list("eeprom")()c.getBootAddress=function()return e(y,"getData")end;c.setBootAddress=function(f)return e(y,"setData",f)end;local z=b.list("screen")()local A=b.proxy(b.list("gpu")())if A and z then e(A,"bind",z)end;if not A then error("No graphics card available")end;local B,C=A.getResolution()A.setForeground(0xFFFFFF)A.setBackground(0)A.fill(1,1,B,C," ")local D=A.set;D(1,1,"Wings BIOS")D(1,2,"Press left control to boot BIOS")local function E(u)c.setBootAddress(u)A.fill(1,1,B,C," ")D(1,1,"Booting in "..u.."...")local F=i(u)local r,G=e(u,"open",F)if not r then return nil,G end;local H=""repeat local I,G=e(u,"read",r,math.huge)if not I and G then return nil,G end;H=H..(I or"")until not I;e(u,"close",r)return load(H,"="..F)end;local function J()local K=E(c.getBootAddress())if K then K()else for L in b.list("filesystem")do K=E(L)if K then return K()end end;if K then K()else error("No bootable device found")end end end;local M=c.pullSignal;do local N,O,O,P=M(3)if N~="key_down"or P~=29 then J()end end;local Q="touch"local R="m"local S=""local T=""local U=""local V=""while true do A.fill(1,1,B,C," ")local W={}local X={}for L in b.list("filesystem")do local Y=b.proxy(L)if c.tmpAddress()~=L then table.insert(W,L)local Z=""if c.getBootAddress()==L then Z=" < Default boot drive"end;local _=Y.getLabel()local a0=math.floor(Y.spaceUsed()/1048576*100)/100;local a1=math.floor(Y.spaceTotal()/1048576*100)/100;if _ then table.insert(X,_.." ("..string.sub(L,1,8)..") ("..a0 .."/"..a1 .."MB used)"..Z)else table.insert(X,string.sub(L,1,8).." ("..a0 .."/"..a1 .."MB used)"..Z)end end end;if R=="m"then local a2={"Drives","Update BIOS"}for l,m in ipairs(a2)do D(1,l,m)end;local N,O,a3,a4=M()if N==Q then for l,m in ipairs(a2)do if a4==l then if a3>=1 and a3<=#m then if l==1 then R="d"elseif l==2 then local a5=n("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/Wings/minified.lua")if a5 then e(y,"set",a5)else U="No internet card detected"V="m"R="e"end end end end end end end;if R=="d"then local a2={"Boot normally","Back"}for l=1,#X do table.insert(a2,1,X[l])end;for l,m in ipairs(a2)do D(1,l,m)end;local N,O,a3,a4=M()if N==Q then for l,m in ipairs(a2)do if a4==l then if a3>=1 and a3<=#m then if l<=#X then S=W[l]T=X[l]R="ds"elseif l==#X+1 then J()elseif l==#X+2 then R="m"end end end end end end;if R=="ds"then local a2={T,"","Erase Drive","Boot Drive","Back"}for l,m in ipairs(a2)do D(1,l,m)end;local N,O,a3,a4=M()if N==Q then for l,m in ipairs(a2)do if a4==l then if a3>=1 and a3<=#m then if l==3 then R="es"elseif l==4 then local K=E(S)if K then K()else U="Drive failed to boot"V="ds"R="e"end elseif l==5 then R="d"S=""end end end end end end;if R=="es"then local a2={"Are you sure you want to erase this drive?","","Yes","No"}for l,m in ipairs(a2)do D(1,l,m)end;local N,O,a3,a4=M()if N==Q then for l,m in ipairs(a2)do if a4==l then if a3>=1 and a3<=#m then if l==3 then t(S)R="d"S=""elseif l==4 then R="d"S=""end end end end end end;if R=="e"then local a2={U,"","Back"}for l,m in ipairs(a2)do D(1,l,m)end;local N,O,a3,a4=M()if N==Q then for l,m in ipairs(a2)do if a4==l then if a3>=1 and a3<=#m then if l==3 then R=V end end end end end end end end
