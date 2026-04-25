--!strict

local SocialPropModule = {
	_id = "socialProp",
	_initialized = false,
	_running = false,
}

function SocialPropModule:Init()
	if self._initialized then
		return
	end

	self._initialized = true
	print("[SocialPropModule] Init")
end

function SocialPropModule:Start()
	if self._running then
		return
	end

	self._running = true
	print("[SocialPropModule] Start greybox sandbox")
end

function SocialPropModule:Stop()
	if not self._running then
		return
	end

	self._running = false
	print("[SocialPropModule] Stop greybox sandbox")
end

return SocialPropModule