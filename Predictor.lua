--// GREEDY GROWERS
--// AUTO FARM ALL FRUIT MAX MUTATIONS + WEATHER HOP
--// SAVED SETTINGS & PERSISTENT STATE

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--==================================================
-- EVENTS & MUTATIONS CONFIG
--==================================================

local EVENTS = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

local Selected = {}
for _, eventName in ipairs(EVENTS) do
    Selected[eventName] = true -- Standardmäßig alle für Wetter-Hop aktivieren
end

local Running = false
local Hopping = false
local AutoMaxMutationsRunning = false

local LastNextWeather = nil
local LastNextTime = "--"

--==================================================
-- SAVED SETTINGS
--==================================================

local SETTINGS_KEY = "GreedyGrowersMaxMutationsSettingsV1"

pcall(function()
    local saved = TeleportService:GetTeleportSetting(SETTINGS_KEY)
    if type(saved) == "table" then
        if type(saved.Selected) == "table" then
            for _, eventName in ipairs(EVENTS) do
                if saved.Selected[eventName] ~= nil then
                    Selected[eventName] = saved.Selected[eventName]
                end
            end
        end
        if saved.AutoMaxRunning == true then
            AutoMaxMutationsRunning = true
            Running = true
        end
    end
end)

local function saveSettings()
    pcall(function()
        local data = {
            Selected = Selected,
            AutoMaxRunning = AutoMaxMutationsRunning
        }
        TeleportService:SetTeleportSetting(SETTINGS_KEY, data)
    end)
end

--==================================================
-- COLORS
--==================================================

local WHITE = Color3.fromRGB(240, 243, 248)
local GREEN = Color3.fromRGB(90, 230, 125)
local RED = Color3.fromRGB(235, 75, 75)
local YELLOW = Color3.fromRGB(230, 180, 60)
local GREY = Color3.fromRGB(120, 128, 142)

--==================================================
-- REMOVE OLD GUI
--==================================================

pcall(function()
    local old = CoreGui:FindFirstChild("GreedyGrowersAutoFarm")
    if old then
        old:Destroy()
    end
end)

--==================================================
-- GUI SETUP
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GreedyGrowersAutoFarm"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(350, 530)
Main.Position = UDim2.new(0.5, -175, 0.5, -265)
Main.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 72)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.35
MainStroke.Parent = Main

--==================================================
-- DRAG LOGIC
--==================================================

local dragging = false
local dragStart
local startPos

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- TITLE & HEADER
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 34)
Title.Position = UDim2.fromOffset(15, 12)
Title.BackgroundTransparency = 1
Title.Text = "GREEDY GROWERS"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(245, 247, 250)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -30, 0, 20)
Subtitle.Position = UDim2.fromOffset(15, 39)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "WEATHER & MUTATION AUTO FARM"
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 10
Subtitle.TextColor3 = Color3.fromRGB(125, 132, 145)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Main

--==================================================
-- WEATHER CARDS
--==================================================

local function createCard(y, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -30, 0, 70)
    card.Position = UDim2.fromOffset(15, y)
    card.BackgroundColor3 = Color3.fromRGB(21, 24, 31)
    card.BorderSizePixel = 0
    card.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.fromOffset(10, 6)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 9
    label.TextColor3 = GREY
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local value = Instance.new("TextLabel")
    value.Size = UDim2.fromOffset(125, 26)
    value.Position = UDim2.fromOffset(10, 24)
    value.BackgroundTransparency = 1
    value.Text = "..."
    value.Font = Enum.Font.GothamBold
    value.TextSize = 15
    value.TextColor3 = WHITE
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = card

    local result = Instance.new("TextLabel")
    result.Size = UDim2.new(1, -140, 0, 36)
    result.Position = UDim2.fromOffset(135, 24)
    result.BackgroundTransparency = 1
    result.Text = ""
    result.Font = Enum.Font.GothamBold
    result.TextSize = 8
    result.TextColor3 = GREY
    result.TextXAlignment = Enum.TextXAlignment.Left
    result.TextWrapped = true
    result.Parent = card

    return card, value, result
end

local CurrentCard, CurrentValue, CurrentResult = createCard(65, "CURRENT WEATHER")
local NextCard, NextValue, NextResult = createCard(140, "NEXT WEATHER")

local NextStart = Instance.new("TextLabel")
NextStart.Size = UDim2.new(1, -30, 0, 16)
NextStart.Position = UDim2.fromOffset(15, 212)
NextStart.BackgroundTransparency = 1
NextStart.Text = "Start: --"
NextStart.Font = Enum.Font.GothamMedium
NextStart.TextSize = 10
NextStart.TextColor3 = GREY
NextStart.TextXAlignment = Enum.TextXAlignment.Left
NextStart.Parent = Main

--==================================================
-- NEW SECTION: AUTO FARM ALL FRUIT MAX MUTATIONS
--==================================================

local TargetHeader = Instance.new("TextLabel")
TargetHeader.Size = UDim2.new(1, -30, 0, 18)
TargetHeader.Position = UDim2.fromOffset(15, 232)
TargetHeader.BackgroundTransparency = 1
TargetHeader.Text = "autofarm all fruit max mutations"
TargetHeader.Font = Enum.Font.GothamBold
TargetHeader.TextSize = 11
TargetHeader.TextColor3 = Color3.fromRGB(210, 215, 225)
TargetHeader.TextXAlignment = Enum.TextXAlignment.Left
TargetHeader.Parent = Main

local StartMaxButton = Instance.new("TextButton")
StartMaxButton.Size = UDim2.new(1, -30, 0, 36)
StartMaxButton.Position = UDim2.fromOffset(15, 252)
StartMaxButton.BackgroundColor3 = AutoMaxMutationsRunning and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(35, 39, 49)
StartMaxButton.BorderSizePixel = 0
StartMaxButton.Text = AutoMaxMutationsRunning and "STOP" or "START"
StartMaxButton.Font = Enum.Font.GothamBold
StartMaxButton.TextSize = 12
StartMaxButton.TextColor3 = Color3.fromRGB(235, 238, 244)
StartMaxButton.AutoButtonColor = false
StartMaxButton.Parent = Main

local StartMaxCorner = Instance.new("UICorner")
StartMaxCorner.CornerRadius = UDim.new(0, 10)
StartMaxCorner.Parent = StartMaxButton

--==================================================
-- STATUS BAR
--==================================================

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -60, 0, 20)
StatusText.Position = UDim2.fromOffset(37, 498)
StatusText.BackgroundTransparency = 1
StatusText.Text = AutoMaxMutationsRunning and "RUNNING (MAX MUTATIONS)" or "OFF"
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 10
StatusText.TextColor3 = AutoMaxMutationsRunning and GREEN or GREY
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Main

local Dot = Instance.new("Frame")
Dot.Size = UDim2.fromOffset(8, 8)
Dot.Position = UDim2.fromOffset(18, 504)
Dot.BackgroundColor3 = AutoMaxMutationsRunning and GREEN or RED
Dot.BorderSizePixel = 0
Dot.Parent = Main

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = Dot

--==================================================
-- EVENT PANEL (DROPDOWN)
--==================================================

local AutoHeader = Instance.new("TextButton")
AutoHeader.Size = UDim2.new(1, -30, 0, 30)
AutoHeader.Position = UDim2.fromOffset(15, 294)
AutoHeader.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
AutoHeader.BorderSizePixel = 0
AutoHeader.Text = ""
AutoHeader.AutoButtonColor = false
AutoHeader.Parent = Main

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoHeader

local AutoTitle = Instance.new("TextLabel")
AutoTitle.Size = UDim2.new(1, -70, 1, 0)
AutoTitle.Position = UDim2.fromOffset(10, 0)
AutoTitle.BackgroundTransparency = 1
AutoTitle.Text = "Weather Filter Settings"
AutoTitle.Font = Enum.Font.GothamBold
AutoTitle.TextSize:let = 11
AutoTitle.TextColor3 = Color3.fromRGB(200, 205, 215)
AutoTitle.TextXAlignment = Enum.TextXAlignment.Left
AutoTitle.Parent = AutoHeader

local Arrow = Instance.new("TextLabel")
Arrow.Size = UDim2.fromOffset(20, 30)
Arrow.Position = UDim2.new(1, -25, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = ">"
Arrow.Font = Enum.Font.GothamBold
Arrow.TextSize = 14
Arrow.TextColor3 = Color3.fromRGB(180, 185, 195)
Arrow.Parent = AutoHeader

local EventPanel = Instance.new("Frame")
EventPanel.Size = UDim2.new(1, -30, 0, 130)
EventPanel.Position = UDim2.fromOffset(15, 328)
EventPanel.BackgroundColor3 = Color3.fromRGB(19, 22, 28)
EventPanel.BorderSizePixel = 0
EventPanel.Visible = false
EventPanel.Parent = Main

local EventCorner = Instance.new("UICorner")
EventCorner.CornerRadius = UDim.new(0, 9)
EventCorner.Parent = EventPanel

local EventScroll = Instance.new("ScrollingFrame")
EventScroll.Size = UDim2.new(1, -12, 1, -10)
EventScroll.Position = UDim2.fromOffset(6, 5)
EventScroll.BackgroundTransparency = 1
EventScroll.BorderSizePixel = 0
EventScroll.ScrollBarThickness = 3
EventScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
EventScroll.Parent = EventPanel

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.Parent = EventScroll

local EventButtons = {}

local function refreshButtons()
    for eventName, button in pairs(EventButtons) do
        if Selected[eventName] then
            button.BackgroundColor3 = Color3.fromRGB(55, 90, 65)
            button.TextColor3 = Color3.fromRGB(220, 255, 225)
            button.Text = "✓  " .. eventName
        else
            button.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
            button.TextColor3 = Color3.fromRGB(185, 190, 200)
            button.Text = "○  " .. eventName
        end
    end
end

for _, eventName in ipairs(EVENTS) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 24)
    button.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
    button.BorderSizePixel = 0
    button.Text = Selected[eventName] and "✓  " .. eventName or "○  " .. eventName
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = Selected[eventName] and Color3.fromRGB(220, 255, 225) or Color3.fromRGB(185, 190, 200)
    button.AutoButtonColor = false
    button.Parent = EventScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    EventButtons[eventName] = button

    button.MouseButton1Click:Connect(function()
        Selected[eventName] = not Selected[eventName]
        refreshButtons()
        saveSettings()
    end)
end

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    EventScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 5)
end)

refreshButtons()

local Expanded = false
AutoHeader.MouseButton1Click:Connect(function()
    Expanded = not Expanded
    if Expanded then
        Arrow.Text = "<"
        EventPanel.Visible = true
        Main.Size = UDim2.fromOffset(350, 665)
        EventPanel.Position = UDim2.fromOffset(15, 328)
        StartMaxButton.Position = UDim2.fromOffset(15, 462)
        StatusText.Position = UDim2.fromOffset(37, 508)
        Dot.Position = UDim2.fromOffset(18, 514)
    else
        Arrow.Text = ">"
        EventPanel.Visible = false
        Main.Size = UDim2.fromOffset(350, 530)
        StartMaxButton.Position = UDim2.fromOffset(15, 252)
        StatusText.Position = UDim2.fromOffset(37, 498)
        Dot.Position = UDim2.fromOffset(18, 504)
    end
end)

--==================================================
-- WEATHER FUNCTIONS
--==================================================

local function getNextWeatherRemote()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return nil end
    local Index = Packages:FindFirstChild("_Index")
    if not Index then return nil end

    for _, child in ipairs(Index:GetChildren()) do
        local childName = string.lower(child.Name)
        if string.sub(childName, 1, 14) == "sleitnick_knit" then
            local knit = child:FindFirstChild("knit")
            if knit then
                local Services = knit:FindFirstChild("Services")
                if Services then
                    local WeatherService = Services:FindFirstChild("WeatherService")
                    if WeatherService then
                        local RF = WeatherService:FindFirstChild("RF")
                        if RF then
                            local Remote = RF:FindFirstChild("GetNextWeather")
                            if Remote and Remote:IsA("RemoteFunction") then
                                return Remote
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getCurrentWeather()
    local current = ReplicatedStorage:FindFirstChild("CurrentWeather")
    if not current then return "Normal" end
    local value = nil
    pcall(function()
        if current:IsA("ValueBase") then
            value = current.Value
        end
    end)
    if value == nil then return "Normal" end
    local weather = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if weather == "" or weather:lower() == "nil" or weather:lower() == "none" or weather:lower() == "normal" then
        return "Normal"
    end
    return weather
end

local function getNextWeather()
    local remote = getNextWeatherRemote()
    if not remote then return nil, nil end

    local success, result = pcall(function()
        return remote:InvokeServer()
    end)

    if not success or type(result) ~= "table" then
        return nil, nil
    end

    local nextWeather = result.key
    local startTime = result.startTime

    if nextWeather ~= nil then
        nextWeather = tostring(nextWeather)
    end

    if startTime ~= nil then
        local numericTime = tonumber(startTime)
        if numericTime then
            startTime = os.date("%H:%M:%S", numericTime)
        else
            startTime = tostring(startTime)
        end
    else
        startTime = "--"
    end

    return nextWeather, startTime
end

local function isSelectedWeather(weather)
    if not weather then return false end
    local weatherNorm = tostring(weather):lower():gsub("^%s+", ""):gsub("%s+$", "")
    for _, eventName in ipairs(EVENTS) do
        if weatherNorm == eventName:lower() then
            return Selected[eventName] == true
        end
    end
    return false
end

--==================================================
-- PLOT & FRUIT LOGIC (MAX MUTATIONS AUTOMATION)
--==================================================

-- Hier werden alle erforderlichen Mutationen definiert, die eine Frucht haben muss (Infested und Huge durch Pets)
local REQUIRED_MUTATIONS = {
    "Dewy", "Dusty", "Frosted", "Shocked", "Infested", "Radioactive", "Golden", "Cosmic", "HUGE"
}

local function findMyPlot()
    local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("PlayerPlots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("Sign")
        pcall(function()
            if owner and (owner.Value == LocalPlayer or owner.Text:find(LocalPlayer.Name)) then
                return plot
            end
        end)
        if plot.Name == LocalPlayer.Name or plot:FindFirstChild(LocalPlayer.Name) then
            return plot
        end
    end
    return plots:GetChildren()[1] -- Fallback
end

local function getFruitsFromPlot()
    local plot = findMyPlot()
    local fruits = {}
    if not plot then return fruits end

    -- Sucht nach Pflanzen/Früchten im Plot (angepasst an gängige Tycoon/Bau-Strukturen)
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("fruit") or obj.Name:lower():find("plant") or obj:FindFirstChild("Mutations")) then
            table.insert(fruits, obj)
        end
    end
    return fruits
end

local function getFruitMutations(fruit)
    local mutationsFound = {}
    -- Prüft Attribute, Werte oder Unterordner im Modell auf Mutationen
    for _, desc in ipairs(fruit:GetDescendants()) do
        for _, req in ipairs(REQUIRED_MUTATIONS) do
            if desc.Name:lower():find(req:lower()) or (desc:IsA("ValueBase") and tostring(desc.Value):lower():find(req:lower())) then
                mutationsFound[req] = true
            end
        end
    end
    return mutationsFound
end

local function checkAllFruitsHaveMaxMutations()
    local fruits = getFruitsFromPlot()
    if #fruits == 0 then return false, "Keine Früchte gefunden" end

    for _, fruit in ipairs(fruits) do
        local mutations = getFruitMutations(fruit)
        for _, req in ipairs(REQUIRED_MUTATIONS) do
            if not mutations[req] then
                return false, req -- Gibt die erste fehlende Mutation der ersten unvollständigen Frucht zurück!
            end
        end
    end
    return true, "Alle bereit"
end

local function harvestAndSellAll()
    StatusText.Text = "ERNTE & VERKAUFE..."
    Dot.BackgroundColor3 = YELLOW

    -- Ernte-Logik (Remote oder ProximityPrompt)
    pcall(function()
        for _, fruit in ipairs(getFruitsFromPlot()) do
            local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            end
        end
    end)

    task.wait(1)

    -- Verkauf-Logik (Interaktion mit Verkaufspunkt/Shop)
    pcall(function()
        local sellRemote = ReplicatedStorage:FindFirstChild("Events", true):FindFirstChild("Sell") or ReplicatedStorage:FindFirstChild("SellRemote", true)
        if sellRemote and sellRemote:IsA("RemoteEvent") then
            sellRemote:FireServer()
        end
    end)
end

--==================================================
-- SERVER HOP LOGIC
--==================================================

local function serverHop()
    if Hopping or not AutoMaxMutationsRunning then return end
    saveSettings()
    Hopping = true

    StatusText.Text = "SERVER HOPPING..."
    Dot.BackgroundColor3 = YELLOW

    task.spawn(function()
        local success, data = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if not success or not data or not data.data then
            StatusText.Text = "HOP FAILED"
            Dot.BackgroundColor3 = RED
            Hopping = false
            return
        end

        local servers = {}
        for _, server in ipairs(data.data) do
            if server.id and server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end

        if #servers == 0 then
            StatusText.Text = "NO SERVER"
            Dot.BackgroundColor3, Hopping = RED, false
            return
        end

        local target = servers[math.random(1, #servers)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, target, LocalPlayer)
        end)
        task.wait(6)
        Hopping = false
    end)
end

--==================================================
-- START / STOP BUTTON ACTION
--==================================================

StartMaxButton.MouseButton1Click:Connect(function()
    AutoMaxMutationsRunning = not AutoMaxMutationsRunning
    Running = AutoMaxMutationsRunning

    if AutoMaxMutationsRunning then
        StartMaxButton.Text = "STOP"
        StartMaxButton.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
        StatusText.Text = "RUNNING (MAX MUTATIONS)"
        Dot.BackgroundColor3 = GREEN
    else
        StartMaxButton.Text = "START"
        StartMaxButton.BackgroundColor3 = Color3.fromRGB(35, 39, 49)
        StatusText.Text = "OFF"
        Dot.BackgroundColor3 = RED
    end
    saveSettings()
end)

--==================================================
-- KEYBIND (RIGHT SHIFT)
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

--==================================================
-- MAIN AUTOMATION LOOP
--==================================================

task.spawn(function()
    task.wait(3) -- Kurz warten beim Start

    while Gui.Parent do
        local current = getCurrentWeather()
        local nextWeather, startTime = getNextWeather()

        -- UI Aktualisieren für Wetter-Displays
        CurrentValue.Text = current
        LastNextWeather = nextWeather
        LastNextTime = startTime or "--"
        NextValue.Text = LastNextWeather or "..."
        NextStart.Text = "Start: " .. LastNextTime

        if isSelectedWeather(current) then
            CurrentValue.TextColor3 = GREEN
            CurrentResult.Text = "AKTIVES WETTER PASST"
        else
            CurrentValue.TextColor3 = WHITE
            CurrentResult.Text = "KEIN ZIELWETTER"
        end

        if AutoMaxMutationsRunning then
            local allReady, missingInfo = checkAllFruitsHaveMaxMutations()

            if allReady then
                -- Wenn alle Früchte alles haben -> Ernten & Verkaufen!
                harvestAndSellAll()
                task.wait(5)
            else
                -- Prüfen, ob der Frucht ein wetterabhängiges Merkmal fehlt
                -- missingInfo enthält z.B. das fehlende Wetter wie "Acid Rain" oder "Rainbow"
                local needsWeather = false
                for _, eventName in ipairs(EVENTS) do
                    if missingInfo and missingInfo:lower() == eventName:lower() then
                        needsWeather = true
                        break
                    end
                end

                if needsWeather then
                    -- Schauen, ob das benötigte Wetter gerade da ist oder als nächstes kommt
                    local currentMatches = (current:lower() == missingInfo:lower())
                    local nextMatches = (nextWeather and nextWeather:lower() == missingInfo:lower())

                    if currentMatches or nextMatches then
                        StatusText.Text = "WARTE AUF MUTATION (" .. missingInfo .. ")"
                        Dot.BackgroundColor3 = GREEN
                        -- Bleiben und warten, bis die Mutation eintrifft
                    else
                        StatusText.Text = "SUCHE WETTER: " .. missingInfo
                        Dot.BackgroundColor3 = YELLOW
                        serverHop()
                    end
                else
                    -- Wenn es keine wetterabhängige Mutation ist (oder Pets sie holen), einfach weiterlaufen lassen
                    StatusText.Text = "FARMING (FEHLT: " .. tostring(missingInfo) .. ")"
                    Dot.BackgroundColor3 = GREEN
                end
            end
        else
            StatusText.Text = "OFF"
            Dot.BackgroundColor3 = RED
        end

        task.wait(4)
    end
end)
