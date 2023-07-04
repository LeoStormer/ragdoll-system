local RunService = game:GetService("RunService")
local Signal = require(script.Parent.Signal)
local RagdollFactory = require(script.RagdollFactory)

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
	.ActivatePlayerRagdoll Signal
	.DeactivatePlayerRagdoll Signal
	.CollapsePlayerRagdoll Signal
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
local RagdollSystem = {
	Remotes = {
		ActivateRagdoll = script.Remotes.ActivateRagdollRemote,
		DeactivateRagdoll = script.Remotes.DeactivateRagdollRemote,
		CollapseRagdoll = script.Remotes.CollapseRagdollRemote,
	},
	Signals = {
		ActivateRagdoll = Signal.new(),
		DeactivateRagdoll = Signal.new(),
		CollapseRagdoll = Signal.new(),
		ActivatePlayerRagdoll = Signal.new(),
		DeactivatePlayerRagdoll = Signal.new(),
		CollapsePlayerRagdoll = Signal.new(),
	},
	RagdollFactory = RagdollFactory,
	_localPlayerRagdoll = nil,
	_playerRagdolls = {},
	_ragdolls = {},
}

local collapsed = {}
function registerCollapse(ragdoll: Ragdoll)
	ragdoll.Collapsed:Connect(function()
		table.insert(collapsed, { ragdoll, ragdoll.HumanoidRootPart.Position, DateTime.now().UnixTimestampMillis })
	end)
end
RagdollFactory.RagdollConstructed:Connect(registerCollapse)

--[=[
	@server
	Creates and caches a ragdoll corresponding to the Model.
]=]
function RagdollSystem:addRagdoll(ragdollModel: Model): Ragdoll
	local ragdoll = RagdollFactory.new(ragdollModel)
	self._ragdolls[ragdollModel] = ragdoll
	return ragdoll
end

--[=[
	@server
	@private
	Creates and caches a ragdoll corresponding to the players character if it exists.
]=]
function RagdollSystem:addPlayerRagdoll(player: Player, character: Model?): Ragdoll?
	local char = if character then character else player.Character
	if not character then
		return
	end

	local ragdoll = RagdollFactory.new(char)
	self._playerRagdolls[player.UserId] = ragdoll
	self._ragdolls[char] = ragdoll
	return ragdoll
end

--[=[
	@server
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
	@server
	@private
	Destroys the ragdoll corresponding to player's character and removes it from the cache.
]=]
function RagdollSystem:removePlayerRagdoll(player: Player)
	local ragdoll = self._playerRagdolls[player.UserId]
	if not ragdoll then
		return
	end

	self._playerRagdolls[player.UserId] = nil
	self._ragdolls[ragdoll.Character] = nil
	ragdoll:destroy()
end

--[=[
	@server
	Returns the ragdoll corresponding to the model or nil if there isn't one.
]=]
function RagdollSystem:getRagdoll(ragdollModel: Model): Ragdoll?
	return self._ragdolls[ragdollModel]
end

--[=[
	@server
	Returns the ragdoll corresponding to player's character or nil if there isnt one.
]=]
function RagdollSystem:getPlayerRagdoll(player: Player): Ragdoll?
	return self._playerRagdolls[player.UserId]
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
	Set value of the local player's ragdoll.
]=]
function RagdollSystem:setLocalRagdoll(ragdoll: Ragdoll)
	registerCollapse(ragdoll)

	self._localPlayerRagdoll = ragdoll
end

--[=[
	@client
	Activates ragdoll physics on the local player's ragdoll.
]=]
function RagdollSystem:activateLocalRagdoll()
	self.Signals.ActivatePlayerRagdoll:Fire()
end

--[=[
	@client
	Deactivates ragdoll physics on the local player's ragdoll.
]=]
function RagdollSystem:deactivateLocalRagdoll()
	self.Signals.DeactivatePlayerRagdoll:Fire()
end

--[=[
	@client
	Activates ragdoll physics on the local player's ragdoll, deactivates ragdoll physics after the ragdoll has remained still for 1.5 seconds.
]=]
function RagdollSystem:collapseLocalRagdoll()
	self.Signals.CollapsePlayerRagdoll:Fire()
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

export type Ragdoll = RagdollFactory.Ragdoll

--Motion sensor that deactivates ragdoll physics on collapsed ragdolls that have remained still for 1.5 seconds.
task.defer(function()
	local RAGDOLL_TIMEOUT_INTERVAL = 1.5
	local RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD = 2
	local startTime

	if RunService:IsServer() then
		startTime = DateTime.now().UnixTimestampMillis
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
		local now = DateTime.now().UnixTimestampMillis
		local elapsedSeconds = (now - startTime) / 1000
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
			if (now - collapsedStart) / 1000 < RAGDOLL_TIMEOUT_INTERVAL then
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

return RagdollSystem
