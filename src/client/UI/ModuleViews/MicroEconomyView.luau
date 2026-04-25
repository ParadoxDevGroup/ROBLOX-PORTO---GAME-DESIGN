--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local function costForSpeed(level)
	return 15 + (level * 20)
end

local function costForTips(level)
	return 20 + (level * 24)
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

local function MicroEconomyView()
	local tokens, setTokens = React.useState(30)
	local speedLevel, setSpeedLevel = React.useState(1)
	local tipLevel, setTipLevel = React.useState(1)
	local servedCount, setServedCount = React.useState(0)
	local statusText, setStatusText = React.useState("Serve the first customer to begin the cafe loop.")

	local speedNextCost = costForSpeed(speedLevel)
	local tipNextCost = costForTips(tipLevel)

	local function serveCustomer()
		local payout = 8 + (speedLevel * 2) + (tipLevel * 2)
		setTokens(tokens + payout)
		setServedCount(servedCount + 1)
		setStatusText(string.format("Customer served for %d tokens. The shift keeps scaling.", payout))
	end

	local function upgradeSpeed()
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
		local cost = costForTips(tipLevel)
		if tokens < cost then
			setStatusText(string.format("Need %d tokens for tip multiplier level %d.", cost, tipLevel + 1))
			return
		end

		setTokens(tokens - cost)
		setTipLevel(tipLevel + 1)
		setStatusText(string.format("Tip multiplier upgraded to level %d.", tipLevel + 1))
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
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 46),
				Size = UDim2.new(1, -36, 0, 34),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "Players serve NPCs for tokens, then spend tokens to improve throughput and tips.",
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
			Tokens = statCard("Tokens", tostring(tokens), Color3.fromRGB(84, 153, 133)),
			Speed = statCard("Serve Speed", string.format("Level %d", speedLevel), Color3.fromRGB(222, 146, 68)),
			Tips = statCard("Tip Multiplier", string.format("Level %d", tipLevel), Color3.fromRGB(112, 122, 224)),
		}),
		BalanceSheet = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 20, 26),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 74),
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
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Body = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 30),
				Size = UDim2.new(1, -28, 0, 36),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = string.format(
					"Speed upgrade: %d tokens | Tip upgrade: %d tokens | Payout: 8 + speed*2 + tip*2",
					speedNextCost,
					tipNextCost
				),
				TextColor3 = Color3.fromRGB(210, 218, 231),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
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
			ServeButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = "Serve NPC Customer",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
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
				Size = UDim2.new(1, 0, 0, 46),
				Text = string.format("Upgrade Serve Speed (%d tokens)", costForSpeed(speedLevel)),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
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
				Size = UDim2.new(1, 0, 0, 46),
				Text = string.format("Upgrade Tip Multiplier (%d tokens)", costForTips(tipLevel)),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = upgradeTips,
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
			Text = string.format("Shift total: %d customers served.", servedCount),
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Note = React.createElement("TextLabel", {
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

return MicroEconomyView
