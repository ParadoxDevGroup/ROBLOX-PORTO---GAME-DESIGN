--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ModuleIds = require(Shared:WaitForChild("Config"):WaitForChild("ModuleIds"))

local ModuleRegistry = {}

local initializers = {
	[ModuleIds.SocialProp] = function()
		-- Stub: spawn social prop greybox references here.
		print("[ModuleRegistry] Initializing Module 1: Social Prop")
	end,
	[ModuleIds.MicroEconomy] = function()
		-- Stub: spawn cafe loop greybox references here.
		print("[ModuleRegistry] Initializing Module 2: Micro-Economy")
	end,
	[ModuleIds.DynamicQuest] = function()
		-- Stub: spawn quest search greybox references here.
		print("[ModuleRegistry] Initializing Module 3: Dynamic Quest")
	end,
}

function ModuleRegistry.initialize(moduleId)
	local initializer = initializers[moduleId]
	if not initializer then
		warn(string.format("[ModuleRegistry] No initializer registered for module: %s", moduleId))
		return
	end

	initializer()
end

return ModuleRegistry