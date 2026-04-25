--!strict

local DynamicQuestModule = {
	_id = "dynamicQuest",
	_initialized = false,
	_running = false,
}

function DynamicQuestModule:Init()
	if self._initialized then
		return
	end

	self._initialized = true
	print("[DynamicQuestModule] Init")
end

function DynamicQuestModule:Start()
	if self._running then
		return
	end

	self._running = true
	print("[DynamicQuestModule] Start greybox sandbox")
end

function DynamicQuestModule:Stop()
	if not self._running then
		return
	end

	self._running = false
	print("[DynamicQuestModule] Stop greybox sandbox")
end

return DynamicQuestModule