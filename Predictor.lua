-- Greedy Growers Meteor Shower Auto-ServerHopper (Saubere GUI)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen, falls vorhanden
if CoreGui:FindFirstChild("MeteorSnifferGui") then
    CoreGui.MeteorSnifferGui:Destroy()
end

-- GUI erstellen (Super clean & minimalistisch)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorSnifferGui"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 100)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local function createLabel(posY, text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MainFrame
    return lbl
end

-- Nur noch das Aktuelle Wetter und der Status auf der GUI!
local CurrentLbl = createLabel(15, "Aktuelles Wetter: Lade...", Color3.fromRGB(200, 200, 200))
local StatusLbl = createLabel(45, "Status: Prüfe Server...", Color3.fromRGB(255, 100, 100))

local validWeathers = {
    "Misty", "Sandstorm", "Blizzard", "Acid-Rain", "Acid Rain", "Rainbow", "Meteor Shower", "Lucky River"
}

local function normalize(str)
    return tostring(str):lower():gsub("[%s_%-]+", "")
end

local latestCurrent = "Normal"
local isScanning = true

-- Funktion zum Scannen (Ignoriert Shop & Menüs komplett)
local function scanGame()
    local detectedWeather = "Normal / Keins"

    if LocalPlayer:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                local txt = gui.Text
                local cleanTxt = normalize(txt)
                
                if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                    -- Shop, Markt und andere UI-Fenster ignorieren, damit Acid Rain aus dem Shop nicht triggert
                    local ignore = false
                    local parentObj = gui.Parent
                    while parentObj and parentObj ~= LocalPlayer.PlayerGui do
                        local pName = parentObj.Name:lower()
                        if pName:find("shop") or pName:find("market") or pName:find("inventory") or pName:find("index") or pName:find("rebirth") or pName:find("pass") then
                            ignore = true
                            break
                        end
                        parentObj = parentObj.Parent
                    end
                    
                    if not ignore then
                        for _, w in ipairs(validWeathers) do
                            if cleanTxt:find(normalize(w)) then
                                -- Wir wollen primär das aktuelle/aktive Wetter wissen
                                detectedWeather = w
                            end
                        end
                    end
                end
            end
        end
    end

    latestCurrent = detectedWeather
end

-- Server-Hop Funktion
local function serverHop()
    StatusLbl.Text = "Status: Kein Meteor! Server Hop..."
    StatusLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local servers = {}
    local success = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        for _, server in ipairs(response.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end)
    
    if success and #servers > 0 then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        end)
    else
        pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
    end
end

-- Automatischer Ablauf beim Server-Start
task.spawn(function()
    -- Kurz warten, damit das Spiel auf dem iPad lädt
    task.wait(4)
    
    while isScanning do
        scanGame()
        
        CurrentLbl.Text = "Aktuelles Wetter: " .. latestCurrent
        
        -- Prüfen ob "Meteor Shower" aktiv ist
        local hasMeteor = (normalize(latestCurrent) == normalize("Meteor Shower"))
        
        if hasMeteor then
            StatusLbl.Text = "Status: METEOR SHOWER GEFUNDEN!"
            StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            isScanning = false -- Stoppt den Hop, du bleibst im Server!
            break
        else
            StatusLbl.Text = "Status: Kein Meteor. Hop in 3 Sek..."
            task.wait(3)
            
            -- Sicherheitscheck vor dem Sprung
            scanGame()
            if (normalize(latestCurrent) == normalize("Meteor Shower")) then
                StatusLbl.Text = "Status: METEOR SHOWER GEFUNDEN!"
                StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
                break
            else
                serverHop()
                break
            end
        end
        
        task.wait(1)
    end
end)
