local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = require(script.Parent.RagdollFactory)

-- For activating player ragdolls
local ragdolls: { [any]: RagdollFactory.Ragdoll? } = {}

function onNPCRagdollAdded(ragdollModel)
	ragdolls[ragdollModel] = RagdollFactory.new(ragdollModel)
end

function onNPCRagdollRemoved(ragdollModel)
	local ragdoll = ragdolls[ragdollModel]
	if not ragdoll then
		return
	end
	ragdoll:destroy()
end

for _, ragdollModel in CollectionService:GetTagged("Ragdoll") do
	onNPCRagdollAdded(ragdollModel)
end

CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(onNPCRagdollAdded)
CollectionService:GetInstanceRemovedSignal("Ragdoll"):Connect(onNPCRagdollRemoved)

local playerRagdolls: { [number]: RagdollFactory.Ragdoll? } = {}

function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local ragdoll = playerRagdolls[player.UserId]
		if ragdoll then
			ragdoll:Destroy()
		end

		--for reasons I dont want to think about, the character model literally loses
		--its head without this wait if you use this system with imediate mode signal behavior
		task.wait()

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

RagdollSystem.Remotes.ActivateRagdoll.OnServerEvent:Connect(activateRagdollPhysics)
RagdollSystem.Remotes.DeactivateRagdoll.OnServerEvent:Connect(deactivateRagdollPhysics)
RagdollSystem.Remotes.CollapseRagdoll.OnServerEvent:Connect(collapseRagdoll)
RagdollSystem.Signals.ActivatePlayerRagdoll:Connect(activateRagdollPhysics)
RagdollSystem.Signals.DeactivatePlayerRagdoll:Connect(deactivateRagdollPhysics)
RagdollSystem.Signals.CollapsePlayerRagdoll:Connect(collapseRagdoll)

RagdollSystem.Signals.ActivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = ragdolls[ragdollModel]
	if ragdoll then
		ragdoll:activateRagdollPhysics()
	end
end)

RagdollSystem.Signals.DeactivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = ragdolls[ragdollModel]
	if ragdoll then
		ragdoll:deactivateRagdollPhysics()
	end
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(ragdollModel)
	local ragdoll = ragdolls[ragdollModel]
	if ragdoll then
		ragdoll:collapse()
	end
end)
