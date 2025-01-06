local RunService = game:GetService("RunService")
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
	@interface Remotes
	.ActivateRagdoll RemoteEvent
	.DeactivateRagdoll RemoteEvent
	.CollapseeRagdoll RemoteEvent
]=]
--[=[
	@within RagdollSystem
	@private
	@prop Remotes Remotes
]=]
--[=[
	@within RagdollSystem
	@private
	@interface Signals
	.ActivateLocalRagdoll Signal
	.DeactivateLocalRagdoll Signal
	.CollapseLocalRagdoll Signal
	.ActivateRagdoll Signal
	.DeactivateRagdoll Signal
	.CollapseRagdoll Signal
]=]
--[=[
	@within RagdollSystem
	@private
	@prop Signals Signals
]=]
--[=[
	@within RagdollSystem
	@prop RagdollFactory RagdollFactory
]=]
--[=[
	@within RagdollSystem
	@readonly
	@prop RagdollConstructed Signal
	Fires when a ragdoll is constructed by the factory.
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
RagdollSystem.RagdollFactory = RagdollFactory
RagdollSystem.RagdollConstructed = RagdollFactory.RagdollConstructed
RagdollSystem._activeRagdolls = 0
RagdollSystem._lowDetailThreshold = 15
RagdollSystem._localPlayerRagdoll = nil
RagdollSystem._ragdolls = {}

--[=[
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
	Activates ragdoll physics on the ragdoll, deactivates ragdoll physics after the ragdoll has remained still for 1.5 seconds.
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
	Creates and caches a Ragdoll from a model that already has its Constraints constructed.
]=]
function RagdollSystem:replicateRagdoll(ragdollModel: Model, blueprint: Types.Blueprint?)
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
	Activates ragdoll physics on the local player's ragdoll, deactivates ragdoll physics after the ragdoll has remained still for 1.5 seconds.
]=]
function RagdollSystem:collapseLocalRagdoll()
	self.Signals.CollapseLocalRagdoll:Fire()
end

local collapsed = {}
function registerEvents(ragdoll)
	ragdoll.Collapsed:Connect(function()
		table.insert(collapsed, { ragdoll, ragdoll.HumanoidRootPart.Position, workspace:GetServerTimeNow() })
	end)

	ragdoll.RagdollBegan:Connect(function()
		RagdollSystem._activeRagdolls += 1
	end)

	ragdoll.RagdollEnded:Connect(function()
		RagdollSystem._activeRagdolls -= 1
	end)

	ragdoll.Destroying:Connect(function()
		if ragdoll:isRagdolled() then
			RagdollSystem._activeRagdolls -= 1
		end
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

--Motion sensor that deactivates ragdoll physics on collapsed ragdolls that have remained still for 1.5 seconds.
task.defer(function()
	local RAGDOLL_TIMEOUT_INTERVAL = 1.5
	local RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD = 2
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
		counter = elapsedSeconds % RAGDOLL_TIMEOUT_INTERVAL
		if counter > oldCounter then
			return
		end

		for i = #collapsed, 1, -1 do
			local collapsedInfo = collapsed[i]
			local ragdoll = collapsedInfo[1]
			if ragdoll._ragdolled == false then
				ragdoll._collapsed = false
				table.remove(collapsed, i)
				continue
			end

			local lastPos = collapsedInfo[2]
			local collapsedStart = collapsedInfo[3]
			if (now - collapsedStart) < RAGDOLL_TIMEOUT_INTERVAL then
				continue
			end

			local newPos = ragdoll.HumanoidRootPart.Position
			local distance = (newPos - lastPos).Magnitude
			collapsedInfo[2] = newPos
			if distance >= RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD then
				continue
			end

			ragdoll._collapsed = false
			table.remove(collapsed, i)
			if ragdoll.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
				ragdoll:freeze()
			else
				ragdoll:deactivateRagdollPhysics()
			end
		end
	end)
end)

export type Ragdoll = Types.Ragdoll

return RagdollSystem
