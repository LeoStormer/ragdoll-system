local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseRagdoll = require(script.Parent.Parent.RagdollFactory.BaseRagdoll)
local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ClientRagdoll = setmetatable({}, BaseRagdoll)
ClientRagdoll.__index = ClientRagdoll

function ClientRagdoll.new(character: Model): BaseRagdoll.Ragdoll
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
	}, ClientRagdoll)

	BaseRagdoll._recordOriginalSettings(self)

	self.ragdollBegan:Connect(function()
		self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)

	self.ragdollEnded:Connect(function()
		self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	trove:Connect(character:GetAttributeChangedSignal("Ragdolled"), function()
		--the server has ragdolled us, we dont need to do anything other than manage the humanoid
		local ragdolled = character:GetAttribute("Ragdolled")
		if ragdolled == true then
			self:activateRagdollPhysics()
		else
			self:deactivateRagdollPhysics()
		end
		self.ragdolled = ragdolled
	end)

	trove:Connect(humanoid.Died, function()
		self:collapse()
	end)
	
	return self
end

return ClientRagdoll
