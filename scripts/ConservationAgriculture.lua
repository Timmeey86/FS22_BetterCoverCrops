MOD_DIR = g_currentModDirectory or ""
MOD_NAME = g_currentModName or "unknown"

-- Dynamically load the specializations
source(MOD_DIR .. "scripts/specializations/MulcherFertilizerSpecialization.lua")
source(MOD_DIR .. "scripts/specializations/RollerFertilizerSpecialization.lua")
source(MOD_DIR .. "scripts/specializations/SeederFertilizerSpecialization.lua")
source(MOD_DIR .. "scripts/specializations/CultivatorFertilizerSpecialization.lua")
source(MOD_DIR .. "scripts/specializations/ChopperFertilizerSpecialization.lua")
source(MOD_DIR .. "scripts/specializations/FertilizingCultivatorSpecialization.lua")

local function printSpecRegistration(typeName, specType)
    print(("%s: Type %s will be handled by %s specialization"):format(MOD_NAME, typeName, specType))
end
---Registers the specializations for this mod
---@param   manager     table       the specialization manager
local function registerSpecialization(manager)

    if manager.typeName == "vehicle" then

        -- Register the specialization types in the specialization manager (this also allows other mods to extend them)
        g_specializationManager:addSpecialization(
            "CA_MulcherSpecialization", "MulcherFertilizerSpecialization", MOD_DIR .. "scripts/specializations/MulcherFertilizerSpecialization.lua", nil)
        g_specializationManager:addSpecialization(
            "CA_RollerSpecialization", "RollerFertilizerSpecialization", MOD_DIR .. "scripts/specializations/RollerFertilizerSpecialization.lua", nil)
        g_specializationManager:addSpecialization(
            "CA_SeederSpecialization", "SeederFertilizerSpecialization", MOD_DIR .. "scripts/specializations/SeederFertilizerSpecialization.lua", nil)
        g_specializationManager:addSpecialization(
            "CA_CultivatorSpecialization", "CultivatorFertilizerSpecialization", MOD_DIR .. "scripts/specializations/CultivatorFertilizerSpecialization.lua", nil)
        g_specializationManager:addSpecialization(
            "CA_ChopperSpecialization", "ChopperFertilizerSpecialization", MOD_DIR .. "scripts/specializations/ChopperFertilizerSpecialization.lua", nil)
        g_specializationManager:addSpecialization(
            "CA_FertilizingCultivatorSpecialization", "FertilizingCultivatorSpecialization", MOD_DIR .. "scripts/specializations/FertilizingCultivatorSpecialization.lua", nil)

        -- Add the specializations to vehicles based on which kind of specializations they already have
        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do
            if typeEntry ~= nil then
                local specializationApplied = false
                -- Allow any mulcher to mulch forageable crops
                if SpecializationUtil.hasSpecialization(Mulcher, typeEntry.specializations)  then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_MulcherSpecialization")
                    printSpecRegistration(typeName, "Mulcher")
                    specializationApplied = true
                end
                -- Allow any roller to mulch forageable crops, except for "FertilizingRollerCultivator"
                if SpecializationUtil.hasSpecialization(Roller, typeEntry.specializations) and
                    not SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations) then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_RollerSpecialization")
                    printSpecRegistration(typeName, "Roller")
                    specializationApplied = true
                end
                -- Modify any sowing machine (including ExtendedSowingMachine) to adapt the nitrogen behavior when seeding into cover crops
                if SpecializationUtil.hasSpecialization(SowingMachine, typeEntry.specializations) then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_SeederSpecialization")
                    printSpecRegistration(typeName, "Seeder")
                    specializationApplied = true
                end
                -- Allow any cultivator to mulch cover crops
                if SpecializationUtil.hasSpecialization(Cultivator, typeEntry.specializations) and
                    not SpecializationUtil.hasSpecialization(FertilizingCultivator, typeEntry.specializations) then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_CultivatorSpecialization")
                    printSpecRegistration(typeName, "Cultivator")
                    specializationApplied = true
                end
                -- Extend combines so straw chopping can fertilize the field if desired
                if SpecializationUtil.hasSpecialization(Combine, typeEntry.specializations) then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_ChopperSpecialization")
                    printSpecRegistration(typeName, "Chopper")
                    specializationApplied = true
                end
                -- Extend combines so straw chopping can fertilize the field if desired
                if SpecializationUtil.hasSpecialization(FertilizingCultivator, typeEntry.specializations) then
                    g_vehicleTypeManager:addSpecialization(typeName, MOD_NAME .. ".CA_FertilizingCultivatorSpecialization")
                    printSpecRegistration(typeName, "FertilizingCultivator")
                    specializationApplied = true
                end
                if not specializationApplied then
                    printSpecRegistration(typeName, "no")
                end
            end
        end
    end
end

---Creates a settings object which can be accessed from the UI and the rest of the code
---@param   mission     table   @The object which is later available as g_currentMission
local function createModSettings(mission)
    mission.conservationAgricultureSettings = CASettings:new()
    addModEventListener(mission.conservationAgricultureSettings)
end

---Destroys the settings object when it is no longer needed.
local function destroyModSettings()
    if g_currentMission ~= nil and g_currentMission.conservationAgricultureSettings ~= nil then
        removeModEventListener(g_currentMission.conservationAgricultureSettings)
        g_currentMission.conservationAgricultureSettings = nil
    end
end

-- Register specializations before type validation
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, registerSpecialization)

-- Do one-time calculations when the map is about to finish loading, and allow global access to the results
g_rollerCrimpingData = RollerCrimpingData.new()
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
        CASettingsRepository.restoreSettings()
        CALockMapRepository.restoreLockMapData()
    end)

-- Create (and cleanup) a global settings object
Mission00.load = Utils.prependedFunction(Mission00.load, createModSettings)
FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, destroyModSettings)
FSBaseMission.onConnectionReady = Utils.appendedFunction(FSBaseMission.onConnectionReady, function(...) CASettings.publishNewSettings() end )

-- Add elements to the settings UI
InGameMenuGeneralSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameOpen, CASettingsGUI.inj_onFrameOpen)
InGameMenuGeneralSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.updateGameSettings, CASettingsGUI.inj_updateGameSettings)

-- Save and load settings (loading is done in loadMapFinished)
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, function()
    CASettingsRepository.storeSettings()
    CALockMapRepository.storeLockMapData()
end)