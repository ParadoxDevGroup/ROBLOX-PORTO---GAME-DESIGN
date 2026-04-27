--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))

local Modules = script.Parent.Parent:WaitForChild("Modules")
local ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))

local defaultContext = {
	activeModule = nil,
	isMenuVisible = true,
	isUiVisible = true,
	sessionStartedAt = nil,
	activateModule = function(_moduleId)
		warn("[HubContext] activateModule called before provider mount")
	end,
	returnToMenu = function()
		warn("[HubContext] returnToMenu called before provider mount")
	end,
	toggleUi = function()
		warn("[HubContext] toggleUi called before provider mount")
	end,
}

local HubContext = React.createContext(defaultContext)

local function HubProvider(props)
	local activeModule, setActiveModule = React.useState(nil)
	local isMenuVisible, setMenuVisible = React.useState(true)
	local isUiVisible, setUiVisible = React.useState(true)
	local sessionStartedAt, setSessionStartedAt = React.useState(nil)

	local contextValue = React.useMemo(function()
		return {
			activeModule = activeModule,
			isMenuVisible = isMenuVisible,
			isUiVisible = isUiVisible,
			sessionStartedAt = sessionStartedAt,
			activateModule = function(moduleId)
				setActiveModule(moduleId)
				setMenuVisible(false)
				setSessionStartedAt(os.clock())
				ModuleLoader.selectModule(moduleId)
			end,
			returnToMenu = function()
				setActiveModule(nil)
				setMenuVisible(true)
				setSessionStartedAt(nil)
				ModuleLoader.returnToHub()
			end,
			toggleUi = function()
				setUiVisible(function(currentVisible)
					return not currentVisible
				end)
			end,
		}
	end, { activeModule, isMenuVisible, isUiVisible, sessionStartedAt })

	return React.createElement(HubContext.Provider, {
		value = contextValue,
	}, props.children)
end

local function useHubContext()
	return React.useContext(HubContext)
end

return {
	HubContext = HubContext,
	HubProvider = HubProvider,
	useHubContext = useHubContext,
}
