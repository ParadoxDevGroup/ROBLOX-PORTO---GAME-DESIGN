--!strict

local MicroEconomyModule = {
	_id = "microEconomy",
	_initialized = false,
	_running = false,
}

function MicroEconomyModule:Init()
	if self._initialized then
		return
	end

	self._initialized = true
	print("[MicroEconomyModule] Init")
end

function MicroEconomyModule:Start()
	if self._running then
		return
	end

	self._running = true
	print("[MicroEconomyModule] Start greybox sandbox")
end

function MicroEconomyModule:Stop()
	if not self._running then
		return
	end

	self._running = false
	print("[MicroEconomyModule] Stop greybox sandbox")
end

return MicroEconomyModule