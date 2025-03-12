"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[427],{1155:a=>{a.exports=JSON.parse('{"functions":[{"name":"_insertNoCollisionConstraint","desc":"Inserts a NoCollisionConstraint into the ragdoll. Used to fine-tune the ragdoll\'s limb collisions. ","params":[{"name":"limb0","desc":"","lua_type":"BasePart"},{"name":"limb1","desc":"","lua_type":"BasePart"}],"returns":[],"function_type":"method","private":true,"source":{"line":539,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"activateRagdollPhysics","desc":"Activates ragdoll physics.","params":[],"returns":[],"function_type":"method","source":{"line":552,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"activateRagdollPhysicsLowDetail","desc":"Activates ragdoll physics in low detail mode.","params":[],"returns":[],"function_type":"method","source":{"line":566,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"deactivateRagdollPhysics","desc":"Deactivates ragdoll physics.","params":[],"returns":[],"function_type":"method","source":{"line":580,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"collapse","desc":"Activates ragdoll physics, then deactivates it when the ragdoll has remained still.","params":[],"returns":[],"function_type":"method","source":{"line":623,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"collapseLowDetail","desc":"Activates ragdoll physics in low detail mode, then deactivates it when the ragdoll has remained still.","params":[],"returns":[],"function_type":"method","source":{"line":636,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"freeze","desc":"Anchors all of the ragdoll\'s BaseParts.","params":[],"returns":[],"function_type":"method","source":{"line":649,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"unfreeze","desc":"Returns all of the ragdoll\'s BaseParts to their original settings.","params":[],"returns":[],"function_type":"method","source":{"line":664,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"isRagdolled","desc":"Returns true if ragdoll physics is active on this ragdoll.","params":[],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","source":{"line":679,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"isCollapsed","desc":"Returns true if the ragdoll has callapsed.","params":[],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","source":{"line":686,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"isFrozen","desc":"Returns true if the ragdoll is frozen.","params":[],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","source":{"line":693,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"destroy","desc":"Destroys the ragdoll.","params":[],"returns":[],"function_type":"method","source":{"line":700,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"Destroy","desc":"Alias for destroy().","params":[],"returns":[],"function_type":"method","source":{"line":710,"path":"lib/RagdollFactory/Ragdoll.lua"}}],"properties":[{"name":"_constraintsFolder","desc":"The root container for the ragdoll\'s internally created constraints.","lua_type":"Folder","private":true,"source":{"line":23,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_noCollisionConstraintsFolder","desc":"The folder containing all internally created NoCollisionConstraints.","lua_type":"Folder","private":true,"source":{"line":29,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_socketFolder","desc":"The folder containing all internally created BallSocketConstraints.","lua_type":"Folder","private":true,"source":{"line":35,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_noCollisionConstraints","desc":"","lua_type":"{ NoCollisionConstraint }","private":true,"source":{"line":40,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_sockets","desc":"","lua_type":"{ BallSocketConstraint }","private":true,"source":{"line":45,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_limbs","desc":"Array of the Ragdoll\'s direct children BaseParts exluding the root part.","lua_type":"{ BasePart }","private":true,"source":{"line":51,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_accessoryHandles","desc":"","lua_type":"{ BasePart }","private":true,"source":{"line":56,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"_joints","desc":"","lua_type":"{ AnimationConstraint | Motor6D }","private":true,"source":{"line":61,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"Character","desc":"The model this ragdoll wraps.","lua_type":"Model","readonly":true,"source":{"line":67,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"Humanoid","desc":"The Humanoid descendant of this Ragdoll\'s Character.","lua_type":"Humanoid","readonly":true,"source":{"line":73,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"HumanoidRootPart","desc":"The root part of this Ragdoll\'s Character.","lua_type":"BasePart","readonly":true,"source":{"line":79,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"RagdollBegan","desc":"A signal fired when ragdoll physics has begun.\\n\\n```lua\\n\\tragdoll.RagdollBegan:Connect(function()\\n\\t\\t--Do something when ragdoll physics has begun\\n\\tend)\\n```","lua_type":"Signal","readonly":true,"source":{"line":92,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"RagdollEnded","desc":"A signal fired when ragdoll physics has ended.\\n\\n```lua\\n\\tragdoll.RagdollEnded:Connect(function()\\n\\t\\t--Do something when ragdoll physics has ended\\n\\tend)\\n```","lua_type":"Signal","readonly":true,"source":{"line":104,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"Collapsed","desc":"A signal fired when ragdoll:collapse() is called.","lua_type":"Signal","readonly":true,"source":{"line":110,"path":"lib/RagdollFactory/Ragdoll.lua"}},{"name":"Destroying","desc":"A signal fired when ragdoll:destroy() is called.","lua_type":"Signal","readonly":true,"source":{"line":116,"path":"lib/RagdollFactory/Ragdoll.lua"}}],"types":[],"name":"Ragdoll","desc":"This class wraps around a Model and enables ragdoll physics by finding or\\ncreating physics constraints for it based on a [Blueprint]. The [Model] must\\ncontain a [Humanoid], a HumanoidRootPart, and have [Motor6D] or\\n[AnimationConstraint] descendants as joints.","source":{"line":17,"path":"lib/RagdollFactory/Ragdoll.lua"}}')}}]);