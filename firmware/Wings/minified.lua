do local a={"/boot/kernel/pipes","/OS.lua","/init.lua"}local b=component;local c=computer;local d=b.invoke;local function e(f,g,...)local h=table.pack(pcall(d,f,g,...))if not h[1]then return nil,h[2]else return table.unpack(h,2,h.n)end end;local function i(j)local k=b.proxy(j)for l,m in ipairs(a)do if k.exists(m)then return m end end end;local function n(o)local p=b.list("internet")()if not p then return end;local q=b.proxy(p)local r,s=q.request(o)local h=""while true do s=r.read(math.huge)if s then h=h..s else break end end;r.close()return h end;local function t(u)local v=b.proxy(u)local w=v.list("/")for x,m in ipairs(w)do v.remove(m)end;v.setLabel(nil)end;local y=b.list("eeprom")()c.getBootAddress=function()return e(y,"getData")end;c.setBootAddress=function(f)return e(y,"setData",f)end;local z=b.list("screen")()local A=b.proxy(b.list("gpu")())if A and z then e(A,"bind",z)end;if not A then error("No graphics card available")end;local B,C=A.getResolution()A.setForeground(0xFFFFFF)A.setBackground(0)A.fill(1,1,B,C," ")A.set(1,1,"Wings BIOS")A.set(1,2,"Press left control to boot BIOS")local function D(u)c.setBootAddress(u)A.fill(1,1,B,C," ")A.set(1,1,"Booting in "..u.."...")local E=i(u)local r,F=e(u,"open",E)if not r then return nil,F end;local G=""repeat local H,F=e(u,"read",r,math.huge)if not H and F then return nil,F end;G=G..(H or"")until not H;e(u,"close",r)return load(G,"="..E)end;local function I()local J=D(c.getBootAddress())if J then J()else for K in b.list("filesystem")do J=D(K)if J then return J()end end;if J then J()else error("No bootable device found")end end end;local L=c.pullSignal;do local M,N,N,O=L(3)if M~="key_down"or O~=29 then I()end end;local P="touch"local Q="m"local R=""local S=""local T=""local U=""while true do A.fill(1,1,B,C," ")local V={}local W={}for K in b.list("filesystem")do local X=b.proxy(K)if c.tmpAddress()~=K then table.insert(V,K)local Y=""if c.getBootAddress()==K then Y=" < Default boot drive"end;local Z=X.getLabel()local _=math.floor(X.spaceUsed()/1048576*100)/100;local a0=math.floor(X.spaceTotal()/1048576*100)/100;if Z then table.insert(W,Z.." ("..string.sub(K,1,8)..") (".._.."/"..a0 .."MB used)"..Y)else table.insert(W,string.sub(K,1,8).." (".._.."/"..a0 .."MB used)"..Y)end end end;if Q=="m"then local a1={"Drives","Update BIOS"}for l,m in ipairs(a1)do A.set(1,l,m)end;local M,N,a2,a3=L()if M==P then for l,m in ipairs(a1)do if a3==l then if a2>=1 and a2<=#m then if l==1 then Q="d"elseif l==2 then local a4=n("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/Wings/minified.lua")if a4 then else T="No internet card detected"U="m"Q="e"end end end end end end end;if Q=="d"then local a1={"Boot normally","Back"}for l=1,#W do table.insert(a1,W[l],1)end;for l,m in ipairs(a1)do A.set(1,l,m)end;local M,N,a2,a3=L()if M==P then for l,m in ipairs(a1)do if a3==l then if a2>=1 and a2<=#m then if l<=#W then R=V[l]S=W[l]Q="ds"elseif l==#W+1 then I()elseif l==#W+2 then Q="m"end end end end end end;if Q=="ds"then local a1={S,"","Erase Drive","Boot Drive","Back"}for l,m in ipairs(a1)do A.set(1,l,m)end;local M,N,a2,a3=L()if M==P then for l,m in ipairs(a1)do if a3==l then if a2>=1 and a2<=#m then if l==3 then Q="es"elseif l==4 then local J=D(R)if J then J()else T="Drive failed to boot"U="ds"Q="e"end elseif l==5 then Q="d"R=""end end end end end end;if Q=="es"then local a1={"Are you sure you want to erase this drive?","","Yes","No"}for l,m in ipairs(a1)do A.set(1,l,m)end;local M,N,a2,a3=L()if M==P then for l,m in ipairs(a1)do if a3==l then if a2>=1 and a2<=#m then if l==3 then t(R)Q="d"R=""elseif l==4 then Q="d"R=""end end end end end end;if Q=="e"then local a1={T,"","Back"}for l,m in ipairs(a1)do A.set(1,l,m)end;local M,N,a2,a3=L()if M==P then for l,m in ipairs(a1)do if a3==l then if a2>=1 and a2<=#m then if l==3 then Q=U end end end end end end end end
