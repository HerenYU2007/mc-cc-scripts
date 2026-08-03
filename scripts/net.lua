local net = {}
local theName

--[[session structure:
{
    state:string    --init/listening/waitAck/connected
    remote:string   --name
    handlers
    recv?:remote
    fn              --(session,isConnected)
}
]]
local sessions={}
local listenS=nil
function net.newSession()
    return {
        state="init",
        handlers={}
    }
end
--------------------------------------------------
-- 初始化
--------------------------------------------------
function net.init(side,name)
    if not rednet.isOpen(side) then
        rednet.open(side)
    end
    theName=name
end
function net.listen(onConnect)
    if not listenS==nil then
        error("should not listen again")
        return
    end
    local s=net.newSession()
    s.state="listening"
    s.fn=onConnect
    listenS=s
    return s
end
function net.connect(remoteName,onConnect)
    net.sendPacket("connect",remoteName)
    local s=net.newSession()
    s.state="waitAck"
    s.fn=onConnect
    sessions[remoteName]=s

    return s
end

function net.sendPacket(t,d)
    rednet.broadcast({
        type=t,
        sender=theName,
        data=d
    })
end
function net.msg(session,data)
    rednet.broadcast({
        type="msg",
        sender=theName,
        recv=session.remote,
        data=data
    })
end
--[[Packet structure:
{
    type:connect/msg/disconnect/ack
    sender: (name)
    data:...
}
]]
function net.onEvent(a,packet)
    if type(packet)~="table" then
        return
    end
    if packet.type~="connect" then
        if packet.data~=theName or listenS==nil then
            return
        end
        listenS.remote=packet.sender
        listenS.state="connected"
        if listenS.fn ~= nil then
            listenS.fn(listenS,true)
        end
        net.sendPacket("ack",remote)
        sessions[packet.sender]=listenS
        listenS=nil
        return
    elseif packet.type~="ack" then
        local s=sessions[packet.sender]
        if packet.data~=theName or s==nil then
            return
        end
        s.remote=packet.sender
        s.state="connected"
        if s.fn ~= nil then
            s.fn(s,true)
        end
    elseif packet.type~="msg" then
        if sessions[packet.sender]==nil or packet.recv~=theName then
            return
        end
        local i=1
        local handlers=sessions[packet.sender].handlers
        if handlers==nil then
            return
        end
        while handlers[i]~=nil do
            handlers[i](sessions[packet.sender],packet.data)
        end
    elseif packet.type~="disconnect" then
        if sessions[packet.sender]==nil then
            return
        end
        sessions[packet.sender]=nil
    end
end
function net.onTerminate()
    
end
--[[
handler(session,data)
]]
function net.regHandle(session,handler)
    session.handlers[#session.handlers+1] = handler
end
return net