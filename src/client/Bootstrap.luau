--!strict

local Controllers = script.Parent:WaitForChild("Controllers")
local UI = script.Parent:WaitForChild("UI")

local HubController = require(Controllers:WaitForChild("HubController"))
local mountHub = require(UI:WaitForChild("mountHub"))

local Bootstrap = {}

function Bootstrap.start()
	HubController.start()
	mountHub()
end

return Bootstrap