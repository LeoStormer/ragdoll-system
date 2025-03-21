local RunService = game:GetService("RunService")

local Blueprint = require(script.Blueprint)
local Signal = require(script.Parent.Signal)
local RagdollFactory = require(script.RagdollFactory)
local Types = require(script.Types)

--[=[
	@class RagdollSystem
	@__index RagdollSystem
]=]
--[=[
	@within RagdollSystem
	@private
	@prop Remotes { ActivateRagdoll: RemoteEvent, DeactivateRagdoll: RemoteEvent, CollapseeRagdoll: RemoteEvent, }
]=]
--[=[
	@within RagdollSystem
	@private
	@external Signal https://sleitnick.github.io/RbxUtil/api/Signal/
	@prop Signals { ActivateLocalRagdoll: Signal, DeactivateLocalRagdoll: Signal, CollapseLocalRagdoll: Signal, ActivateRagdoll: Signal, DeactivateRagdoll: Signal, CollapsRagdoll: Signal}
]=]
--[=[
	@within RagdollSystem
	@prop Blueprint Blueprint
	A reference to the base Blueprint class
]=]
--[=[
	@within RagdollSystem
	@prop RagdollFactory RagdollFactory
	A reference to the Ragdoll Factory
]=]
--[=[
	@within RagdollSystem
	@readonly
	@prop RagdollConstructed Signal
	Fires when a ragdoll is constructed by the Ragdoll Factory.

	```lua
	RagdollSystem.RagdollConstructed:Connect(function(ragdoll: Ragdoll)
		doSomething(ragdoll)
	end)
	```
]=]
local RagdollSystem = {}
RagdollSystem.Remotes = {
	ActivateRagdoll = script.Remotes.ActivateRagdollRemote,
	DeactivateRagdoll = script.Remotes.DeactivateRagdollRemote,
	CollapseRagdoll = script.Remotes.CollapseRagdollRemote,
}
RagdollSystem.Signals = {
	ActivateRagdoll = Signal.new(),
	DeactivateRagdoll = Signal.new(),
	CollapseRagdoll = Signal.new(),
	ActivateLocalRagdoll = Signal.new(),
	DeactivateLocalRagdoll = Signal.new(),
	CollapseLocalRagdoll = Signal.new(),
}
RagdollSystem.Blueprint = Blueprint
RagdollSystem.RagdollFactory = RagdollFactory
RagdollSystem.RagdollConstructed = RagdollFactory.RagdollConstructed
RagdollSystem._activeRagdolls = 0
RagdollSystem._localPlayerRagdoll = nil
RagdollSystem._ragdolls = {}

--[=[
	@within RagdollSystem
	@type SystemSettings { LowDetailModeThreshold: number, CollapseTimoutInterval: number, CollapseTimeoutDistanceThreshold: number, FreezeIfDead: boolean, }
	LowDetailModeThreshold is the number of active ragdolls before the system 
	starts using low detail mode. CollapseTimeoutInterval is the interval in 
	seconds between ragdoll distance checks while collapsed.
	CollapseTimeoutDistanceThreshold is the minimum distance in studs a ragdoll
	must have moved between distance checks to remain collapsed. FreezeIfDead 
	determines whether the system freezes ragdolls when they are being
	timed out of collapse if they are dead. If false they remain collapsed.
]=]
local defaultSettings = table.freeze({
	LowDetailModeThreshold = 15,
	CollapseTimeoutInterval = 1,
	CollapseTimeoutDistanceThreshold = 2,
	FreezeIfDead = true,
})

local systemSettings

--[=[
	@param settingsDictionary SystemSettings
	Sets the settings of the system, all fields are optional. If a field is not
	provided, it remains unchanged.

	```lua
		RagdollSystem:setSystemSettings({
			FreezeIfDead = false,
		}) -- This is ok.
	```
]=]
function RagdollSystem:setSystemSettings(settingsDictionary: {
	LowDetailModeThreshold: number?,
	CollapseTimeoutInterval: number?,
	CollapseTimeoutDistanceThreshold: number?,
	FreezeIfDead: boolean?,
})
	local newSettings = {}
	newSettings.LowDetailModeThreshold = if settingsDictionary.LowDetailModeThreshold
			and typeof(settingsDictionary.LowDetailModeThreshold) == "number"
			and settingsDictionary.LowDetailModeThreshold == settingsDictionary.LowDetailModeThreshold
		then settingsDictionary.LowDetailModeThreshold
		else defaultSettings.LowDetailModeThreshold

	newSettings.CollapseTimeoutInterval = if settingsDictionary.CollapseTimeoutInterval
			and typeof(settingsDictionary.CollapseTimeoutInterval) == "number"
			and settingsDictionary.CollapseTimeoutInterval == settingsDictionary.CollapseTimeoutInterval
		then settingsDictionary.CollapseTimeoutInterval
		else defaultSettings.CollapseTimeoutInterval

	newSettings.CollapseTimeoutDistanceThreshold = if settingsDictionary.CollapseTimeoutDistanceThreshold
			and typeof(settingsDictionary.CollapseTimeoutDistanceThreshold) == "number"
			and settingsDictionary.CollapseTimeoutDistanceThreshold
				== settingsDictionary.CollapseTimeoutDistanceThreshold
		then settingsDictionary.CollapseTimeoutDistanceThreshold
		else defaultSettings.CollapseTimeoutDistanceThreshold

	newSettings.FreezeIfDead = if settingsDictionary.FreezeIfDead ~= nil
			and typeof(settingsDictionary.FreezeIfDead) == "boolean"
		then settingsDictionary.FreezeIfDead
		else defaultSettings.FreezeIfDead

	systemSettings = table.freeze(newSettings) :: Types.SystemSettings
end

RagdollSystem:setSystemSettings(script:GetAttributes())

--[=[
	@return SystemSettings
]=]
function RagdollSystem:getSystemSettings()
	return systemSettings
end

--[=[
	@param ragdollModel Model
	Returns the ragdoll corresponding to the model or nil if there isn't one.
]=]
function RagdollSystem:getRagdoll(ragdollModel: Model): Ragdoll?
	return self._ragdolls[ragdollModel]
end

--[=[
	@param ragdollModel Model
	Activates ragdoll physics on the ragdoll.
]=]
function RagdollSystem:activateRagdoll(ragdollModel: Model)
	self.Signals.ActivateRagdoll:Fire(ragdollModel)
end

--[=[
	@param ragdollModel Model
	Deactivates ragdoll physics on the ragdoll.
]=]
function RagdollSystem:deactivateRagdoll(ragdollModel: Model)
	self.Signals.DeactivateRagdoll:Fire(ragdollModel)
end

--[=[
	@param ragdollModel Model
	Activates ragdoll physics on the ragdoll, deactivates ragdoll physics after the ragdoll has remained still for 1+ seconds.
]=]
function RagdollSystem:collapseRagdoll(ragdollModel: Model)
	self.Signals.CollapseRagdoll:Fire(ragdollModel)
end

--[=[
	@param ragdollModel Model
	@param blueprint Blueprint?
	Creates and caches a ragdoll corresponding to the Model.
]=]
function RagdollSystem:addRagdoll(ragdollModel: Model, blueprint: Types.Blueprint?): Ragdoll
	local ragdoll = RagdollFactory.new(ragdollModel, blueprint)
	self._ragdolls[ragdollModel] = ragdoll
	return ragdoll
end

--[=[
	@param ragdollModel Model
	@param blueprint Blueprint?
	@client
	Creates and caches a Ragdoll from a model that already has its Constraints constructed.
]=]
function RagdollSystem:replicateRagdoll(ragdollModel: Model, blueprint: Types.Blueprint?): Ragdoll
	local ragdoll = RagdollFactory.wrap(ragdollModel, blueprint)
	self._ragdolls[ragdollModel] = ragdoll
	return ragdoll
end

--[=[
	@param ragdollModel Model
	Destroys the ragdoll corresponding to the model and removes it from the cache.
]=]
function RagdollSystem:removeRagdoll(ragdollModel: Model)
	local ragdoll = self._ragdolls[ragdollModel]
	if not ragdoll then
		return
	end

	ragdoll:destroy()
	self._ragdolls[ragdollModel] = nil
end

--[=[
	@param player Player
	Returns the ragdoll corresponding to player's character or nil if there isnt one.
]=]
function RagdollSystem:getPlayerRagdoll(player: Player): Ragdoll?
	return self._ragdolls[player.Character]
end

--[=[
	@client
	Returns the ragdoll coresponding to the local player's character.
]=]
function RagdollSystem:getLocalRagdoll(): Ragdoll?
	return self._localPlayerRagdoll
end

--[=[
	@client
	@private
	Sets the local player's ragdoll.
]=]
function RagdollSystem:setLocalRagdoll(ragdoll: Ragdoll)
	self._localPlayerRagdoll = ragdoll
end

--[=[
	@client
	Activates ragdoll physics on the local player's ragdoll.
]=]
function RagdollSystem:activateLocalRagdoll()
	self.Signals.ActivateLocalRagdoll:Fire()
end

--[=[
	@client
	Deactivates ragdoll physics on the local player's ragdoll.
]=]
function RagdollSystem:deactivateLocalRagdoll()
	self.Signals.DeactivateLocalRagdoll:Fire()
end

--[=[
	@client
	Activates ragdoll physics on the local player's ragdoll, deactivates ragdoll physics after the ragdoll has remained still.
]=]
function RagdollSystem:collapseLocalRagdoll()
	self.Signals.CollapseLocalRagdoll:Fire()
end

local collapsed = {}
local ragdollMap = {}
local function removeFromLoop(ragdoll)
	local index = ragdollMap[ragdoll]
	if not index then
		return
	end

	local lastIndex = #collapsed
	local temp = collapsed[lastIndex]
	collapsed[index] = temp
	ragdollMap[temp.Ragdoll] = index
	collapsed[lastIndex] = nil
	ragdollMap[ragdoll] = nil
end

function registerEvents(ragdoll)
	ragdoll.Collapsed:Connect(function()
		table.insert(collapsed, {
			Ragdoll = ragdoll,
			RootPosition = ragdoll.HumanoidRootPart.Position,
			StartTime = workspace:GetServerTimeNow(),
		})
		ragdollMap[ragdoll] = #collapsed
	end)

	ragdoll.RagdollBegan:Connect(function()
		RagdollSystem._activeRagdolls += 1
	end)

	ragdoll.RagdollEnded:Connect(function()
		RagdollSystem._activeRagdolls -= 1
		removeFromLoop(ragdoll)
	end)

	ragdoll.Destroying:Connect(function()
		if ragdoll:isRagdolled() then
			RagdollSystem._activeRagdolls -= 1
		end
		removeFromLoop(ragdoll)
	end)

	ragdoll._trove:Connect(ragdoll.Character:GetAttributeChangedSignal("Ragdolled"), function()
		if ragdoll.Character:GetAttribute("Ragdolled") then
			RagdollSystem:activateRagdoll(ragdoll.Character)
		else
			RagdollSystem:deactivateRagdoll(ragdoll.Character)
		end
	end)

	ragdoll._trove:Connect(ragdoll.Humanoid.Died, function()
		RagdollSystem:collapseRagdoll(ragdoll.Character)
	end)
end

RagdollFactory.RagdollConstructed:Connect(registerEvents)

--Motion sensor that deactivates ragdoll physics on collapsed ragdolls that have remained still.
task.defer(function()
	local startTime

	if RunService:IsServer() then
		startTime = workspace:GetServerTimeNow()
		script:SetAttribute("StartTime", startTime)
	else
		startTime = script:GetAttribute("StartTime")
		if not startTime then
			script:GetAttributeChangedSignal("StartTime"):Wait()
			startTime = script:GetAttribute("StartTime")
		end
	end

	local counter = 0
	RunService.Heartbeat:Connect(function(_dt)
		local now = workspace:GetServerTimeNow()
		local elapsedSeconds = (now - startTime)
		local oldCounter = counter
		counter = elapsedSeconds % systemSettings.CollapseTimeoutInterval
		if counter > oldCounter then
			return
		end

		for i = #collapsed, 1, -1 do
			local collapsedInfo = collapsed[i]
			local ragdoll = collapsedInfo.Ragdoll
			local lastPos = collapsedInfo.RootPosition
			local collapsedStart = collapsedInfo.StartTime
			if (now - collapsedStart) < systemSettings.CollapseTimeoutInterval then
				continue
			end

			local newPos = ragdoll.HumanoidRootPart.Position
			local distance = (newPos - lastPos).Magnitude
			collapsedInfo.RootPosition = newPos
			if distance >= systemSettings.CollapseTimeoutDistanceThreshold then
				continue
			end

			ragdoll._collapsed = false
			removeFromLoop(ragdoll)
			if ragdoll.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				ragdoll:deactivateRagdollPhysics()
				continue
			end

			if systemSettings.FreezeIfDead then
				ragdoll:freeze()
			end
		end
	end)
end)

export type SystemSettings = Types.SystemSettings
export type Ragdoll = Types.Ragdoll

return RagdollSystem
