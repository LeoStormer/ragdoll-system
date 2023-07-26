local Ragdoll = require(script.Parent.Parent.RagdollFactory.Ragdoll)
local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Parent.Trove)

local ReplicatedRagdoll = setmetatable({}, Ragdoll)
ReplicatedRagdoll.__index = ReplicatedRagdoll

function ReplicatedRagdoll.new(character: Model, blueprint): Ragdoll.Ragdoll
	local trove = Trove.new()
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local children = character:GetChildren()

	local constraintsFolder = character:WaitForChild("RagdollConstraints")
	local sockets = constraintsFolder:WaitForChild("BallSocketConstraints")
	local noCollisionConstraints = constraintsFolder:WaitForChild("NoCollisionConstraints")

	local self = setmetatable({
		Character = character,
		Humanoid = humanoid,
		HumanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		RagdollBegan = trove:Construct(Signal),
		RagdollEnded = trove:Construct(Signal),
		Collapsed = trove:Construct(Signal),
		_frozen = false,
		_ragdolled = false,
		_collapsed = false,
		_trove = trove,
		_sockets = sockets:GetChildren(),
		_noCollisionConstraints = noCollisionConstraints:GetChildren(),
		_originalSettings = {},
		_limbs = TableUtils.filter(children, function(limb)
			return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
		end),
		_accessoryHandles = TableUtils.map(
			TableUtils.filter(children, function(accessory)
				return accessory:IsA("Accessory")
			end),
			function(accessory)
				return accessory:FindFirstChild("Handle")
			end
		),
		_motor6Ds = TableUtils.filter(character:GetDescendants(), function(motor)
			return motor:IsA("Motor6D")
		end),
	}, ReplicatedRagdoll)

	Ragdoll._recordOriginalSettings(self)

	self._lowDetailModeSockets = if blueprint.lowDetailModeLimbs
		then TableUtils.filter(self._sockets, function(socket: BallSocketConstraint)
			return blueprint.lowDetailModeLimbs[socket.Name]
		end)
		else self._sockets

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

export type Ragdoll = Ragdoll.Ragdoll

return ReplicatedRagdoll
