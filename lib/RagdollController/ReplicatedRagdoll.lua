local BaseRagdoll = require(script.Parent.Parent.RagdollFactory.BaseRagdoll)
local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Parent.Trove)

local ReplicatedRagdoll = setmetatable({}, BaseRagdoll)
ReplicatedRagdoll.__index = ReplicatedRagdoll

function ReplicatedRagdoll.new(character: Model): BaseRagdoll.Ragdoll
	local trove = Trove.new()
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local children = character:GetChildren()

	local self = setmetatable({
		character = character,
		humanoid = humanoid,
		humanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		frozen = false,
		ragdolled = false,
		ragdollBegan = trove:Construct(Signal),
		ragdollEnded = trove:Construct(Signal),
		_trove = trove,
		_activeTrove = trove:Extend(),
		_constraints = character:WaitForChild("RagdollConstraints"):GetChildren(),
		_originalSettings = {},
		_limbs = TableUtils.filter(children, function(limb: BasePart)
			return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
		end),
		_accessoryHandles = TableUtils.map(
			TableUtils.filter(children, function(accessory: Accessory)
				return accessory:IsA("Accessory")
			end),
			function(accessory: Accessory)
				return accessory:FindFirstChild("Handle")
			end
		),
		_motor6Ds = TableUtils.filter(character:GetDescendants(), function(motor: Motor6D)
			return motor:IsA("Motor6D")
		end),
	}, ReplicatedRagdoll)

	BaseRagdoll._recordOriginalSettings(self)

	trove:Connect(character:GetAttributeChangedSignal("Ragdolled"), function()
		if character:GetAttribute("Ragdolled") == true then
			self:activateRagdollPhysics()
		else
			self:deactivateRagdollPhysics()
		end
	end)

	trove:Connect(humanoid.Died, function()
		self:collapse()
	end)

	return self
end

export type Ragdoll = BaseRagdoll.Ragdoll

return ReplicatedRagdoll