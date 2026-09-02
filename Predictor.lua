-- ===================================================
-- SPIRIT FRUIT SMART GRINDER (Multi-Frucht Prioritäts-Logik)
-- ===================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

print("[SmartGrinder] Gestartet mit Multi-Frucht Logik. JobId:", game.JobId)

-- Die 6 Wetter-Mutationen mit ihren Events
local WEATHER_ORDER = {
    {weather = "Misty",         mutation = "Dewy"},
    {weather = "Sandstorm",     mutation = "Dusty"},
    {weather = "Blizzard",      mutation = "Frosted"},
    {weather = "Acid-Rain",     mutation = "Radioactive"},
    {weather = "Rainbow",       mutation = "Golden"},
    {weather = "Meteor Shower", mutation = "Cosmic"}
}

local autoHopEnabled = true
local teleporting = false
local grindCompleted = false

-- Altes GUI auf PlayerGui aufräumen
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("SpiritGrinderGUI") then
    playerGui.SpiritGrinderGUI:Destroy()
end

-- GUI Erstellen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritGrinderGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 360)
mainFrame.Position = UDim2.new(0, 25, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 65)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌱 SMART GRINDER <font color='#8888aa'>(Multi-Frucht)</font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Inhalt Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -44)
contentContainer.Position = UDim2.new(0, 10, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 4)
contentLayout.Parent = contentContainer

local function createRow(name, sizeY, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, 0, 0, sizeY or 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextSize = textSize or 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = contentContainer
    return lbl
end

local lblWeather = createRow("LblWeather", 20, 12)
local lblNextWeather = createRow("LblNextWeather", 20, 12)

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div1.BorderSizePixel = 0
div1.Parent = contentContainer

local fruitLabels = {
    createRow("Fruit1", 18, 11),
    createRow("Fruit2", 18, 11),
    createRow("Fruit3", 18, 11),
    createRow("Fruit4", 18, 11)
}

local div2 = Instance.new("Frame")
div2.Size = UDim2.new(1, 0, 0, 1)
div2.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div2.BorderSizePixel = 0
div2.Parent = contentContainer

local lblPhase = createRow("LblPhase", 20, 11)
lblPhase.Font = Enum.Font.GothamBold
lblPhase.TextColor3 = Color3.fromRGB(100, 200, 255)

local lblTarget = createRow("LblTarget", 20, 11)
lblTarget.Font = Enum.Font.GothamBold
lblTarget.TextColor3 = Color3.fromRGB(255, 190, 80)

local lblNeeded = createRow("LblNeeded", 20, 11)
lblNeeded.Font = Enum.Font.GothamBold
lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

-- Auto-Hop Button
local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, 0, 0, 28)
hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.TextSize = 12
hopButton.Font = Enum.Font.GothamBold
hopButton.Text = "Auto-Hop: AN"
hopButton.Parent = contentContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = hopButton

hopButton.MouseButton1Click:Connect(function()
    if grindCompleted then return end
    autoHopEnabled = not autoHopEnabled
    if autoHopEnabled then
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        hopButton.Text = "Auto-Hop: AN"
    else
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        hopButton.Text = "Auto-Hop: AUS (Manuell)"
    end
end)

local function resetUIState(phaseText, targetText, neededText)
    lblPhase.Text = phaseText
    lblTarget.Text = targetText
    lblNeeded.Text = neededText
    for i = 1, 4 do
        fruitLabels[i].Text = string.format("Frucht %d: Warten...", i)
        fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
    end
end

local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):lower()
end

local function getActiveWeather()
    local currentWeatherObj = ReplicatedStorage:FindFirstChild("CurrentWeather") 
        or ReplicatedStorage:FindFirstChild("CurrentWeather", true)
    if currentWeatherObj then
        local val = nil
        if currentWeatherObj:IsA("ValueBase") then
            val = currentWeatherObj.Value
        elseif currentWeatherObj:IsA("TextLabel") or currentWeatherObj:IsA("TextBox") then
            val = currentWeatherObj.Text
        end
        if not val or val == "" then
            val = currentWeatherObj:GetAttribute("Value") or currentWeatherObj:GetAttribute("Weather") or currentWeatherObj:GetAttribute("CurrentWeather")
        end
        if val and tostring(val) ~= "" then
            return tostring(val)
        end
    end
    local attrWeather = ReplicatedStorage:GetAttribute("CurrentWeather")
    if attrWeather then
        return tostring(attrWeather)
    end
    return "Unknown"
end

local function getNextWeather()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "GetNextWeather" and desc:IsA("RemoteFunction") then
            local success, res = pcall(function()
                return desc:InvokeServer()
            end)
            if success and type(res) == "table" then
                return res.key or res.Name or "Unknown"
            elseif success and type(res) == "string" then
                return res
            end
        end
    end
    return "Unknown"
end

local function triggerServerHop()
    if not autoHopEnabled or grindCompleted then return end
    if teleporting then return end

    teleporting = true
    print("[SmartGrinder] 🔄 Starte Serverhop! JobId:", game.JobId)
    hopButton.Text = "Auto-Hop: Wechsle Server..."

    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function getPlayerSpiritTree()
    local playerPlots = Workspace:FindFirstChild("BigField") and Workspace.BigField:FindFirstChild("PlayerPlots")
    if not playerPlots then return nil end

    local myPlot = nil
    for _, plot in ipairs(playerPlots:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            myPlot = plot
            break
        end
    end
    if not myPlot then return nil end

    for _, child in ipairs(myPlot:GetChildren()) do
        if child:GetAttribute("SeedType") == "Spirit" then
            return child
        end
    end
    return nil
end

local cachedCurW = "Laden..."
local cachedNextW = "Laden..."

task.spawn(function()
    while screenGui.Parent do
        cachedCurW = getActiveWeather()
        cachedNextW = getNextWeather()
        task.wait(4)
    end
end)

task.spawn(function()
    while screenGui.Parent do
        local ok, err = pcall(function()
            lblWeather.Text = "Aktuell: " .. cachedCurW
            lblNextWeather.Text = "Nächstes: " .. cachedNextW

            local spiritTree = getPlayerSpiritTree()
            if not spiritTree then
                resetUIState("Phase: Fehler", "Ziel: Kein Spirit-Baum", "Baum pflanzen...")
                return
            end

            local fruitSpawnsFolder = spiritTree:FindFirstChild("FruitSpawns")
            if not fruitSpawnsFolder then
                resetUIState("Phase: Fehler", "Ziel: Spawns fehlen", "Strukturfehler")
                return
            end

            local fruitMap = {}
            local uniqueCount = 0

            for _, obj in ipairs(fruitSpawnsFolder:GetChildren()) do
                local idx = obj:GetAttribute("SpawnIndex")
                if typeof(idx) == "number" and idx >= 1 and idx <= 4 and idx % 1 == 0 then
                    fruitMap[idx] = obj
                    uniqueCount = uniqueCount + 1
                end
            end

            if uniqueCount ~= 4 then
                resetUIState("Phase: Fehler", "Ziel: Ungültige Spawns", "Warte auf Spawns 1-4...")
                return
            end

            local fruitDataList = {}
            local allWeatherComplete = true

            for i = 1, 4 do
                local spawnObj = fruitMap[i]
                local mutationsAttr = spawnObj:GetAttribute("FruitMutations") or ""
                local foundMap = {}
                for mut in mutationsAttr:gmatch("[^,%s]+") do
                    foundMap[mut:lower()] = true
                end

                local weatherCount = 0
                local missingList = {}
                for _, entry in ipairs(WEATHER_ORDER) do
                    local mutName = entry.mutation:lower()
                    if foundMap[mutName] then
                        weatherCount = weatherCount + 1
                    else
                        table.insert(missingList, entry)
                    end
                end

                if weatherCount < #WEATHER_ORDER then
                    allWeatherComplete = false
                end

                fruitDataList[i] = {
                    count = weatherCount,
                    missing = missingList
                }
            end

            -- WETTER-SAMMEL-PHASE (MULTI-FRUCHT-PRIORITÄT)
            if not allWeatherComplete then
                local allMissingWeathers = {}

                for i = 1, 4 do
                    local dat = fruitDataList[i]
                    if dat.count >= #WEATHER_ORDER then
                        fruitLabels[i].Text = string.format("Frucht %d: 6/6 Komplett ✅", i)
                        fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                    else
                        fruitLabels[i].Text = string.format("Frucht %d: %d/6 Mutationen", i, dat.count)
                        fruitLabels[i].TextColor3 = Color3.fromRGB(255, 170, 80)

                        for _, missingEntry in ipairs(dat.missing) do
                            table.insert(allMissingWeathers, {
                                fruitIdx = i,
                                weather = missingEntry.weather,
                                mutation = missingEntry.mutation
                            })
                        end
                    end
                end

                lblPhase.Text = string.format("Status: Suche %d fehlende Mutationen", #allMissingWeathers)

                local curClean = cleanString(cachedCurW)
                local nextClean = cleanString(cachedNextW)

                local matchedReq = nil
                for _, req in ipairs(allMissingWeathers) do
                    local reqClean = cleanString(req.weather)
                    if curClean == reqClean or nextClean == reqClean then
                        matchedReq = req
                        break
                    end
                end

                if matchedReq then
                    if cleanString(matchedReq.weather) == curClean then
                        lblTarget.Text = string.format("Ziel: F%d braucht '%s' (%s)", matchedReq.fruitIdx, matchedReq.weather, matchedReq.mutation)
                        lblNeeded.Text = "Wetter aktiv! Bleibe auf Server..."
                        lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)
                    else
                        lblTarget.Text = string.format("Ziel: F%d braucht '%s' (%s)", matchedReq.fruitIdx, matchedReq.weather, matchedReq.mutation)
                        lblNeeded.Text = "Nächstes Wetter passt! Warte..."
                        lblNeeded.TextColor3 = Color3.fromRGB(255, 220, 80)
                    end
                else
                    if #allMissingWeathers > 0 then
                        local firstReq = allMissingWeathers[1]
                        lblTarget.Text = string.format("Ziel: F%d braucht '%s' (%s)", firstReq.fruitIdx, firstReq.weather, firstReq.mutation)
                    else
                        lblTarget.Text = "Ziel: Keine offenen Mutationen"
                    end
                    lblNeeded.Text = "Wetter passt nicht -> Hoppe"
                    lblNeeded.TextColor3 = Color3.fromRGB(220, 100, 100)

                    if autoHopEnabled then
                        triggerServerHop()
                    end
                end

            -- FERTIG-PHASE (Kein Auto-Collect!)
            else
                grindCompleted = true
                autoHopEnabled = false
                hopButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                hopButton.Text = "Auto-Hop: FERTIG (6/6)"

                lblPhase.Text = "🎉 ALLE 4 FRÜCHTE HABEN 6/6 WETTER!"
                lblTarget.Text = "Ziel: Bereit zum manuellen Ernten"
                lblNeeded.Text = "Status: Server-Hop gestoppt."
                lblTarget.TextColor3 = Color3.fromRGB(100, 255, 100)
                lblNeeded.TextColor3 = Color3.fromRGB(100, 255, 100)

                for i = 1, 4 do
                    fruitLabels[i].Text = string.format("Frucht %d: 6/6 Wetter aktiv ✅", i)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                end
            end

        end)

        if not ok then
            warn("[SmartGrinder] Fehler:", err)
        end
        
        task.wait(1.5)
    end
end)
