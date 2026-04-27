--!strict

local Remotes = {
	FolderName = "Remotes",
	SocialPropDeployRequest = "SocialPropDeployRequest",
	SocialPropActionRequest = "SocialPropActionRequest",
	SocialPropSnapshotRequest = "SocialPropSnapshotRequest",
	SocialPropStateUpdated = "SocialPropStateUpdated",
	MicroEconomyActionRequest = "MicroEconomyActionRequest",
	MicroEconomySnapshotRequest = "MicroEconomySnapshotRequest",
	MicroEconomyStateUpdated = "MicroEconomyStateUpdated",
	DynamicQuestActionRequest = "DynamicQuestActionRequest",
	DynamicQuestSnapshotRequest = "DynamicQuestSnapshotRequest",
	DynamicQuestStateUpdated = "DynamicQuestStateUpdated",
}

return table.freeze(Remotes)
