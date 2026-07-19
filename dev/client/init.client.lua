--# selene: allow(unused_variable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RagdollSystem = require(ReplicatedStorage.Packages.RagdollSystem)
local Types = require(ReplicatedStorage.Packages.RagdollSystem.Types)

local function collapse(ragdoll: Types.Ragdoll)
	-- ragdoll:collapseLowDetail()
	ragdoll:collapse()
	-- RagdollSystem:collapseLocalRagdoll()
end

local function activate(ragdoll: Types.Ragdoll)
	-- ragdoll:activateRagdollPhysicsLowDetail()
	ragdoll:activateRagdollPhysics()
	-- RagdollSystem:activateLocalRagdoll()
end

local function deactivate(ragdoll: Types.Ragdoll)
	ragdoll:deactivateRagdollPhysics()
	-- RagdollSystem:deactivateLocalRagdoll()
end

local function toggle(ragdoll: Types.Ragdoll)
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
