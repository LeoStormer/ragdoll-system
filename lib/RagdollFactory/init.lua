local Blueprint = require(script.Blueprint)
local Signal = require(script.Parent.Parent.Signal)
local Ragdoll = require(script.Ragdoll)
local R15RagdollBlueprint = require(script.R15RagdollBlueprint)
local R6RagdollBlueprint = require(script.R6RagdollBlueprint)

--[=[
	@class RagdollFactory
	@__index RagdollFactory
]=]
-- --[=[
-- 	@within RagdollFactory
-- 	@private
-- 	@readonly
-- 	@prop _blueprintAdded Signal
-- 	Fires when a blueprint is added to the factory.
-- ]=]
--[=[
	@within RagdollFactory
	@readonly
	@prop RagdollConstructed Signal
	Fires when a ragdoll is constructed by the factory.
]=]
local RagdollFactory = {}
RagdollFactory._blueprints = {}
RagdollFactory._blueprintAdded = Signal.new()
RagdollFactory.RagdollConstructed = Signal.new()

function RagdollFactory._constructRagdoll(model: Model, blueprint: Blueprint): Ragdoll
	local ragdoll = Ragdoll.new(model, blueprint.numConstraints)
	Ragdoll._setupLimbs(ragdoll, blueprint.socketSettings, blueprint.cframeOverrides)
	blueprint.finalTouches(ragdoll)
	RagdollFactory.RagdollConstructed:Fire(ragdoll)
	return ragdoll
end

--[=[
	Constructs a ragdoll from a model that satisfies any of its blueprints. Returns nil if no blueprint is satisfied.
]=]
function RagdollFactory.new(model: Model, blueprint: Blueprint?): Ragdoll?
	if blueprint then
		if not blueprint.satisfiesRequirements(model) then
			error(`{model} did not satisfy blueprint's requirements `)
		end
		return RagdollFactory._constructRagdoll(model, blueprint)
	end

	for _, backupBlueprint: Blueprint in RagdollFactory._blueprints do
		if backupBlueprint.satisfiesRequirements(model) then
			return RagdollFactory._constructRagdoll(model, backupBlueprint)
		end
	end

	return nil
end

--[=[
	Adds a blueprint to the factory. Retroactively updates all existing ragdolls to this type of ragdoll if they satisfy its requirements.
]=]
function RagdollFactory.addBlueprint(blueprint: Blueprint)
	table.insert(RagdollFactory._blueprints, 1, blueprint)
	RagdollFactory._blueprintAdded:Fire(blueprint)
end

export type Ragdoll = Ragdoll.Ragdoll
export type Blueprint = Blueprint.Blueprint

RagdollFactory.addBlueprint(R6RagdollBlueprint)
RagdollFactory.addBlueprint(R15RagdollBlueprint)

return RagdollFactory
