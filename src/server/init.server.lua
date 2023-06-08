local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = script.Components:GetChildren()
local sharedComponents = ReplicatedStorage.Components:GetChildren()

for _, module: ModuleScript in table.move(sharedComponents, 1, #sharedComponents, #components, components) do
	if not module:IsA("ModuleScript") then
		continue
	end
	require(module)
end