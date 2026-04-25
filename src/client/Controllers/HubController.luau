--!strict

local Modules = script.Parent.Parent:WaitForChild("Modules")

local ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))
local ModuleRegistry = require(Modules:WaitForChild("ModuleRegistry"))
local ClientModuleService = require(Modules:WaitForChild("ClientModuleService"))

local HubController = {}

local started = false
local moduleConnection = nil
local hubReturnedConnection = nil
local moduleService = nil

function HubController.start()
	if started then
		return
	end

	moduleService = ClientModuleService.new()
	moduleService:Init(ModuleRegistry.getModules())

	started = true
	moduleConnection = ModuleLoader.onModuleSelected(function(moduleId)
		moduleService:Start(moduleId)
	end)

	hubReturnedConnection = ModuleLoader.onHubReturned(function()
		moduleService:Stop()
	end)
end

function HubController.stop()
	if hubReturnedConnection then
		hubReturnedConnection:Disconnect()
		hubReturnedConnection = nil
	end

	if moduleConnection then
		moduleConnection:Disconnect()
		moduleConnection = nil
	end

	if moduleService then
		moduleService:Stop()
		moduleService = nil
	end

	started = false
end

return HubController
