local Signal = require(script.Parent.Signal)
local RagdollFactory = require(script.RagdollFactory)

local RagdollSystem = {
	Remotes = {
		ActivateRagdoll = script.Remotes.ActivateRagdollRemote,
		DeactivateRagdoll = script.Remotes.DeactivateRagdollRemote,
		CollapseRagdoll = script.Remotes.CollapseRagdollRemote,
	},
	Signals = {
		ActivateRagdoll = Signal.new(),
		DeactivateRagdoll = Signal.new(),
		CollapseRagdoll = Signal.new(),
		ActivatePlayerRagdoll = Signal.new(),
		DeactivatePlayerRagdoll = Signal.new(),
		CollapsePlayerRagdoll = Signal.new(),
	},
	LocalPlayerRagdoll = nil,
}

export type Ragdoll = RagdollFactory.Ragdoll

return RagdollSystem
