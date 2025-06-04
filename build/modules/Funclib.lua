-- Table/Column/Query Specific Library
--
-- This module provides domain-specific functions for working with tables, columns, and queries.
-- Pure functional programming utilities are in Module:Functools, which is imported here.
-- funclib focuses on specific UI components and builders, while functools provides
-- general-purpose functional programming tools.

local funclib = {}

-- Imports
local arr = require('Module:Array')
local mw = require('mw')
local clean = require('Module:Clean image')
local libUtil = require('libraryUtil')
local checkType = libUtil.checkType
local checkTypeMulti = libUtil.checkTypeMulti

-- Import functional utilities from Module:Functools
local functools = require('Module:Functools')

-- ======================
-- TABLE/COLUMN VALIDATION - Domain Specific  
-- ======================

-- Use functools for validation (delegate to pure functional validation)
funclib.validate_value = functools.validation.validate_value
funclib.validate_options = functools.validation.validate_options
funclib.default_value = functools.validation.default_value -- Added from paramtest

-- Standard validation rule sets
funclib.VALIDATION_RULES = {
    COLUMN = {
        header = {type = 'string', required = true},
        field = {type = 'string', required = true},
        align = {type = 'string', required = false},
        colspan = {type = 'number', required = false},
        formatter = {type = 'function', required = false},
        tooltip = {type = 'string', required = false},
        sortable = {type = 'boolean', required = false}
    }
}

function funclib.validate_column(column, index)
    -- Column must be a table
    local valid_table = funclib.validate_value(column, {type = 'table', required = true})
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
    local paramtest = require('Module:Paramtest')
    
    -- Only create tooltip if tooltip text has content
    if not paramtest.has_content(tooltip) then
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
        icon.link,
        clean.main(icon.file),
        icon.width
    )
end

-- String formatting helpers that use paramtest
function funclib.format_name(name)
    local paramtest = require('Module:Paramtest')
    if not paramtest.has_content(name) then
        return ""
    end
    return paramtest.ucfirst(name)
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
    local paramtest = require('Module:Paramtest')
    defaults = defaults or funclib.DEFAULTS

    config.align = paramtest.default_to(config.align, defaults.ALIGN)
    config.sortable = config.sortable ~= false

    local classes = {funclib.FORMAT.TABLE.CLASS.BASE}
    if config.sortable then
        table.insert(classes, funclib.FORMAT.TABLE.CLASS.SORTABLE)
    end

    table.insert(classes, string.format(
        funclib.FORMAT.TABLE.CLASS.ALIGN,
        config.align,
        paramtest.default_to(config.colspan, 1)
    ))

    config.classes = table.concat(classes, " ")

    return config
end

function funclib.make_column(header, options, defaults)
    local config = {
        header = header
    }

    -- Start with defaults
    if defaults then
        for k, v in pairs(defaults) do
            config[k] = v
        end
    end

    -- Override with column-specific options
    if options then
        for k, v in pairs(options) do
            config[k] = v
        end
    end

    -- Apply tooltip if specified
    if config.tooltip then
        config.header = funclib.tooltip(header, config.tooltip)
    end
    
    -- Ensure proper defaults using paramtest's functionality
    local paramtest = require('Module:Paramtest')
    config.align = paramtest.default_to(config.align, "left")
    config.sortable = config.sortable ~= false -- true unless explicitly false

    return config
end

-- ======================
-- JSON UTILITIES - Direct Access
-- ======================

function funclib.safe_decode_json(json_str, name)
    local paramtest = require('Module:Paramtest')
    
    -- Return nil for empty strings
    if not paramtest.has_content(json_str) then
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
        rows = arr:new(),
        classes = arr:new({funclib.FORMAT.TABLE.CLASS.BASE}),
        attributes = {},
        current_row = nil
    }, TableBuilder)

    if columns then
        for _, col in ipairs(columns) do
            if col.sortable ~= false then
                self.classes:push(funclib.FORMAT.TABLE.CLASS.SORTABLE)
                break
            end
        end
    end

    return self
end

function TableBuilder:add_class(class)
    self.classes:push(class)
    return self
end

function TableBuilder:set_attribute(name, value)
    self.attributes[name] = value
    return self
end

function TableBuilder:start_row()
    self.current_row = {
        cells = arr:new(),
        classes = arr:new(),
        attributes = {}
    }
    return self
end

function TableBuilder:add_cell(content, options)
    if not self.current_row then
        self:start_row()
    end

    self.current_row.cells:push({
        content = content,
        options = options or {}
    })

    return self
end

function TableBuilder:end_row()
    if self.current_row then
        self.rows:push(self.current_row)
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
        conditions = arr:new(),
        properties = arr:new(),
        limit = funclib.DEFAULTS.LIMIT
    }, QueryBuilder)
end

function QueryBuilder:add_condition(condition)
    if condition then
        self.conditions:push(condition)
    end
    return self
end

function QueryBuilder:add_property(property)
    if property then
        self.properties:push(property)
    end
    return self
end

function QueryBuilder:set_limit(limit)
    self.limit = limit
    return self
end

function QueryBuilder:build()
    local query = arr:new()

    if self.category then
        query:push(string.format('[Category:%s]', self.category))
    end

    for _, prop in ipairs(self.properties) do
        query:push(string.format('?%s', prop))
    end

    for _, cond in ipairs(self.conditions) do
        query:push(cond)
    end

    query:push('mainline=-')
    query:push(string.format('limit=%d', self.limit))

    return query:concat('\n')
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
    checkType('build_table', 1, columns, 'table')
    checkType('build_table', 2, rows, 'table')
    checkType('build_table', 3, options, 'table', true)

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
funclib.cols = ColumnBuilder.new            -- Quick column builder
funclib.query = QueryBuilder.new            -- Quick query builder

-- ======================
-- FUNCTIONAL PROGRAMMING ACCESS - Convenience delegates
-- ======================

-- Expose key functional utilities for convenience
funclib.id = functools.id
funclib.const = functools.const
funclib.comp = functools.comp
funclib.flip = functools.flip
funclib.pipe = functools.pipe
funclib.compose = functools.compose

-- Currying utilities
funclib.c2 = functools.c2
funclib.c3 = functools.c3

return funclib
