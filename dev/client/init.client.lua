--# selene: allow(unused_variable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RagdollSystem = require(ReplicatedStorage.Packages.RagdollSystem)
local Types = require(ReplicatedStorage.Packages.RagdollSystem.Types)

function collapse(ragdoll: Types.Ragdoll)
	-- ragdoll:collapseLowDetail()
	RagdollSystem:collapseLocalRagdoll()
end

function activate(ragdoll: Types.Ragdoll)
	-- ragdoll:activateRagdollPhysicsLowDetail()
	RagdollSystem:activateLocalRagdoll()
end

function deactivate(_ragdoll: Types.Ragdoll)
	RagdollSystem:deactivateLocalRagdoll()
end

function toggle(ragdoll: Types.Ragdoll)
	if ragdoll:isRagdolled() then
		deactivate(ragdoll)
	else
		activate(ragdoll)
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
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll then
		return
	end

	actions[inputObject.KeyCode](ragdoll)
end)
