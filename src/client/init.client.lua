local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = script:WaitForChild("Components"):GetChildren()
local sharedComponents = ReplicatedStorage:WaitForChild("Components"):GetChildren()

for _, module: ModuleScript in table.move(sharedComponents, 1, #sharedComponents, #components, components) do
	if not module:IsA("ModuleScript") then
		continue
	end
	require(module)
end

require(script.Services.RagdollController)