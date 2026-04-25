--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ModuleIds = require(Shared:WaitForChild("Config"):WaitForChild("ModuleIds"))

local Implementations = script.Parent:WaitForChild("Implementations")
local SocialPropModule = require(Implementations:WaitForChild("SocialPropModule"))
local MicroEconomyModule = require(Implementations:WaitForChild("MicroEconomyModule"))
local DynamicQuestModule = require(Implementations:WaitForChild("DynamicQuestModule"))

local ModuleRegistry = {}

local modulesById = {
	[ModuleIds.SocialProp] = SocialPropModule,
	[ModuleIds.MicroEconomy] = MicroEconomyModule,
	[ModuleIds.DynamicQuest] = DynamicQuestModule,
}

function ModuleRegistry.getModules()
	return modulesById
end

return ModuleRegistry
