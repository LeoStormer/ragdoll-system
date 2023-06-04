local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientRagdoll = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("ClientRagdoll"))

local RagdollService = ReplicatedStorage:WaitForChild("Services"):WaitForChild("RagdollService")
local activateRagdollPhysics: RemoteEvent = RagdollService:WaitForChild("ActivateRagdollPhysics")
local deactivateRagdollPhysics: RemoteEvent = RagdollService:WaitForChild("DeactivateRagdollPhysics")

local RagdollController = {
	_ragdoll = nil,
}

function RagdollController.onPlayerAdded(character)
	if RagdollController._ragdoll then
		RagdollController._ragdoll:destroy()
	end
	RagdollController._ragdoll = ClientRagdoll.new(character)
end

function RagdollController.activateRagdollPhysics()
    (workspace.CurrentCamera).CameraSubject = RagdollController._ragdoll.character:FindFirstChild("Head")
	RagdollController._ragdoll:activateRagdollPhysics()
	activateRagdollPhysics:FireServer()
end

function RagdollController.deactivateRagdollPhysics()
    (workspace.CurrentCamera).CameraSubject = RagdollController._ragdoll.humanoid
	RagdollController._ragdoll:deactivateRagdollPhysics()
	deactivateRagdollPhysics:FireServer()
end

Players.LocalPlayer.CharacterAdded:Connect(RagdollController.onPlayerAdded)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.L or RagdollController._ragdoll == nil then
		return
	end

	if RagdollController._ragdoll.ragdolled then
		RagdollController.deactivateRagdollPhysics()
	else
		RagdollController.activateRagdollPhysics()
	end
end)

return RagdollController
