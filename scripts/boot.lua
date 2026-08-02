local gui =
    require("gui")


gui.init()


gui.log(
"System start"
)


gui.setState({

    yaw=90,

    altitude=120,

    engineL=32,

    engineR=32,

    status="Flying"

})



while true do


    local e,b,x,y =
        os.pullEvent(
            "mouse_click"
        )


    local cmd =
        gui.click(
            x,
            y
        )


    if cmd then

        gui.log(
            "CMD "..cmd
        )


        -- 这里调用net.lua

        -- net.request(
        -- server,
        -- "turn",
        -- cmd
        -- )

    end


end