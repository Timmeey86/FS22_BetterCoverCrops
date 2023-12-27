--- This class is responsible for adding a specialization to Mulchers which fertilizes when mulching over oilseed radish
MulcherFertilizerSpecialization = {
}

--- Checks for other required specializations.
---Since this is only added to implements with the Mulcher specilization anyway, we don't need to check anything here.
---@param   specializations     table   @A table of existing specializations (unused).
---@return  boolean     @Always true
function MulcherFertilizerSpecialization.prerequisitesPresent(specializations)
    return true
end

--- Overrides the processMulcherArea so we can add fertilizer during the mulching process
---@param   vehicleType     table     @Provides information about the current vehicle (or rather implement) type.
function MulcherFertilizerSpecialization.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processMulcherArea", MulcherFertilizerSpecialization.processMulcherArea)
end

--- Adds fertilizer when mulching ready-to-harvest cover crops
---@param   superFunc   function        @The GIANTS implementation of the method.
---@param   workArea    table           @Provides information about the area to be mulched.
---@param   dt          table           @delta time? Not used here.
---@return  integer     @The amount of pixels which were processed
---@return  integer     @The amount of pixels in the work area
function MulcherFertilizerSpecialization:processMulcherArea(superFunc, workArea, dt)

    -- Mulch and fertilize any cover crops in the work area
    CoverCropUtils.mulchAndFertilizeCoverCrops(workArea, true)

    -- Execute base game behavior
    return superFunc(self, workArea, dt)
end
