local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollFactory = require(script.Parent.RagdollFactory)

local Remotes = script.Parent.Remotes
-- For activating player ragdolls
local ActivateRagdollRemote: RemoteEvent = Remotes.ActivateRagdollRemote
local DeactivateRagdollRemote: RemoteEvent = Remotes.DeactivateRagdollRemote
local CollapseRagdollRemote: RemoteEvent = Remotes.CollapseRagdollRemote
local ActivatePlayerRagdollBindable: BindableEvent = Remotes.ActivatePlayerRagdollBindable
local DeactivatePlayerRagdollBindable: BindableEvent = Remotes.DeactivatePlayerRagdollBindable
local CollapsePlayerRagdollBindable: BindableEvent = Remotes.CollapsePlayerRagdollBindable
--For activating npc ragdolls
local ActivateRagdollBindable: BindableEvent = Remotes.ActivateRagdollBindable
local DeactivateRagdollBindable: BindableEvent = Remotes.DeactivateRagdollBindable
local CollapseRagdollBindable: BindableEvent = Remotes.CollapseRagdollBindable

local ragdolls: { [any]: RagdollFactory.Ragdoll? } = {}

function onNPCRagdollAdded(npcModel)
	ragdolls[npcModel] = RagdollFactory.new(npcModel)
end

function onNPCRagdollRemoved(npcModel)
	local ragdoll = ragdolls[npcModel]
	if not ragdoll then
		return
	end
	ragdoll:destroy()
end

for _, npcModel in CollectionService:GetTagged("NPCRagdoll") do
	onNPCRagdollAdded(npcModel)
end

CollectionService:GetInstanceAddedSignal("NPCRagdoll"):Connect(onNPCRagdollAdded)
CollectionService:GetInstanceRemovedSignal("NPCRagdoll"):Connect(onNPCRagdollRemoved)

local playerRagdolls: { [any]: RagdollFactory.Ragdoll? } = {}

function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local ragdoll = playerRagdolls[player.UserId]
		if ragdoll then
			ragdoll:Destroy()
		end

		ragdoll = RagdollFactory.new(character)
		playerRagdolls[player.UserId] = ragdoll
		ragdolls[character] = ragdoll
	end)

	player.CharacterRemoving:Connect(function(character)
		local ragdoll = playerRagdolls[player.UserId]
		if ragdoll then
			ragdoll:Destroy()
		end

		playerRagdolls[player.UserId] = nil
		ragdolls[character] = nil
	end)
end

function onPlayerRemoving(player: Player)
	local ragdoll = playerRagdolls[player.UserId]
	if ragdoll then
		ragdoll:destroy()
	end

	playerRagdolls[player.UserId] = nil
	local character = player.Character
	if character then
		ragdolls[character] = nil
	end
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

function activateRagdollPhysics(player: Player)
	local ragdoll = playerRagdolls[player.UserId]
	if ragdoll then
		ragdoll:activateRagdollPhysics()
	end
end

function deactivateRagdollPhysics(player: Player)
	local ragdoll = playerRagdolls[player.UserId]
	if ragdoll then
		ragdoll:deactivateRagdollPhysics()
	end
end

function collapseRagdoll(player: Player)
	local ragdoll = playerRagdolls[player.UserId]
	if ragdoll then
		ragdoll:collapse()
	end
end

ActivateRagdollRemote.OnServerEvent:Connect(activateRagdollPhysics)
DeactivateRagdollRemote.OnServerEvent:Connect(deactivateRagdollPhysics)
CollapseRagdollRemote.OnServerEvent:Connect(collapseRagdoll)
ActivatePlayerRagdollBindable.Event:Connect(activateRagdollPhysics)
DeactivatePlayerRagdollBindable.Event:Connect(deactivateRagdollPhysics)
CollapsePlayerRagdollBindable.Event:Connect(collapseRagdoll)

ActivateRagdollBindable.Event:Connect(function(npcModel)
	local ragdoll = ragdolls[npcModel]
	if ragdoll then
		ragdoll:activateRagdollPhysics()
	end
end)

DeactivateRagdollBindable.Event:Connect(function(npcModel)
	local ragdoll = ragdolls[npcModel]
	if ragdoll then
		ragdoll:deactivateRagdollPhysics()
	end
end)

CollapseRagdollBindable.Event:Connect(function(npcModel)
	local ragdoll = ragdolls[npcModel]
	if ragdoll then
		ragdoll:collapse()
	end
end)