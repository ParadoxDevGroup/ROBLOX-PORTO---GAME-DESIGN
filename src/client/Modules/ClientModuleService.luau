--!strict

local ClientModuleService = {}
ClientModuleService.__index = ClientModuleService

function ClientModuleService.new()
	return setmetatable({
		modules = {},
		activeModuleId = nil,
	}, ClientModuleService)
end

function ClientModuleService:Init(modulesById)
	self.modules = modulesById

	for moduleId, module in pairs(self.modules) do
		if type(module.Init) == "function" then
			module:Init()
		end

		print(string.format("[ClientModuleService] Registered module: %s", moduleId))
	end
end

function ClientModuleService:Start(moduleId)
	if self.activeModuleId == moduleId then
		return
	end

	self:Stop()

	local module = self.modules[moduleId]
	if not module then
		warn(string.format("[ClientModuleService] No module found for id: %s", moduleId))
		return
	end

	if type(module.Start) == "function" then
		module:Start()
	end

	self.activeModuleId = moduleId
end

function ClientModuleService:Stop()
	if not self.activeModuleId then
		return
	end

	local activeModule = self.modules[self.activeModuleId]
	if activeModule and type(activeModule.Stop) == "function" then
		activeModule:Stop()
	end

	self.activeModuleId = nil
end

function ClientModuleService:GetActiveModuleId()
	return self.activeModuleId
end

return ClientModuleService