--[[
File System Utilities for Documentation Generation
Provides file I/O and directory operations for the documentation generator.
]]

local lfs = require('lfs')

local FileUtils = {}

-- Read a file's contents
-- @param filename string Path to the file to read
-- @return string|nil File contents or nil if file doesn't exist
function FileUtils.readFile(filename)
    local file = io.open(filename, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- Write content to a file
-- @param filename string Path to the file to write
-- @param content string Content to write to the file
function FileUtils.writeFile(filename, content)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end
    file:write(content)
    file:close()
end

-- Ensure a directory exists, create it if it doesn't
-- @param path string Directory path to ensure exists
-- @return boolean Success status
function FileUtils.ensureDirectory(path)
    local success = lfs.mkdir(path)
    return success
end

-- Get all Lua module files from a directory
-- @param directory string Directory path to scan
-- @return table List of Lua filenames
function FileUtils.getModuleFiles(directory)
    local files = {}
    for file in lfs.dir(directory) do
        if file:match("%.lua$") then
            table.insert(files, file)
        end
    end
    return files
end

-- Get the module name from a filename
-- @param filename string The filename (e.g., "Array.lua")
-- @return string|nil Module name (e.g., "Array") or nil if not a Lua file
function FileUtils.getModuleName(filename)
    return filename:match("(.+)%.lua$")
end

return FileUtils
