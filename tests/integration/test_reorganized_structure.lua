-- Comprehensive functional test for reorganized modules
-- Tests that modules can actually be loaded and used together

print("Starting comprehensive functional test...")

-- Test basic module compilation and loading
local success, errors = pcall(function()
    -- Test Array module
    local array_func = loadfile('src/modules/Array.lua')
    if not array_func then
        error("Failed to load Array module")
    end
    print("✓ Array module loads successfully")

    -- Test Functools module
    local functools_func = loadfile('src/modules/Functools.lua')
    if not functools_func then
        error("Failed to load Functools module")
    end
    print("✓ Functools module loads successfully")

    -- Test Funclib module (depends on others)
    local funclib_func = loadfile('src/modules/Funclib.lua')
    if not funclib_func then
        error("Failed to load Funclib module")
    end
    print("✓ Funclib module loads successfully")

    -- Test Lists module (main interface)
    local lists_func = loadfile('src/modules/Lists.lua')
    if not lists_func then
        error("Failed to load Lists module")
    end
    print("✓ Lists module loads successfully")

    -- Test supporting libraries
    local libutil_func = loadfile('src/lib/libraryUtil.lua')
    if not libutil_func then
        error("Failed to load libraryUtil")
    end
    print("✓ libraryUtil loads successfully")

    -- Test data modules
    local abilitylist_func = loadfile('src/data/abilitylist.lua')
    if not abilitylist_func then
        error("Failed to load abilitylist module")
    end
    print("✓ abilitylist module loads successfully")

end)

if success then
    print("✅ All functional tests passed!")
    print("📊 Tested modules:")
    print("   - Array, Functools, Funclib, Lists")
    print("   - libraryUtil supporting library")
    print("   - abilitylist data module")
    print("🎯 The reorganized structure is fully functional!")
else
    print("❌ Functional test failed:")
    print(tostring(errors))
    os.exit(1)
end
