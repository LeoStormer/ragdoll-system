local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local ReplicatedRagdoll = require(script:WaitForChild("ReplicatedRagdoll"))

local player = Players.LocalPlayer

function onCharacterAdded(character)
	local ragdoll = RagdollSystem.LocalPlayerRagdoll
	if ragdoll then
		ragdoll:destroy()
	end

	ragdoll = ReplicatedRagdoll.new(character)
	RagdollSystem.LocalPlayerRagdoll = ragdoll
	
	ragdoll.ragdollBegan:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.character:FindFirstChild("Head")
	end)
	
	ragdoll.ragdollEnded:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.humanoid
	end)
end

function activateRagdollPhysics()
	local ragdoll = RagdollSystem.LocalPlayerRagdoll
	if not ragdoll or ragdoll.ragdolled then
		return
	end

	ragdoll:activateRagdollPhysics()
	RagdollSystem.Remotes.ActivateRagdoll:FireServer()
end

function deactivateRagdollPhysics()
	local ragdoll = RagdollSystem.LocalPlayerRagdoll
	if not ragdoll or not ragdoll.ragdolled then
		return
	end
	
	ragdoll:deactivateRagdollPhysics()
	RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
end

function collapseRagdoll()
	local ragdoll = RagdollSystem.LocalPlayerRagdoll
	if not ragdoll then
		return
	end

	ragdoll:collapse()
	RagdollSystem.Remotes.CollapseRagdoll:FireServer()
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
RagdollSystem.Signals.ActivatePlayerRagdoll:Connect(activateRagdollPhysics)
RagdollSystem.Signals.DeactivatePlayerRagdoll:Connect(deactivateRagdollPhysics)
RagdollSystem.Signals.CollapsePlayerRagdoll:Connect(collapseRagdoll)
