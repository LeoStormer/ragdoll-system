# Extending the System

So you want to create a different type of ragdoll than R15 or R6? No problem create a [Blueprint](/api/Blueprint) and add it to the RagdollFactory.


```lua title="MyBlueprint.lua"
    local Blueprint = require(path.to.RagdollSystem).Blueprint

    local MyBlueprint = setmetatable({}, Blueprint)
    MyBlueprint.socketSettings = { --The keys are names of Motor6Ds in your model e.g. Wrist, Waist, or Neck.
		Neck = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
		Root = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30 },
		MyJoint = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
		MyJoint2 = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
    }
    MyBlueprint.cframeOverrides = {} --The keys are names of Motor6Ds in your model.

    function MyBlueprint.satisfiesRequirements(model: Model): boolean
        --How can we tell that model satisfies my blueprint?
        return model:FindFirstChild("MyLimb") ~= nil
    end

    function MyBlueprint.finalTouches(ragdoll: Ragdoll & RagdollInternals)
        --Do something with ragdoll, or don't, ragdoll won't mind.
        local noCollision = Instance.new("NoCollisionConstraint")
        noCollision.Enabled = false
        noCollision.Part0 = ragdoll.Character.MyLimb
        noCollision.Part1 = ragdoll.Character.MyLimb2
        noCollision.Parent = ragdoll._noCollisionConstraintFolder
        table.insert(ragdoll._noCollisionConstraints, noCollision)
    end

    return MyBlueprint
```

```lua title="Main"
local MyBlueprint = require(path.to.MyBlueprint)
local RagdollFactory = require(path.to.RagdollSystem).RagdollFactory
RagdollFactory.addBlueprint(MyBlueprint)
```
