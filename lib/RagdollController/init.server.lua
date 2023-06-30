local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = require(script.Parent.RagdollFactory)
local ReplicatedRagdoll = require(script:WaitForChild("ReplicatedRagdoll"))

-- Automated Ragdoll Activation and Deactivation
function activateRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or ragdoll:isRagdolled() then
		return
	end

	ragdoll:activateRagdollPhysics()
	RagdollSystem.Remotes.ActivateRagdoll:FireServer()
end

function deactivateRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or not ragdoll:isRagdolled() then
		return
	end

	ragdoll:deactivateRagdollPhysics()
	RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
end

function collapseRagdoll()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll then
		return
	end

	ragdoll:collapse()
	RagdollSystem.Remotes.CollapseRagdoll:FireServer()
end

RagdollSystem.Signals.ActivatePlayerRagdoll:Connect(activateRagdollPhysics)
RagdollSystem.Signals.DeactivatePlayerRagdoll:Connect(deactivateRagdollPhysics)
RagdollSystem.Signals.CollapsePlayerRagdoll:Connect(collapseRagdoll)

--Automated Ragdoll Construction
local player = Players.LocalPlayer

function onCharacterAdded(character)
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if ragdoll then
		ragdoll:destroy()
	end

	ragdoll = ReplicatedRagdoll.new(character)
	RagdollSystem:setLocalRagdoll(ragdoll)

	ragdoll.RagdollBegan:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Character:FindFirstChild("Head")
	end)

	ragdoll.RagdollEnded:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Humanoid
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end

RagdollFactory.BlueprintAdded:Connect(function(blueprint: RagdollFactory.Blueprint)
	for model, ragdoll: RagdollSystem.Ragdoll in RagdollSystem._ragdolls do
		if not blueprint.satisfiesRequirements(model) then
			continue
		end
		ragdoll:destroy()
		local newRagdoll = blueprint.construct(model)
		RagdollSystem._ragdolls[model] = newRagdoll
		local characterOwner = Players:GetPlayerFromCharacter(model)
		if not characterOwner or characterOwner ~= player then
			return
		end
		
		RagdollSystem:setLocalRagdoll(newRagdoll)
	end
end)

player.CharacterAdded:Connect(onCharacterAdded)
