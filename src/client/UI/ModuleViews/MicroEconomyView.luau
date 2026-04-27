--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local RemotesConfig = require(ConfigFolder:WaitForChild("Remotes"))
local MicroEconomyBalance = require(ConfigFolder:WaitForChild("MicroEconomyBalance"))

local function costForSpeed(level)
	return MicroEconomyBalance.costForSpeed(level)
end

local function costForTips(level)
	return MicroEconomyBalance.costForTips(level)
end

local function payoutForServe(speedLevel, tipLevel)
	return MicroEconomyBalance.payoutForServe(speedLevel, tipLevel)
end

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

local function MicroEconomyView()
	local tokens, setTokens = React.useState(MicroEconomyBalance.InitialTokens)
	local speedLevel, setSpeedLevel = React.useState(MicroEconomyBalance.InitialSpeedLevel)
	local tipLevel, setTipLevel = React.useState(MicroEconomyBalance.InitialTipLevel)
	local servedCount, setServedCount = React.useState(MicroEconomyBalance.InitialServedCount)
	local statusText, setStatusText = React.useState("Connecting to cafe service...")
	local serviceMode, setServiceMode = React.useState("connecting")

	React.useEffect(function()
		local alive = true
		local actionRequest = nil
		local snapshotRequest = nil
		local stateUpdated = nil

		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		if remotesFolder then
			actionRequest = remotesFolder:FindFirstChild(RemotesConfig.MicroEconomyActionRequest)
			snapshotRequest = remotesFolder:FindFirstChild(RemotesConfig.MicroEconomySnapshotRequest)
			stateUpdated = remotesFolder:FindFirstChild(RemotesConfig.MicroEconomyStateUpdated)
		end

		if actionRequest and snapshotRequest and stateUpdated then
			setServiceMode("server")

			local ok, snapshot = pcall(function()
				return snapshotRequest:InvokeServer()
			end)

			if ok and alive and type(snapshot) == "table" then
				setTokens(snapshot.tokens or MicroEconomyBalance.InitialTokens)
				setSpeedLevel(snapshot.speedLevel or MicroEconomyBalance.InitialSpeedLevel)
				setTipLevel(snapshot.tipLevel or MicroEconomyBalance.InitialTipLevel)
				setServedCount(snapshot.servedCount or MicroEconomyBalance.InitialServedCount)
				setStatusText(snapshot.statusText or "Serve the first customer to begin the cafe loop.")
			end

			local connection = stateUpdated.OnClientEvent:Connect(function(serverState)
				if not alive then
					return
				end

				setTokens(serverState.tokens or MicroEconomyBalance.InitialTokens)
				setSpeedLevel(serverState.speedLevel or MicroEconomyBalance.InitialSpeedLevel)
				setTipLevel(serverState.tipLevel or MicroEconomyBalance.InitialTipLevel)
				setServedCount(serverState.servedCount or MicroEconomyBalance.InitialServedCount)
				setStatusText(serverState.statusText or "Serve the first customer to begin the cafe loop.")
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

	local speedNextCost = costForSpeed(speedLevel)
	local tipNextCost = costForTips(tipLevel)
	local currentPayout = payoutForServe(speedLevel, tipLevel)

	local function fireServerAction(action)
		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		local actionRequest = remotesFolder and remotesFolder:FindFirstChild(RemotesConfig.MicroEconomyActionRequest)
		if actionRequest then
			actionRequest:FireServer(action)
			return true
		end

		return false
	end

	local function serveCustomer()
		if serviceMode == "server" then
			if fireServerAction("serve") then
				setStatusText("Serving customer via server sync...")
				return
			end
		end

		local payout = payoutForServe(speedLevel, tipLevel)
		setTokens(tokens + payout)
		setServedCount(servedCount + 1)
		setStatusText(string.format("Customer served for %d tokens. The shift keeps scaling.", payout))
	end

	local function upgradeSpeed()
		if serviceMode == "server" then
			if fireServerAction("upgradeSpeed") then
				setStatusText("Applying serve speed upgrade via server sync...")
				return
			end
		end

		local cost = costForSpeed(speedLevel)
		if tokens < cost then
			setStatusText(string.format("Need %d tokens for serve speed level %d.", cost, speedLevel + 1))
			return
		end

		setTokens(tokens - cost)
		setSpeedLevel(speedLevel + 1)
		setStatusText(string.format("Serve speed upgraded to level %d.", speedLevel + 1))
	end

	local function upgradeTips()
		if serviceMode == "server" then
			if fireServerAction("upgradeTips") then
				setStatusText("Applying tip multiplier upgrade via server sync...")
				return
			end
		end

		local cost = costForTips(tipLevel)
		if tokens < cost then
			setStatusText(string.format("Need %d tokens for tip multiplier level %d.", cost, tipLevel + 1))
			return
		end

		setTokens(tokens - cost)
		setTipLevel(tipLevel + 1)
		setStatusText(string.format("Tip multiplier upgraded to level %d.", tipLevel + 1))
	end

	local serviceLabel = serviceMode == "server" and "Server Sync" or "Local Preview"
	local serviceColor = serviceMode == "server" and Color3.fromRGB(84, 232, 204) or Color3.fromRGB(222, 146, 68)

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
				Color = Color3.fromRGB(84, 153, 133),
				Transparency = 0.5,
				Thickness = 1,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 14),
				Size = UDim2.new(1, -36, 0, 28),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Text = "Module 2: Micro-Economy",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 42),
				Size = UDim2.new(1, -178, 0, 30),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "Players serve NPCs for tokens, then spend tokens to improve throughput and tips.",
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
			Size = UDim2.new(1, -4, 0, 72),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Tokens = statCard("Tokens", tostring(tokens), Color3.fromRGB(84, 153, 133)),
			Speed = statCard("Serve Speed", string.format("Level %d", speedLevel), Color3.fromRGB(222, 146, 68)),
			Tips = statCard("Tip Multiplier", string.format("Level %d", tipLevel), Color3.fromRGB(112, 122, 224)),
		}),
		BalanceSheet = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 20, 26),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 70),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(84, 153, 133),
				Transparency = 0.65,
				Thickness = 1,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 10),
				Size = UDim2.new(1, -28, 0, 18),
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Text = "Balancing Sheet",
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Body = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 30),
				Size = UDim2.new(1, -28, 0, 36),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = string.format(
					"Speed upgrade: %d tokens | Tip upgrade: %d tokens | Current payout: %d",
					speedNextCost,
					tipNextCost,
					currentPayout
				),
				TextColor3 = Color3.fromRGB(210, 218, 231),
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		Actions = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 154),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			ServeButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = "Serve NPC Customer",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = serveCustomer,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			SpeedButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = string.format("Upgrade Serve Speed (%d tokens)", costForSpeed(speedLevel)),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = upgradeSpeed,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			TipButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = string.format("Upgrade Tip Multiplier (%d tokens)", costForTips(tipLevel)),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = upgradeTips,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),
		Status = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Text = string.format("Shift total: %d customers served.", servedCount),
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Note = React.createElement("TextLabel", {
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

return MicroEconomyView
