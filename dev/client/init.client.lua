local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RagdollSystem = require(ReplicatedStorage.Packages.RagdollSystem)

function collapse()
	RagdollSystem.Signals.CollapsePlayerRagdoll:Fire()
end

function activate()
	RagdollSystem.Signals.ActivatePlayerRagdoll:Fire()
end

function deactivate()
	RagdollSystem.Signals.DeactivatePlayerRagdoll:Fire()
end

function toggle()
	local ragdoll: RagdollSystem.Ragdoll = RagdollSystem.LocalPlayerRagdoll
	if ragdoll and ragdoll.ragdolled then
		deactivate()
	else
		activate()
	end
end

local actions = {
	[Enum.KeyCode.R] = collapse,
	[Enum.KeyCode.L] = toggle,
	[Enum.KeyCode.Q] = activate,
	[Enum.KeyCode.E] = deactivate,
}

UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if gameProcessedEvent or not actions[inputObject.KeyCode] then
		return
	end

	actions[inputObject.KeyCode]()
end)
