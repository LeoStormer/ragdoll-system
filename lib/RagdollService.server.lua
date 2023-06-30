local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = require(script.Parent.RagdollFactory)

--Automated Ragdoll Activation and Deactivation
function activateRagdollPhysics(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
	if ragdoll then
		ragdoll:activateRagdollPhysics()
	end
end

function deactivateRagdollPhysics(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
	if ragdoll then
		ragdoll:deactivateRagdollPhysics()
	end
end

function collapseRagdoll(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
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
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		ragdoll:activateRagdollPhysics()
	end
end)

RagdollSystem.Signals.DeactivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		ragdoll:deactivateRagdollPhysics()
	end
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		ragdoll:collapse()
	end
end)

--Automated Ragdoll Construction
function onRagdollAdded(ragdollModel)
	RagdollSystem:addRagdoll(ragdollModel)
end

function onRagdollRemoved(ragdollModel)
	RagdollSystem:removeRagdoll(ragdollModel)
end

for _, ragdollModel in CollectionService:GetTagged("Ragdoll") do
	onRagdollAdded(ragdollModel)
end

CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(onRagdollAdded)
CollectionService:GetInstanceRemovedSignal("Ragdoll"):Connect(onRagdollRemoved)

function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local ragdoll = RagdollSystem:getPlayerRagdoll(player)
		if ragdoll then
			ragdoll:Destroy()
		end

		--for reasons I dont want to think about, the character model literally loses
		--its head without this wait if you use this system with imediate mode signal behavior
		task.wait()

		RagdollSystem:addPlayerRagdoll(player, character)
	end)

	player.CharacterRemoving:Connect(function(_character)
		RagdollSystem:removePlayerRagdoll(player)
	end)
end

function onPlayerRemoving(player: Player)
	RagdollSystem:removePlayerRagdoll(player)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

RagdollFactory.BlueprintAdded:Connect(function(blueprint: RagdollFactory.Blueprint)
	for model, ragdoll: RagdollSystem.Ragdoll in RagdollSystem._ragdolls do
		if not blueprint.satisfiesRequirements(model) then
			continue
		end
		
		ragdoll:destroy()
		local newRagdoll = blueprint.construct(model)
		RagdollSystem._ragdolls[model] = newRagdoll

		local player = Players:GetPlayerFromCharacter(model)
		if not player then
			return
		end

		RagdollSystem._playerRagdolls[player.UserId] = newRagdoll
	end
end)

