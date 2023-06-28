local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
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
}

return RagdollSystem
