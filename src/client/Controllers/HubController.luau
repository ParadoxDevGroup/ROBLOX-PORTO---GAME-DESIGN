--!strict

local Modules = script.Parent.Parent:WaitForChild("Modules")

local ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))
local ModuleRegistry = require(Modules:WaitForChild("ModuleRegistry"))

local HubController = {}

local started = false
local moduleConnection = nil

function HubController.start()
	if started then
		return
	end

	started = true
	moduleConnection = ModuleLoader.onModuleSelected(function(moduleId)
		ModuleRegistry.initialize(moduleId)
	end)
end

function HubController.stop()
	if moduleConnection then
		moduleConnection:Disconnect()
		moduleConnection = nil
	end

	started = false
end

return HubController