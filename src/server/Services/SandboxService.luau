--!strict

local SocialPropService = require(script.Parent:WaitForChild("SocialPropService"))
local MicroEconomyService = require(script.Parent:WaitForChild("MicroEconomyService"))
local DynamicQuestService = require(script.Parent:WaitForChild("DynamicQuestService"))

local SandboxService = {}

local socialPropService = nil
local microEconomyService = nil
local dynamicQuestService = nil

function SandboxService.start()
	if socialPropService or microEconomyService or dynamicQuestService then
		return
	end

	socialPropService = SocialPropService.new()
	socialPropService:start()

	microEconomyService = MicroEconomyService.new()
	microEconomyService:start()

	dynamicQuestService = DynamicQuestService.new()
	dynamicQuestService:start()
	print("[SandboxService] Server framework online")
end

function SandboxService.stop()
	if socialPropService then
		socialPropService:stop()
		socialPropService = nil
	end

	if microEconomyService then
		microEconomyService:stop()
		microEconomyService = nil
	end

	if dynamicQuestService then
		dynamicQuestService:stop()
		dynamicQuestService = nil
	end
end

return SandboxService
