--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesConfig = require(Shared:WaitForChild("Config"):WaitForChild("Remotes"))
local SocialPropVariants = require(Shared:WaitForChild("Config"):WaitForChild("SocialPropVariants"))

local localBasket = nil
local localBuffState = {
	originalWalkSpeed = nil,
	token = 0,
}

local function clearLocalBasket()
	if localBasket then
		localBasket:Destroy()
		localBasket = nil
	end
end

local function applyLocalBuff(variant)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not localBuffState.originalWalkSpeed then
		localBuffState.originalWalkSpeed = humanoid.WalkSpeed
	end

	localBuffState.token += 1
	local token = localBuffState.token
	humanoid.WalkSpeed = math.max(localBuffState.originalWalkSpeed, 16) + variant.buffBonus
	localPlayer:SetAttribute("SocialPropBuffActive", true)
	localPlayer:SetAttribute("SocialPropBuffLabel", variant.buffLabel)
	localPlayer:SetAttribute("SocialPropBuffExpiresAt", os.clock() + variant.buffDuration)

	local highlight = Instance.new("Highlight")
	highlight.FillColor = variant.accentColor
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = character
	highlight.Parent = character

	task.delay(variant.buffDuration, function()
		if localBuffState.token ~= token then
			return
		end

		local currentCharacter = localPlayer.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		if currentHumanoid and localBuffState.originalWalkSpeed then
			currentHumanoid.WalkSpeed = localBuffState.originalWalkSpeed
		end

		localPlayer:SetAttribute("SocialPropBuffActive", false)
		localPlayer:SetAttribute("SocialPropBuffLabel", nil)
		localPlayer:SetAttribute("SocialPropBuffExpiresAt", nil)
		if highlight.Parent then
			highlight:Destroy()
		end
	end)
end

local function spawnLocalBasket(variant)
	clearLocalBasket()

	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local basketModel = Instance.new("Model")
	basketModel.Name = "SocialPropBasket_Local"
	basketModel.Parent = Workspace

	local basketBase = Instance.new("Part")
	basketBase.Name = "BasketBase"
	basketBase.Anchored = true
	basketBase.CanCollide = true
	basketBase.Material = Enum.Material.Wood
	basketBase.Color = variant.baseColor
	basketBase.Size = Vector3.new(4, 1.1, 3)
	basketBase.Parent = basketModel

	local basketLid = Instance.new("Part")
	basketLid.Name = "BasketLid"
	basketLid.Anchored = true
	basketLid.CanCollide = false
	basketLid.Material = Enum.Material.Fabric
	basketLid.Color = variant.lidColor
	basketLid.Size = Vector3.new(4.15, 0.22, 3.15)
	basketLid.Parent = basketModel

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = true
	handle.CanCollide = false
	handle.Material = Enum.Material.SmoothPlastic
	handle.Color = Color3.fromRGB(37, 31, 24)
	handle.Size = Vector3.new(0.18, 2.2, 0.18)
	handle.Parent = basketModel

	basketModel.PrimaryPart = basketBase
	basketModel:PivotTo(rootPart.CFrame * CFrame.new(0, -1, -6))
	basketLid.CFrame = basketBase.CFrame * CFrame.new(0, 0.72, 0)
	handle.CFrame = basketBase.CFrame * CFrame.new(0, 1.55, 0)

	local promptAttachment = Instance.new("Attachment")
	promptAttachment.Position = Vector3.new(0, 0.8, 0)
	promptAttachment.Parent = basketBase

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Share Snack"
	prompt.ObjectText = variant.name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptAttachment
	prompt.Triggered:Connect(function()
		applyLocalBuff(variant)
	end)

	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Position = Vector3.new(0, 1.25, 0)
	sparkleAttachment.Parent = basketBase

	local sparkleEmitter = Instance.new("ParticleEmitter")
	sparkleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkleEmitter.Color = ColorSequence.new(variant.accentColor)
	sparkleEmitter.LightEmission = 0.6
	sparkleEmitter.Lifetime = NumberRange.new(0.5, 0.8)
	sparkleEmitter.Rate = 0
	sparkleEmitter.Speed = NumberRange.new(1, 2)
	sparkleEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkleEmitter.Parent = sparkleAttachment
	sparkleEmitter:Emit(20)

	local highlight = Instance.new("Highlight")
	highlight.FillColor = variant.accentColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = basketModel
	highlight.Parent = basketModel

	task.delay(1.2, function()
		if highlight.Parent then
			highlight:Destroy()
		end
	end)

	localBasket = basketModel
	return true
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

local function SocialPropView()
	local state, setState = React.useState(nil)
	local basketDeployed, setBasketDeployed = React.useState(false)
	local interactionCount, setInteractionCount = React.useState(0)
	local variantIndex, setVariantIndex = React.useState(1)
	local serviceMode, setServiceMode = React.useState("connecting")
	local statusText, setStatusText = React.useState("Connecting to social prop service...")

	React.useEffect(function()
		local alive = true
		local deployRequest = nil
		local snapshotRequest = nil
		local stateUpdated = nil

		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		if remotesFolder then
			deployRequest = remotesFolder:FindFirstChild(RemotesConfig.SocialPropDeployRequest)
			snapshotRequest = remotesFolder:FindFirstChild(RemotesConfig.SocialPropSnapshotRequest)
			stateUpdated = remotesFolder:FindFirstChild(RemotesConfig.SocialPropStateUpdated)
		end

		if deployRequest and snapshotRequest and stateUpdated then
			setServiceMode("server")

			local ok, snapshot = pcall(function()
				return snapshotRequest:InvokeServer()
			end)

			if ok and alive and type(snapshot) == "table" then
				setState(snapshot)
				setBasketDeployed(snapshot.deployed == true)
				setInteractionCount(snapshot.interactionCount or 0)
				setVariantIndex(snapshot.variantIndex or 1)
				setStatusText(snapshot.statusText or "Deploy the basket to begin the shared loop.")
			end

			local connection = stateUpdated.OnClientEvent:Connect(function(serverState)
				if not alive then
					return
				end

				setState(serverState)
				setBasketDeployed(serverState.deployed == true)
				setInteractionCount(serverState.interactionCount or 0)
				setVariantIndex(serverState.variantIndex or 1)
				setStatusText(serverState.statusText or "Deploy the basket to begin the shared loop.")
			end)

			return function()
				alive = false
				connection:Disconnect()
			end
		end

		setServiceMode("local")
		setStatusText("Local preview mode active. Deploy will spawn a basket in your session only.")

		return function()
			alive = false
			clearLocalBasket()
		end
	end, {})

	local selectedVariant = SocialPropVariants[variantIndex]
	local activeVariant = (state and SocialPropVariants[state.variantIndex or 1]) or selectedVariant

	local function fireSocialAction(action, payload)
		local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
		local actionRequest = remotesFolder and remotesFolder:FindFirstChild(RemotesConfig.SocialPropActionRequest)
		if actionRequest then
			actionRequest:FireServer(action, payload)
			return true
		end

		return false
	end

	local function deployBasket()
		if serviceMode == "server" then
			local remotesFolder = Shared:FindFirstChild(RemotesConfig.FolderName)
			local deployRequest = remotesFolder and remotesFolder:FindFirstChild(RemotesConfig.SocialPropDeployRequest)
			if deployRequest then
				setStatusText(string.format("Requesting %s deployment...", selectedVariant.name))
				deployRequest:FireServer(variantIndex)
				return
			end
		end

		if spawnLocalBasket(selectedVariant) then
			setBasketDeployed(true)
			setInteractionCount(0)
			setStatusText(
				string.format(
					"%s deployed locally. Use the share button or prompt to test the buff.",
					selectedVariant.name
				)
			)
			return
		end

		setStatusText("Your character needs to load before the basket can deploy.")
	end

	local function triggerSharedInteraction()
		if not basketDeployed then
			setStatusText("Deploy the basket first so another player can interact with it.")
			return
		end

		if serviceMode == "server" then
			if fireSocialAction("shareTest", nil) then
				setStatusText("Triggering shared animation preview in sandbox mode...")
				return
			end
		end

		applyLocalBuff(selectedVariant)
		setInteractionCount(interactionCount + 1)
		setStatusText(string.format("Local share test triggered. %s buff applied.", selectedVariant.buffLabel))
	end

	local function cycleVariant()
		local nextIndex = variantIndex + 1
		if nextIndex > #SocialPropVariants then
			nextIndex = 1
		end

		setVariantIndex(nextIndex)

		if serviceMode == "server" then
			if fireSocialAction("cycleVariant", nextIndex) then
				setStatusText(string.format("Cycling live basket variant to %s...", SocialPropVariants[nextIndex].name))
				return
			end
		end

		setStatusText(string.format("Selected cosmetic variant: %s", SocialPropVariants[nextIndex].name))
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
				Color = activeVariant.accentColor,
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
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 42),
				Size = UDim2.new(1, -178, 0, 30),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = "Drive player-to-player interaction with a deployable picnic basket and a shared buff loop.",
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			VariantBadge = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(22, 24, 31),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -162, 0, 14),
				Size = UDim2.fromOffset(136, 22),
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Text = serviceLabel,
				TextColor3 = serviceColor,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Center,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
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
			Variant = statCard("Cosmetic Variant", activeVariant.name, activeVariant.accentColor),
			Interactions = statCard("Shared Interactions", tostring(interactionCount), Color3.fromRGB(84, 232, 204)),
			Status = statCard("Prop State", basketDeployed and "Deployed" or "Idle", Color3.fromRGB(222, 146, 68)),
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
			DeployButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = basketDeployed and "Basket Deployed" or "Deploy Picnic Basket",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = deployBasket,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = activeVariant.accentColor,
					Transparency = 0.6,
					Thickness = 1,
				}),
			}),
			ShareButton = React.createElement("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(29, 33, 41),
				BorderSizePixel = 0,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 40),
				Text = serviceMode == "server" and "Trigger Shared Animation (Sandbox)" or "Trigger Shared Animation",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
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
				Size = UDim2.new(1, 0, 0, 40),
				Text = "Cycle Cosmetic Variant",
				TextColor3 = Color3.fromRGB(236, 241, 247),
				TextSize = 15,
				[React.Event.Activated] = cycleVariant,
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
			Text = statusText,
			TextColor3 = Color3.fromRGB(136, 145, 158),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		}),
	})
end

return SocialPropView
