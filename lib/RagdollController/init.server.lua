--Driver for the Ragdoll System on the client
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollSystem = require(script.Parent)
local RagdollFactory = RagdollSystem.RagdollFactory
local Types = require(script.Parent.Types)

local player = Players.LocalPlayer

-- Automated Ragdoll Activation and Deactivation
function activateLocalRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or ragdoll:isRagdolled() then
		return
	end

	ragdoll:activateRagdollPhysics()
	RagdollSystem.Remotes.ActivateRagdoll:FireServer()
end

function deactivateLocalRagdollPhysics()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll or not ragdoll:isRagdolled() then
		return
	end

	ragdoll:deactivateRagdollPhysics()
	RagdollSystem.Remotes.DeactivateRagdoll:FireServer()
end

function collapseLocalRagdoll()
	local ragdoll = RagdollSystem:getLocalRagdoll()
	if not ragdoll then
		return
	end

	ragdoll:collapse()
	RagdollSystem.Remotes.CollapseRagdoll:FireServer()
end

RagdollSystem.Signals.ActivateLocalRagdoll:Connect(activateLocalRagdollPhysics)
RagdollSystem.Signals.DeactivateLocalRagdoll:Connect(deactivateLocalRagdollPhysics)
RagdollSystem.Signals.CollapseLocalRagdoll:Connect(collapseLocalRagdoll)

RagdollSystem.Signals.ActivateRagdoll:Connect(function(ragdollModel)
	if ragdollModel == player.Character then
		activateLocalRagdollPhysics()
		return
	end

	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	if RagdollSystem._activeRagdolls < RagdollSystem._lowDetailThreshold then
		ragdoll:activateRagdollPhysics()
	else
		ragdoll:activateRagdollPhysicsLowDetail()
	end
end)

RagdollSystem.Signals.DeactivateRagdoll:Connect(function(ragdollModel)
	if ragdollModel == player.Character then
		deactivateLocalRagdollPhysics()
		return
	end

	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	ragdoll:deactivateRagdollPhysics()
end)

RagdollSystem.Signals.CollapseRagdoll:Connect(function(ragdollModel)
	if ragdollModel == player.Character then
		collapseLocalRagdoll()
		return
	end

	local ragdoll = RagdollSystem:getRagdoll(ragdollModel)
	if not ragdoll then
		return
	end

	if RagdollSystem._activeRagdolls < RagdollSystem._lowDetailThreshold then
		ragdoll:collapse()
	else
		ragdoll:collapseLowDetail()
	end
end)

--Automated Ragdoll Construction
RagdollSystem.RagdollConstructed:Connect(function(ragdoll: Types.Ragdoll)
	if ragdoll.Character ~= player.Character then
		return
	end

	RagdollSystem:setLocalRagdoll(ragdoll)

	ragdoll.RagdollBegan:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Character:FindFirstChild("Head")
	end)

	ragdoll.RagdollEnded:Connect(function()
		(workspace.CurrentCamera).CameraSubject = ragdoll.Humanoid
	end)
end)

function onRagdollAdded(ragdollModel: Model)
	ragdollModel:WaitForChild("Humanoid")
	RagdollSystem:replicateRagdoll(ragdollModel)
end

for _, ragdollModel in CollectionService:GetTagged("Ragdoll") do
	onRagdollAdded(ragdollModel)
end

CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(onRagdollAdded)

CollectionService:GetInstanceRemovedSignal("Ragdoll"):Connect(function(ragdollModel)
	RagdollSystem:removeRagdoll(ragdollModel)
end)

RagdollFactory._blueprintAdded:Connect(function(blueprint: Types.Blueprint)
	for model, oldRagdoll: Types.Ragdoll in RagdollSystem._ragdolls do
		if not blueprint.satisfiesRequirements(model) then
			continue
		end

		oldRagdoll:destroy()
		RagdollSystem:replicateRagdoll(model, blueprint)
	end
end)
