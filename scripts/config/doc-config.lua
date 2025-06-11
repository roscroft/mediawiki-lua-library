--[[
Configuration for Documentation Generation
Centralized configuration settings for the documentation generator.
]]

local DocConfig = {
    -- Directory paths
    directories = {
        source = "src/modules",
        docs = "src/module-docs"
    },

    -- Function parsing settings
    parsing = {
        -- Minimum percentage of functions an object must have to be considered primary
        objectDetectionThreshold = 0.3,
        -- Maximum number of functions to show in debug output
        maxDebugOutput = 10,
        -- Comment block detection patterns
        commentPatterns = {
            start = "^%s*%-%-%-",
            jsDocParam = "^@param%s+",
            jsDocReturn = "^@return%s+",
            jsDocGeneric = "^@generic%s+",
            jsDocDirective = "^@[%w_]+",
            codeBlock = "^```"
        }
    },

    -- Function sorting configuration
    sorting = {
        -- Use hierarchical sorting based on object structure
        hierarchical = true,
        -- Primary sort by depth (deeper hierarchies first)
        primaryByDepth = true,
        -- Secondary sort by object path (alphabetical)
        secondaryByPath = true,
        -- Tertiary sort by function name (alphabetical)
        tertiaryByName = true
    },

    -- MediaWiki template configuration
    templates = {
        mediawiki = {
            -- Main template structure
            header = "{{Documentation}}\n{{Helper module",
            footer = "}}",
            -- Function documentation template parts
            functionTemplate = {
                namePrefix = "|fname",
                typePrefix = "|ftype",
                usePrefix = "|fuse"
            },
            -- Example section configuration
            exampleSection = {
                header = "|example =",
                codeStart = "<syntaxhighlight lang='lua'>",
                codeEnd = "</syntaxhighlight>",
                placeholder = "    -- Example usage of %s will be added manually"
            }
        }
    },

    -- Debug and output settings
    debug = {
        -- Show function sorting order
        showSortingOrder = true,
        -- Show object detection results
        showObjectDetection = true,
        -- Show parsing progress
        showParsingProgress = true
    },

    -- Type annotation formatting
    typeFormatting = {
        -- HTML tags for different type elements
        typeTag = "samp",
        returnArrow = "-> ",
        genericPrefix = "generic: ",
        -- Separators
        paramSeparator = "<br>",
        typeSeparator = ": "
    }
}

return DocConfig
