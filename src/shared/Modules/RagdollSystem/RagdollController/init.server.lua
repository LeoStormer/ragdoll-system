local Players = game:GetService("Players")

local ClientRagdoll = require(script:WaitForChild("ClientRagdoll"))

local Remotes = script.Parent:WaitForChild("Remotes")
local ActivateRagdollRemote: RemoteEvent = Remotes:WaitForChild("ActivateRagdollRemote")
local DeactivateRagdollRemote: RemoteEvent = Remotes:WaitForChild("DeactivateRagdollRemote")
local CollapseRagdollRemote: RemoteEvent = Remotes:WaitForChild("CollapseRagdollRemote")
local ActivatePlayerRagdollBindable: BindableEvent = Remotes:WaitForChild("ActivatePlayerRagdollBindable")
local DeactivatePlayerRagdollBindable: BindableEvent = Remotes:WaitForChild("DeactivatePlayerRagdollBindable")
local CollapsePlayerRagdollBindable: BindableEvent = Remotes:WaitForChild("CollapsePlayerRagdollBindable")

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
	ActivateRagdollRemote:FireServer()
end

function deactivateRagdollPhysics()
	if not ragdoll or not ragdoll.ragdolled then
		return
	end
    (workspace.CurrentCamera).CameraSubject = ragdoll.humanoid
	ragdoll:deactivateRagdollPhysics()
	DeactivateRagdollRemote:FireServer()
end

function collapseRagdoll()
	if not ragdoll then
		return
	end
	ragdoll:collapse()
	CollapseRagdollRemote:FireServer()
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
ActivatePlayerRagdollBindable.Event:Connect(activateRagdollPhysics)
DeactivatePlayerRagdollBindable.Event:Connect(deactivateRagdollPhysics)
CollapsePlayerRagdollBindable.Event:Connect(collapseRagdoll)