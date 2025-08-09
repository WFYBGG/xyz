local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local LastSearch = ""
local LastUpdate = 0
-- Function to get unique areas
local function GetUniqueAreas()
    local success, areas = pcall(function()
        local areaList = {}
        local areaMarkers = ReplicatedStorage.WorldModel and ReplicatedStorage.WorldModel.AreaMarkers
        if not areaMarkers then
            print("AreaMarkers not found in ReplicatedStorage.WorldModel")
            return areaList
        end
        for _, marker in ipairs(areaMarkers:GetChildren()) do
            if marker.Name and not table.find(areaList, marker.Name) then
                table.insert(areaList, marker.Name)
            end
        end
        table.sort(areaList)
        if #areaList == 0 then
            print("No areas found in AreaMarkers")
        end
        return areaList
    end)
    if not success then
        print("Error getting areas: " .. tostring(areas))
        return {}
    end
    return areas
end
-- Function to get NPCs with town prefixes
local function GetNPCsWithTownPrefixes()
    local success, npcs = pcall(function()
        local npcList = {}
        local npcFolder = Workspace.NPCs
        if not npcFolder then
            print("NPCs folder not found in Workspace")
            return npcList
        end
        local townMarkers = ReplicatedStorage.TownMarkers
        if not townMarkers then
            print("TownMarkers not found in ReplicatedStorage")
            return npcList
        end
       
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc.Name then
                local npcName = npc.Name
                local prefixedName = npcName
               
                for _, town in ipairs(townMarkers:GetChildren()) do
                    if town:FindFirstChild(npcName) then
                        prefixedName = town.Name .. " " .. npcName
                        break
                    end
                end
               
                table.insert(npcList, prefixedName)
            end
        end
        table.sort(npcList)
        if #npcList == 0 then
            print("No NPCs found in Workspace.NPCs")
        end
        return npcList
    end)
    if not success then
        print("Error getting NPCs: " .. tostring(npcs))
        return {}
    end
    return npcs
end
-- Function to update dropdowns
local function UpdateDropdowns(searchText)
    local success, result = pcall(function()
        local areas = GetUniqueAreas()
        local npcs = GetNPCsWithTownPrefixes()
       
        if #areas == 0 then
            print("Warning: Area list is empty")
            areas = {"No Areas Found"}
        end
        if #npcs == 0 then
            print("Warning: NPC list is empty")
            npcs = {"No NPCs Found"}
        end
       
        -- Filter based on search text
        local filteredAreas = {}
        local filteredNPCs = {}
        searchText = searchText:lower()
       
        for _, area in ipairs(areas) do
            if searchText == "" or area:lower():find(searchText) then
                table.insert(filteredAreas, area)
            end
        end
       
        for _, npc in ipairs(npcs) do
            if searchText == "" or npc:lower():find(searchText) then
                table.insert(filteredNPCs, npc)
            end
        end
       
        -- Ensure lists are not empty
        if #filteredAreas == 0 then
            filteredAreas = areas
            print("No areas match search, reverting to full list")
        end
        if #filteredNPCs == 0 then
            filteredNPCs = npcs
            print("No NPCs match search, reverting to full list")
        end
       
        -- Update dropdowns
        Options.Areas:SetValues(filteredAreas)
        Options.NPCs:SetValues(filteredNPCs)
       
        -- Set default values if needed
        if #filteredAreas > 0 and (Options.Areas.Value == "" or not table.find(filteredAreas, Options.Areas.Value)) then
            Options.Areas:SetValue(filteredAreas[1])
            print("Set default area: " .. filteredAreas[1])
        elseif #filteredAreas == 0 then
            Options.Areas:SetValue("")
            print("Cleared area selection due to empty filtered list")
        end
       
        if #filteredNPCs > 0 and (Options.NPCs.Value == "" or not table.find(filteredNPCs, Options.NPCs.Value)) then
            Options.NPCs:SetValue(filteredNPCs[1])
            print("Set default NPC: " .. filteredNPCs[1])
        elseif #filteredNPCs == 0 then
            Options.NPCs:SetValue("")
            print("Cleared NPC selection due to empty filtered list")
        end
    end)
    if not success then
        print("Error updating dropdowns: " .. tostring(result))
    end
end
-- Update search bar callback
MainGroup3:AddInput("Search", {
    Text = "Search",
    Default = "",
    Placeholder = "Search or select below...",
    Callback = function(value)
        local success, result = pcall(function()
            if value == LastSearch then return end
            LastSearch = value
            UpdateDropdowns(value)
        end)
        if not success then
            print("Error in search callback: " .. tostring(result))
        end
    end
})
-- Initialize dropdowns
UpdateDropdowns("")
-- Monitor for changes in areas and NPCs
game:GetService("RunService").Heartbeat:Connect(function()
    local success, result = pcall(function()
        if tick() - LastUpdate >= 1 then -- Update every second to avoid lag
            UpdateDropdowns(LastSearch)
            LastUpdate = tick()
        end
    end)
    if not success then
        print("Error in heartbeat update: " .. tostring(result))
    end
end)
