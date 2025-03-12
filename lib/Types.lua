local Signal = require(script.Parent.Parent.Signal)

export type SystemSettings = {
	--- The number of active ragdolls before the system starts using low detail mode.
	LowDetailModeThreshold: number,
	--- The interval in seconds between ragdoll distance checks while collapsed.
	CollapseTimeoutInterval: number,
	--- The minimum distance in studs a ragdoll must have moved between
	--- distance checks to remain collapsed.
	CollapseTimeoutDistanceThreshold: number,
	--- Whether the system freezes ragdolls if dead when they are being timed
	--- out of collapse. If false they remain collapsed.
	FreezeIfDead: boolean,
}

export type RagdollInternals = {
	--- The root container for the ragdoll's internally created constraints.
	_constraintsFolder: Folder,
	--- The folder containing all internally created NoCollisionConstraints.
	_noCollisionConstraintFolder: Folder,
	--- The folder containing all internally created BallSocketConstraints.
	_socketFolder: Folder,
	_sockets: { BallSocketConstraint },
	_noCollisionConstraints: { NoCollisionConstraint },
	--- Array of the Ragdoll's direct children BaseParts exluding the root part.
	_limbs: { BasePart },
	_accessoryHandles: { BasePart },
	_joints: { AnimationConstraint | Motor6D },
	--- Inserts a NoCollisionConstraint into the ragdoll. Used to fine-tune the
	--- ragdoll's limb collisions
	_insertNoCollisionConstraint: (self: Ragdoll, limb0: BasePart, limb2: BasePart) -> (),
}

export type Ragdoll = {
	--- @readonly The model this ragdoll wraps.
	Character: Model,
	--- @readonly The Humanoid descendant of this Ragdoll's Character.
	Humanoid: Humanoid,
	--- @readonly The root part of this Ragdoll's Character.
	HumanoidRootPart: BasePart,
	--[=[
		@readonly
		A signal fired when ragdoll physics has begun.

		```lua
			ragdoll.RagdollBegan:Connect(function()
				--Do something when ragdoll physics has begun
			end)
		```
	]=]
	RagdollBegan: Signal.Signal<()>,
	--[=[
		@readonly
		@prop RagdollEnded Signal
		A signal fired when ragdoll physics has ended.

		```lua
			ragdoll.RagdollEnded:Connect(function()
				--Do something when ragdoll physics has ended
			end)
		```
	]=]
	RagdollEnded: Signal.Signal<()>,
	--- A signal fired when ragdoll:collapse() is called.
	Collapsed: Signal.Signal<()>,
	--- A signal fired when ragdoll:destroy() is called.
	Destroying: Signal.Signal<()>,
	--- Returns true if ragdoll physics is active on this ragdoll.
	isRagdolled: (self: Ragdoll) -> boolean,
	--- Returns true if the ragdoll has callapsed.
	isCollapsed: (self: Ragdoll) -> boolean,
	--- Returns true if the ragdoll is frozen.
	isFrozen: (self: Ragdoll) -> boolean,
	--- Activates ragdoll physics.
	activateRagdollPhysics: (self: Ragdoll) -> (),
	--- Activates ragdoll physics in low detail mode.
	activateRagdollPhysicsLowDetail: (self: Ragdoll) -> (),
	--- Deactivates ragdoll physics.
	deactivateRagdollPhysics: (self: Ragdoll) -> (),
	--- Activates ragdoll physics, then deactivates it when the ragdoll has
	--- remained still.
	collapse: (self: Ragdoll) -> (),
	--- Activates ragdoll physics in low detail mode, then deactivates it when
	--- the ragdoll has remained still.
	collapseLowDetail: (self: Ragdoll) -> (),
	--- Anchors all of the ragdoll's BaseParts.
	freeze: (self: Ragdoll) -> (),
	--- Returns all of the ragdoll's BaseParts to their original settings.
	unfreeze: (self: Ragdoll) -> (),
	--- Destroys the ragdoll.
	destroy: (self: Ragdoll) -> (),
	--- Alias for destroy().
	Destroy: (self: Ragdoll) -> (),
}

export type SocketSetting = {
	MaxFrictionTorque: number,
	UpperAngle: number,
	TwistLowerAngle: number,
	TwistUpperAngle: number,
}

export type Blueprint = {
	numJoints: number,
	socketSettings: { [string]: SocketSetting },
	cframeOverrides: { [string]: { C0: CFrame, C1: CFrame }? },
	lowDetailModeJoints: { [string]: boolean }?,
	satisfiesRequirements: (Model) -> boolean,
	finalTouches: (RagdollInternals & Ragdoll) -> (),
}

local Types = {}

return Types
