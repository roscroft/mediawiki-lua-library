--[[
=====================================
MediaWiki Funclib Module - Enhanced
=====================================

Domain-specific functional programming library for MediaWiki table/column/query operations.
This module provides high-level utilities for UI components, data transformation, and
MediaWiki-specific functionality, building upon the core functional programming tools
in Module:Functools.

Features:
- Domain-specific column and table builders
- MediaWiki wikitext generation utilities
- Validation systems for UI components
- Template and parameter processing utilities
- Integration with MediaWiki's semantic queries
- Performance-optimized UI component builders

Architecture:
- funclib: Domain-specific, MediaWiki-focused utilities
- functools: Pure functional programming utilities (imported)
- Separation of concerns for maintainability and reusability

Examples:
```lua
local funclib = require('Module:Funclib')

-- Column building
local column = funclib.make_preset_column('LEVEL', {
    header = 'Name',
    field = 'name',
    align = 'left'
})

-- Table generation with validation
local table_config = {
    columns = {column},
    data = {{name = 'Alice'}, {name = 'Bob'}}
}
local html = funclib.build_table(table_config)

-- Template processing
local params = funclib.process_template_params(frame.args, {
    required = {'title'},
    optional = {'description', 'category'}
})
```

@module Funclib
@version 2.0.0
@author MediaWiki Lua Team
@since 2024
--]]

-- Table/Column/Query Specific Library
--
-- This module provides domain-specific functions for working with tables, columns, and queries.
-- Pure functional programming utilities are in Module:Functools, which is imported here.
-- funclib focuses on specific UI components and builders, while functools provides
-- general-purpose functional programming tools.

local funclib = {}

-- Imports
local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType

-- Import functional utilities from Functools
local functools = require('Functools')
-- Import Arguments for frame processing
local arguments = require('Arguments')
-- ======================
-- TABLE/COLUMN VALIDATION - Domain Specific
-- ======================

-- Use functools for validation (delegate to pure functional validation)
funclib.validate_value = functools.validation and functools.validation.validate_value or
    function(value, rules) return true end
funclib.validate_options = functools.validation and functools.validation.validate_options or
    function(options, rules) return nil end
funclib.default_value = functools.validation and functools.validation.default_value or
    function(value, default) return value ~= nil and value or default end

-- Standard validation rule sets
funclib.VALIDATION_RULES = {
    COLUMN = {
        header = { type = 'string', required = true },
        field = { type = 'string', required = true },
        align = { type = 'string', required = false },
        colspan = { type = 'number', required = false },
        formatter = { type = 'function', required = false },
        tooltip = { type = 'string', required = false },
        sortable = { type = 'boolean', required = false }
    }
}

function funclib.validate_column(column, index)
    -- Column must be a table
    local valid_table = funclib.validate_value(column, { type = 'table', required = true })
    if valid_table ~= true then
        return false, string.format("Column %s must be a table", index or "")
    end

    -- Validate required and optional fields
    local valid_fields = funclib.validate_options(column, funclib.VALIDATION_RULES.COLUMN)
    if valid_fields then
        return false, string.format("Column %s: %s", index or "", valid_fields)
    end

    return true
end

function funclib.validate_columns(columns)
    for i, col in ipairs(columns) do
        local valid, err = funclib.validate_column(col, i)
        if not valid then
            return false, err
        end
    end
    return true
end

-- ======================
-- SAFE FUNCTION UTILITIES - Delegate to functools
-- ======================

funclib.safe_call = functools.safe_call
funclib.maybe_call = functools.maybe_call
funclib.chain_safe = functools.chain_safe

-- ======================
-- TABLE-SPECIFIC ROW MAPPING
-- ======================

function funclib.make_row_mapper(field_alignments)
    return function(t, entry)
        t:tr()
        for field, align in pairs(field_alignments) do
            t:td(entry[field] or "")
                :addClass("align-" .. align)
                :naIf(not entry[field])
        end
        return t
    end
end

-- ======================
-- FORMATTING HELPERS - Direct Access
-- ======================

function funclib.tooltip(text, tooltip, format_str)
    -- Use functools validation for content checking
    if not funclib.default_value(tooltip, nil) then
        return text
    end

    format_str = format_str or '<span class="Tooltip-noedit" title="%s">%s</span>'
    return string.format(format_str, tooltip, text)
end

function funclib.icon(config, value)
    if not config[value] then return "" end
    local icon = config[value]
    return string.format(
        '<img alt="%s" src="%s" width="%s" class="image" />',
        icon.link or "",
        icon.file or "",
        icon.width or "30"
    )
end

-- String formatting helpers that use functional validation
function funclib.format_name(name)
    -- Use functools validation instead of direct paramtest
    if not funclib.default_value(name, nil) then
        return ""
    end

    -- Use functional composition for string transformation
    if functools.pipe then
        return functools.pipe(
            funclib.default_value,
            function(str) return str:sub(1, 1):upper() .. str:sub(2) end
        )(name)
    else
        -- Fallback implementation
        local cleaned = funclib.default_value(name, "")
        return cleaned ~= "" and (cleaned:sub(1, 1):upper() .. cleaned:sub(2)) or ""
    end
end

-- String manipulation utilities
function funclib.trim(text)
    if type(text) ~= 'string' then
        return text
    end
    return text:gsub("^%s*(.-)%s*$", "%1")
end

-- Table manipulation utilities
function funclib.keys(table)
    checkType('funclib.keys', 1, table, 'table')

    local keys = {}
    local index = 1
    for key, _ in pairs(table) do
        keys[index] = key
        index = index + 1
    end
    return keys
end

-- ======================
-- CONSTANTS - Direct Access
-- ======================

funclib.DEFAULTS = {
    LIMIT = 10000,
    ALIGN = "left",
    IMAGE_SIZE = "30px"
}

funclib.FORMAT = {
    HTML = {
        ERROR = '<div class="error">%s</div>',
        TOOLTIP = '<span class="Tooltip-noedit" title="%s">%s</span>'
    },
    TABLE = {
        CLASS = {
            BASE = "wikitable",
            SORTABLE = "sortable",
            ALIGN = "align-%s-%d"
        }
    }
}

funclib.SMW_FORMAT = {
    CATEGORY = '[[Category:%s]]',
    FIELD = "?%s=JSON",
    MAINLINE = "mainline=-",
    LIMIT = "limit=%d"
}

funclib.ICONS = {
    MEMBERS = {
        [false] = {
            file = 'F2P icon.png',
            width = '30',
            link = 'Free-to-play'
        },
        [true] = {
            file = 'P2P icon.png',
            width = '30',
            link = 'Members'
        }
    }
}

-- ======================
-- COLUMN CONFIGURATION - Direct Access
-- ======================

funclib.COLUMN_PRESETS = {
    LEVEL = {
        header = "Level",
        align = "center",
        field = "level"
    },
    MEMBERS = {
        header = "Members",
        align = "center",
        field = "members",
        formatter = function(is_members)
            return funclib.icon(funclib.ICONS.MEMBERS, is_members)
        end
    },
    NAME = {
        header = "Name",
        align = "left",
        field = "name"
    }
}

function funclib.make_preset_column(preset, options)
    local base = funclib.COLUMN_PRESETS[preset]
    if not base then
        error("Unknown column preset: " .. preset)
    end
    return funclib.make_column(base.header, options or {}, base)
end

function funclib.process_column_config(config, defaults)
    -- Remove dependency on Paramtest module
    defaults = defaults or funclib.DEFAULTS

    -- Use functools validation instead
    config.align = funclib.default_value(config.align, defaults.ALIGN)
    config.sortable = config.sortable ~= false

    local classes = { funclib.FORMAT.TABLE.CLASS.BASE }
    if config.sortable then
        table.insert(classes, funclib.FORMAT.TABLE.CLASS.SORTABLE)
    end

    table.insert(classes, string.format(
        funclib.FORMAT.TABLE.CLASS.ALIGN,
        config.align,
        funclib.default_value(config.colspan, 1)
    ))

    config.classes = table.concat(classes, " ")

    return config
end

function funclib.make_column(header, options, defaults)
    if type(header) ~= 'string' then
        error("Header must be a string", 2)
    end

    options = options or {}
    defaults = defaults or {}

    if type(options) ~= 'table' then
        error("Options must be a table", 2)
    end

    if type(defaults) ~= 'table' then
        error("Defaults must be a table", 2)
    end

    local config = {
        header = header
    }

    -- Start with defaults
    for k, v in pairs(defaults) do
        config[k] = v
    end

    -- Override with column-specific options
    for k, v in pairs(options) do
        config[k] = v
    end

    -- Apply tooltip if specified
    if config.tooltip then
        config.header = funclib.tooltip(header, config.tooltip)
    end

    -- Use functional validation for proper defaults
    config.align = funclib.default_value(config.align, "left")
    config.sortable = config.sortable ~= false -- true unless explicitly false

    return config
end

-- ======================
-- JSON UTILITIES - Direct Access
-- ======================

function funclib.safe_decode_json(json_str, name)
    -- Use functional validation for content checking
    if not funclib.default_value(json_str, nil) then
        return nil, "Empty JSON string"
    end

    local success, result = pcall(mw.text.jsonDecode, json_str)
    if not success then
        return nil, string.format("JSON decode failed in %s: %s", name or "unknown", result)
    end
    return result
end

-- ======================
-- BUILDER CLASSES - Direct Access
-- ======================

-- ColumnBuilder for configuring table columns
local ColumnBuilder = {}
ColumnBuilder.__index = ColumnBuilder

function ColumnBuilder.new(columns)
    return setmetatable({
        columns = columns or {}
    }, ColumnBuilder)
end

function ColumnBuilder:add_column(header, options)
    table.insert(self.columns, funclib.make_column(header, options or {}))
    return self
end

function ColumnBuilder:add_columns(columns)
    for _, col in ipairs(columns) do
        if type(col) == 'string' then
            self:add_column(col, {})
        else
            self:add_column(col.header, col)
        end
    end
    return self
end

function ColumnBuilder:apply_formatter(formatter, indices)
    if indices then
        for _, i in ipairs(indices) do
            if self.columns[i] then
                self.columns[i].formatter = formatter
            end
        end
    else
        for i = 1, #self.columns do
            self.columns[i].formatter = formatter
        end
    end
    return self
end

function ColumnBuilder:build()
    for i, col in ipairs(self.columns) do
        self.columns[i] = funclib.process_column_config(col)
    end
    return self.columns
end

-- TableBuilder for creating HTML tables
local TableBuilder = {}
TableBuilder.__index = TableBuilder

function TableBuilder.new(columns)
    local self = setmetatable({
        columns = columns,
        rows = {},
        classes = { funclib.FORMAT.TABLE.CLASS.BASE },
        attributes = {},
        current_row = nil
    }, TableBuilder)

    if columns then
        for _, col in ipairs(columns) do
            if col.sortable ~= false then
                table.insert(self.classes, funclib.FORMAT.TABLE.CLASS.SORTABLE)
                break
            end
        end
    end

    return self
end

function TableBuilder:add_class(class)
    table.insert(self.classes, class)
    return self
end

function TableBuilder:set_attribute(name, value)
    self.attributes[name] = value
    return self
end

function TableBuilder:start_row()
    self.current_row = {
        cells = {},
        classes = {},
        attributes = {}
    }
    return self
end

function TableBuilder:add_cell(content, options)
    if not self.current_row then
        self:start_row()
    end

    table.insert(self.current_row.cells, {
        content = content,
        options = options or {}
    })

    return self
end

function TableBuilder:end_row()
    if self.current_row then
        table.insert(self.rows, self.current_row)
        self.current_row = nil
    end
    return self
end

function TableBuilder:build()
    local table = mw.html.create('table')

    local class_string = ""
    if #self.classes > 0 then
        class_string = table.concat(self.classes, ' ')
    end
    table:addClass(class_string)
    for name, value in pairs(self.attributes) do
        table:attr(name, value)
    end

    if self.columns then
        local header = table:tag('tr')
        for i, col in ipairs(self.columns) do
            local th = header:tag('th')
                :addClass(string.format(
                    funclib.FORMAT.TABLE.CLASS.ALIGN,
                    col.align or funclib.DEFAULTS.ALIGN,
                    i
                ))
                :wikitext(col.header)

            if col.colspan then
                th:attr('colspan', col.colspan)
            end
        end
    end

    for _, row in ipairs(self.rows) do
        local tr = table:tag('tr')

        local row_class_string = ""
        if #row.classes > 0 then
            row_class_string = table.concat(row.classes, ' ')
        end
        tr:addClass(row_class_string)
        for name, value in pairs(row.attributes) do
            tr:attr(name, value)
        end

        for _, cell in ipairs(row.cells) do
            local td = tr:tag('td')
                :addClass(string.format(
                    funclib.FORMAT.TABLE.CLASS.ALIGN,
                    cell.options.align or funclib.DEFAULTS.ALIGN,
                    1
                ))
                :wikitext(cell.content)

            for name, value in pairs(cell.options) do
                if name ~= "align" then
                    td:attr(name, value)
                end
            end
        end
    end

    return tostring(table)
end

-- QueryBuilder for building SMW queries
local QueryBuilder = {}
QueryBuilder.__index = QueryBuilder

function QueryBuilder.new(category)
    return setmetatable({
        category = category,
        conditions = {},
        properties = {},
        limit = funclib.DEFAULTS.LIMIT
    }, QueryBuilder)
end

function QueryBuilder:add_condition(condition)
    if condition then
        table.insert(self.conditions, condition)
    end
    return self
end

function QueryBuilder:add_property(property)
    if property then
        table.insert(self.properties, property)
    end
    return self
end

function QueryBuilder:set_limit(limit)
    self.limit = limit
    return self
end

function QueryBuilder:build()
    local query = {}

    if self.category then
        table.insert(query, string.format('[Category:%s]', self.category))
    end

    for _, prop in ipairs(self.properties) do
        table.insert(query, string.format('?%s', prop))
    end

    for _, cond in ipairs(self.conditions) do
        table.insert(query, cond)
    end

    table.insert(query, 'mainline=-')
    table.insert(query, string.format('limit=%d', self.limit))

    return table.concat(query, '\n')
end

-- ======================
-- MAIN API - Direct Access
-- ======================

-- Expose builders directly
funclib.ColumnBuilder = ColumnBuilder
funclib.TableBuilder = TableBuilder
funclib.QueryBuilder = QueryBuilder

-- Generic table builder utility
function funclib.build_table(columns, rows, options)
    -- Simple parameter validation without CodeStandards
    if type(columns) ~= 'table' then
        error("Columns must be a table", 2)
    end
    if type(rows) ~= 'table' then
        error("Rows must be a table", 2)
    end

    options = options or {}

    local builder = TableBuilder.new(columns)

    if options.classes then
        for _, class in ipairs(options.classes) do
            builder:add_class(class)
        end
    end

    if options.attributes then
        for name, value in pairs(options.attributes) do
            builder:set_attribute(name, value)
        end
    end

    for _, row in ipairs(rows) do
        builder:start_row()
        for _, col in ipairs(columns) do
            local cell_value = row[col.field]

            if col.formatter then
                cell_value = col.formatter(cell_value, row)
            end

            builder:add_cell(cell_value, {})
        end
        builder:end_row()
    end

    return builder:build()
end

---Create enhanced table builder with Arguments integration
---@param frame table MediaWiki frame object
---@param config table Table configuration
---@return string HTML table
function funclib.build_table_from_frame(frame, config)
    checkType('build_table_from_frame', 1, frame, 'table')
    checkType('build_table_from_frame', 2, config, 'table')

    -- Process frame arguments with sophisticated handling
    local args_config = {
        trim = true,
        removeBlanks = true,
        wrappers = config.wrappers,
        translate = config.arg_translate,
        required = config.required_args or {},
        optional = config.optional_args or {},
        defaults = config.arg_defaults
    }

    local args = funclib.process_frame_args(frame, args_config)

    -- Build columns using functional composition if available
    local columns
    if functools.pipe and functools.map then
        columns = functools.pipe(
            function(cols)
                return functools.map(function(col_config)
                    if type(col_config) == 'string' then
                        return funclib.make_column(col_config, {})
                    else
                        return funclib.make_column(col_config.header, col_config)
                    end
                end, cols)
            end
        )(config.columns or {})
    else
        -- Fallback without functools
        columns = {}
        for _, col_config in ipairs(config.columns or {}) do
            if type(col_config) == 'string' then
                table.insert(columns, funclib.make_column(col_config, {}))
            else
                table.insert(columns, funclib.make_column(col_config.header, col_config))
            end
        end
    end

    -- Process data using functional transformations
    local data = config.data or {}
    if config.data_transformations then
        data = funclib.create_pipeline(config.data_transformations)(data)
    end

    -- Build table with enhanced options
    return funclib.build_table(columns, data, {
        classes = config.classes,
        attributes = config.attributes
    })
end

-- ======================
-- FUNCTIONAL COMPOSITION HELPERS FOR COLUMN PROCESSING
-- ======================

---Create column processing pipeline using functional composition
---@param processors function[] Array of column processors
---@return function Pipeline function for column processing
function funclib.create_column_pipeline(processors)
    checkType('create_column_pipeline', 1, processors, 'table')

    if functools.compose then
        return functools.compose(unpack(processors))
    else
        -- Fallback implementation
        return function(data)
            local result = data
            for _, processor in ipairs(processors) do
                result = processor(result)
            end
            return result
        end
    end
end

---Column processor: Apply tooltip to column headers
---@param tooltip_map table Map of column headers to tooltips
---@return function Column processor function
function funclib.apply_tooltips(tooltip_map)
    return function(columns)
        if functools.map then
            return functools.map(function(col)
                if tooltip_map[col.header] then
                    col.header = funclib.tooltip(col.header, tooltip_map[col.header])
                end
                return col
            end, columns)
        else
            -- Fallback implementation
            local result = {}
            for i, col in ipairs(columns) do
                if tooltip_map[col.header] then
                    col.header = funclib.tooltip(col.header, tooltip_map[col.header])
                end
                result[i] = col
            end
            return result
        end
    end
end

---Column processor: Apply consistent formatting
---@param format_config table Formatting configuration
---@return function Column processor function
function funclib.apply_formatting(format_config)
    return function(columns)
        if functools.map then
            return functools.map(function(col)
                if format_config.align then
                    col.align = col.align or format_config.align
                end
                if format_config.sortable ~= nil then
                    col.sortable = col.sortable ~= false and format_config.sortable
                end
                return col
            end, columns)
        else
            -- Fallback implementation
            local result = {}
            for i, col in ipairs(columns) do
                if format_config.align then
                    col.align = col.align or format_config.align
                end
                if format_config.sortable ~= nil then
                    col.sortable = col.sortable ~= false and format_config.sortable
                end
                result[i] = col
            end
            return result
        end
    end
end

-- ======================
-- CONVENIENCE SHORTCUTS - Ultra Easy Access
-- ======================

-- Most commonly used functions get ultra-short names
funclib.col = funclib.make_column           -- Quick column creation
funclib.preset = funclib.make_preset_column -- Quick preset columns
funclib.table = funclib.build_table         -- Quick table building
funclib.decode = funclib.safe_decode_json   -- Quick JSON decode

-- Quick preset helpers (even shorter)
funclib.level_col = function(opts) return funclib.make_preset_column("LEVEL", opts) end
funclib.members_col = function(opts) return funclib.make_preset_column("MEMBERS", opts) end
funclib.name_col = function(opts) return funclib.make_preset_column("NAME", opts) end

-- Quick builders
funclib.cols = ColumnBuilder.new -- Quick column builder
funclib.query = QueryBuilder.new -- Quick query builder

-- ======================
-- ADVANCED PERFORMANCE OPTIMIZATIONS
-- ======================

---Performance-optimized column processing with memoization
local columnCache = {}
local maxColumnCacheSize = 500

---Clear the column processing cache
function funclib.clearColumnCache()
    columnCache = {}
end

---Optimized column builder with caching for repeated configurations
---@param header string Column header
---@param options table Column options
---@param defaults? table Default options
---@return table Processed column configuration
function funclib.fast_column(header, options, defaults)
    options = options or {}
    defaults = defaults or {}

    -- Generate cache key using simple approach
    local options_keys = {}
    for k, _ in pairs(options) do table.insert(options_keys, tostring(k)) end
    local defaults_keys = {}
    for k, _ in pairs(defaults) do table.insert(defaults_keys, tostring(k)) end

    local key = string.format("%s_%s_%s",
        header or "",
        table.concat(options_keys, "_"),
        table.concat(defaults_keys, "_")
    )

    if columnCache[key] then
        return columnCache[key]
    end

    -- Prevent cache overflow by counting cache entries
    local cache_count = 0
    for _ in pairs(columnCache) do cache_count = cache_count + 1 end
    if cache_count >= maxColumnCacheSize then
        funclib.clearColumnCache()
    end

    local result = funclib.make_column(header, options, defaults)
    columnCache[key] = result
    return result
end

---Batch column creation with performance optimizations
---@param column_configs table[] Array of column configurations
---@return table[] Array of processed columns
function funclib.batch_columns(column_configs)
    checkType('batch_columns', 1, column_configs, 'table')

    local result = {}
    for i, config in ipairs(column_configs) do
        if type(config) == 'string' then
            result[i] = funclib.fast_column(config, {})
        else
            result[i] = funclib.fast_column(config.header, config.options, config.defaults)
        end
    end

    return result
end

-- ======================
-- ENHANCED TEMPLATE PROCESSING UTILITIES
-- ======================

---Enhanced template parameter processing using Arguments module
---@param frame table MediaWiki frame object
---@param config table Processing configuration
---@return table Processed parameters
function funclib.process_frame_args(frame, config)
    checkType('process_frame_args', 1, frame, 'table')
    checkType('process_frame_args', 2, config, 'table')

    -- Set up Arguments options based on config
    local args_options = {
        trim = config.trim ~= false,                 -- Default to true
        removeBlanks = config.removeBlanks ~= false, -- Default to true
        readOnly = config.readOnly or false,
        noOverwrite = config.noOverwrite or false,
        wrappers = config.wrappers,
        valueFunc = config.valueFunc
    }

    -- Use Arguments module for sophisticated frame processing
    local args = arguments.getArgs(frame, args_options)
    local result = {}

    -- Process required parameters
    if config.required then
        for _, param in ipairs(config.required) do
            local value = args[param]
            if not value then
                error(string.format("Required parameter '%s' is missing", param))
            end
            result[param] = value
        end
    end

    -- Process optional parameters with defaults
    if config.optional then
        for _, param in ipairs(config.optional) do
            local value = args[param]
            if value then
                result[param] = value
            elseif config.defaults and config.defaults[param] then
                result[param] = config.defaults[param]
            end
        end
    end

    -- Apply type conversions if specified
    if config.types then
        for param, target_type in pairs(config.types) do
            if result[param] then
                result[param] = funclib.convert_type(result[param], target_type)
            end
        end
    end

    -- Apply argument translation if specified
    if config.translate then
        local translated_result = {}
        for param, value in pairs(result) do
            local translated_param = config.translate[param] or param
            translated_result[translated_param] = value
        end
        result = translated_result
    end

    return result
end

-- ======================
-- TEMPLATE PROCESSING UTILITIES
-- ======================

---Process MediaWiki template parameters with validation and defaults
---@param args table Template arguments
---@param config table Processing configuration
---@return table Processed parameters
function funclib.process_template_params(args, config)
    checkType('process_template_params', 1, args, 'table')
    checkType('process_template_params', 2, config, 'table')

    local result = {}

    -- Process required parameters using functional validation
    if config.required then
        for _, param in ipairs(config.required) do
            local value = args[param]
            if not funclib.default_value(value, nil) then
                error(string.format("Required parameter '%s' is missing", param))
            end
            result[param] = value
        end
    end

    -- Process optional parameters with defaults using functional approach
    if config.optional then
        for _, param in ipairs(config.optional) do
            local default_val = config.defaults and config.defaults[param] or ""
            result[param] = funclib.default_value(args[param], default_val)
        end
    end

    -- Process with type conversion
    if config.types then
        for param, target_type in pairs(config.types) do
            if result[param] then
                result[param] = funclib.convert_type(result[param], target_type)
            end
        end
    end

    return result
end

---Convert string values to appropriate types
---@param value string Input value
---@param target_type string Target type ('number', 'boolean', 'table')
---@return any Converted value
function funclib.convert_type(value, target_type)
    if target_type == 'number' then
        local num = tonumber(value)
        return num or 0
    elseif target_type == 'boolean' then
        return value == 'true' or value == '1' or value == 'yes'
    elseif target_type == 'table' then
        -- Try to decode as JSON, fallback to split by comma
        local success, result = pcall(mw.text.jsonDecode, value)
        if success then return result end
        return mw.text.split(value, ',')
    end
    return value
end

-- ======================
-- WIKITEXT GENERATION UTILITIES
-- ======================

---Generate optimized wikitext with functional composition
---@param generators table[] Array of generator functions
---@return string Generated wikitext
function funclib.compose_wikitext(generators)
    checkType('compose_wikitext', 1, generators, 'table')

    local parts = {}
    for i, gen in ipairs(generators) do
        local result = type(gen) == 'function' and gen() or tostring(gen)
        if result and result ~= "" then
            parts[#parts + 1] = result
        end
    end

    return table.concat(parts, '\n')
end

---Create a template invocation builder
---@param template_name string Name of the template
---@return table Builder object
function funclib.template_builder(template_name)
    checkType('template_builder', 1, template_name, 'string')

    local builder = {
        name = template_name,
        params = {}
    }

    function builder:param(name, value)
        if value and value ~= "" then
            self.params[name] = value
        end
        return self
    end

    function builder:numbered_param(value)
        if value and value ~= "" then
            table.insert(self.params, value)
        end
        return self
    end

    function builder:build()
        local parts = { '{{' .. self.name }

        -- Add numbered parameters first
        for i, value in ipairs(self.params) do
            table.insert(parts, '|' .. value)
        end

        -- Add named parameters
        for name, value in pairs(self.params) do
            if type(name) ~= 'number' then
                table.insert(parts, string.format('|%s=%s', name, value))
            end
        end

        table.insert(parts, '}}')
        return table.concat(parts)
    end

    return builder
end

-- ======================
-- DATA TRANSFORMATION PIPELINES
-- ======================

---Create a data transformation pipeline with error handling
---@param transformations function[] Array of transformation functions
---@return function Pipeline function
function funclib.create_pipeline(transformations)
    checkType('create_pipeline', 1, transformations, 'table')

    return function(data)
        local result = data

        for i, transform in ipairs(transformations) do
            local success, new_result = pcall(transform, result)
            if not success then
                error(string.format("Pipeline stage %d failed: %s", i, new_result))
            end
            result = new_result
        end

        return result
    end
end

---Common data transformations
funclib.transforms = {
    -- Filter out empty values
    filter_empty = function(data)
        local result = {}
        for _, item in ipairs(data) do
            if item and item ~= "" then
                table.insert(result, item)
            end
        end
        return result
    end,

    -- Sort by field
    sort_by = function(field)
        return function(data)
            table.sort(data, function(a, b)
                return (a[field] or "") < (b[field] or "")
            end)
            return data
        end
    end,

    -- Group by field
    group_by = function(field)
        return function(data)
            local groups = {}
            for _, item in ipairs(data) do
                local key = item[field] or "unknown"
                if not groups[key] then
                    groups[key] = {}
                end
                table.insert(groups[key], item)
            end
            return groups
        end
    end,

    -- Map field values
    map_field = function(field, mapper)
        return function(data)
            local result = {}
            for i, item in ipairs(data) do
                local new_item = {}
                for k, v in pairs(item) do
                    new_item[k] = v
                end
                if new_item[field] then
                    new_item[field] = mapper(new_item[field])
                end
                result[i] = new_item
            end
            return result
        end
    end
}

-- ======================
-- SEMANTIC MEDIAWIKI INTEGRATION
-- ======================

---Execute semantic query with error handling and caching
---@param query string SMW query
---@param use_cache? boolean Whether to use query caching
---@return table Query results
function funclib.semantic_query(query, use_cache)
    checkType('semantic_query', 1, query, 'string')

    -- Simple cache based on query hash
    local query_hash = mw.hash('md5', query)
    if use_cache and columnCache['query_' .. query_hash] then
        return columnCache['query_' .. query_hash]
    end

    local success, result = pcall(mw.smw.ask, query)
    if not success then
        error("Semantic query failed: " .. result)
    end

    if use_cache then
        columnCache['query_' .. query_hash] = result
    end

    return result or {}
end

---Build semantic query string with fluent interface
---@param category string Category to query
---@return table Query builder
function funclib.semantic_builder(category)
    return funclib.QueryBuilder.new(category)
end

-- ======================
-- SIMPLE TABLE HELPERS - Alternative to Tables.lua
-- ======================

---Simple helper to add cells to a table row (alternative to Tables._row)
---@param row table mw.html row object
---@param cells table|string[] Array of cell content or cell configs
---@param is_header boolean Whether to use th tags instead of td
---@return table The row object for chaining
function funclib.add_cells(row, cells, is_header)
    local tag_name = is_header and 'th' or 'td'

    for _, cell in ipairs(cells) do
        if type(cell) == 'table' and cell.text then
            -- Enhanced cell with attributes
            row:tag(tag_name)
                :wikitext(cell.text)
                :attr(cell.attr or {})
                :addClass(cell.class or "")
                :css(cell.css or {})
                :done()
        else
            -- Simple cell content
            row:tag(tag_name):wikitext(tostring(cell)):done()
        end
    end

    return row
end

---Simple helper to build a table from data (alternative to Tables._table)
---@param table_element table mw.html table object
---@param rows table[] Array of row data
---@return table The table object
function funclib.add_rows(table_element, rows)
    for _, row_data in ipairs(rows) do
        if row_data ~= false then
            local row = table_element:tag('tr')
            funclib.add_cells(row, row_data, false)
            row:done()
        end
    end

    return table_element
end

---Ultra-simple table creator (combines both helpers)
---@param data table[] Array of row data
---@param options table Optional table configuration
---@return string HTML table string
function funclib.simple_table(data, options)
    options = options or {}

    local table_elem = mw.html.create('table')
        :addClass(options.class or 'wikitable')

    if options.attributes then
        for name, value in pairs(options.attributes) do
            table_elem:attr(name, value)
        end
    end

    funclib.add_rows(table_elem, data)
    return tostring(table_elem)
end

return funclib
