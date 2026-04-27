--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local RemotesConfig = require(ConfigFolder:WaitForChild("Remotes"))
local DynamicQuestConfig = require(ConfigFolder:WaitForChild("DynamicQuestConfig"))

local zones = DynamicQuestConfig.Zones

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
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 30),
			Size = UDim2.new(1, -28, 0, 22),
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
			Text = value,
			TextColor3 = Color3.fromRGB(236, 241, 247),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

local function DynamicQuestView()
	local questActive, setQuestActive = React.useState(false)
	local remainingSeconds, setRemainingSeconds = React.useState(DynamicQuestConfig.QuestDurationSeconds)
	local foundPet, setFoundPet = React.useState(false)
	local zoneIndex, setZoneIndex = React.useState(1)
	local titleTag, setTitleTag = React.useState("None")
	local titleExpiresAt, setTitleExpiresAt = React.useState(0)
	local statusText, setStatusText = React.useState("Connecting to dynamic quest service...")
	local completedCount, setCompletedCount = React.useState(0)
	local questExpiresAt, setQuestExpiresAt = React.useState(0)
	local contextualPromptAvailable, setContextualPromptAvailable = React.useState(false)
	local promptZoneName, setPromptZoneName = React.useState("-")
	local serviceMode, setServiceMode = React.useState("connecting")

	React.useEffect(function()
		local alive = true
		local actionRequest = nil
		local snapshotRequest = nil
		local stateUpdated = nil

		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		if remotesFolder then
			actionRequest = remotesFolder:FindFirstChild(RemotesConfig.DynamicQuestActionRequest)
			snapshotRequest = remotesFolder:FindFirstChild(RemotesConfig.DynamicQuestSnapshotRequest)
			stateUpdated = remotesFolder:FindFirstChild(RemotesConfig.DynamicQuestStateUpdated)
		end

		local function applySnapshot(snapshot)
			setQuestActive(snapshot.questActive == true)
			setFoundPet(snapshot.foundPet == true)
			setZoneIndex(snapshot.zoneIndex or 1)
			setTitleTag(snapshot.titleTag or "None")
			setTitleExpiresAt(snapshot.titleExpiresAt or 0)
			setContextualPromptAvailable(snapshot.contextualPromptAvailable == true)
			setPromptZoneName(snapshot.promptZoneName or "-")
			setStatusText(snapshot.statusText or "Start a quest when the player enters a supported zone.")
			setCompletedCount(snapshot.completedCount or 0)
			setQuestExpiresAt(snapshot.questExpiresAt or 0)
		end

		if actionRequest and snapshotRequest and stateUpdated then
			setServiceMode("server")

			local ok, snapshot = pcall(function()
				return snapshotRequest:InvokeServer()
			end)

			if ok and alive and type(snapshot) == "table" then
				applySnapshot(snapshot)
			end

			local connection = stateUpdated.OnClientEvent:Connect(function(serverState)
				if not alive then
					return
				end

				applySnapshot(serverState)
			end)

			return function()
				alive = false
				connection:Disconnect()
			end
		end

		setServiceMode("local")
		setStatusText("Local preview mode active. Actions are simulated on this client only.")

		return function()
			alive = false
		end
	end, {})

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
					if nextSeconds == 0 and serviceMode ~= "server" then
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
	end, { questActive, foundPet, serviceMode })

	React.useEffect(function()
		if serviceMode ~= "server" then
			return
		end

		if questActive and questExpiresAt > 0 then
			local remaining = math.max(math.ceil(questExpiresAt - os.clock()), 0)
			setRemainingSeconds(remaining)
			if remaining == 0 then
				setQuestActive(false)
			end
			return
		end

		if not questActive then
			setRemainingSeconds(0)
		end
	end, { questActive, questExpiresAt, serviceMode })

	local function fireServerAction(action)
		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		local actionRequest = remotesFolder and remotesFolder:FindFirstChild(RemotesConfig.DynamicQuestActionRequest)
		if actionRequest then
			actionRequest:FireServer(action)
			return true
		end

		return false
	end

	local function startQuest()
		if serviceMode == "server" then
			if fireServerAction("startQuest") then
				setStatusText("Requesting a dynamic quest from the server...")
				return
			end
		end

		setQuestActive(true)
		setRemainingSeconds(DynamicQuestConfig.QuestDurationSeconds)
		setFoundPet(false)
		setTitleTag("None")
		setTitleExpiresAt(0)
		setStatusText(string.format("Quest live in %s. Find the pet before the timer expires.", zones[zoneIndex].name))
	end

	local function acceptPrompt()
		if serviceMode == "server" then
			if fireServerAction("acceptPrompt") then
				setStatusText("Accepting contextual quest prompt from the server...")
				return
			end
		end

		startQuest()
	end

	local function searchForCat()
		if serviceMode == "server" then
			if fireServerAction("searchForCat") then
				setStatusText("Search request sent. Use the Lost Pet world prompt to complete the run.")
				return
			end
		end

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
		setCompletedCount(completedCount + 1)
		setTitleTag(DynamicQuestConfig.RewardTitle)
		setStatusText("Cat found. The player receives a temporary social title tag as a reward.")
	end

	local function cycleZone()
		if serviceMode == "server" then
			if fireServerAction("cycleZone") then
				setStatusText("Cycling quest hint zone on the server...")
				return
			end
		end

		local nextIndex = zoneIndex + 1
		if nextIndex > #zones then
			nextIndex = 1
		end

		setZoneIndex(nextIndex)
		setStatusText(string.format("Quest hint moved to %s.", zones[nextIndex].name))
	end

	local activeZoneName = zones[zoneIndex] and zones[zoneIndex].name or zones[1].name
	local serviceLabel = serviceMode == "server" and "Server Sync" or "Local Preview"
	local serviceColor = serviceMode == "server" and Color3.fromRGB(84, 232, 204) or Color3.fromRGB(222, 146, 68)
	local titleRemainingSeconds = titleTag ~= "None"
			and titleExpiresAt > 0
			and math.max(math.ceil(titleExpiresAt - os.clock()), 0)
		or 0
	local promptLabel = contextualPromptAvailable and string.format("Prompt Ready: %s", promptZoneName)
		or "Prompt Ready: None"

	return React.createElement("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageTransparency = 0.35,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.fromScale(1, 1),
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 4),
		}),
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 20, 26),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 88),
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
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 42),
				Size = UDim2.new(1, -178, 0, 30),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "A two-minute hunt activates by zone and awards a temporary title tag when the cat is found.",
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Mode = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -18, 0, 14),
				Size = UDim2.fromOffset(136, 20),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Text = serviceLabel,
				TextColor3 = serviceColor,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),
		Stats = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 92),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Zone = statCard("Current Zone", activeZoneName, Color3.fromRGB(112, 122, 224)),
			Timer = statCard(
				"Time Remaining",
				string.format("%d seconds", remainingSeconds),
				Color3.fromRGB(84, 232, 204)
			),
			Reward = statCard(
				"Title Tag",
				titleRemainingSeconds > 0 and string.format("%s (%ds)", titleTag, titleRemainingSeconds) or titleTag,
				Color3.fromRGB(222, 146, 68)
			),
		}),
		PromptStatus = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 92),
			Size = UDim2.new(1, -4, 0, 18),
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Text = promptLabel,
			TextColor3 = contextualPromptAvailable and Color3.fromRGB(84, 232, 204) or Color3.fromRGB(136, 145, 158),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Actions = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 202),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			AcceptPromptButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = contextualPromptAvailable and Color3.fromRGB(84, 232, 204)
					or Color3.fromRGB(60, 66, 75),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Size = UDim2.new(1, 0, 0, 48),
				Text = contextualPromptAvailable and string.format("ACCEPT PROMPT\n%s", promptZoneName)
					or "⊝ No Zone Nearby",
				TextColor3 = contextualPromptAvailable and Color3.fromRGB(12, 14, 18)
					or Color3.fromRGB(165, 178, 199),
				TextSize = contextualPromptAvailable and 16 or 14,
				Enabled = contextualPromptAvailable,
				[React.Event.Activated] = acceptPrompt,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			StartButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(45, 50, 60),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Size = UDim2.new(1, 0, 0, 32),
				Text = questActive and "Quest Active" or "[Debug] Start in Current Zone",
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 12,
				Enabled = not questActive,
				[React.Event.Activated] = startQuest,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			SearchButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = "Search Zone for Cat",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
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
				Size = UDim2.new(1, 0, 0, 40),
				Text = string.format("Cycle Zone Hint (%s)", activeZoneName),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = cycleZone,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),
		Completion = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Text = string.format("Quests completed this session: %d", completedCount),
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Status = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Text = statusText,
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		}),
	})
end

return DynamicQuestView
