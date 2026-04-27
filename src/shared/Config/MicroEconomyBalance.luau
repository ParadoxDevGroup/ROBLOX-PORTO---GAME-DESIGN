--!strict

local MicroEconomyBalance = {
	InitialTokens = 30,
	InitialSpeedLevel = 1,
	InitialTipLevel = 1,
	InitialServedCount = 0,
}

function MicroEconomyBalance.costForSpeed(level)
	return 15 + (level * 20)
end

function MicroEconomyBalance.costForTips(level)
	return 20 + (level * 24)
end

function MicroEconomyBalance.payoutForServe(speedLevel, tipLevel)
	return 8 + (speedLevel * 2) + (tipLevel * 2)
end

return table.freeze(MicroEconomyBalance)
