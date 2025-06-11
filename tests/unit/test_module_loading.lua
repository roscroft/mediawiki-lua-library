-- Simple unit test for module loading in reorganized structure
-- This tests that modules can be loaded and basic functions work

print("Starting module loading test...")

-- Test basic Lua module loading (without MediaWiki dependencies)
local success, err = pcall(function()
    -- Test that we can load files as Lua modules (use relative paths)
    local array_code = assert(loadfile('src/modules/Array.lua'))
    print("✓ Array.lua loads successfully")

    local lists_code = assert(loadfile('src/modules/Lists.lua'))
    print("✓ Lists.lua loads successfully")

    local funclib_code = assert(loadfile('src/modules/Funclib.lua'))
    print("✓ Funclib.lua loads successfully")

    -- Note: We can't actually execute these modules without the MediaWiki environment
    -- but we can verify they compile correctly
end)

if success then
    print("✓ All module compilation tests passed")
    return true
else
    print("✗ Module compilation failed: " .. tostring(err))
    return false
end
