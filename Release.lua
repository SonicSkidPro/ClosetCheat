local Athena = {functions = {}}

local Vector2New, Cam, Mouse, client, find, Draw, Inset, players, RunService, UIS=
    Vector2.new,
    workspace.CurrentCamera,
    game.Players.LocalPlayer:GetMouse(),
    game.Players.LocalPlayer,
    table.find,
    Drawing.new,
    game:GetService("GuiService"):GetGuiInset().Y,
    game.Players, 
    game.RunService,
    game:GetService("UserInputService")


local mf, rnew = math.floor, Random.new

local Targetting
local lockedCamTo

local Circle = Draw("Circle")
Circle.Thickness = 1
Circle.Transparency = 0.7
Circle.Color = Color3.new(1,1,1)

Athena.functions.update_FOVs = function ()
    if not (Circle) then
        return Circle
    end
    Circle.Radius =  getgenv().Athena.SilentAim.FOVData.Radius * 3
    Circle.Visible = getgenv().Athena.SilentAim.FOVData.Visibility
    Circle.Filled = getgenv().Athena.SilentAim.FOVData.Filled
    Circle.Position = Vector2New(Mouse.X, Mouse.Y + (Inset))
    return Circle
end

    if inputObject.KeyCode == Enum.KeyCode[getgenv().Athena.Tracing.Key:upper()] then
        getgenv().Athena.Tracing.Enabled = not getgenv().Athena.Tracing.Enabled
        if getgenv().Athena.Tracing.Enabled then
            lockedCamTo = Athena.functions.returnClosestPlayer(getgenv().Athena.SilentAim.ChanceData.Chance)
        end
    end
end

UIS.InputBegan:Connect(Athena.functions.onKeyPress)


Athena.functions.wallCheck = function(direction, ignoreList)
    if not getgenv().Athena.SilentAim.AimingData.CheckWalls then
        return true
    end

    local ray = Ray.new(Cam.CFrame.p, direction - Cam.CFrame.p)
    local part, _, _ = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, ignoreList)

    return not part
end

Athena.functions.pointDistance = function(part)
    local OnScreen = Cam.WorldToScreenPoint(Cam, part.Position)
    if OnScreen then
        return (Vector2New(OnScreen.X, OnScreen.Y) - Vector2New(Mouse.X, Mouse.Y)).Magnitude
    end
end

Athena.functions.returnClosestPart = function(Character)
    local data = {
        dist = math.huge,
        part = nil,
        filteredparts = {},
        classes = {"Part", "BasePart", "MeshPart"}
    }

    if not (Character and Character:IsA("Model")) then
        return data.part
    end
    local children = Character:GetChildren()
    for _, child in pairs(children) do
        if table.find(data.classes, child.ClassName) then
            table.insert(data.filteredparts, child)
            for _, part in pairs(data.filteredparts) do
                local dist = Athena.functions.pointDistance(part)
                if Circle.Radius > dist and dist < data.dist then
                    data.part = part
                    data.dist = dist
                end
            end
        end
    end
    return data.part
end

Athena.functions.returnClosestPlayer = function (amount)
    local data = {
        dist = 1/0,
        player = nil
    }

    amount = amount or nil

    for _, player in pairs(players:GetPlayers()) do
        if (player.Character and player ~= client) then
            local dist = Athena.functions.pointDistance(player.Character.HumanoidRootPart)
            if Circle.Radius > dist and dist < data.dist and 
            Athena.functions.wallCheck(player.Character.Head.Position,{client, player.Character}) then
                data.dist = dist
                data.player = player
            end
        end
    end
    local calc = mf(rnew().NextNumber(rnew(), 0, 1) * 100) / 100
    local use = getgenv().Athena.SilentAim.ChanceData.UseChance
    if use and calc <= mf(amount) / 100 then
        return calc and data.player
    else
        return data.player
    end
end

Athena.functions.setAimingType = function (player, type)
    local previousSilentAimPart = getgenv().Athena.SilentAim.AimPart
    local previousTracingPart = getgenv().Athena.Tracing.AimPart
    if type == "Closest Part" then
        getgenv().Athena.SilentAim.AimPart = tostring(Athena.functions.returnClosestPart(player.Character))
        getgenv().Athena.Tracing.AimPart = tostring(Athena.functions.returnClosestPart(player.Character))
    elseif type == "Closest Point" then
        Athena.functions.returnClosestPoint()
    elseif type == "Default" then
        getgenv().Athena.SilentAim.AimPart = previousSilentAimPart
        getgenv().Athena.Tracing.AimPart = previousTracingPart
    else
        getgenv().Athena.SilentAim.AimPart = previousSilentAimPart
        getgenv().Athena.Tracing.AimPart = previousTracingPart
    end
end

Athena.functions.aimingCheck = function (player)
    if getgenv().Athena.SilentAim.AimingData.CheckKnocked == true and player and player.Character then
        if player.Character.BodyEffects["K.O"].Value then
            return true
        end
    end
    if getgenv().Athena.SilentAim.AimingData.CheckGrabbed == true and player and player.Character then
        if player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            return true
        end
    end
    return false
end


local lastRender = 0
local interpolation = 0.01

RunService.RenderStepped:Connect(function(delta)
    local valueTypes = 1.375
    lastRender = lastRender + delta
    while lastRender > interpolation do
        lastRender = lastRender - interpolation
    end
    if getgenv().Athena.Tracing.Enabled and lockedCamTo ~= nil and getgenv().Athena.Tracing.TracingOptions.Strength == "Hard" then
        local Vel =  lockedCamTo.Character[getgenv().Athena.Tracing.AimPart].Velocity / (getgenv().Athena.Tracing.Prediction * valueTypes)
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().Athena.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().Athena.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Athena.functions.setAimingType(lockedCamTo, getgenv().Athena.Tracing.TracingOptions.AimingType)
    elseif getgenv().Athena.Tracing.Enabled and lockedCamTo ~= nil and getgenv().Athena.Tracing.TracingOptions.Strength == "Soft" then
        local Vel =  lockedCamTo.Character[getgenv().Athena.Tracing.AimPart].Velocity / (getgenv().Athena.Tracing.Prediction / valueTypes)
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().Athena.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().Athena.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Athena.functions.setAimingType(lockedCamTo, getgenv().Athena.Tracing.TracingOptions.AimingType)
    else

    end
end)

task.spawn(function ()
    while task.wait() do
        if Targetting then
            Athena.functions.setAimingType(Targetting, getgenv().Athena.SilentAim.AimingType)
        end
        Athena.functions.update_FOVs()
    end
end)


local __index
__index = hookmetamethod(game,"__index", function(Obj, Property)
    if Obj:IsA("Mouse") and Property == "Hit" then
        Targetting = Athena.functions.returnClosestPlayer(getgenv().Athena.SilentAim.ChanceData.Chance)
        if Targetting ~= nil and getgenv().Athena.SilentAim.Enabled and not Athena.functions.aimingCheck(Targetting) then
            local currentvelocity = Targetting.Character[getgenv().Athena.SilentAim.AimPart].Velocity
            local currentposition = Targetting.Character[getgenv().Athena.SilentAim.AimPart].CFrame

            return currentposition + (currentvelocity * getgenv().Athena.SilentAim.Prediction)
        end
    end
    return __index(Obj, Property)
end)


getgenv().Desync = true
getgenv().KeyBind = Enum.KeyCode.L

local uis = game:service'UserInputService'





uis.InputBegan:Connect(
    function(a, t)
        if not t then
            if a.KeyCode == getgenv().KeyBind and getgenv().Desync == false then
                getgenv().Desync = true
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Athena Desync";
                    Text = "on";
                    Duration = 3.5;
                    })
                elseif a.KeyCode == getgenv().KeyBind and getgenv().Desync == true then
                getgenv().Desync = false
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Athena Desync";
                    Text = "off";
                    Duration = 3.5;
                    })
            end
        end
end)






game:GetService("RunService").heartbeat:Connect(function()
    if getgenv().Desync == true then
    local DesyncValue = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(getgenv().Athena.Misc.X,getgenv().Athena.Misc.Y,getgenv().Athena.Misc.Z) * (2^16)
    game:GetService("RunService").RenderStepped:Wait()
    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = DesyncValue
    end
end)

if getgenv().Athena.Misc.Desync == true then
    getgenv().KeyBind = getgenv().Athena.Misc.DesyncKeyBind
end

if getgenv().Athena.Misc.CSHeadless == true then
    game.Players.LocalPlayer.Character.Head.Transparency = 1
game.Players.LocalPlayer.Character.Head.Transparency = 1
for i,v in pairs(game.Players.LocalPlayer.Character.Head:GetChildren()) do
if (v:IsA("Decal")) then
v.Transparency = 1
end
end
end

if getgenv().Athena.Misc.CSKorblox == true then
    local ply = game.Players.LocalPlayer
local chr = ply.Character
chr.RightLowerLeg.MeshId = "902942093"
chr.RightLowerLeg.Transparency = "1"
chr.RightUpperLeg.MeshId = "http://www.roblox.com/asset/?id=902942096"
chr.RightUpperLeg.TextureID = "http://roblox.com/asset/?id=902843398"
chr.RightFoot.MeshId = "902942089"
chr.RightFoot.Transparency = "1"
end

spawn(function()
if getgenv().Athena.Misc.GalaxyRevolver == true then
    if game.Players.LocalPlayer.Character["[Revolver]"] or game.Players.LocalPlayer.Backpack["[Revolver"] then
        spawn(function()
            game.Players.LocalPlayer.Character["[Revolver]"].Default.TextureID = "rbxassetid://9370936730"
            game.Players.LocalPlayer.Backpack["[Revolver"].Default.TextureID = "rbxassetid://9370936730"
        end)
    end
end
end)

spawn(function()
if getgenv().Athena.Misc.BulletTracers == true then
BulletColor = true
bullet_tracer_color = Color3.fromRGB(0, 0, 255)
function GetGun()
    if game.Players.LocalPlayer.Character then
        for i, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
            if v:FindFirstChild 'Ammo' then
                return v
            end
        end
    end
    return nil
end

local Services = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
}

local Local = {
    Player = Services.Players.LocalPlayer,
    Mouse = Services.Players.LocalPlayer:GetMouse(),
}
local Other = {
    Camera = workspace.CurrentCamera,
    BeamPart = Instance.new("Part", workspace)
}

Other.BeamPart.Name = "BeamPart"
Other.BeamPart.Transparency = 1
local Settings = {
    StartColor = MainAccentColor,
    EndColor = MainAccentColor,
    StartWidth = 4,
    EndWidth = 4,
    ShowImpactPoint = true,
    ImpactTransparency = 0.2,
    ImpactColor = Color3.new(1, 1, 1),
    Time = 0.435,
}
game:GetService "RunService".Heartbeat:Connect(function()
    if game:GetService("Workspace").Ignored:FindFirstChild 'BULLET_RAYS' and BulletColor then
        game:GetService("Workspace").Ignored.BULLET_RAYS:Destroy()
    end
end)
local funcs = {}
Local.Mouse.TargetFilter = Other.BeamPart
function funcs:Beam(v1, v2)
    v2 = Vector3.new(v2.X - 0.1, v2.Y + 0.2, v2.Z)
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, bullet_tracer_color),
        ColorSequenceKeypoint.new(1, bullet_tracer_color),
    })
    local Part = Instance.new("Part", Other.BeamPart)
    Part.Size = Vector3.new(0, 0, 0)
    Part.Massless = true
    Part.Transparency = 1
    Part.CanCollide = false
    Part.Position = v1
    Part.Anchored = true
    local Attachment = Instance.new("Attachment", Part)
    local Part2 = Instance.new("Part", Other.BeamPart)
    Part2.Size = Vector3.new(0, 0, 0)
    Part2.Transparency = 0
    Part2.CanCollide = false
    Part2.Position = v2
    Part2.Anchored = true
    Part2.Material = Enum.Material.Plastic
    Part2.Color = Settings.ImpactColor
    Part2.Massless = true
    local Attachment2 = Instance.new("Attachment", Part2)
    local Beam = Instance.new("Beam", Part)
    Beam.FaceCamera = true
    Beam.Color = colorSequence
    Beam.Attachment0 = Attachment
    Beam.Attachment1 = Attachment2
    Beam.LightEmission = 6
    Beam.LightInfluence = 1
    Beam.Width0 = 0.05
    Beam.Width1 =  0.05
    Beam.Texture = "http://www.roblox.com/asset/?id=5210472215"
    Beam.TextureSpeed = 0
    Beam.TextureLength = 0
    delay(Settings.Time, function()
        Part:Destroy()
        Part2:Destroy()
    end)
end

spawn(function()
    while task.wait(0.5) do
        gun = GetGun()
        if gun then
            LastAmmo = gun.Ammo.Value
            gun.Ammo:GetPropertyChangedSignal("Value"):Connect(function()
                if BulletColor and gun.Ammo.Value < LastAmmo then
                    LastAmmo = gun.Ammo.Value
                    funcs:Beam(gun.Handle.Position, Local.Mouse.hit.p)
                end
            end)
        end
    end
end)
end
end)

spawn(function()
if getgenv().Athena.Misc.FEFat == true then
    game.Players.LocalPlayer.Character.Humanoid.BodyDepthScale:Destroy()
    game.Players.LocalPlayer.Character.Humanoid.BodyWidthScale:Destroy()
end
end)

spawn(function()
if getgenv().Athena.Misc.AnimationChanger == true then
    game.Players.LocalPlayer.Character.Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616163682"
game.Players.LocalPlayer.Character.Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=707829716"
game.Players.LocalPlayer.Character.Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=656117878"
end
end)

spawn(function()
if getgenv().Athena.Misc.AnimationGamepass == true then
    repeat
        wait()
    until game:IsLoaded() and game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lean") then
        game.ReplicatedStorage.ClientAnimations.Lean:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lay") then
        game.ReplicatedStorage.ClientAnimations.Lay:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance1") then
        game.ReplicatedStorage.ClientAnimations.Dance1:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance2") then
        game.ReplicatedStorage.ClientAnimations.Dance2:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Greet") then
        game.ReplicatedStorage.ClientAnimations.Greet:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Chest Pump") then
        game.ReplicatedStorage.ClientAnimations["Chest Pump"]:Destroy()
    end
    
    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Praying") then
        game.ReplicatedStorage.ClientAnimations.Praying:Destroy()
    end
    
    local Animations = game.ReplicatedStorage.ClientAnimations
    
    local LeanAnimation = Instance.new("Animation", Animations)
    LeanAnimation.Name = "Lean"
    LeanAnimation.AnimationId = "rbxassetid://3152375249"
    
    local LayAnimation = Instance.new("Animation", Animations)
    LayAnimation.Name = "Lay"
    LayAnimation.AnimationId = "rbxassetid://3152378852"
    
    local Dance1Animation = Instance.new("Animation", Animations)
    Dance1Animation.Name = "Dance1"
    Dance1Animation.AnimationId = "rbxassetid://3189773368"
    
    local Dance2Animation = Instance.new("Animation", Animations)
    Dance2Animation.Name = "Dance2"
    Dance2Animation.AnimationId = "rbxassetid://3189776546"
    
    local GreetAnimation = Instance.new("Animation", Animations)
    GreetAnimation.Name = "Greet"
    GreetAnimation.AnimationId = "rbxassetid://3189777795"
    
    local ChestPumpAnimation = Instance.new("Animation", Animations)
    ChestPumpAnimation.Name = "Chest Pump"
    ChestPumpAnimation.AnimationId = "rbxassetid://3189779152"
    
    local PrayingAnimation = Instance.new("Animation", Animations)
    PrayingAnimation.Name = "Praying"
    PrayingAnimation.AnimationId = "rbxassetid://3487719500"
    
    function AnimationPack(Character)
        Character:WaitForChild'Humanoid'
        repeat
            wait()
        until game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
    
        local AnimationPack = game:GetService("Players").LocalPlayer.PlayerGui.MainScreenGui.AnimationPack
        local ScrollingFrame = AnimationPack.ScrollingFrame
        local CloseButton = AnimationPack.CloseButton
    
        local Lean = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LeanAnimation)
    
        local Lay = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LayAnimation)
    
        local Dance1 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance1Animation)
    
        local Dance2 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance2Animation)
    
        local Greet = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(GreetAnimation)
    
        local ChestPump = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(ChestPumpAnimation)
    
        local Praying = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(PrayingAnimation)
    
        AnimationPack.Visible = true
    
        AnimationPack.ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Lean" then
                    v.Name = "LeanButton"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Lay" then
                    v.Name = "LayButton"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Dance1" then
                    v.Name = "Dance1Button"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Dance2" then
                    v.Name = "Dance2Button"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Greet" then
                    v.Name = "GreetButton"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Chest Pump" then
                    v.Name = "ChestPumpButton"
                end
            end
        end
    
        for i,v in pairs(ScrollingFrame:GetChildren()) do
            if v.Name == "TextButton" then
                if v.Text == "Praying" then
                    v.Name = "PrayingButton"
                end
            end
        end
    
        function Stop()
            Lean:Stop()
            Lay:Stop()
            Dance1:Stop()
            Dance2:Stop()
            Greet:Stop()
            ChestPump:Stop()
            Praying:Stop()
        end
    
        local LeanTextButton = ScrollingFrame.LeanButton
        local LayTextButton = ScrollingFrame.LayButton
        local Dance1TextButton = ScrollingFrame.Dance1Button
        local Dance2TextButton = ScrollingFrame.Dance2Button
        local GreetTextButton = ScrollingFrame.GreetButton
        local ChestPumpTextButton = ScrollingFrame.ChestPumpButton
        local PrayingTextButton = ScrollingFrame.PrayingButton
    
        AnimationPack.MouseButton1Click:Connect(function()
            if ScrollingFrame.Visible == false then
                ScrollingFrame.Visible = true
                CloseButton.Visible = true
            end
        end)
        CloseButton.MouseButton1Click:Connect(function()
            if ScrollingFrame.Visible == true then
                ScrollingFrame.Visible = false
                CloseButton.Visible = false
            end
        end)
        LeanTextButton.MouseButton1Click:Connect(function()
            Stop()
            Lean:Play()
        end)
        LayTextButton.MouseButton1Click:Connect(function()
            Stop()
            Lay:Play()
        end)
        Dance1TextButton.MouseButton1Click:Connect(function()
            Stop()
            Dance1:Play()
        end)
        Dance2TextButton.MouseButton1Click:Connect(function()
            Stop()
            Dance2:Play()
        end)
        GreetTextButton.MouseButton1Click:Connect(function()
            Stop()
            Greet:Play()
        end)
        ChestPumpTextButton.MouseButton1Click:Connect(function()
            Stop()
            ChestPump:Play()
        end)
        PrayingTextButton.MouseButton1Click:Connect(function()
            Stop()
            Praying:Play()
        end)
    
        game:GetService("Players").LocalPlayer.Character.Humanoid.Running:Connect(function()
            Stop()
        end)
    
        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
            Stop()
        end)
    end
    AnimationPack(game.Players.LocalPlayer.Character)
    game.Players.LocalPlayer.CharacterAdded:Connect(AnimationPack)
end
end)


