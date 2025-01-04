local Players = game:GetService("Players")
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

local function characterAdded(character: Model)
	local ragdoll: RagdollSystem.Ragdoll?

		while not ragdoll do task.wait()
			ragdoll = RagdollSystem:getRagdoll(character)
		end

		print("Got ragdoll!")
end

local function playerAdded(player: Player)
	if player.Character then
		characterAdded(player.Character)
	end

	player.CharacterAdded:Connect(characterAdded)
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

for _, player in Players:GetPlayers() do
	local localPlayer = Players.LocalPlayer

	if player == localPlayer then
		continue
	end

	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
