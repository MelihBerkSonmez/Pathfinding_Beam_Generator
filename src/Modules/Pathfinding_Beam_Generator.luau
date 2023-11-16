--Services
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

-- Module
local Pathfinding_Beam_Generator = {}
Pathfinding_Beam_Generator.__index = Pathfinding_Beam_Generator

--Definations
local Current_Path_Folder = nil

Pathfinding_Beam_Generator.Players_That_Has_Path = {}

-- Settings
Pathfinding_Beam_Generator.Agent_Parameters = {
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = true,
    AgentCanClimb = false,
    WaypointSpacing = 5,
}

Pathfinding_Beam_Generator.Beam_Settings = {
    Beam_Width = 1.5,
    Beam_Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
    Beam_Texture = "rbxassetid://2557513411",
    Beam_FaceCamera = true,
    Beam_Brightness = 1,
    Beam_Segments = 20,
    Beam_LightEmission = 1,
    Beam_LightInfluence = 1,
    Beam_TextureLength = 1.5,
    Beam_TextureMode = Enum.TextureMode.Wrap,
    Beam_TextureSpeed = 1,
    Beam_Transparency = NumberSequence.new(0),
    Beam_ZOffset = 1,
}

Pathfinding_Beam_Generator.General_Settings = {
    Beams_Height_From_Ground = 1.5, -- 1.5 Studs
}

--Functions
function CustomizeBeam(Beam :Beam)
    
    local Beam_Settings = Pathfinding_Beam_Generator.Beam_Settings

    Beam.FaceCamera = Beam_Settings.Beam_FaceCamera
    Beam.Brightness = Beam_Settings.Beam_Brightness
    Beam.Color = Beam_Settings.Beam_Color
    Beam.Width0 = Beam_Settings.Beam_Width
    Beam.Width1 = Beam_Settings.Beam_Width
    Beam.Texture = Beam_Settings.Beam_Texture
    Beam.Segments = Beam_Settings.Beam_Segments
    Beam.LightEmission = Beam_Settings.Beam_LightEmission
    Beam.LightInfluence = Beam_Settings.Beam_LightInfluence
    Beam.TextureLength = Beam_Settings.Beam_TextureLength
    Beam.TextureMode = Beam_Settings.Beam_TextureMode
    Beam.TextureSpeed = Beam_Settings.Beam_TextureSpeed
    Beam.Transparency = Beam_Settings.Beam_Transparency
    Beam.ZOffset = Beam_Settings.Beam_ZOffset

end

function Create_Info_Ball(Ball :BasePart)

    local Sphere

    
    if not Ball or Ball:IsA("BasePart") then
        warn("There is no custom ball. Creating defualt ball.")

        Sphere = Instance.new("Part")
        Sphere.Color = Color3.fromRGB(255, 255, 255)
        Sphere.Material = Enum.Material.SmoothPlastic
        Sphere.Shape = Enum.PartType.Ball
        Sphere.Anchored = true
        Sphere.CanCollide = false
        Sphere.CanQuery = false
        Sphere.CanTouch = false
        Sphere.CastShadow = false
        Sphere.Transparency = 0.75
        Sphere.Parent = workspace

        local AgentRadius = Pathfinding_Beam_Generator.Agent_Parameters.AgentRadius
        Sphere.Size = Vector3.new(AgentRadius, AgentRadius, AgentRadius)


        local Light :PointLight = Instance.new("PointLight")
        Light.Parent = Sphere
        Light.Color = Color3.fromRGB(255, 255, 255)
        Light.Brightness = 5
        Light.Shadows = true
        Light.Range = 30

    else

        Sphere = Ball:Clone()

    end

    return Sphere
end


-- Function to get path
function Pathfinding_Beam_Generator:Find_Path(Player :Player, Goal :Vector3)

    local Path = PathfindingService:CreatePath(self.Agent_Parameters)

    if not Player.Character then
        
        Player.CharacterAdded:Wait()

    end

    local Character = Player.Character

    Path:ComputeAsync(Character.HumanoidRootPart.Position, Goal)

    return Path
end


-- Function to create beam
function Pathfinding_Beam_Generator:Create_Beams(Path :Path)

    local Instances_Folder = Instance.new("Folder")
    Instances_Folder.Parent = workspace

    local Waypoints = Path:GetWaypoints()

    local General_Settings = Pathfinding_Beam_Generator.General_Settings
    local Beams_Height_From_Ground = General_Settings.Beams_Height_From_Ground

    for i = 2, #Waypoints - 1 do

        local Start_Part = Instance.new("Part")
        Start_Part.Size = Vector3.new(1,1,1)
        Start_Part.Anchored = true
        Start_Part.Parent = Instances_Folder
        Start_Part.Position = Waypoints[i].Position + Vector3.new(0, Beams_Height_From_Ground, 0)
        Start_Part.CanCollide = false
        Start_Part.CanQuery = false
        Start_Part.CanTouch = false

        local End_Part = Instance.new("Part")
        End_Part.Size = Vector3.new(1,1,1)
        End_Part.Anchored = true
        End_Part.Parent = Instances_Folder
        End_Part.Position = Waypoints[i + 1].Position + Vector3.new(0, Beams_Height_From_Ground, 0)
        End_Part.CanCollide = false
        End_Part.CanQuery = false
        End_Part.CanTouch = false

        Start_Part.Transparency, End_Part.Transparency = 1, 1

        local Start_Part_Attachment = Instance.new("Attachment")
        Start_Part_Attachment.Parent = Start_Part

        local End_Part_Attachment = Instance.new("Attachment")
        End_Part_Attachment.Parent = End_Part

        local Beam = Instance.new("Beam")
        Beam.Attachment0 = Start_Part_Attachment
        Beam.Attachment1 = End_Part_Attachment
        Beam.Parent = Start_Part

        CustomizeBeam(Beam)

    end

    if Current_Path_Folder then
        Current_Path_Folder:Destroy()
    end

    Current_Path_Folder = Instances_Folder

end

-- Function that guides the player and recreates beams only for changed waypoints
function Pathfinding_Beam_Generator:Guide_Player(Player :Player, Goal :Vector3)

    local Path = self:Find_Path(Player, Goal)
    self:Create_Beams(Path)
    self:Get_Character_Infos(Player)
    task.delay(3, function()
        self:Send_Info_Ball(Path, nil)
    end)

    if not table.find(Pathfinding_Beam_Generator.Players_That_Has_Path, Player.UserId) then
        table.insert(Pathfinding_Beam_Generator.Players_That_Has_Path, Player.UserId)
    end

    if not Player.Character then
        Player.CharacterAdded:Wait()
    end

    local Previous_Waypoints = Path:GetWaypoints()

    self.Connection = RunService:BindToRenderStep("Recreate_Beams",301,function()

        local New_Path = self:Find_Path(Player, Goal)
        local New_Waypoints = New_Path:GetWaypoints()

        -- Check if waypoints count is not the same, then recreate all beams
        if #New_Waypoints ~= #Previous_Waypoints then
            self:Create_Beams(New_Path)
            --print("recrated all beams due to waypoint count change")
        else
            -- Check if any waypoint has been changed
            for i=1, #New_Waypoints do
                if New_Waypoints[i].Position ~= Previous_Waypoints[i].Position then
                    self:Create_Beams(New_Path)
                    --print("recreated beams due to waypoint change")
                    break
                end
            end
        end

        -- Save the current waypoints for the next comparison
        Previous_Waypoints = New_Waypoints

    end)
end


function Pathfinding_Beam_Generator:Get_Character_Infos(Player :Player)

    local Character = Player.Character or Player.CharacterAdded:Wait()

    local Orientation, Size :Vector3 = Character:GetBoundingBox()

    self.Agent_Parameters.AgentRadius = Size.X
    self.Agent_Parameters.AgentHeight = Size.Y

end


function Pathfinding_Beam_Generator:Destroy_Player_Path(Player :Player)

    if table.find(Pathfinding_Beam_Generator.Players_That_Has_Path, Player.UserId) then

        self.Connection:Disconnect()
        self.Info_Ball:Destroy()
        Pathfinding_Beam_Generator.Players_That_Has_Path[Player.UserId] = nil

    end

end


function Pathfinding_Beam_Generator:Send_Info_Ball(Path :Path, Ball :BasePart)

    local Waypoints = Path:GetWaypoints()

    task.spawn(function()

        local Spawn_Waypoint = Waypoints[1]
        local Info_Ball = Create_Info_Ball(Ball)
        Info_Ball.Position = Spawn_Waypoint.Position

        self.Info_Ball = Info_Ball

        for i = 1, #Waypoints - 1 do

            if not Info_Ball then
                return
            end

            if not Waypoints[i + 1] then
                
                local Fade_In_Tween = TweenService:Create(
                    Info_Ball, 
                    TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0),
                    {Transparency = 1}
                )

                Fade_In_Tween:Play()

                Fade_In_Tween.Completed:Once(function()
                    Info_Ball:Destroy()
                end)

            end


            local Goal_Waypoint = Waypoints[i + 1]
            local Start_Waypoint = Waypoints[i]
            local Tween_Time = (Start_Waypoint.Position - Goal_Waypoint.Position).Magnitude / 15

            local General_Settings = Pathfinding_Beam_Generator.General_Settings
            local Beams_Height_From_Ground = General_Settings.Beams_Height_From_Ground
            local AgentRadius = Pathfinding_Beam_Generator.Agent_Parameters.AgentRadius

            local Tween_Info = TweenInfo.new(Tween_Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)

            local Tween = TweenService:Create(Info_Ball, Tween_Info, {Position = Goal_Waypoint.Position + Vector3.new(0, Beams_Height_From_Ground + AgentRadius, 0) })
            Tween:Play()

            Tween.Completed:Wait()

        end

    end)

end



return Pathfinding_Beam_Generator   