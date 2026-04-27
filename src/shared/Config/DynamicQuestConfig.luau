--!strict

local DynamicQuestConfig = {
	QuestDurationSeconds = 120,
	ZoneTriggerRadius = 55,
	ZonePromptCooldownSeconds = 30,
	TitleDurationSeconds = 90,
	RewardTitle = "Neighborhood Hero",
	QuestTypes = {
		{
			name = "LostPet",
			display = "Lost Cat",
			targetModel = "Cat",
			rewardLabel = "Neighborhood Hero",
		},
		{
			name = "RescueBird",
			display = "Rescue Bird",
			targetModel = "Bird",
			rewardLabel = "Friend of the Sky",
		},
	},
	Zones = {
		{
			name = "Downtown Plaza",
			position = Vector3.new(0, -7, -45),
		},
		{
			name = "Canal Market",
			position = Vector3.new(55, -7, 35),
		},
		{
			name = "Rooftop Garden",
			position = Vector3.new(-55, -7, 35),
		},
	},
}

return table.freeze(DynamicQuestConfig)
