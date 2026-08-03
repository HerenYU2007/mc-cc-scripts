local net=require("net")
net.init("up","navi")
local serverSession
net.listen(function (session,ok)
    if ok then
        serverSession=session
        
    end
end)

local l={}
l["rednet_message"]=function (a,b,c)
    net.onEvent(a,b,c)
end
l["terminate"]=function ()
    gui.log("On terminate")
    net.onTerminate()
end

local lastTime=os.epoch("utc")
l["timer"]=function ()
    if serverSession~=nil then
        net.msg(serverSession,{omega="aa"})
    end
    os.startTimer(0.1)
    lastTime=os.epoch("utc")
end

local e,b,x,y
os.startTimer(0.1)
while true do
    e,b,x,y =os.pullEventRaw()
    if l[e]~=nil then
        l[e](b,x,y)
    end
end
