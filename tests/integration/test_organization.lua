-- Test file to verify the new module organization structure

print("Testing module organization structure...")

-- Try to require all modules from both root and library paths
local function test_require(module_name)
    local success, module = pcall(require, module_name)
    if success then
        print("✓ Successfully loaded: " .. module_name)
        return true
    else
        print("✗ Failed to load: " .. module_name .. " - " .. tostring(module))
        return false
    end
end

-- Mock libraryUtil if needed
if not package.loaded['libraryUtil'] then
    package.loaded['libraryUtil'] = {
        checkType = function() return true end
    }
end

-- Mock mw if needed
if not package.loaded['mw'] then
    package.loaded['mw'] = {
        html = {
            create = function()
                return setmetatable({}, {__index = {}})
            end
        },
        text = {
            jsonDecode = function(s) return {} end,
            jsonEncode = function(t) return "{}" end
        }
    }
end

-- Mock Module:Mw html extension
package.loaded['Module:Mw html extension'] = {}

print("\n== Testing Core Modules ==")
-- Test loading core modules from root symlinks
test_require('Module:Functools')
test_require('Module:Funclib')
test_require('Module:Paramtest')
test_require('Module:Lists')

print("\n== Testing Library Modules ==")
-- Test loading modules directly from library
test_require('library.functools')
test_require('library.funclib')
test_require('library.paramtest')
test_require('library.lists')

print("\n== Testing Integration ==")
-- Test integration - this should work because the main module dependencies use Module:X paths
local lists = require('Module:Lists')
if lists then
    print("✓ Lists module loads with all dependencies")

    -- Check if key functions are available
    if type(lists.build_table) == 'function' then
        print("✓ lists.build_table function is available")
    else
        print("✗ lists.build_table function is missing")
    end

    if lists.COLUMN_PRESETS then
        print("✓ lists.COLUMN_PRESETS is available")
    else
        print("✗ lists.COLUMN_PRESETS is missing")
    end
else
    print("✗ Failed to load Lists module with dependencies")
end

print("\nTesting interface modules...")
-- We don't need to actually test loading these since they might have wiki-specific dependencies
-- Just check if they exist
local function check_file_exists(file_path)
    local f = io.open(file_path, "r")
    if f then
        f:close()
        print("✓ File exists: " .. file_path)
        return true
    else
        print("✗ File not found: " .. file_path)
        return false
    end
end

print("\nOrganization test complete!")
