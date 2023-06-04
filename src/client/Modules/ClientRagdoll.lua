local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)

local ClientRagdoll = {}
ClientRagdoll.__index = ClientRagdoll

function ClientRagdoll.new(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local trove = Trove.new()
	local constraintsFolder = character:WaitForChild("RagdollConstraints")

	local self = setmetatable({
		character = character,
		humanoid = humanoid,
		humanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		frozen = false,
		ragdolled = false,
		_trove = trove,
		_activeTrove = trove:Extend(),
		_constraints = constraintsFolder:GetChildren(),
		_originalSettings = {},
		_accessoryHandles = {},
		_motor6Ds = {},
		_limbs = {},
	}, ClientRagdoll)

	for _, limb in character:GetChildren() do
		if limb:IsA("Accessory") then
			local handle = limb.Handle
			self:_recordOriginalSettings(handle, {
				CanCollide = handle.CanCollide,
				CanTouch = handle.CanTouch,
				Massless = handle.Massless,
			})
			table.insert(self._accessoryHandles, handle)
		end

		for _, motor6D: Motor6D in limb:getChildren() do
			if not motor6D:IsA("Motor6D") then
				continue
			end

			local affectedLimb = motor6D.Part1
			self:_recordOriginalSettings(motor6D, { Enabled = motor6D.Enabled })
			self:_recordOriginalSettings(
				affectedLimb,
				{
					Anchored = affectedLimb.Anchored,
					CanCollide = affectedLimb.CanCollide,
					CustomPhysicalProperties = affectedLimb.CustomPhysicalProperties,
				}
			)

			table.insert(self._motor6Ds, motor6D)
			table.insert(self._limbs, affectedLimb)
		end
	end

	self:_recordOriginalSettings(self.humanoidRootPart, { CanCollide = self.humanoidRootPart.CanCollide })
	self:_recordOriginalSettings(humanoid, { WalkSpeed = humanoid.WalkSpeed })

	character:GetAttributeChangedSignal("Ragdolled"):Connect(function()
        local ragdolled = character:GetAttribute("Ragdolled")
		if ragdolled  == true then
			self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		else
			self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
        self.ragdolled = ragdolled
	end)

	return self
end

function ClientRagdoll:_recordOriginalSettings(object: Instance, record)
	if self._originalSettings[object] then
		for key, value in record do
			self._originalSettings[object][key] = value
		end
	else
		self._originalSettings[object] = record
	end
end

function ClientRagdoll:activateRagdollPhysics()
	if self.ragdolled then
		return
	end

	self.ragdolled = true
	self.humanoidRootPart.CanCollide = false
	self.humanoid.WalkSpeed = 0
    self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _, handle in self._accessoryHandles do
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end

	for _, motor6D: Motor6D in self._motor6Ds do
		motor6D.Enabled = false
	end

	for _, limb in self._limbs do
		limb.CanCollide = true
		limb.CustomPhysicalProperties = LIMB_PHYSICAL_PROPERTIES
	end

	for _, constraint: Constraint in self._constraints do
		constraint.Enabled = true
	end
end

function ClientRagdoll:deactivateRagdollPhysics()
	if not self.ragdolled then
		return
	end

	self.ragdolled = false
	self.humanoidRootPart.CanCollide = self._originalSettings[self.humanoidRootPart].CanCollide
	self.humanoid.WalkSpeed = self._originalSettings[self.humanoid].WalkSpeed
    self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	for _, handle in self._accessoryHandles do
		handle.CanCollide = self._originalSettings[handle].CanCollide
		handle.CanTouch = self._originalSettings[handle].CanTouch
		handle.Massless = self._originalSettings[handle].Massless
	end

	for _, motor6D: Motor6D in self._motor6Ds do
		motor6D.Enabled = self._originalSettings[motor6D].Enabled
	end

	for _, limb in self._limbs do
		limb.CanCollide = self._originalSettings[limb].CanCollide
		limb.CustomPhysicalProperties = self._originalSettings[limb].CustomPhysicalProperties
	end

	for _, constraint: Constraint in self._constraints do
		constraint.Enabled = false
	end
end

function ClientRagdoll:destroy()
    self._trove:Destroy()
end
ClientRagdoll.Destroy = ClientRagdoll.destroy

return ClientRagdoll
