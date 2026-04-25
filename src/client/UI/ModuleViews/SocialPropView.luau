--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local variants = {
	{
		name = "Classic Wicker",
		description = "Standard prop for every player.",
		accent = Color3.fromRGB(160, 118, 72),
	},
	{
		name = "Sunset Citrus",
		description = "Warm visual variant for premium feel.",
		accent = Color3.fromRGB(222, 146, 68),
	},
	{
		name = "Neon Cyber Basket",
		description = "High-contrast cosmetic variant with glow effects.",
		accent = Color3.fromRGB(84, 232, 204),
	},
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

local function SocialPropView()
	local basketDeployed, setBasketDeployed = React.useState(false)
	local interactionCount, setInteractionCount = React.useState(0)
	local variantIndex, setVariantIndex = React.useState(1)
	local statusText, setStatusText = React.useState("Deploy the basket to begin the shared loop.")

	local variant = variants[variantIndex]

	local function deployBasket()
		setBasketDeployed(true)
		setStatusText(string.format("%s deployed. Nearby players can now share the effect.", variant.name))
	end

	local function triggerSharedInteraction()
		if not basketDeployed then
			setStatusText("Deploy the basket first so another player can interact with it.")
			return
		end

		setInteractionCount(interactionCount + 1)
		setStatusText("Shared interaction triggered. Buff granted and animation played.")
	end

	local function cycleVariant()
		local nextIndex = variantIndex + 1
		if nextIndex > #variants then
			nextIndex = 1
		end

		setVariantIndex(nextIndex)
		setStatusText(string.format("Selected cosmetic variant: %s", variants[nextIndex].name))
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
				Color = variant.accent,
				Transparency = 0.5,
				Thickness = 1,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 14),
				Size = UDim2.new(1, -36, 0, 28),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Text = "Module 1: Social Prop",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 46),
				Size = UDim2.new(1, -36, 0, 34),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "Drive player-to-player interaction with a deployable picnic basket and a shared buff loop.",
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
			Variant = statCard("Cosmetic Variant", variant.name, variant.accent),
			Interactions = statCard("Shared Interactions", tostring(interactionCount), Color3.fromRGB(84, 232, 204)),
			Status = statCard("Prop State", basketDeployed and "Deployed" or "Idle", Color3.fromRGB(222, 146, 68)),
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
			DeployButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = basketDeployed and "Basket Deployed" or "Deploy Picnic Basket",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = deployBasket,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = variant.accent,
					Transparency = 0.6,
					Thickness = 1,
				}),
			}),
			ShareButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = "Trigger Shared Animation",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = triggerSharedInteraction,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
			VariantButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 46),
				Text = "Cycle Cosmetic Variant",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 17,
				[React.Event.Activated] = cycleVariant,
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

return SocialPropView
