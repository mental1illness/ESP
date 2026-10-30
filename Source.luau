--@ Services

local HttpService = cloneref(Game:GetService("HttpService"))
local RunService  = Game:GetService("RunService")
local Players     = Game:GetService("Players")

--@ Variables

local Camera      = workspace.CurrentCamera
const Corners = {
    {1, 1, 1},
    {-1, 1, 1},
    {1, 1, -1},
    {-1, 1, -1},
    {1, -1, 1},
    {-1, -1, 1},
    {1, -1, -1},
    {-1, -1, -1}
}
local Player      = Players.LocalPlayer

local ESP = {
    Enabled = true, -- (master(psst'kashou') toggle)

    BoundingBox = { -- Draws a box around a player.
        Enabled     = true,

        ColorTop    = Color3.fromRGB(100, 100, 100), -- yes this is gradient slop, shut up.
        ColorBottom = Color3.fromRGB(255, 255, 255),

        Style       = "Full", -- You can pick "Full" or "Dropshadow".

        Filled = { -- Draws a frame inside the bounding box, filling the insides (ay bor wtf is this explanation)
            Enabled      = true,

            ColorTop     = Color3.fromRGB(100, 100, 100),
            ColorBottom  = Color3.fromRGB(255, 255, 255),

            Transparency = 0.5
        }
    },

    Name = { -- Draws a text above the bounding box, it represents the player's name.
        Enabled = true,
        Color   = Color3.fromRGB(255, 255, 255)
    },

    HealthBar = { -- 
        Enabled = true,

        ColorTop     = Color3.fromRGB(131, 245, 78),
        ColorMiddle  = Color3.fromRGB(255, 255, 0),
        ColorBottom  = Color3.fromRGB(252, 71, 77),

        Style        = "Full", -- You can pick "Full" or "Dropshadow".
        Thickness    = 2
    },

    Cache    = {},
    Entities = {},
    Assets   = {
        Fonts = {
            -- ["ProggyClean.tff"] = Game:HttpGet("https://github.com/onichan-ren/framework/raw/refs/heads/main/resources/fonts/proggy-clean.ttf")
            ["ProggyCleanBold.tff"] = Game:HttpGet("https://github.com/mental1illness/ESP/raw/refs/heads/main/Assets/ProggyCleanBold.ttf"),
            ["ProggyClean.tff"] = Game:HttpGet("https://github.com/mental1illness/ESP/raw/refs/heads/main/Assets/ProggyClean.ttf"),
        }
    }
} do
    ESP.__index = ESP
    ESP.ScreenGui = Instance.new( "ScreenGui", gethui() or cloneref( Game:GetService("CoreGui") ) )
    ESP.ScreenGui.ZIndexBehavior = "Global"
    ESP.ScreenGui.IgnoreGuiInset = true

    --# Assets

    for Name, Byte in  ESP.Assets.Fonts do
        writefile(Name, Byte)

        local FontAsset = getcustomasset(Name)

        local Family = {
            name = Name,
            faces = {
                {
                    name    = Name,
                    weight  = 400,
                    style   = "normal",
                    assetId = FontAsset
                }
            }
        }

        writefile(Name .. ".json", HttpService:JSONEncode(Family))
        ESP.Assets.Fonts[Name] = Font.new(getcustomasset(Name .. ".json"))
    end

    --# Util

    function ESP:Create(Class : string, Properties : { [string]: any? })
        local Object = Instance.new(Class) -- I am not pcalling this, this is your issue if you can not even get the class name properly.
        
        do --@ Outlines

            local Outlines = Properties.Outlines
            if Outlines then
                Properties.Outlines = nil
    
                local Outline = Instance.new("UIStroke", Object); do
                    Outline.Thickness    = Outlines.Thickness or 1
                    Outline.BorderOffset = Outlines.Offset or UDim.new()
                    Outline.Transparency = Outlines.Transparency or 0
                    Outline.Color        = Outlines.Color or Color3.fromRGB(0, 0, 0)
                    Outline.LineJoinMode = Outlines.LineJoinMode or "Miter"
                end

            end

        end

        for Property, Value in Properties do
            Object[Property] = Value
        end

        do --@ Normalize

            if Object:IsA("GuiObject") then
                Object.BorderSizePixel = 0
                Object.Name = "\0"

                if Object.ClassName == "TextLabel" then
                    Object.TextStrokeTransparency = 1
                end
            end

        end

        return Object
    end

    function ESP:GetHealth(Model : Model)
        local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return 0, nil
        end

        return Humanoid.Health, Humanoid.MaxHealth
    end

    function ESP:GetBodyParts(Model : Model)
        local BodyParts = {}
        
        for _, Value in Model:QueryDescendants("BasePart, Bone") do
            table.insert(BodyParts, Value)
        end

        return BodyParts
    end

    function ESP:GetBoundingBox(BodyParts : { [any]: any })

        local LowestX,  HighestX = math.huge, -math.huge
        local LowestY,  HighestY = math.huge, -math.huge
        local OnScreen = false
    
        for _, Object in BodyParts do
    
            if not Object.Parent then
                continue
            end
    
            if Object:IsA("MeshPart") and gethiddenproperty(Object, "HasSkinnedMesh") then
    
                local Cache = ESP.Cache[Object]
    
                if not Cache then
                    local Success, EditableMesh = pcall(function()
                        return Game:GetService("AssetService"):CreateEditableMeshAsync(Object.MeshId)
                    end)
    
                    if Success and EditableMesh then
                        local Character     = Object:FindFirstAncestorOfClass("Model")
                        local BoneInstances = {}
    
                        for _, Bone in Character:GetDescendants() do
                            if Bone:IsA("Bone") then
                                BoneInstances[Bone.Name] = Bone
                            end
                        end
    
                        local BoneBounds = {}
    
                        for _, BoneId in EditableMesh:GetBones() do
                            local BoneName = EditableMesh:GetBoneName(BoneId)
                            local Bone     = BoneInstances[BoneName]
    
                            if Bone then
                                BoneBounds[BoneId] = {
                                    Instance = Bone,
                                    BindPose = EditableMesh:GetBoneCFrame(BoneId),
                                }
                            end
                        end
    
                        for _, VertexId in EditableMesh:GetVertices() do
                            local Position = EditableMesh:GetPosition(VertexId)
                            local Bones    = EditableMesh:GetVertexBones(VertexId)
                            local Weights  = EditableMesh:GetVertexBoneWeights(VertexId)
    
                            local BestBone, BestWeight
    
                            for Index, Weight in Weights do
                                if Weight > 0 and (not BestWeight or Weight > BestWeight) then
                                    BestBone   = Bones[Index]
                                    BestWeight = Weight
                                end
                            end
    
                            local Bound = BestBone and BoneBounds[BestBone]
    
                            if Bound and BestWeight >= 0.99 then
                                local LocalPos = Bound.BindPose:Inverse() * Position
    
                                if not Bound.Min then
                                    Bound.Min = LocalPos
                                    Bound.Max = LocalPos
                                else
                                    Bound.Min = Vector3.new(
                                        math.min(Bound.Min.X, LocalPos.X),
                                        math.min(Bound.Min.Y, LocalPos.Y),
                                        math.min(Bound.Min.Z, LocalPos.Z)
                                    )
                                    Bound.Max = Vector3.new(
                                        math.max(Bound.Max.X, LocalPos.X),
                                        math.max(Bound.Max.Y, LocalPos.Y),
                                        math.max(Bound.Max.Z, LocalPos.Z)
                                    )
                                end
                            end
                        end
    
                        Cache             = { Bones = BoneBounds }
                        ESP.Cache[Object] = Cache
                    end
                end
    
                if Cache then
                    for _, Bound in Cache.Bones do
                        if Bound.Min then
                            local Transform = Bound.Instance.TransformedWorldCFrame
                            local Min, Max  = Bound.Min, Bound.Max
    
                            for _, Signs in Corners do
                                local Position       = Transform * Vector3.new(
                                    Signs[1] > 0 and Max.X or Min.X,
                                    Signs[2] > 0 and Max.Y or Min.Y,
                                    Signs[3] > 0 and Max.Z or Min.Z
                                )
                                local Screen, Visible = Camera:WorldToViewportPoint(Position)
    
                                if Screen.Z > 0 then
                                    OnScreen = OnScreen or Visible
                                    LowestX  = math.min(LowestX,  Screen.X)
                                    HighestX = math.max(HighestX, Screen.X)
                                    LowestY  = math.min(LowestY,  Screen.Y)
                                    HighestY = math.max(HighestY, Screen.Y)
                                end
                            end
                        end
                    end
                end
    
            elseif Object:IsA("BasePart") and Object.Transparency < 0.99 then
    
                local CF   = Object.CFrame
                local Half = Object.Size * 0.5
    
                for _, Signs in Corners do
                    local Position       = CF * Vector3.new(
                        Half.X * Signs[1],
                        Half.Y * Signs[2],
                        Half.Z * Signs[3]
                    )
                    local Screen, Visible = Camera:WorldToViewportPoint(Position)
    
                    if Screen.Z > 0 then
                        OnScreen = OnScreen or Visible
                        LowestX  = math.min(LowestX,  Screen.X)
                        HighestX = math.max(HighestX, Screen.X)
                        LowestY  = math.min(LowestY,  Screen.Y)
                        HighestY = math.max(HighestY, Screen.Y)
                    end
                end
    
            end
        end
    
        if LowestX == math.huge then
            return 0, 0, 0, 0, false
        end
    
        return LowestX, HighestX, LowestY, HighestY, OnScreen
    
    end
    
    --# Funcs
    
    function ESP:Add(Property : { [string]: any? })
        if not Property.Model then return end

        local This = {
            Guy         = Property.Player, -- Optional (note)
            Model       = Property.Model, -- required

            BodyParts   = Property.BodyParts or {}, -- Optional, we can figure it out thru the model.
            Connections = {},

            Elements    = {}
        }
        This.BodyParts = Property.BodyParts or self:GetBodyParts(This.Model)

        do --@ Connections
            table.insert(This.Connections, This.Model.DescendantAdded:Connect(function(Descendant)
                if Descendant:IsA("BasePart") or Descendant:IsA("Bone") then
                    table.insert(This.BodyParts, Descendant)
                end
            end))

            table.insert(This.Connections, This.Model.DescendantRemoving:Connect(function(Descendant)
                if Descendant:IsA("BasePart") or Descendant:IsA("Bone") then
                    local Index = table.find(This.BodyParts, Descendant)
                    if Index then
                        table.remove(This.BodyParts, Index)
                    end
                end
            end))
        end

        do --@ Elements
            This.Elements.Holder = self:Create("Frame", { Parent = self.ScreenGui, BackgroundTransparency = 1 }); do
                

                do --@ Sides

                    
                    This.Elements.Top = self:Create("Frame", {
                        AnchorPoint = Vector2.new(0.5, 1),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        Name = "Top",
                        Parent = This.Elements.Holder,
                        Position = UDim2.new(0.5, 0, 0, -3),
                        Size = UDim2.new(1, 0, 0, 100),
                    })
                    
                    self:Create("UIListLayout", {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 1),
                        Parent = This.Elements.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    })
                    
                    This.Elements.Left = self:Create("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        Name = "Left",
                        Parent = This.Elements.Holder,
                        Position = UDim2.new(0, -3, 0.5, 0),
                        Size = UDim2.new(0, 100, 1, 0),
                    })
                    
                    self:Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        Padding = UDim.new(0, 1),
                        Parent = This.Elements.Left,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    })
                    
                    This.Elements.Right = self:Create("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        Name = "Right",
                        Parent = This.Elements.Holder,
                        Position = UDim2.new(1, 3, 0.5, 0),
                        Size = UDim2.new(0, 100, 1, 0),
                    })
                    
                    self:Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        Padding = UDim.new(0, 1),
                        Parent = This.Elements.Right,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    })
                    
                    This.Elements.Bottom = self:Create("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        Name = "Bottom",
                        Parent = This.Elements.Holder,
                        Position = UDim2.new(0.5, 0, 1, 3),
                        Size = UDim2.new(1, 0, 0, 100),
                    })
                    
                    self:Create("UIListLayout", {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 1),
                        Parent = This.Elements.Bottom,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    })                    
                end

                This.Elements.BoundingBoxHolder = self:Create("Frame", { Parent = This.Elements.Holder, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }); do --@ Bounding Box
                    
                    --# Full

                    This.Elements.FullBoundingBox = self:Create("Frame", { Parent = This.Elements.BoundingBoxHolder, Outlines = { Thickness = 3, Offset = UDim.new(0, -2) }, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }); do
                        This.Elements.FullBoundingBoxInline = self:Create("UIStroke", {
                            Color  = Color3.fromRGB(255, 255, 255),
                            BorderOffset = UDim.new(0, -1),
                            LineJoinMode = "Miter",
                            ZIndex = 5,
                            Parent = This.Elements.FullBoundingBox,
                        })

                        This.Elements.FullBoundingBoxGradient = self:Create("UIGradient", {
                            Color    = ColorSequence.new(ESP.BoundingBox.ColorTop, ESP.BoundingBox.ColorBottom),
                            Rotation = 90,
                            Parent   = This.Elements.FullBoundingBoxInline,
                        })
                    end

                    --# Drop Shadow

                    This.Elements.ShadowBoundingBox = self:Create("Frame", { Parent = This.Elements.BoundingBoxHolder, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }); do
                        This.Elements.ShadowBoundingBoxInline = self:Create("UIStroke", {
                            Color  = Color3.fromRGB(255, 255, 255),
                            LineJoinMode = "Miter",
                            ZIndex = 5,
                            Parent = This.Elements.ShadowBoundingBox,
                        })

                        self:Create("UIStroke", {
                            Color  = Color3.fromRGB(0, 0, 0),
                            LineJoinMode = "Miter",
                            Parent = self:Create("Frame", { Parent = This.Elements.ShadowBoundingBox, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Position = UDim2.new(0, 1, 0, 1), ZIndex = -5 }),
                        })

                        This.Elements.ShadowBoundingBoxGradient = self:Create("UIGradient", {
                            Color    = ColorSequence.new(ESP.BoundingBox.ColorTop, ESP.BoundingBox.ColorBottom),
                            Rotation = 90,
                            Parent   = This.Elements.ShadowBoundingBoxInline,
                        })
                    end

                    --# Filled

                    This.Elements.BoundingBoxFill = self:Create("Frame", { Parent = This.Elements.BoundingBoxHolder, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = ESP.BoundingBox.Filled.Transparency, ZIndex = -50 }); do
                        This.Elements.BoundingBoxFillGradient = self:Create("UIGradient", {
                            Color    = ColorSequence.new(ESP.BoundingBox.Filled.ColorTop, ESP.BoundingBox.Filled.ColorBottom),
                            Rotation = 90,
                            Parent   = This.Elements.BoundingBoxFill,
                        })
                    end

                end

                This.Elements.NameHolder   = self:Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = This.Elements.Top, Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1 })
                This.Elements.NameText          = self:Create("TextLabel", { BackgroundTransparency = 1, AutomaticSize = "XY", Parent = This.Elements.NameHolder, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -1), FontFace = ESP.Assets.Fonts["ProggyCleanBold.tff"], TextSize = 12, TextColor3 = ESP.Name.Color }) do
                    do --@ Shadow
                        This.Elements.NameTextShadow = self:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            AutomaticSize          = "XY",
                            Parent                 = This.Elements.NameHolder,
                            AnchorPoint            = Vector2.new(0.5, 0),
                            Position               = UDim2.new(0.5, 1, 0, 0),
                            FontFace               = ESP.Assets.Fonts["ProggyCleanBold.tff"],
                            TextSize               = 12,
                            TextColor3             = Color3.fromRGB(0, 0, 0),
                            ZIndex                 = This.Elements.Holder.ZIndex - 1,
                        })
                    end
                end

                This.Elements.HealthBarHolder   = self:Create("Frame", { BackgroundColor3 = Color3.fromRGB(50, 50, 50), Parent = This.Elements.Left, Size = UDim2.new(0, ESP.HealthBar.Thickness, 1, 0) }) do
                    This.Elements.HealthBarOutline = self:Create("UIStroke", {
                        Enabled = true,
                        Color  = Color3.fromRGB(0, 0, 0),
                        LineJoinMode = "Miter",
                        ZIndex = 5,
                        Parent = This.Elements.HealthBarHolder,
                    })

                    This.Elements.HealthBarShadow = self:Create("Frame", { 
                        BackgroundColor3  = Color3.fromRGB(0, 0, 0),
                        Visible = false,
                        ZIndex = -1,
                        Parent = This.Elements.HealthBarHolder,
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, 0, 1, 0) 
                    })

                    This.Elements.HealthBarFill = self:Create("Frame", {
                        BackgroundColor3  = Color3.fromRGB(255, 255, 255),
                        Parent = This.Elements.HealthBarHolder,
                        Size = UDim2.new(1, 0, 1, 0),
                        ZIndex = 1,
                        ClipsDescendants = true
                    })

                    This.Elements.HealthBarCover = self:Create("Frame", { 
                        BackgroundColor3  = Color3.fromRGB(50, 50, 50),
                        AnchorPoint = Vector2.new(1, 0),
                        Visible = true,
                        ZIndex = 5,
                        Parent = This.Elements.HealthBarFill,
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 0, 1, 0)
                    })

                    This.Elements.HealthBarFillGradient = self:Create("UIGradient", {
                        Color    = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.0, ESP.HealthBar.ColorTop),
                            ColorSequenceKeypoint.new(0.5, ESP.HealthBar.ColorMiddle),
                            ColorSequenceKeypoint.new(1.0, ESP.HealthBar.ColorBottom)
                        }),
                        Rotation = 90,
                        Parent   = This.Elements.HealthBarFill,
                    })
                end

            end
        end

        do --@ Funcs
            function This:Render(Delta : number)
                if not ESP.Enabled or not This.Model or not This.Model.Parent then
                    This.Elements.Holder.Visible = false
                    return
                end
            
                local LowestX, HighestX, LowestY, HighestY, OnScreen = ESP:GetBoundingBox(This.BodyParts)
            
                if not OnScreen then
                    This.Elements.Holder.Visible = false
                    return
                end
            
                local Width  = HighestX - LowestX
                local Height = HighestY - LowestY
            
                This.Elements.Holder.Visible  = true
                This.Elements.Holder.Position = UDim2.fromOffset(LowestX, LowestY)
                This.Elements.Holder.Size     = UDim2.fromOffset(Width, Height)

                if ESP.BoundingBox.Enabled then
                    if This.Elements.BoundingBoxHolder.Visible == true then This.Elements.BoundingBoxHolder.Visible = true end

                    if ESP.BoundingBox.Style == "Full" then
                        local ColorTop    = ESP.BoundingBox.ColorTop
                        local ColorBottom = ESP.BoundingBox.ColorBottom
                        local Keypoints   = This.Elements.FullBoundingBoxGradient.Color.Keypoints
                    
                        if Keypoints[1].Value ~= ColorTop or Keypoints[#Keypoints].Value ~= ColorBottom then
                            This.Elements.FullBoundingBoxGradient.Color = ColorSequence.new(ColorTop, ColorBottom)
                        end
                    
                        if This.Elements.FullBoundingBox.Visible   ~= true  then This.Elements.FullBoundingBox.Visible   = true  end
                        if This.Elements.ShadowBoundingBox.Visible ~= false then This.Elements.ShadowBoundingBox.Visible = false end
                    
                    elseif ESP.BoundingBox.Style == "Dropshadow" then
                        local ColorTop    = ESP.BoundingBox.ColorTop
                        local ColorBottom = ESP.BoundingBox.ColorBottom
                        local Keypoints   = This.Elements.ShadowBoundingBoxGradient.Color.Keypoints
                    
                        if Keypoints[1].Value ~= ColorTop or Keypoints[#Keypoints].Value ~= ColorBottom then
                            This.Elements.ShadowBoundingBoxGradient.Color = ColorSequence.new(ColorTop, ColorBottom)
                        end
                    
                        if This.Elements.ShadowBoundingBox.Visible ~= true  then This.Elements.ShadowBoundingBox.Visible = true  end
                        if This.Elements.FullBoundingBox.Visible   ~= false then This.Elements.FullBoundingBox.Visible   = false end
                    end

                    if ESP.BoundingBox.Filled.Enabled then
                        local ColorTop       = ESP.BoundingBox.Filled.ColorTop
                        local ColorBottom    = ESP.BoundingBox.Filled.ColorBottom
                        local Transparency   = ESP.BoundingBox.Filled.Transparency
                        local Keypoints      = This.Elements.BoundingBoxFillGradient.Color.Keypoints
                    
                        if Keypoints[1].Value ~= ColorTop or Keypoints[#Keypoints].Value ~= ColorBottom then
                            This.Elements.BoundingBoxFillGradient.Color = ColorSequence.new(ColorTop, ColorBottom)
                        end
                    
                        if This.Elements.BoundingBoxFill.BackgroundTransparency ~= Transparency then
                            This.Elements.BoundingBoxFill.BackgroundTransparency = Transparency
                        end
                    
                        if This.Elements.BoundingBoxFill.Visible ~= true then This.Elements.BoundingBoxFill.Visible = true end
                    else
                        if This.Elements.BoundingBoxFill.Visible ~= false then This.Elements.BoundingBoxFill.Visible = false end
                    end

                else
                    if This.Elements.BoundingBoxHolder.Visible ~= false then This.Elements.BoundingBoxHolder.Visible = false end
                end

                if ESP.HealthBar.Enabled then
                    if ESP.HealthBar.Style == "Full" then
                        if This.Elements.HealthBarOutline.Enabled ~= true then This.Elements.HealthBarOutline.Enabled = true end
                        if This.Elements.HealthBarShadow.Visible ~= false  then This.Elements.HealthBarShadow.Visible = false end

                        if This.Elements.HealthBarHolder.Size.Y.Offset ~= 0 then
                            This.Elements.HealthBarHolder.Size = UDim2.new(0, ESP.HealthBar.Thickness, 1, 0)
                        end
                    elseif ESP.HealthBar.Style == "Dropshadow" then
                        if This.Elements.HealthBarOutline.Enabled ~= false then This.Elements.HealthBarOutline.Enabled = false end
                        if This.Elements.HealthBarShadow.Visible ~= true  then This.Elements.HealthBarShadow.Visible = true end
                    
                        if This.Elements.HealthBarHolder.Size.Y.Offset ~= 2 then
                            This.Elements.HealthBarHolder.Size = UDim2.new(0, ESP.HealthBar.Thickness, 1, 2)
                        end
                    end

                    local Health, MaxHealth = ESP:GetHealth(This.Model)

                    if not MaxHealth then
                        if This.Elements.HealthBarHolder.Visible ~= false then
                            This.Elements.HealthBarHolder.Visible = false
                        end
                    else
                        local FillRatio = math.clamp(Health / MaxHealth, 0, 1)
                        local CoverRatio = 1 - FillRatio

                        if This.Elements.HealthBarHolder.Visible ~= true then
                            This.Elements.HealthBarHolder.Visible = true
                        end

                        local CoverSize = UDim2.new(1, 0, CoverRatio, 0)
                        if This.Elements.HealthBarCover.Size ~= CoverSize then
                            This.Elements.HealthBarCover.Size = CoverSize
                        end
                    end
                else
                    if This.Elements.HealthBarHolder.Visible ~= false then
                        This.Elements.HealthBarHolder.Visible = false
                    end
                end

                if ESP.Name.Enabled then -- beautiful code ik
                    local Elements = This.Elements
                    local Color    = ESP.Name.Color
                    local Text     = string.lower((This.Guy and This.Guy.Name) or This.Model.Name)
                    local Shift    = string.find(Text, "[gypjq]") and 0 or 3
                
                    if Elements.NameText.Text ~= Text then
                        Elements.NameText.Text           = Text
                        Elements.NameTextShadow.Text     = Text
                    end
                
                    if Elements.NameText.Position.Y.Offset ~= -1 + Shift then
                        Elements.NameText.Position           = UDim2.new(0.5, 0, 0, -1 + Shift)
                        Elements.NameTextShadow.Position     = UDim2.new(0.5, 1, 0, Shift)
                    end
                
                    if Elements.NameText.TextColor3 ~= Color then
                        Elements.NameText.TextColor3     = Color
                    end
                
                    if Elements.NameText.Visible ~= true then
                        Elements.NameText.Visible           = true
                        Elements.NameTextShadow.Visible     = true
                    end
                else
                    local Elements = This.Elements
                
                    if Elements.NameText.Visible ~= false then
                        Elements.NameText.Visible           = false
                        Elements.NameTextShadow.Visible     = false
                    end
                end

            end
        end

        self.Entities[This.Model] = This
    end

    function ESP:Remove(Model)
        local This = self.Entities[Model]
        if not This then return end
    
        for _, Connection in This.Connections do
            Connection:Disconnect()
        end
    
        This.Elements.Holder:Destroy()
        self.Entities[Model] = nil
    end

end

do --@ Render
    RunService.RenderStepped:Connect(function(DeltaTime)
        for Model, This in ESP.Entities do
            This:Render(DeltaTime)
        end
    end)
end

for Index, Value in Players:GetPlayers() do
    ESP:Add({ Model = Value.Character, Player = Value })
end
