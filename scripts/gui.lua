local gui = {}
local w,h =term.getSize()
local state = {
    yaw = 0,
    altitude = 0,
    engineL = 0,
    engineR = 0,
    status = "Offline"
}
local logs = {}
local maxLog =h - 12
------------------------------------------------
-- 初始化
------------------------------------------------
function gui.init()
    term.setBackgroundColor(colors.black)
    term.clear()
    gui.draw()
end
------------------------------------------------
-- 更新状态
------------------------------------------------
function gui.setState(data)
    for k,v in pairs(data) do
        state[k]=v
    end
    gui.draw()
end
------------------------------------------------
-- 添加日志
-----------------------------------------------
function gui.log(text)
    table.insert(logs,text)
    while #logs > maxLog do
        table.remove(logs,1)
    end
    gui.draw()
end
------------------------------------------------
-- 清屏区域
------------------------------------------------
local function box(x1,y1,x2,y2)
    for y=y1,y2 do
        term.setCursorPos(
            x1,
            y
        )
        term.write(
            string.rep(
                " ",
                x2-x1+1
            )
        )
    end
end
------------------------------------------------
-- 绘制状态
------------------------------------------------
local function drawInfo()
    term.setCursorPos(1,1)
    term.write("=== Aircraft ===")
    term.setCursorPos(1,3)
    term.write(
        string.format(
        "Yaw: %.1f",
        state.yaw
        )
    )
    term.setCursorPos(1,4)
    term.write(
        "Alt: "..state.altitude
    )
    term.setCursorPos(1,5)
    term.write(
        string.format(
        "Engine L:%s R:%s",
        state.engineL,
        state.engineR
        )
    )
    term.setCursorPos(1,6)
    term.write(
        "Status: "
        ..
        state.status
    )
end
------------------------------------------------
-- 绘制日志
------------------------------------------------

local function drawLog()
    term.setCursorPos(1,8)
    term.write("--- LOG ---")
    local y=9
    for _,msg in ipairs(logs) do
        term.setCursorPos(1,y)
        term.write(
            "> "
            ..
            msg
        )
        y=y+1
    end
end
------------------------------------------------
-- 绘制按钮
------------------------------------------------

local buttons={
    {
        name="LEFT",
        x=2,
        y=h-3,
        w=8
    },
    {
        name="RIGHT",
        x=12,
        y=h-3,
        w=8
    },
    {
        name="UP",
        x=22,
        y=h-3,
        w=8
    },
    {
        name="STOP",
        x=32,
        y=h-3,
        w=8
    }
}
local function drawButtons()
    for _,b in ipairs(buttons) do
        term.setCursorPos(
            b.x,
            b.y
        )
        term.write(
            "["
            ..
            b.name
            ..
            "]"
        )
    end
end
------------------------------------------------
-- 总绘制
-----------------------------------------------
function gui.draw()
    term.clear()
    drawInfo()
    drawLog()
    drawButtons()
end
------------------------------------------------
-- 点击检测
------------------------------------------------
function gui.click(x,y)
    for _,b in ipairs(buttons) do
        if y==b.y
        and x>=b.x
        and x<=b.x+b.w then
            return b.name
        end
    end
    return nil
end
return gui