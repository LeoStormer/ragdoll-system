local MODEL_TEMPLATE = Instance.new("Model")
MODEL_TEMPLATE.Name = "CapsuleCollider"

local BALL_TEMPLATE = Instance.new("Part")
BALL_TEMPLATE.Name = "Ball"
BALL_TEMPLATE.Shape = Enum.PartType.Ball
BALL_TEMPLATE.TopSurface = Enum.SurfaceType.Smooth
BALL_TEMPLATE.BottomSurface = Enum.SurfaceType.Smooth
BALL_TEMPLATE.Transparency = 1
BALL_TEMPLATE.CanCollide = false
BALL_TEMPLATE.CanTouch = false
BALL_TEMPLATE.CanQuery = false
BALL_TEMPLATE.Massless = true

local CYLINDER_TEMPLATE = BALL_TEMPLATE:Clone()
CYLINDER_TEMPLATE.Name = "Cylinder"
CYLINDER_TEMPLATE.Shape = Enum.PartType.Cylinder
--Pivot Offset is rotated 90 degrees around zAxis
CYLINDER_TEMPLATE.PivotOffset = CFrame.fromMatrix(Vector3.zero, -Vector3.yAxis, Vector3.xAxis, Vector3.zAxis)

local CapsuleCollider = {}
CapsuleCollider.__index = CapsuleCollider

function CapsuleCollider.new(
	radius: number,
	height: number,
	overlapParams: OverlapParams?,
	raycastParams: RaycastParams?
)
	local diameter = 2 * radius
	local ball = BALL_TEMPLATE:Clone()
	ball.Size = Vector3.one * diameter

	local self = setmetatable({
		_overlapParams = if overlapParams then overlapParams else OverlapParams.new(),
		_raycastParams = if raycastParams then raycastParams else RaycastParams.new(),
		_model = MODEL_TEMPLATE:Clone(),
		_topBall = ball,
		_bottomBall = ball:Clone(),
		_cylinder = CYLINDER_TEMPLATE:Clone(),
		_height = height,
		_radius = radius,
		_diameter = diameter,
		_cylinderHeight = height - diameter,
		_weld1 = Instance.new("WeldConstraint"),
		_weld2 = Instance.new("WeldConstraint"),
		_boundingBoxSize = Vector3.new(diameter, height, diameter),
	}, CapsuleCollider)

	self._weld1.Part0 = self._bottomBall
	self._weld1.Part1 = self._cylinder
	self._weld1.Parent = self._cylinder
	self._weld2.Part0 = self._cylinder
	self._weld2.Part1 = self._topBall
	self._weld2.Parent = self._topBall

	self._cylinder.Size = Vector3.new(self._cylinderHeight, diameter, diameter)
	self:setBottomBallCFrame(CFrame.new(0, 10, 0))

	self._topBall.Parent = self._model
	self._cylinder.Parent = self._model
	self._bottomBall.Parent = self._model

	return self
end

-- function CapsuleCollider:capsuleCast(direction: Vector3, worldRoot: WorldRoot?): RaycastResult?
--     --TODO: Do something here--
--     local world = if worldRoot then worldRoot else workspace
--     local result = world:Spherecast(self._topBall.Position, self._radius, direction, self._raycastParams)
--     if result then
--         return result
--     end

--     result = world:Spherecast(self._bottomBall, self._radius, direction, self._raycastParams)
--     if result then
--         return result
--     end

--     -- cast with the cylinder
--     return result
-- end

function CapsuleCollider:getPartsInCapsule(worldRoot: WorldRoot?): { BasePart }
	local world = if worldRoot then worldRoot else workspace
	local originalFilter = table.clone(self._overlapParams.FilterDescendantsInstances)

	local initialResult =
		world:GetPartBoundsInBox(self._cylinder:GetPivot(), self._boundingBoxSize, self._overlapParams)
	if #initialResult == 0 then
		self._overlapParams.FilterDescendantsInstances = originalFilter
		return initialResult
	end

	local baseParts = world:GetPartBoundsInRadius(self._topBall.Position, self._radius, self._overlapParams)
	self._overlapParams:AddToFilter(baseParts)

	local moreParts = world:GetPartBoundsInRadius(self._bottomBall.Position, self._radius, self._overlapParams)
	self._overlapParams:AddToFilter(moreParts)
	baseParts = table.move(moreParts, 1, #moreParts, #baseParts + 1, baseParts)

	local evenMoreParts = world:GetPartsInPart(self._cylinder, self._overlapParams)
	self._overlapParams.FilterDescendantsInstances = originalFilter

	return table.move(evenMoreParts, 1, #evenMoreParts, #baseParts + 1, baseParts)
end

function CapsuleCollider:setParent(parent: Instance?)
	self._model.Parent = parent
end

function CapsuleCollider:setRaycastParams(params: RaycastParams)
	self._raycastParams = params
end

function CapsuleCollider:setOverlapParams(params: OverlapParams)
	self._overlapParams = params
end

function CapsuleCollider:getParent(): Instance?
	return self._model.Parent
end

function CapsuleCollider:getTopBall(): Part
	return self._topBall
end

function CapsuleCollider:getCylinder(): Part
	return self._cylinder
end

function CapsuleCollider:getBottomBall(): Part
	return self._bottomBall
end

function CapsuleCollider:setRadius(radius: number)
	self._radius = radius
	self._diameter = 2 * radius
	self._boundingBoxSize = Vector3.new(self._diameter, self._height, self._diameter)
	self._cylinderHeight = self._height - self._diameter

	local newBallSize = Vector3.one * self._diameter
	self._topBall.Size = newBallSize
	self._bottomBall.Size = newBallSize
	self._cylinder.Size = Vector3.new(self._cylinderHeight, self._diameter, self._diameter)

	self:setCylinderCFrame(self._cylinder:GetPivot())
end

function CapsuleCollider:setHeight(height: number)
	self._boundingBoxSize = Vector3.new(self._diameter, height, self._diameter)
	self._height = height
	self._cylinderHeight = self._height - self._diameter
	self._cylinder.Size = Vector3.new(self._cylinderHeight, self._diameter, self._diameter)

	self:setCylinderCFrame(self._cylinder:GetPivot())
end

function CapsuleCollider:setBottomBallCFrame(targetCFrame: CFrame)
	self._weld1.Enabled, self._weld2.Enabled = false, false
	self._bottomBall:PivotTo(targetCFrame)
	self._cylinder:PivotTo(targetCFrame:ToWorldSpace(CFrame.new(0, self._cylinderHeight / 2, 0)))
	self._topBall:PivotTo(targetCFrame:ToWorldSpace(CFrame.new(0, self._cylinderHeight, 0)))
	self._weld1.Enabled, self._weld2.Enabled = true, true
end

function CapsuleCollider:setCylinderCFrame(targetCFrame: CFrame)
	self._weld1.Enabled, self._weld2.Enabled = false, false
	self._cylinder:PivotTo(targetCFrame)
	local pivot = self._cylinder:GetPivot()
	self._bottomBall:PivotTo(pivot:ToWorldSpace(CFrame.new(0, -self._cylinderHeight / 2, 0)))
	self._topBall:PivotTo(pivot:ToWorldSpace(CFrame.new(0, self._cylinderHeight / 2, 0)))
	self._weld1.Enabled, self._weld2.Enabled = true, true
end

function CapsuleCollider:setTopBallCFrame(targetCFrame: CFrame)
	self._weld1.Enabled, self._weld2.Enabled = false, false
	self._topBall:PivotTo(targetCFrame)
	self._cylinder:PivotTo(targetCFrame:ToWorldSpace(CFrame.new(0, -self._cylinderHeight / 2, 0)))
	self._bottomBall:PivotTo(targetCFrame:ToWorldSpace(CFrame.new(0, -self._cylinderHeight, 0)))
	self._weld1.Enabled, self._weld2.Enabled = true, true
end

function CapsuleCollider:destroy()
	self._model:Destroy()
end
CapsuleCollider.Destroy = CapsuleCollider.destroy

return CapsuleCollider
