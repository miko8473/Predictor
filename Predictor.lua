-- Greedy Growers Meteor Hopper (Präzise Wetter-Erkennung)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen
pcall(function()
    if CoreGui:FindFirstChild("MeteorSnifferGui") then
        CoreGui.MeteorSnifferGui:Destroy()
    end
end)

-- Clean GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorSnifferGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 90)
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
    lbl.Size = UDim2.new(1, -20, 0, 22)
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

local CurrentLbl = createLabel(12, "Wetter: Normal", Color3.fromRGB(200, 200, 200))
local StatusLbl = createLabel(42, "Status: Prüfe Server...", Color3.fromRGB(255, 220, 100))

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

-- Prüfung beim Start
task.spawn(function()
    task.wait(4) -- Kurz warten bis das Spiel geladen ist
    
    local foundMeteor = false
    local activeWeather = "Normal"
    
    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                    local txt = gui.Text
                    if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                        local lowerTxt = txt:lower()
                        
                        -- Shop / Menüs / unnötige UI-Texte komplett ignorieren
                        if not lowerTxt:find("shop") and not lowerTxt:find("buy") and not lowerTxt:find("price") and not lowerTxt:find("chance") then
                            
                            -- Exakte Wetter-Erkennung (Kein falsches Misty mehr bei Normalwetter)
                            if lowerTxt:find("meteor shower") or lowerTxt:find("meteorshower") then
                                foundMeteor = true
                                activeWeather = "Meteor Shower"
                            elseif lowerTxt:find("acid rain") or lowerTxt:find("acidrain") then
                                activeWeather = "Acid Rain"
                            elseif lowerTxt:find("blizzard") then
                                activeWeather = "Blizzard"
                            elseif lowerTxt:find("sandstorm") then
                                activeWeather = "Sandstorm"
                            elseif lowerTxt:find("rainbow") then
                                activeWeather = "Rainbow"
                            elseif lowerTxt:find("lucky river") then
                                activeWeather = "Lucky River"
                            elseif lowerTxt == "misty" or lowerTxt:find("weather: misty") then
                                activeWeather = "Misty"
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- UI aktualisieren
    CurrentLbl.Text = "Wetter: " .. activeWeather
    
    if foundMeteor then
        StatusLbl.Text = "Status: METEOR GEFUNDEN! Bleibe hier!"
        StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        StatusLbl.Text = "Status: Kein Meteor (" .. activeWeather .. "), springe weiter..."
        task.wait(2)
        serverHop()
    end
end)
