-- Greedy Growers Weather Sniffer & Hopper (Universal Fix)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen
pcall(function()
    if CoreGui:FindFirstChild("WeatherHopperGui") then
        CoreGui.WeatherHopperGui:Destroy()
    end
end)

-- GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WeatherHopperGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 195)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local function createLabel(posY, text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MainFrame
    return lbl
end

local CurrentLbl = createLabel(12, "Aktuell: Verbinde...", Color3.fromRGB(200, 200, 200))
local NextLbl    = createLabel(38, "Nächstes: Verbinde...", Color3.fromRGB(100, 220, 255))
local TimeLbl    = createLabel(64, "Uhrzeit: --:--", Color3.fromRGB(255, 220, 100))
local StatusLbl  = createLabel(90, "Status: Suche Remote...", Color3.fromRGB(250, 200, 100))

-- Ausklapp-Button ("Suche >")
local SearchToggleBtn = Instance.new("TextButton")
SearchToggleBtn.Size = UDim2.new(1, -24, 0, 26)
SearchToggleBtn.Position = UDim2.new(0, 12, 0, 116)
SearchToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SearchToggleBtn.Text = "  Suche >"
SearchToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchToggleBtn.TextSize = 12
SearchToggleBtn.Font = Enum.Font.GothamBold
SearchToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
SearchToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = SearchToggleBtn

-- Container für die Event-Liste
local EventContainer = Instance.new("ScrollingFrame")
EventContainer.Size = UDim2.new(1, -24, 0, 110)
EventContainer.Position = UDim2.new(0, 12, 0, 148)
EventContainer.BackgroundTransparency = 1
EventContainer.BorderSizePixel = 0
EventContainer.Visible = false
EventContainer.ScrollBarThickness = 4
EventContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = EventContainer

-- Server Hop Button
local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(1, -24, 0, 32)
HopButton.Position = UDim2.new(0, 12, 0, 150)
HopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
HopButton.Text = "SERVER HOP"
HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HopButton.TextSize = 14
HopButton.Font = Enum.Font.GothamBold
HopButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = HopButton

-- Alle Events aus dem Shop
local availableWeathers = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

-- Standardmäßig Meteor ausgewählt
local selectedWeathers = {
    ["meteor shower"] = true
}

EventContainer.CanvasSize = UDim2.new(0, 0, 0, #availableWeathers * 24)

-- Checkboxen generieren
for i, weatherName in ipairs(availableWeathers) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.LayoutOrder = i
    row.Parent = EventContainer

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = weatherName
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local checkbox = Instance.new("TextButton")
    checkbox.Size = UDim2.new(0, 16, 0, 16)
    checkbox.Position = UDim2.new(1, -16, 0.5, -8)
    checkbox.BackgroundColor3 = selectedWeathers[weatherName:lower()] and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(50, 50, 65)
    checkbox.Text = ""
    checkbox.Parent = row

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 4)
    cbCorner.Parent = checkbox

    checkbox.MouseButton1Click:Connect(function()
        local key = weatherName:lower()
        if selectedWeathers[key] then
            selectedWeathers[key] = nil
            checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        else
            selectedWeathers[key] = true
            checkbox.BackgroundColor3 = Color3.fromRGB(100, 220, 255)
        end
    end)
end

-- Ausklapp-Logik
local isExpanded = false
SearchToggleBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        SearchToggleBtn.Text = "  Suche v"
        EventContainer.Visible = true
        MainFrame.Size = UDim2.new(0, 280, 0, 310)
        HopButton.Position = UDim2.new(0, 12, 0, 264)
    else
        SearchToggleBtn.Text = "  Suche >"
        EventContainer.Visible = false
        MainFrame.Size = UDim2.new(0, 280, 0, 195)
        HopButton.Position = UDim2.new(0, 12, 0, 150)
    end
end)

-- Server Hop Funktion
local function serverHop()
    StatusLbl.Text = "Status: Suche neuen Server..."
    StatusLbl.TextColor3 = Color3.fromRGB(255, 150, 0)
    pcall(function()
        local servers = {}
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end)
end

HopButton.MouseButton1Click:Connect(serverHop)

-- UNIVERSALE SUCHE (Findet den Remote-Befehl im ganzen Spiel)
local function getNextWeatherRemote()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == "GetNextWeather" and obj:IsA("RemoteFunction") then
            return obj
        end
    end
    return nil
end

local function normalize(str)
    return tostring(str):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

-- Live Überwachung starten
task.spawn(function()
    task.wait(1)
    local remote = nil
    
    -- Sucht so lange, bis der Remote-Befehl gefunden wurde
    while not remote do
        remote = getNextWeatherRemote()
        if not remote then
            StatusLbl.Text = "Status: Suche Remote..."
            StatusLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
            task.wait(2)
        else
            StatusLbl.Text = "Status: Verbunden!"
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
        end
    end

    while true do
        pcall(function()
            -- 1. Aktuelles Wetter dynamisch im Spiel finden
            local curr = "Normal"
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj.Name == "CurrentWeather" and obj:IsA("ValueBase") then
                    curr = tostring(obj.Value)
                    break
                end
            end
            CurrentLbl.Text = "Aktuell: " .. curr

            -- 2. Nächstes Wetter über den gefundenen Remote-Befehl abrufen
            local nxt = "Keines"
            local timeStr = "Unbekannt"
            
            local success, res = pcall(function()
                return remote:InvokeServer()
            end)
            
            if success and type(res) == "table" then
                if res.key then
                    nxt = tostring(res.key)
                end
                if res.startTime then
                    timeStr = os.date("%H:%M:%S", res.startTime)
                end
            end
            
            NextLbl.Text = "Nächstes: " .. nxt
            TimeLbl.Text = "Uhrzeit: " .. timeStr

            -- Prüfen ob eines der angekreuzten Events aktiv oder das nächste ist
            local foundMatch = false
            local normCurr = normalize(curr)
            local normNxt = normalize(nxt)

            for weatherKey, _ in pairs(selectedWeathers) do
                if normCurr:find(weatherKey) or normNxt:find(weatherKey) then
                    foundMatch = true
                    break
                end
            end

            local count = 0
            for _ in pairs(selectedWeathers) do count = count + 1 end

            if count == 0 then
                StatusLbl.Text = "Status: Nichts ausgewählt"
                StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            elseif foundMatch then
                StatusLbl.Text = "Status: 🎯 Event gefunden!"
                StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            else
                StatusLbl.Text = "Status: Kein Event -> Hop!"
                StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
                task.wait(1.5)
                serverHop()
            end
        end)
        task.wait(3)
    end
end)
