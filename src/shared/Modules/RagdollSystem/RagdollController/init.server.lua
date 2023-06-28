local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local ClientRagdoll = require(script:WaitForChild("ClientRagdoll"))

local player = Players.LocalPlayer
local ragdoll = nil

function onCharacterAdded(character)
	if ragdoll then
		ragdoll:destroy()
	end
	ragdoll = ClientRagdoll.new(character)
end

function activateRagdollPhysics()
	if not ragdoll or ragdoll.ragdolled then
		return
	end
	(workspace.CurrentCamera).CameraSubject = ragdoll.character:FindFirstChild("Head")
	ragdoll:activateRagdollPhysics()
	RagdollSystem.Remotes.ActivateRagdoll:FireServer()
end

function deactivateRagdollPhysics()
	if not ragdoll or not ragdoll.ragdolled then
		return
	end
	(workspace.CurrentCamera).CameraSubject = ragdoll.humanoid
	ragdoll:deactivateRagdollPhysics()
	RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
end

function collapseRagdoll()
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
