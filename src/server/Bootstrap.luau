--!strict

local Services = script.Parent:WaitForChild("Services")
local SandboxService = require(Services:WaitForChild("SandboxService"))

local Bootstrap = {}

function Bootstrap.start()
	SandboxService.start()
end

return Bootstrap
