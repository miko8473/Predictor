-- Greedy Growers Weather Sniffer & Hopper (Original Data + Multi-Event Selector)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen, falls sie noch da ist
pcall(function()
    if CoreGui:FindFirstChild("WeatherHopperGui") then
        CoreGui.WeatherHopperGui:Destroy()
    end
end)

-- Schöne, verschiebbare GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WeatherHopperGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 185)
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

local CurrentLbl = createLabel(12, "Aktuell: Lädt...", Color3.fromRGB(200, 200, 200))
local NextLbl    = createLabel(38, "Nächstes: Lädt...", Color3.fromRGB(100, 220, 255))
local TimeLbl    = createLabel(64, "Uhrzeit: Lädt...", Color3.fromRGB(255, 220, 100))
local StatusLbl  = createLabel(90, "Status: Bereit", Color3.fromRGB(150, 255, 150))

-- Ausklapp-Button ("Suche >") für das Menü
local SearchToggleBtn = Instance.new("TextButton")
SearchToggleBtn.Size = UDim2.new(1, -24, 0, 24)
SearchToggleBtn.Position = UDim2.new(0, 12, 0, 116)
SearchToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SearchToggleBtn.Text = "Suche  >"
SearchToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchToggleBtn.TextSize = 12
SearchToggleBtn.Font = Enum.Font.GothamBold
SearchToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
SearchToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = SearchToggleBtn

-- Container für die Event-Liste (Standardmäßig eingeklappt)
local EventContainer = Instance.new("ScrollingFrame")
EventContainer.Size = UDim2.new(1, -24, 0, 75)
EventContainer.Position = UDim2.new(0, 12, 0, 144)
EventContainer.BackgroundTransparency = 1
EventContainer.BorderSizePixel = 0
EventContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
EventContainer.ScrollBarThickness = 4
EventContainer.Visible = false
EventContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = EventContainer

-- Server Hop Button
local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(1, -24, 0, 32)
HopButton.Position = UDim2.new(0, 12, 0, 145)
HopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
HopButton.Text = "SERVER HOP"
HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HopButton.TextSize = 14
HopButton.Font = Enum.Font.GothamBold
HopButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = HopButton

-- Liste aller auswählbaren Events
local availableWeathers = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

-- Standardmäßig ist Meteor Shower ausgewählt
local selectedWeathers = {
    ["meteor shower"] = true
}

-- Checkboxen für jedes Event generieren
for i, weatherName in ipairs(availableWeathers) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
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

UIListLayout.AbsoluteContentSizeChanged:Connect(function(size)
    EventContainer.CanvasSize = UDim2.new(0, 0, 0, size.Y)
end)

-- Ein- und Ausklapp-Logik für den Pfeil
local isExpanded = false
SearchToggleBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        SearchToggleBtn.Text = "Suche  v"
        EventContainer.Visible = true
        MainFrame.Size = UDim2.new(0, 280, 0, 230)
        HopButton.Position = UDim2.new(0, 12, 0, 190)
    else
        SearchToggleBtn.Text = "Suche  >"
        EventContainer.Visible = false
        MainFrame.Size = UDim2.new(0, 280, 0, 185)
        HopButton.Position = UDim2.new(0, 12, 0, 145)
    end
end)

-- Server-Hop Funktion
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

-- Funktion um den Knit RemoteFunction-Pfad zu finden (aus deinem funktionierenden Skript)
local function getNextWeatherRemote()
    local rfPath = ReplicatedStorage:FindFirstChild("Packages")
    if rfPath and rfPath:FindFirstChild("_Index") then
        for _, child in ipairs(rfPath._Index:GetChildren()) do
            if child.Name:sub(1, 14) == "sleitnick_knit" then
                local knit = child:FindFirstChild("knit")
                if knit and knit:FindFirstChild("Services") then
                    local ws = knit.Services:FindFirstChild("WeatherService")
                    if ws and ws:FindFirstChild("RF") then
                        return ws.RF:FindFirstChild("GetNextWeather")
                    end
                end
            end
        end
    end
    return nil
end

local function normalize(str)
    return tostring(str):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

-- Live-Aktualisierung im Hintergrund mit der funktionierenden Logik
task.spawn(function()
    task.wait(2)
    
    while true do
        pcall(function()
            -- 1. Aktuelles Wetter auslesen
            local curr = "Normal"
            if ReplicatedStorage:FindFirstChild("CurrentWeather") then
                curr = tostring(ReplicatedStorage.CurrentWeather.Value)
            end
            CurrentLbl.Text = "Aktuell: " .. curr

            -- 2. Nächstes Wetter & Uhrzeit über die Server-Funktion abfragen
            local nxt = "Keines"
            local timeStr = "Unbekannt"
            
            local remote = getNextWeatherRemote()
            if remote then
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
            end
            
            NextLbl.Text = "Nächstes: " .. nxt
            TimeLbl.Text = "Uhrzeit: " .. timeStr

            -- Multi-Event Check: Prüft ob IRGENDEIN ausgewähltes Event da ist
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
                StatusLbl.Text = "Status: 🎯 Event gefunden! Bleibe hier"
                StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            else
                StatusLbl.Text = "Status: Kein Event -> Server Hop!"
                StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
                task.wait(1.5)
                serverHop()
            end
        end)
        task.wait(3)
    end
end)
