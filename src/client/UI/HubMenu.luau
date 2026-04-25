--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ModuleIds = require(Shared:WaitForChild("Config"):WaitForChild("ModuleIds"))

local State = script.Parent.Parent:WaitForChild("State")
local HubContext = require(State:WaitForChild("HubContext"))

local Components = script.Parent:WaitForChild("Components")
local ModuleButton = require(Components:WaitForChild("ModuleButton"))

local function HubMenu()
	local hub = HubContext.useHubContext()

	if not hub.isMenuVisible then
		local activeLabel = "None"
		if hub.activeModule == ModuleIds.SocialProp then
			activeLabel = "Module 1: Social Prop"
		elseif hub.activeModule == ModuleIds.MicroEconomy then
			activeLabel = "Module 2: Micro-Economy"
		elseif hub.activeModule == ModuleIds.DynamicQuest then
			activeLabel = "Module 3: Dynamic Quest"
		end

		return React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 14, 18),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(420, 170),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(48, 53, 62),
				Thickness = 1,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 0, 34),
				Text = "Greybox Running",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 25,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Position = UDim2.fromOffset(0, 44),
				Size = UDim2.new(1, 0, 0, 24),
				Text = activeLabel,
				TextColor3 = Color3.fromRGB(129, 140, 158),
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Back = React.createElement("TextButton", {
				AnchorPoint = Vector2.new(0, 1),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(24, 26, 31),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.fromOffset(170, 40),
				Text = "Return To Hub",
				TextColor3 = Color3.fromRGB(220, 226, 235),
				TextSize = 16,
				[React.Event.Activated] = function()
					hub.returnToMenu()
				end,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 14, 18),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 370),
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(48, 53, 62),
			Thickness = 1,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 24),
			PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
		}),
		Title = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
			Size = UDim2.new(1, 0, 0, 42),
			Text = "Social System Sandbox",
			TextColor3 = Color3.fromRGB(236, 241, 247),
			TextSize = 30,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Subtitle = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 28),
			Text = "Choose a prototype module to load its greybox sandbox.",
			TextColor3 = Color3.fromRGB(129, 140, 158),
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		ButtonList = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 102),
			Size = UDim2.new(1, 0, 1, -102),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),
			SocialProp = React.createElement(ModuleButton, {
				layoutOrder = 1,
				text = "Module 1: Social Prop",
				onActivated = function()
					hub.activateModule(ModuleIds.SocialProp)
				end,
			}),
			MicroEconomy = React.createElement(ModuleButton, {
				layoutOrder = 2,
				text = "Module 2: Micro-Economy",
				onActivated = function()
					hub.activateModule(ModuleIds.MicroEconomy)
				end,
			}),
			DynamicQuest = React.createElement(ModuleButton, {
				layoutOrder = 3,
				text = "Module 3: Dynamic Quest",
				onActivated = function()
					hub.activateModule(ModuleIds.DynamicQuest)
				end,
			}),
		}),
	})
end

return HubMenu