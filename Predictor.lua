-- Greedy Growers Weather Sniffer & Hopper (Mit Auto-Hop)
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

-- Server Hop Button
local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(1, -24, 0, 35)
HopButton.Position = UDim2.new(0, 12, 0, 125)
HopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
HopButton.Text = "SERVER HOP"
HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HopButton.TextSize = 14
HopButton.Font = Enum.Font.GothamBold
HopButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = HopButton

-- Server-Hop Funktion
local function serverHop()
    StatusLbl.Text = "Status: Kein Meteor -> Server Hop!"
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

-- Funktion um den Knit RemoteFunction-Pfad sicher zu finden
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

-- Live-Aktualisierung und automatische Hop-Logik
task.spawn(function()
    task.wait(2) -- Kurz warten, bis das Spiel geladen ist
    
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
                        -- Unix-Timestamp in lesbare Uhrzeit umwandeln
                        timeStr = os.date("%H:%M:%S", res.startTime)
                    end
                end
            end
            
            NextLbl.Text = "Nächstes: " .. nxt
            TimeLbl.Text = "Uhrzeit: " .. timeStr

            -- Automatische Prüfung: Meteor da (aktuell oder nächste)?
            if normalize(curr):find("meteor") or normalize(nxt):find("meteor") then
                StatusLbl.Text = "Status: 🎯 Meteor gefunden! Bleibe hier!"
                StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
                return -- Skript bleibt in diesem Server und hört auf zu prüfen
            else
                StatusLbl.Text = "Status: Kein Meteor -> Server Hop!"
                StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
                task.wait(1.5)
                serverHop()
                return
            end
        end)
        task.wait(3)
    end
end)
