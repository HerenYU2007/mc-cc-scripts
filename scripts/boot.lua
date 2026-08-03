local gui =require("gui")
local net=require("net")
net.init("bottom","server")

gui.init()
gui.log("System start")
gui.setState({
    yaw=90,
    altitude=120,
    engineL=32,
    engineR=32,
    status="Flying"
})

local l={}
l["mouse_click"]=function (b,x,y)
    local cmd =gui.click(x,y)
    if cmd then
        gui.log("CMD "..cmd)
    end
end
l["rednet_message"]=function (a,b,c)
    net.onEvent(a,b,c)
end
l["terminate"]=function ()
    gui.log("On terminate")
    net.onTerminate()
end

local naviS=net.connect("navi",function (s,ok)
    gui.log("navi connected")
    net.regHandle(s,function (ss,data)
        gui.log(data.omega)
    end)
end)
local e,b,x,y
while true do
    e,b,x,y =os.pullEventRaw()
    if l[e]~=nil then
        l[e](b,x,y)
    end
end