-- Greedy Growers Meteor Hopper (Direct Game Data & UI Inspector)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen
pcall(function()
    if CoreGui:FindFirstChild("MeteorSnifferGui") then
        CoreGui.MeteorSnifferGui:Destroy()
    end
end)

-- Profi GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorSnifferGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 140)
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
    lbl.Size = UDim2.new(1, -24, 0, 24)
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

local CurrentLbl = createLabel(12, "Aktuell: Suche...", Color3.fromRGB(200, 200, 200))
local NextLbl    = createLabel(40, "Nächstes: Suche...", Color3.fromRGB(100, 220, 255))
local StatusLbl  = createLabel(72, "Status: Analysiere Spieldaten...", Color3.fromRGB(255, 220, 100))

local validWeathers = {
    "Meteor Shower", "Acid Rain", "Blizzard", "Sandstorm", "Misty", "Rainbow", "Lucky River"
}

local function normalize(str)
    return tostring(str):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

-- Server-Hop Funktion
local function serverHop()
    StatusLbl.Text = "Status: Kein Meteor -> Server Hop!"
    StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 0)
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

-- Smarter Scanner: Durchsucht Spieldaten (ReplicatedStorage/Workspace) + Bildschirm
local function scanGame()
    local detectedWeather = "Normal"
    local detectedNext = "Keines"

    pcall(function()
        -- 1. Versuch: Spieldaten / Werte direkt aus ReplicatedStorage oder Workspace auslesen
        local function checkFolder(parent)
            if not parent then return end
            for _, obj in ipairs(parent:GetDescendants()) do
                local nameLower = obj.Name:lower()
                if nameLower:find("weather") or nameLower:find("wetter") or nameLower:find("event") then
                    local val = nil
                    if obj:IsA("StringValue") or obj:IsA("IntValue") then
                        val = tostring(obj.Value)
                    elseif obj:IsA("Attribute") or (obj.GetAttribute and obj:GetAttribute("Weather")) then
                        val = tostring(obj:GetAttribute("Weather"))
                    end
                    
                    if val then
                        for _, w in ipairs(validWeathers) do
                            if normalize(val):find(normalize(w)) then
                                if nameLower:find("next") or nameLower:find("upcoming") then
                                    detectedNext = w
                                else
                                    detectedWeather = w
                                end
                            end
                        end
                    end
                end
            end
        end

        checkFolder(ReplicatedStorage)
        checkFolder(Workspace)

        -- 2. Versuch: Wenn in den Spieldaten nichts gefunden wurde, den Bildschirm scannen
        if detectedWeather == "Normal" and LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                    local txt = gui.Text
                    local cleanTxt = normalize(txt)
                    
                    if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                        local ignore = false
                        local parentObj = gui.Parent
                        while parentObj and parentObj ~= LocalPlayer.PlayerGui do
                            local pName = parentObj.Name:lower()
                            if pName:find("shop") or pName:find("market") or pName:find("guide") or pName:find("info") or pName:find("index") or pName:find("list") or pName:find("pass") then
                                ignore = true
                                break
                            end
                            parentObj = parentObj.Parent
                        end
                        
                        if not ignore then
                            for _, w in ipairs(validWeathers) do
                                local normW = normalize(w)
                                if cleanTxt:find(normW) then
                                    local pName = gui.Parent.Name:lower()
                                    local gName = gui.Name:lower()
                                    if cleanTxt:find("next") or cleanTxt:find("upcoming") or pName:find("next") or gName:find("next") or pName:find("upcoming") then
                                        detectedNext = w
                                    else
                                        detectedWeather = w
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    return detectedWeather, detectedNext
end

-- Hauptlogik mit Multi-Scan
task.spawn(function()
    StatusLbl.Text = "Status: Warte auf Verbindung..."
    task.wait(5)
    
    local foundMeteor = false
    local finalWeather = "Normal"
    local finalNext = "Keines"
    
    for attempt = 1, 5 do
        StatusLbl.Text = "Status: Prüfe Spieldaten (" .. attempt .. "/5)..."
        
        local cur, nxt = scanGame()
        if cur ~= "Normal" then finalWeather = cur end
        if nxt ~= "Keines" then finalNext = nxt end
        
        CurrentLbl.Text = "Aktuell: " .. finalWeather
        NextLbl.Text    = "Nächstes: " .. finalNext
        
        if normalize(finalWeather) == "meteor shower" or normalize(finalNext) == "meteor shower" then
            foundMeteor = true
            break
        end
        
        task.wait(1.5)
    end
    
    if foundMeteor then
        StatusLbl.Text = "Status: 🎯 METEOR GEFUNDEN! Bleibe hier!"
        StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        StatusLbl.Text = "Status: Kein Meteor -> Server Hop in 2s..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        task.wait(2)
        serverHop()
    end
end)
