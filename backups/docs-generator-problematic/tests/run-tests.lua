#!/usr/bin/env lua

--[[
Test suite for Lua Documentation Generator
Runs comprehensive tests for all components
]]

package.path = package.path .. ";./lib/?.lua;./lib/parsers/?.lua"

local function runTests()
    print("🧪 Running Lua Documentation Generator Test Suite")
    print("=" .. string.rep("=", 50))

    local totalTests = 0
    local passedTests = 0

    -- Helper function to run a test
    local function test(name, testFunc)
        totalTests = totalTests + 1
        io.write("Testing " .. name .. "... ")

        local success, result = pcall(testFunc)
        if success and result then
            print("✅ PASS")
            passedTests = passedTests + 1
        else
            print("❌ FAIL")
            if not success then
                print("  Error: " .. tostring(result))
            end
        end
    end

    -- Test ArgumentParser
    test("ArgumentParser", function()
        local ArgumentParser = require("argument-parser")
        local parser = ArgumentParser.new()
        parser:addOption("input", "i", "Input directory", ".")
        parser:addFlag("verbose", "v", "Verbose output")

        local args = parser:parse({ "--input", "test", "--verbose" })
        return args.input == "test" and args.verbose == true
    end)

    -- Test ConfigLoader
    test("ConfigLoader", function()
        local ConfigLoader = require("config-loader")
        local loader = ConfigLoader.new()
        local config = loader:loadConfig("./config/default.lua")
        return config and config.input and config.output
    end)

    -- Test TemplateEngine
    test("TemplateEngine", function()
        local TemplateEngine = require("template-engine")
        local template = "Hello {{name}}! You have {{count}} messages."
        local vars = { name = "World", count = 5 }
        local result = TemplateEngine.render(template, vars)
        return result == "Hello World! You have 5 messages."
    end)

    -- Test TemplateEngine loops
    test("TemplateEngine loops", function()
        local TemplateEngine = require("template-engine")
        local template = "Items: {{#each items}}<{{.}}>{{/each}}"
        local vars = { items = { "a", "b", "c" } }
        local result = TemplateEngine.render(template, vars)
        return result == "Items: <a><b><c>"
    end)

    -- Test TemplateEngine conditionals
    test("TemplateEngine conditionals", function()
        local TemplateEngine = require("template-engine")
        local template = "{{#if show}}Visible{{/if}}{{#if hide}}Hidden{{/if}}"
        local vars = { show = true, hide = false }
        local result = TemplateEngine.render(template, vars)
        return result == "Visible"
    end)

    -- Test CommentParser
    test("CommentParser", function()
        local CommentParser = require("comment-parser")
        local source = [=[
        --[[
         * Test function
         * @param {string} name The name
         * @returns {string} Greeting
         ]]
        function test(name)
            return "Hello " .. name
        end
        ]=]

        local comments = CommentParser.parseComments(source)
        return #comments > 0 and comments[1].description:find("Test function")
    end)

    -- Test TypeParser
    test("TypeParser", function()
        local TypeParser = require("type-parser")
        local parsed = TypeParser.parseType("string?")
        return parsed.base == "string" and parsed.optional == true
    end)

    -- Test TypeParser array types
    test("TypeParser arrays", function()
        local TypeParser = require("type-parser")
        local parsed = TypeParser.parseType("number[]")
        return parsed.base == "number" and parsed.array == true
    end)

    -- Test TypeParser union types
    test("TypeParser unions", function()
        local TypeParser = require("type-parser")
        local parsed = TypeParser.parseType("string|number")
        return parsed.base == "union" and #parsed.union == 2
    end)

    -- Test FunctionParser
    test("FunctionParser", function()
        local FunctionParser = require("function-parser")
        local parser = FunctionParser.new()
        local source = "function test(a, b) return a + b end"
        local functions = parser:parse(source)
        return #functions > 0
    end)

    -- Test DocumentationGenerator basic functionality
    test("DocumentationGenerator", function()
        local DocumentationGenerator = require("doc-generator")
        local config = {
            input = { sourceDir = "./examples", patterns = { "*.lua" } },
            output = { dir = "./test-output", format = "html" }
        }
        local generator = DocumentationGenerator.new(config)
        return generator ~= nil
    end)

    -- Print test results
    print("\n" .. string.rep("=", 50))
    print(string.format("Test Results: %d/%d passed (%.1f%%)",
        passedTests, totalTests, (passedTests / totalTests) * 100))

    if passedTests == totalTests then
        print("🎉 All tests passed!")
        return true
    else
        print("❌ Some tests failed!")
        return false
    end
end

-- Run the tests
local success = runTests()
os.exit(success and 0 or 1)
