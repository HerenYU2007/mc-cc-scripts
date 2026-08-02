local basalt = require("basalt")

local frame = basalt.getMainFrame()
frame:setBackground(basalt.rgb("#1e1e2e"))

local label = frame:addLabel({
    x = 2,
    y = 2,
    text = "Hello World",
})

frame:addButton({
    x = 2,
    y = 4,
    text = "Click me",
})
    :onClick(function(self)
        self.text = "Thanks!"
        label.text = "Button clicked!"
    end)

basalt.run()