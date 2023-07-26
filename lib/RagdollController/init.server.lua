--Driver for the Ragdoll System on the client
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = require(script.Parent.RagdollFactory)

-- Automated Ragdoll Activation and Deactivation
function activateLocalRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or ragdoll:isRagdolled() then
		return
	end

	ragdoll:activateRagdollPhysics()
	RagdollSystem.Remotes.ActivateRagdoll:FireServer()
end

function deactivateLocalRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or not ragdoll:isRagdolled() then
		return
	end

	ragdoll:deactivateRagdollPhysics()
	RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
end

function collapseLocalRagdoll()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll then
		return
	end

	ragdoll:collapse()
	RagdollSystem.Remotes.CollapseRagdoll:FireServer()
end

RagdollSystem.Signals.ActivatePlayerRagdoll:Connect(activateLocalRagdollPhysics)
RagdollSystem.Signals.DeactivatePlayerRagdoll:Connect(deactivateLocalRagdollPhysics)
RagdollSystem.Signals.CollapsePlayerRagdoll:Connect(collapseLocalRagdoll)

RagdollSystem.Signals.ActivateRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	ragdoll:activateRagdollPhysics()
end)

RagdollSystem.Signals.DeactivatePlayerRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	ragdoll:deactivateRagdollPhysics()
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	ragdoll:collapse()
end)

--Automated Ragdoll Construction
local player = Players.LocalPlayer

function constructLocalRagdoll(character, blueprint: RagdollFactory.Blueprint?)
	local ragdoll = RagdollFactory.wrap(character, blueprint)
	RagdollSystem:setLocalRagdoll(ragdoll)

	ragdoll.RagdollBegan:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Character:FindFirstChild("Head")
	end)

	ragdoll.RagdollEnded:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Humanoid
	end)

	return ragdoll
end

function onCharacterAdded(character: Model)
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if ragdoll then
		ragdoll:destroy()
	end

	character:WaitForChild("Humanoid")
	RagdollSystem._ragdolls[character] = constructLocalRagdoll(character)
end

function onCharacterRemoving(character)
	RagdollSystem._ragdolls[character] = nil
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

function onRagdollAdded(ragdollModel: Model)
	ragdollModel:WaitForChild("Humanoid")
	local ragdoll = RagdollFactory.wrap(ragdollModel)
	RagdollSystem._ragdolls[ragdollModel] = ragdoll
end

function onRagdollRemoved(ragdollModel)
	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if ragdoll then
		ragdoll:destroy()
	end
	
	RagdollSystem._ragdolls[ragdollModel] = nil
end

for _, ragdollModel in CollectionService:GetTagged("Ragdoll") do
	onRagdollAdded(ragdollModel)
end

CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(onRagdollAdded)
CollectionService:GetInstanceRemovedSignal("Ragdoll"):Connect(onRagdollRemoved)

RagdollFactory._blueprintAdded:Connect(function(blueprint: RagdollFactory.Blueprint)
	for model, oldRagdoll: RagdollSystem.Ragdoll in RagdollSystem._ragdolls do
		if not blueprint.satisfiesRequirements(model) then
			continue
		end

		oldRagdoll:destroy()
		local newRagdoll = if model == player.Character
			then constructLocalRagdoll(model, blueprint)
			else RagdollFactory.wrap(model, blueprint)
		RagdollSystem._ragdolls[model] = newRagdoll
	end
end)
