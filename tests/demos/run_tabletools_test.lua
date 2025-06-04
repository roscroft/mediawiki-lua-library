#!/usr/bin/env lua

-- Set up the path for our modules
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua"

-- Run the integration test
local result = dofile("tests/test_tabletools_array_integration.lua")

print("\n" .. string.rep("=", 60))
print("🏆 TABLETOOLS-ARRAY INTEGRATION COMPLETE")
print(string.rep("=", 60))
print("Status: " .. result.status)
print("Tests Passed: " .. result.tests_passed)
print("Performance: " .. result.performance_improvement)
print("Compatibility: " .. result.compatibility)
print(string.rep("=", 60))