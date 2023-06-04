local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RagdollFactory = require(ReplicatedStorage.Modules.RagdollFactory)

local ragdollServiceFolder = Instance.new("Folder")
ragdollServiceFolder.Name = "RagdollService"
ragdollServiceFolder.Parent = ReplicatedStorage.Services
local activateRagdollPhysics = Instance.new("RemoteEvent")
activateRagdollPhysics.Name = "ActivateRagdollPhysics"
activateRagdollPhysics.Parent = ragdollServiceFolder
local deactivateRagdollPhysics = Instance.new("RemoteEvent")
deactivateRagdollPhysics.Name = "DeactivateRagdollPhysics"
deactivateRagdollPhysics.Parent = ragdollServiceFolder

local RagdollService = {}

local ragdolls = {}

function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
        local ragdoll = ragdolls[player.UserId]
        if ragdoll then
            ragdoll:Destroy()
        end

		ragdoll = RagdollFactory.new(character)
		ragdolls[player.UserId] = ragdoll
	end)
end

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local ragdoll = ragdolls[player.UserId]
    if ragdoll then
        ragdoll:destroy()
    end

    ragdolls[player.UserId] = nil
end)

function RagdollService.getRagdoll(player: Player)
    return ragdolls[player.UserId]
end

activateRagdollPhysics.OnServerEvent:Connect(function(player: Player)
    local ragdoll = RagdollService.getRagdoll(player)
    if ragdoll then
        ragdoll:activateRagdollPhysics()
    end
end)

deactivateRagdollPhysics.OnServerEvent:Connect(function(player: Player)
    local ragdoll = RagdollService.getRagdoll(player)
    if ragdoll then
        ragdoll:deactivateRagdollPhysics()
    end
end)

return RagdollService