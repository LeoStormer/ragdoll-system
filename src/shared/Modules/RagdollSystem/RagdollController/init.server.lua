local Players = game:GetService("Players")

local ClientRagdoll = require(script:WaitForChild("ClientRagdoll"))

local Remotes = script.Parent:WaitForChild("Remotes")
local ActivateRagdollRemote: RemoteEvent = Remotes:WaitForChild("ActivateRagdollRemote")
local DeactivateRagdollRemote: RemoteEvent = Remotes:WaitForChild("DeactivateRagdollRemote")
local CollapseRagdollRemote: RemoteEvent = Remotes:WaitForChild("CollapseRagdollRemote")
local ActivateRagdollBindable: BindableEvent = Remotes:WaitForChild("ActivateRagdollBindable")
local DeactivateRagdollBindable: BindableEvent = Remotes:WaitForChild("DeactivateRagdollBindable")
local CollapseRagdollBindable: BindableEvent = Remotes:WaitForChild("CollapseRagdollBindable")

local ragdoll = nil

function onPlayerAdded(character)
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

Players.LocalPlayer.CharacterAdded:Connect(onPlayerAdded)
ActivateRagdollBindable.Event:Connect(activateRagdollPhysics)
DeactivateRagdollBindable.Event:Connect(deactivateRagdollPhysics)
CollapseRagdollBindable.Event:Connect(collapseRagdoll)
