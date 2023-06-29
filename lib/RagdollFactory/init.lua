local BaseRagdoll = require(script.BaseRagdoll)
local R15Ragdoll = require(script.R15Ragdoll)
local R6Ragdoll = require(script.R6Ragdoll)

local Ragdoll = {}

function Ragdoll.new(character): Ragdoll
	local isR15 = character:FindFirstChild("RightUpperLeg") ~= nil
	return if isR15 then R15Ragdoll.new(character) else R6Ragdoll.new(character)
end

export type Ragdoll = BaseRagdoll.Ragdoll

return Ragdoll
