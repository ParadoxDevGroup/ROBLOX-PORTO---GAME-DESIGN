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

local function HubMenu(props)
	local hub = HubContext.useHubContext()

	local viewportSize = Vector2.new(1440, 900)
	if props and props.viewportSize then
		viewportSize = props.viewportSize
	end

	-- Compute responsive max sizes based on viewport
	local largeMaxWidth = math.min(760, math.floor(viewportSize.X * 0.6))
	local largeMaxHeight = math.min(620, math.floor(viewportSize.Y * 0.7))
	local smallMaxWidth = math.min(520, math.floor(viewportSize.X * 0.45))
	local smallMaxHeight = math.min(430, math.floor(viewportSize.Y * 0.5))

	local function renderHeaderControl()
		return React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(27, 31, 38),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(108, 30),
			Text = "Hide [Tab]",
			TextColor3 = Color3.fromRGB(231, 236, 244),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			[React.Event.Activated] = function()
				hub.toggleUi()
			end,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(70, 78, 92),
				Thickness = 1,
				Transparency = 0.15,
			}),
		})
	end

	local function renderHeader(titleText, titleTextSize)
		return React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 36),
		}, {
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -118, 1, 0),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				Text = titleText,
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = titleTextSize,
				TextScaled = true,
				TextWrapped = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			Control = renderHeaderControl(),
		})
	end

	if not hub.isMenuVisible then
		return React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 14, 18),
			BackgroundTransparency = 0.14,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(largeMaxWidth, largeMaxHeight),
				MinSize = Vector2.new(420, 360),
			}),
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(48, 53, 62),
				Thickness = 1,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			Header = renderHeader(getModuleTitle(hub.activeModule), 22),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Position = UDim2.fromOffset(0, 40),
				Size = UDim2.new(1, 0, 0, 24),
				Text = "The selected module is now running as a greybox prototype.",
				TextColor3 = Color3.fromRGB(129, 140, 158),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Content = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 80),
				Size = UDim2.new(1, 0, 1, -80),
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
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 14, 18),
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(0.76, 0.88),
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(smallMaxWidth, smallMaxHeight),
			MinSize = Vector2.new(320, 260),
		}),
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(48, 53, 62),
			Thickness = 1,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 18),
			PaddingBottom = UDim.new(0, 18),
			PaddingLeft = UDim.new(0, 18),
			PaddingRight = UDim.new(0, 18),
		}),
		Header = renderHeader("Social System Sandbox", 20),
		Subtitle = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Position = UDim2.fromOffset(0, 40),
			Size = UDim2.new(1, 0, 0, 30),
			Text = "Choose a prototype module to load its interactive greybox sandbox.",
			TextColor3 = Color3.fromRGB(129, 140, 158),
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		ButtonList = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 92),
			Size = UDim2.new(1, 0, 1, -98),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
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
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return HubMenu
