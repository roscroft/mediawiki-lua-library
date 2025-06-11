#!/usr/bin/env lua

-- Simple test script for debugging
print("🧪 Testing Lua Documentation Generator Components")

-- Set up paths
package.path = package.path .. ";./lib/?.lua;./lib/parsers/?.lua"

-- Test each component
print("1. Testing ArgumentParser...")
local ArgumentParser = require('argument-parser')
local parser = ArgumentParser.new()
parser:addFlag("test", "t", "Test flag")
local result = parser:parse({ "--test" })
print("   ✅ ArgumentParser works, test flag:", result.test)

print("2. Testing ConfigLoader...")
local ConfigLoader = require('config-loader')
local config = ConfigLoader.loadConfig("./config/default.lua")
print("   ✅ ConfigLoader works, loaded config with input.sourceDir:", config.input.sourceDir)

print("3. Testing TemplateEngine...")
local TemplateEngine = require('template-engine')
local output = TemplateEngine.render("Hello {{name}}", { name = "World" })
print("   ✅ TemplateEngine works, output:", output)

print("4. Testing DocGenerator...")
local DocGenerator = require('doc-generator')
local generator = DocGenerator.new({
    input = { sourceDir = "./examples", patterns = { "*.lua" } },
    output = { dir = "./test-output", format = "html" }
})
print("   ✅ DocGenerator created successfully")

print("🎉 All components working!")
