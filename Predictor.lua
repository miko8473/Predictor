-- Greedy Growers Meteor Hopper (Strict Next-Weather Event Only)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI restlos entfernen
pcall(function()
    if CoreGui:FindFirstChild("MeteorSnifferGui") then
        CoreGui.MeteorSnifferGui:Destroy()
    end
end)

-- GUI erstellen
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

local CurrentLbl = createLabel(12, "Aktuell: Lädt...", Color3.fromRGB(200, 200, 200))
local NextLbl    = createLabel(40, "Nächstes: Lädt...", Color3.fromRGB(100, 220, 255))
local StatusLbl  = createLabel(72, "Status: Scanne Server...", Color3.fromRGB(255, 220, 100))

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

-- Scanner für echte Events (kein Normal für das nächste Event)
local function scanGame()
    local detectedWeather = "Normal"
    local detectedNext = "Suche..."

    pcall(function()
        -- 1. Spieldaten durchsuchen
        local function searchFolder(parent)
            if not parent then return end
            for _, obj in ipairs(parent:GetDescendants()) do
                local nameLower = obj.Name:lower()
                if nameLower:find("weather") or nameLower:find("wetter") or nameLower:find("event") or nameLower:find("queue") then
                    local val = nil
                    if obj:IsA("StringValue") or obj:IsA("IntValue") then
                        val = tostring(obj.Value)
                    elseif obj.GetAttribute then
                        val = tostring(obj:GetAttribute("Weather") or obj:GetAttribute("NextWeather") or obj:GetAttribute("Event"))
                    end
                    
                    if val and val ~= "nil" and val ~= "" then
                        for _, w in ipairs(validWeathers) do
                            if normalize(val):find(normalize(w)) then
                                if nameLower:find("next") or nameLower:find("upcoming") or nameLower:find("queue") then
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

        searchFolder(ReplicatedStorage)
        searchFolder(Workspace)

        -- 2. GUI durchsuchen
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                    local txt = gui.Text
                    local cleanTxt = normalize(txt)
                    
                    if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                        local pName = gui.Parent.Name:lower()
                        local gName = gui.Name:lower()
                        
                        local ignore = false
                        local parentObj = gui.Parent
                        while parentObj and parentObj ~= LocalPlayer.PlayerGui do
                            local pn = parentObj.Name:lower()
                            if pn:find("shop") or pn:find("market") or pn:find("guide") or pn:find("info") or pn:find("pass") then
                                ignore = true
                                break
                            end
                            parentObj = parentObj.Parent
                        end
                        
                        if not ignore then
                            for _, w in ipairs(validWeathers) do
                                local normW = normalize(w)
                                if cleanTxt:find(normW) then
                                    if cleanTxt:find("next") or cleanTxt:find("upcoming") or pName:find("next") or gName:find("next") or pName:find("upcoming") or pName:find("queue") then
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

-- Hauptlogik
task.spawn(function()
    task.wait(5) -- Laden abwarten
    
    local finalWeather = "Normal"
    local finalNext = "Wartet..."
    
    for attempt = 1, 6 do
        StatusLbl.Text = "Status: Analysiere Events (" .. attempt .. "/6)..."
        
        local cur, nxt = scanGame()
        if cur ~= "Normal" then finalWeather = cur end
        if nxt ~= "Suche..." and nxt ~= "Wartet..." then finalNext = nxt end
        
        CurrentLbl.Text = "Aktuell: " .. finalWeather
        NextLbl.Text    = "Nächstes: " .. finalNext
        
        -- Wenn Meteor gefunden (aktuell ODER nächste) -> SOFORT BLEIBEN
        if normalize(finalWeather) == "meteor shower" or normalize(finalNext) == "meteor shower" then
            StatusLbl.Text = "Status: 🎯 METEOR GEFUNDEN! Bleibe hier!"
            StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            return
        end
        
        task.wait(1.5)
    end
    
    -- Wenn nach allen Versuchen kein Meteor da ist -> Hop!
    StatusLbl.Text = "Status: Kein Meteor -> Server Hop!"
    StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
    task.wait(1.5)
    serverHop()
end)
