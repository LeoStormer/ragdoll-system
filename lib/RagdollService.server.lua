--Driver for the Ragdoll System on ther server
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = RagdollSystem.RagdollFactory
local Types = require(script.Parent.Types)

--Automated Ragdoll Activation and Deactivation
function activateRagdollPhysics(ragdoll: Types.Ragdoll)
	if RagdollSystem._activeRagdolls < RagdollSystem._lowDetailThreshold then
		ragdoll:activateRagdollPhysics()
	else
		ragdoll:activateRagdollPhysicsLowDetail()
	end
end

function deactivateRagdollPhysics(ragdoll: Types.Ragdoll)
	ragdoll:deactivateRagdollPhysics()
end

function collapseRagdoll(ragdoll: Types.Ragdoll)
	if RagdollSystem._activeRagdolls < RagdollSystem._lowDetailThreshold then
		ragdoll:collapse()
	else
		ragdoll:collapseLowDetail()
	end
end

RagdollSystem.Remotes.ActivateRagdoll.OnServerEvent:Connect(function(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
	if ragdoll then
		activateRagdollPhysics(ragdoll)
	end
end)

RagdollSystem.Remotes.DeactivateRagdoll.OnServerEvent:Connect(function(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
	if ragdoll and ragdoll.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		deactivateRagdollPhysics(ragdoll)
	end
end)

RagdollSystem.Remotes.CollapseRagdoll.OnServerEvent:Connect(function(player: Player)
	local ragdoll = RagdollSystem:getPlayerRagdoll(player)
	if ragdoll then
		collapseRagdoll(ragdoll)
	end
end)

RagdollSystem.Signals.ActivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		activateRagdollPhysics(ragdoll)
	end
end)

RagdollSystem.Signals.DeactivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		deactivateRagdollPhysics(ragdoll)
	end
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		collapseRagdoll(ragdoll)
	end
end)

--Automated Ragdoll Construction
function onRagdollAdded(ragdollModel)
	RagdollSystem:addRagdoll(ragdollModel)
end

for _, ragdollModel in CollectionService:GetTagged("Ragdoll") do
	onRagdollAdded(ragdollModel)
end

CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(onRagdollAdded)

CollectionService:GetInstanceRemovedSignal("Ragdoll"):Connect(function(ragdollModel)
	RagdollSystem:removeRagdoll(ragdollModel)
end)

function onPlayerAdded(player: Player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		--for reasons I dont want to think about, the character model literally loses
		--its head without this defer if you use this system with imediate mode signal behavior
		task.defer(character.AddTag, character, "Ragdoll")
	end)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

RagdollFactory._blueprintAdded:Connect(function(blueprint: Types.Blueprint)
	for model, ragdoll: Types.Ragdoll in RagdollSystem._ragdolls do
		if not blueprint.satisfiesRequirements(model) then
			continue
		end

		ragdoll:destroy()
		RagdollSystem:addRagdoll(model, blueprint)
	end
end)
