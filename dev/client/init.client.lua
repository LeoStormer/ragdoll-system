local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RagdollSystem = require(ReplicatedStorage.Packages.RagdollSystem)

function collapse()
	RagdollSystem:collapseLocalRagdoll()
end

function activate()
	RagdollSystem:activateLocalRagdoll()
end

function deactivate()
	RagdollSystem:deactivateLocalRagdoll()
end

function toggle()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if ragdoll and ragdoll:isRagdolled() then
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
