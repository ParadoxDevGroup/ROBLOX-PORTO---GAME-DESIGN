--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local zones = {
	"Downtown Plaza",
	"Canal Market",
	"Rooftop Garden",
}

local function statCard(title, value, accent)
	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 24, 31),
		BorderSizePixel = 0,
		Size = UDim2.new(0.333, -8, 1, 0),
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = accent,
			Transparency = 0.55,
			Thickness = 1,
		}),
		Title = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 18),
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Text = title,
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 30),
			Size = UDim2.new(1, -28, 0, 22),
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
			Text = value,
			TextColor3 = Color3.fromRGB(236, 241, 247),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

local function DynamicQuestView()
	local questActive, setQuestActive = React.useState(false)
	local remainingSeconds, setRemainingSeconds = React.useState(120)
	local foundPet, setFoundPet = React.useState(false)
	local zoneIndex, setZoneIndex = React.useState(1)
	local titleTag, setTitleTag = React.useState("None")
	local statusText, setStatusText = React.useState("Start a quest when the player enters a supported zone.")

	React.useEffect(function()
		if not questActive then
			return nil
		end

		local cancelled = false

		task.spawn(function()
			while not cancelled and questActive and not foundPet do
				task.wait(1)

				if cancelled or not questActive or foundPet then
					break
				end

				setRemainingSeconds(function(current)
					local nextSeconds = math.max(current - 1, 0)
					if nextSeconds == 0 then
						setQuestActive(false)
						setStatusText("The cat ran out of time. Start another scan to retry the hunt.")
					end

					return nextSeconds
				end)
			end
		end)

		return function()
			cancelled = true
		end
	end, { questActive, foundPet })

	local function startQuest()
		setQuestActive(true)
		setRemainingSeconds(120)
		setFoundPet(false)
		setTitleTag("None")
		setStatusText(string.format("Quest live in %s. Find the pet before the timer expires.", zones[zoneIndex]))
	end

	local function searchForCat()
		if not questActive then
			setStatusText("Start the quest first to search the zone.")
			return
		end

		if foundPet then
			setStatusText("The pet has already been found for this run.")
			return
		end

		setFoundPet(true)
		setQuestActive(false)
		setTitleTag("Neighborhood Hero")
		setStatusText("Cat found. The player receives a temporary social title tag as a reward.")
	end

	local function cycleZone()
		local nextIndex = zoneIndex + 1
		if nextIndex > #zones then
			nextIndex = 1
		end

		setZoneIndex(nextIndex)
		setStatusText(string.format("Quest hint moved to %s.", zones[nextIndex]))
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 20, 26),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 96),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(112, 122, 224),
				Transparency = 0.5,
				Thickness = 1,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 14),
				Size = UDim2.new(1, -36, 0, 28),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Text = "Module 3: Dynamic Quest",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 46),
				Size = UDim2.new(1, -36, 0, 34),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "A two-minute hunt activates by zone and awards a temporary title tag when the cat is found.",
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 15,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		Stats = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 78),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Zone = statCard("Current Zone", zones[zoneIndex], Color3.fromRGB(112, 122, 224)),
			Timer = statCard(
				"Time Remaining",
				string.format("%d seconds", remainingSeconds),
				Color3.fromRGB(84, 232, 204)
			),
			Reward = statCard("Title Tag", titleTag, Color3.fromRGB(222, 146, 68)),
		}),
		Actions = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 176),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			StartButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = questActive and "Quest Active" or "Start Lost Pet Quest",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = startQuest,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			SearchButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = "Search Zone for Cat",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = searchForCat,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			ZoneButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = string.format("Cycle Zone Hint (%s)", zones[zoneIndex]),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = cycleZone,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),
		Status = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Text = statusText,
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		}),
	})
end

return DynamicQuestView
