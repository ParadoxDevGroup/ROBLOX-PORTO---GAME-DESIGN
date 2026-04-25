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

local ModuleViews = script.Parent:WaitForChild("ModuleViews")
local SocialPropView = require(ModuleViews:WaitForChild("SocialPropView"))
local MicroEconomyView = require(ModuleViews:WaitForChild("MicroEconomyView"))
local DynamicQuestView = require(ModuleViews:WaitForChild("DynamicQuestView"))

local moduleInfo = {
	[ModuleIds.SocialProp] = {
		title = "Module 1: Social Prop",
		description = "Deploy a picnic basket, share a buff, and swap between cosmetic variants.",
		accentColor = Color3.fromRGB(160, 118, 72),
	},
	[ModuleIds.MicroEconomy] = {
		title = "Module 2: Micro-Economy",
		description = "Run the cafe loop, earn tokens, and buy throughput upgrades.",
		accentColor = Color3.fromRGB(84, 153, 133),
	},
	[ModuleIds.DynamicQuest] = {
		title = "Module 3: Dynamic Quest",
		description = "Track the cat through the city and finish before the two-minute timer expires.",
		accentColor = Color3.fromRGB(112, 122, 224),
	},
}

local function getModuleTitle(moduleId)
	local info = moduleInfo[moduleId]
	if info then
		return info.title
	end

	return "Greybox Running"
end

local function getModuleView(moduleId)
	if moduleId == ModuleIds.SocialProp then
		return React.createElement(SocialPropView)
	end

	if moduleId == ModuleIds.MicroEconomy then
		return React.createElement(MicroEconomyView)
	end

	if moduleId == ModuleIds.DynamicQuest then
		return React.createElement(DynamicQuestView)
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Message = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Size = UDim2.fromScale(1, 1),
			Text = "No module is active.",
			TextColor3 = Color3.fromRGB(236, 241, 247),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

local function HubMenu()
	local hub = HubContext.useHubContext()

	if not hub.isMenuVisible then
		return React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 14, 18),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(980, 680),
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(1120, 760),
				MinSize = Vector2.new(760, 520),
			}),
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
				Text = getModuleTitle(hub.activeModule),
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 28,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Position = UDim2.fromOffset(0, 44),
				Size = UDim2.new(1, 0, 0, 24),
				Text = "The selected module is now running as a greybox prototype.",
				TextColor3 = Color3.fromRGB(129, 140, 158),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Content = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 84),
				Size = UDim2.new(1, 0, 1, -84),
			}, {
				Module = getModuleView(hub.activeModule),
				Back = React.createElement("TextButton", {
					AnchorPoint = Vector2.new(1, 1),
					AutoButtonColor = false,
					BackgroundColor3 = Color3.fromRGB(24, 26, 31),
					BorderSizePixel = 0,
					FontFace = Font.fromEnum(Enum.Font.GothamMedium),
					Position = UDim2.new(1, 0, 1, 0),
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
			}),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 14, 18),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(640, 450),
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(780, 540),
			MinSize = Vector2.new(460, 320),
		}),
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
			TextSize = 32,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Subtitle = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 34),
			Text = "Choose a prototype module to load its interactive greybox sandbox.",
			TextColor3 = Color3.fromRGB(129, 140, 158),
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		ButtonList = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 108),
			Size = UDim2.new(1, 0, 1, -108),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),
			SocialProp = React.createElement(ModuleButton, {
				layoutOrder = 1,
				text = "Module 1: Social Prop",
				description = moduleInfo[ModuleIds.SocialProp].description,
				accentColor = moduleInfo[ModuleIds.SocialProp].accentColor,
				onActivated = function()
					hub.activateModule(ModuleIds.SocialProp)
				end,
			}),
			MicroEconomy = React.createElement(ModuleButton, {
				layoutOrder = 2,
				text = "Module 2: Micro-Economy",
				description = moduleInfo[ModuleIds.MicroEconomy].description,
				accentColor = moduleInfo[ModuleIds.MicroEconomy].accentColor,
				onActivated = function()
					hub.activateModule(ModuleIds.MicroEconomy)
				end,
			}),
			DynamicQuest = React.createElement(ModuleButton, {
				layoutOrder = 3,
				text = "Module 3: Dynamic Quest",
				description = moduleInfo[ModuleIds.DynamicQuest].description,
				accentColor = moduleInfo[ModuleIds.DynamicQuest].accentColor,
				onActivated = function()
					hub.activateModule(ModuleIds.DynamicQuest)
				end,
			}),
		}),
		Footer = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 1, -30),
			Size = UDim2.new(1, 0, 0, 22),
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Text = "Each module is now wired to its own interactive greybox panel.",
			TextColor3 = Color3.fromRGB(129, 140, 158),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return HubMenu
