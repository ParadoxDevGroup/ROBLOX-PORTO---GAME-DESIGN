--!strict

local ModuleLoader = {}

local moduleSelectedEvent = Instance.new("BindableEvent")
moduleSelectedEvent.Name = "ModuleSelected"

local hubReturnedEvent = Instance.new("BindableEvent")
hubReturnedEvent.Name = "HubReturned"

local activeModule = nil

function ModuleLoader.selectModule(moduleId)
	activeModule = moduleId
	moduleSelectedEvent:Fire(moduleId)
end

function ModuleLoader.getActiveModule()
	return activeModule
end

function ModuleLoader.onModuleSelected(callback)
	return moduleSelectedEvent.Event:Connect(callback)
end

function ModuleLoader.returnToHub()
	activeModule = nil
	hubReturnedEvent:Fire()
end

function ModuleLoader.onHubReturned(callback)
	return hubReturnedEvent.Event:Connect(callback)
end

return ModuleLoader
