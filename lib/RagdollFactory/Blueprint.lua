local Ragdoll = require(script.Parent.Ragdoll)
--[=[
    @class Blueprint
    @__index Blueprint
]=]
--[=[
	@within Blueprint
	@interface SocketSettings
	.MaxFrictionTorque number
	.UpperAngle number
	.TwistLowerAngle number
	.TwistUpperAngle number
]=]
--[=[
	@within Blueprint
	@type SocketSettingsDictionary {[string] = SocketSetting}
	Each string must refer to a Basepart within the character this blueprint describes.
]=]
--[=[
	@within Blueprint
	@type CFrameOverrides {[string] = {C0: CFrame, C1: CFrame}
	Each string must refer to a Basepart within the character this blueprint describes.
]=]
--[=[
	@within Blueprint
	@prop numlimbs number?
	Number of limbs your character model has
	:::tip

	Putting an accurate number can improve the performance of ragdoll construction slightly, although it isn't necessary.
	
	:::
]=]
--[=[
    @within Blueprint
    @prop socketSettings SocketSettingsDictionary
    Used to describe the range of motion of each BasePart within the ragdoll.
]=]
--[=[
    @within Blueprint
    @prop cframeOverrides CFrameOverrides?
    Used to change how specific parts in the ragdoll are attached on the ragdoll.
    For example, in the R6 blueprint the arms are overridden to be attached the same way Upper Arms are attached in R15 Characters.
]=]
--[=[
	@within Blueprint
	@prop lowDetailModeLimbs { [string]: boolean }?
	Describes which limbs will be activated in low detail mode.
]=]
local Blueprint = {}
Blueprint.__index = Blueprint
Blueprint.numLimbs = 15
Blueprint.socketSettings = {}
Blueprint.cframeOverrides = {}

--[=[
    @within Blueprint
    @function satisfiesRequirements
    @param model Model
    @return boolean
    Returns whether the model can be properly constructed by this blueprint.
]=]
--selene: allow(unused_variable)
function Blueprint.satisfiesRequirements(model: Model)
	error(`satisfiesRequirements() must be defined`)
end

--[=[
    @param ragdoll Ragdoll
    Apply final touches to the ragdoll. For example, in the R15 blueprint some extra NoCollisionConstraints are added to make the ragdoll physics flow smoother.
]=]
--selene: allow(unused_variable)
function Blueprint.finalTouches(ragdoll) end

--[=[
	@within Blueprint
	@function wrap
	@param model Model
	@return Ragdoll
	Creates a ragdoll object from a model that already has its Constraints constructed. Used to replicate a ragdoll across server -> client boundary. 
]=]

export type Blueprint = {
	numLimbs: number?,
	socketSettings: {
		[string]: {
			MaxFrictionTorque: number,
			UpperAngle: number,
			TwistLowerAngle: number,
			TwistUpperAngle: number,
		},
	},
	cframeOverrides: { [string]: { C0: CFrame, C1: CFrame } }?,
	lowDetailModeLimbs: { [string]: boolean },
	satisfiesRequirements: (Model) -> boolean,
	finalTouches: (Ragdoll.Ragdoll) -> (),
}

return Blueprint
