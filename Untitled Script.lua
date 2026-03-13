local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TextChatService = game:GetService("TextChatService")
local VirtualInputManager = game:GetService("VirtualInputManager") 

local player = Players.LocalPlayer

if _G.ValeHubCleanup then pcall(_G.ValeHubCleanup) end
_G.ValeHubCleanup = function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        if pg:FindFirstChild("ValeHub_UGC") then pg.ValeHub_UGC:Destroy() end
        if pg:FindFirstChild("ESPFriendGui") then pg.ESPFriendGui:Destroy() end
    end
    if _G.EspBaseThread then _G.EspBaseThread:Disconnect() end
    if _G.PlayerEspConnection then _G.PlayerEspConnection:Disconnect() end
    if _G.AntiRagdollConnection then _G.AntiRagdollConnection:Disconnect() end 
    _G.espFriendLoop = false
    _G.ValeHubActive = false
end
pcall(_G.ValeHubCleanup)
_G.ValeHubActive = true

-- VARIABILI E SEQUENZE (Invariate)
local NEON_PURPLE   = Color3.fromRGB(157, 78, 221)
local ACCENT_PURPLE = Color3.fromRGB(123, 44, 177)
local BG_DARK       = Color3.fromRGB(12, 10, 18)
local BTN_DARK      = Color3.fromRGB(22, 18, 32)

local pos1, pos2 = Vector3.new(-352.98, -7, 74.30), Vector3.new(-352.98, -6.49, 45.76)
local spot1_sequence = {
    CFrame.new(-370.81, -7, 41.26, 0.99, 0, 0.01, 0, 1, 0, -0.01, 0, 0.99),
    CFrame.new(-336.35, -5.1, 17.23, -0.99, 0, 0.01, 0, 1, 0, -0.01, 0, -0.99)
}
local spot2_sequence = {
    CFrame.new(-354.78, -7, 92.82, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    CFrame.new(-336.94, -5.1, 99.32, 0.99, 0, 0.01, 0, 1, 0, -0.01, 0, 0.99)
}

local desyncActivated = false
local halfTpEnabled   = true 
local speedEnabled    = true 
local SPEED_VAL       = 28.5
local IsStealing      = false
local StealProgress   = 0
local allAnimalsCache = {}

RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    if speedEnabled then
        if hum.MoveDirection.Magnitude > 0 then
            hrp.Velocity = Vector3.new(hum.MoveDirection.X * SPEED_VAL, hrp.Velocity.Y, hum.MoveDirection.Z * SPEED_VAL)
        end
        
        local humState = hum:GetState()
        if humState == Enum.HumanoidStateType.Physics or humState == Enum.HumanoidStateType.Ragdoll or humState == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Running)
            workspace.CurrentCamera.CameraSubject = hum
            
            pcall(function()
                local PlayerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
                if PlayerModule then
                    local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                    Controls:Enable()
                end
            end)
            
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
        
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then 
                obj.Enabled = true 
            end
        end
    end
end)

local function getHRP()
    local char = player.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
end

local function respawnPlayer()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        char:ClearAllChildren()
        local f = Instance.new("Model", workspace)
        player.Character = f; task.wait(); player.Character = char; f:Destroy()
    end
end

local function applyFFlags()
    local flags = {
        {"GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000"},
        {"S2PhysicsSenderRate", "15000"},
        {"PhysicsSenderMaxBandwidthBps", "20000"}
    }
    for _, data in ipairs(flags) do pcall(function() if setfflag then setfflag(data[1], data[2]) end end) end
end

local misc = { espFriendGuis = {} }
local connections = { espFriendConnections = {} }
_G.espFriendLoop = true

local function updateFriendESP(mainPart, imageLabel)
    if misc.espFriendGuis[mainPart] then
        local label = misc.espFriendGuis[mainPart].label
        local imageId = string.match(imageLabel.Image, "(%d+)") or ""
        if imageId == "110783679426495" then
            label.Image = "rbxassetid://110783679426495"; label.ImageColor3 = Color3.new(1, 0, 0)
        elseif imageId == "110507824065923" then
            label.Image = "rbxassetid://110507824065923"; label.ImageColor3 = Color3.new(0, 1, 0)
        else
            label.Image = ""
        end
    end
end

local function createFriendESP(mainPart, imageLabel)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_FriendPanel"; gui.Adornee = mainPart; gui.Size = UDim2.new(0, 180, 0, 180); gui.StudsOffset = Vector3.new(0, 3, 0); gui.AlwaysOnTop = true; gui.Parent = mainPart
    local label = Instance.new("ImageLabel")
    label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.ScaleType = Enum.ScaleType.Fit; label.Parent = gui
    misc.espFriendGuis[mainPart] = { gui = gui, label = label }
    updateFriendESP(mainPart, imageLabel)
    local conn = imageLabel:GetPropertyChangedSignal("Image"):Connect(function() updateFriendESP(mainPart, imageLabel) end)
    table.insert(connections.espFriendConnections, conn)
    misc.espFriendGuis[mainPart].connection = conn
end

local espObjects = {}
local function UpdatePlayerESP()
    for _, obj in pairs(espObjects) do if obj and obj.Parent then obj:Destroy() end end
    espObjects = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local hrp = char.HumanoidRootPart
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = hrp; box.Size = Vector3.new(4, 6, 2); box.Color3 = Color3.fromRGB(255, 50, 50); box.Transparency = 0.3; box.AlwaysOnTop = true; box.Parent = char; table.insert(espObjects, box)
            local bill = Instance.new("BillboardGui")
            bill.Adornee = char:FindFirstChild("Head") or hrp; bill.Size = UDim2.new(0, 200, 0, 50); bill.StudsOffset = Vector3.new(0, 3, 0); bill.AlwaysOnTop = true; bill.Parent = char; table.insert(espObjects, bill)
            local label = Instance.new("TextLabel", bill)
            label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(255, 50, 50); label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.TextStrokeTransparency = 0
            local dist = math.floor((hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude)
            label.Text = plr.Name .. " [" .. dist .. "m]"
        end
    end
end

local baseEspInstances = {}
local function updateBaseESP()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local mainPart = plot:FindFirstChild("Purchases") and plot.Purchases:FindFirstChild("PlotBlock") and plot.Purchases.PlotBlock:FindFirstChild("Main")
        local timeLabel = mainPart and mainPart:FindFirstChild("BillboardGui") and mainPart.BillboardGui:FindFirstChild("RemainingTime")
        if timeLabel and mainPart then
            local billboard = baseEspInstances[plot.Name]
            if not billboard then
                billboard = Instance.new("BillboardGui", plot)
                billboard.Size = UDim2.new(0, 50, 0, 25); billboard.AlwaysOnTop = true; billboard.Adornee = mainPart
                local l = Instance.new("TextLabel", billboard); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.TextScaled = true; l.Font = Enum.Font.Arcade; l.TextColor3 = Color3.new(1,1,0); l.TextStrokeTransparency = 0
                baseEspInstances[plot.Name] = billboard
            end
            billboard.TextLabel.Text = timeLabel.Text
        end
    end
end

local function executeSteal(sequence)
    if IsStealing or not desyncActivated then return end
    local hrp = getHRP()
    if not hrp then return end
    
    local nearest, dist = nil, 200
    for _, animal in ipairs(allAnimalsCache) do
        local d = (hrp.Position - animal.worldPosition).Magnitude
        if d < dist then dist = d; nearest = animal end
    end
    if not nearest then return end
    
    local podium = workspace.Plots[nearest.plot].AnimalPodiums[nearest.slot]
    local prompt = podium.Base.Spawn.PromptAttachment:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

    IsStealing = true
    task.spawn(function()
        local backpack = player:FindFirstChild("Backpack")
        local carpet = player.Character:FindFirstChild("Flying Carpet") or (backpack and backpack:FindFirstChild("Flying Carpet"))
        if carpet then player.Character.Humanoid:EquipTool(carpet) end
        
        hrp.CFrame = sequence[1]
        StealProgress = 0.3
        task.wait(0.1)
        
        hrp.CFrame = sequence[2]
        StealProgress = 0.6
        task.wait(0.41)
        
        if prompt then 
            fireproximityprompt(prompt) 
        end
        
        task.wait(0.3)
        
        local d1, d2 = (hrp.Position - pos1).Magnitude, (hrp.Position - pos2).Magnitude
        hrp.CFrame = CFrame.new(d1 < d2 and pos1 or pos2)
        
        StealProgress = 1
        task.wait(0.05)
        IsStealing = false
        StealProgress = 0
    end)
end

-- GUI Setup
local sg = Instance.new("ScreenGui", player.PlayerGui); sg.Name = "ValeHub_UGC"; sg.ResetOnSpawn = false
local main = Instance.new("Frame", sg); main.Size = UDim2.new(0, 200, 0, 300); main.Position = UDim2.new(0.5, -100, 0.5, -150); main.BackgroundColor3 = BG_DARK; main.BackgroundTransparency = 0.1; main.ClipsDescendants = true; Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12); local stroke = Instance.new("UIStroke", main); stroke.Color = NEON_PURPLE; stroke.Thickness = 2

local dragToggle, dragStart, startPos
main.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = true; dragStart = input.Position; startPos = main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart; main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = false end end)

local topBar = Instance.new("Frame", main); topBar.Size = UDim2.new(1, 0, 0, 40); topBar.BackgroundTransparency = 1
local title = Instance.new("TextLabel", topBar); title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.new(0, 10, 0, 0); title.Text = "ValeHub🌺"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = "Left"; title.BackgroundTransparency = 1

local minBtn = Instance.new("TextButton", topBar); minBtn.Size = UDim2.new(0, 28, 0, 28); minBtn.Position = UDim2.new(1, -33, 0, 6); minBtn.Text = "-"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); minBtn.Font = Enum.Font.GothamBold; Instance.new("UICorner", minBtn)

local content = Instance.new("Frame", main); content.Size = UDim2.new(1, 0, 1, -45); content.Position = UDim2.new(0, 0, 0, 45); content.BackgroundTransparency = 1

local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 200, 0, 40) or UDim2.new(0, 200, 0, 300)
    minBtn.Text = isMinimized and "+" or "-"
    TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end)

local function createBtn(y, text, active)
    local btn = Instance.new("TextButton", content); btn.Size = UDim2.new(0.9, 0, 0, 35); btn.Position = UDim2.new(0.05, 0, 0, y); btn.BackgroundColor3 = active and ACCENT_PURPLE or BTN_DARK; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Text = text; Instance.new("UICorner", btn); return btn
end

local htpBtn = createBtn(0, "HALF TP: ON", true)
local spdBtn = createBtn(40, "SPEED (28.5): ON", true)
local bLeft  = createBtn(80, "Auto Left [Q]", false)
local bRight = createBtn(120, "Auto Right [E]", false)
local spamBtn = createBtn(160, "SPAM NEAREST", false); spamBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 

local premiumLabel = Instance.new("TextLabel", content)
premiumLabel.Size = UDim2.new(1, 0, 0, 20)
premiumLabel.Position = UDim2.new(0, 0, 1, -25)
premiumLabel.BackgroundTransparency = 1
premiumLabel.Text = "PREMIUM"
premiumLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
premiumLabel.Font = Enum.Font.GothamBold
premiumLabel.TextSize = 12

local barBg = Instance.new("Frame", content); barBg.Size = UDim2.new(0.9, 0, 0, 8); barBg.Position = UDim2.new(0.05, 0, 0, 210); barBg.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1) 
local barFill = Instance.new("Frame", barBg); barFill.Size = UDim2.new(0, 0, 1, 0); barFill.BackgroundColor3 = NEON_PURPLE; Instance.new("UICorner", barBg); Instance.new("UICorner", barFill)

htpBtn.MouseButton1Click:Connect(function() halfTpEnabled = not halfTpEnabled; htpBtn.Text = "HALF TP: " .. (halfTpEnabled and "ON" or "OFF"); htpBtn.BackgroundColor3 = halfTpEnabled and ACCENT_PURPLE or BTN_DARK end)

spdBtn.MouseButton1Click:Connect(function() 
    speedEnabled = not speedEnabled
    spdBtn.Text = "SPEED (28.5): " .. (speedEnabled and "ON" or "OFF")
    spdBtn.BackgroundColor3 = speedEnabled and ACCENT_PURPLE or BTN_DARK 
end)

bLeft.MouseButton1Click:Connect(function() executeSteal(spot1_sequence) end)
bRight.MouseButton1Click:Connect(function() executeSteal(spot2_sequence) end)

-- KEYBIND LOGIC (Q per Left, E per Right)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        executeSteal(spot1_sequence)
    elseif input.KeyCode == Enum.KeyCode.E then
        executeSteal(spot2_sequence)
    end
end)

spamBtn.MouseButton1Click:Connect(function()
    local char = player.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local target, dist = nil, 120
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; target = p end
        end
    end
    if target then
        local cmds = {";rocket ", ";balloon ", ";nightvision ", ";jumpscare ", ";ragdoll ", ";inverse ", ";tiny ", ";morph "}
        for _, c in ipairs(cmds) do
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local ch = TextChatService.TextChannels.RBXGeneral; if ch then ch:SendAsync(c .. target.Name) end
            else
                local e = game:GetService("ReplicatedStorage"):FindFirstChild("SayMessageRequest", true); if e then e:FireServer(c .. target.Name, "All") end
            end
            task.wait(0.12)
        end
    end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
    if plr == player and halfTpEnabled then
        local hrp = getHRP()
        if hrp then local d1, d2 = (hrp.Position - pos1).Magnitude, (hrp.Position - pos2).Magnitude; hrp.CFrame = CFrame.new(d1 < d2 and pos1 or pos2) end
    end
end)

task.spawn(function()
    applyFFlags()
    respawnPlayer()
    
    task.wait(1.5)
    desyncActivated = true
    title.Text = "Vale SemiTP🦅: READY"
    
    _G.EspBaseThread = RunService.RenderStepped:Connect(updateBaseESP)
    _G.PlayerEspConnection = RunService.Heartbeat:Connect(UpdatePlayerESP)
    
    task.spawn(function()
        while _G.espFriendLoop do
            local plots = workspace:FindFirstChild("Plots")
            if plots then
                for _, plot in pairs(plots:GetChildren()) do
                    local fp = plot:FindFirstChild("FriendPanel", true)
                    local mp = fp and fp:FindFirstChild("Main")
                    if mp then
                        local img = mp:FindFirstChild("SurfaceGui") and mp.SurfaceGui:FindFirstChildOfClass("ImageLabel")
                        if img and not misc.espFriendGuis[mp] then createFriendESP(mp, img) end
                    end
                end
            end
            local cam = workspace.CurrentCamera
            if cam then
                for part, data in pairs(misc.espFriendGuis) do
                    local d = (cam.CFrame.Position - part.Position).Magnitude
                    local p = 1800 / math.max(d, 1)
                    data.gui.Size = UDim2.new(0, p, 0, p)
                end
            end
            task.wait(0.1)
        end
    end)

    while task.wait() do
        barFill.Size = UDim2.new(math.clamp(StealProgress,0,1), 0, 1, 0)
        local pf = workspace:FindFirstChild("Plots")
        if pf then
            table.clear(allAnimalsCache)
            for _, plot in ipairs(pf:GetChildren()) do
                local sign = plot:FindFirstChild("PlotSign")
                if sign and sign:FindFirstChild("YourBase") and not sign.YourBase.Enabled and plot:FindFirstChild("AnimalPodiums") then
                    for _, podium in ipairs(plot.AnimalPodiums:GetChildren()) do
                        if podium:IsA("Model") and podium:FindFirstChild("Base") then
                            table.insert(allAnimalsCache, {plot = plot.Name, slot = podium.Name, worldPosition = podium:GetPivot().Position})
                        end
                    end
                end
            end
        end
    end
end)