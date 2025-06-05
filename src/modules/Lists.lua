-- Lists Module - Interface for building and displaying lists of data
--
-- This module provides a clean interface to the functionality in Module:Funclib,
-- which contains domain-specific table/column/query functions. Pure functional
-- programming utilities are in Module:Functools, which is imported by Funclib.
--
-- Architecture:
-- * Module:Functools - Pure functional programming utilities
-- * Module:Funclib - Domain-specific table/column/query builders and formatters
-- * Module:Lists (this file) - User-facing interface for list creation
-------------------
-- Module Setup --
-------------------
local p = {}

-- Common module requirements
local functools = require('Functools')  -- For pure functional utilities
local funclib = require('Funclib')      -- For domain-specific operations
-- Note: Module:Mw html extension would be required in MediaWiki context
-- require("Module:Mw html extension")

----------------------
-- Constants --
----------------------

-- Import column presets for the public API
local COLUMN_PRESETS = funclib.COLUMN_PRESETS

----------------------
-- Type Definitions --
----------------------

---@class Lists.ColumnConfig
---@field header string # Column header text
---@field field string # Column data field name
---@field tooltip? string # Optional tooltip text
---@field colspan? number # Optional column span
---@field align? string # Optional alignment
---@field sortable? boolean # Optional sort flag
---@field formatter? function # Optional formatter function
---@field classes? string # Generated CSS classes

---@class Lists.BuildListOptions
---@field get_data_fn fun(args: table): table # Function to fetch data
---@field parse_single_fn fun(entry: table): table # Function to parse single entries
---@field build_table_fn fun(entries: table, args: table): string # Function to build output table
---@field sort_fn? fun(a: table, b: table): boolean # Optional function to sort entries
---@field columns table<number, Lists.ColumnConfig> # Column configuration
---@field row_mapping? fun(row: table, entry: table): table # Optional function for mapping rows

---@class Lists.ModuleConfig
---@field category string # Category to fetch entries from
---@field json_field string # Field containing JSON data
---@field columns table<number, Lists.ColumnConfig> # Column configuration
---@field type_field? string # Optional field for type filtering
---@field field_mapping? table<string, function> # Optional JSON field mapping
---@field filter_fn? fun(args: table): table # Optional function for custom filtering
---@field extra_properties? string[] # Optional extra SMW properties
---@field get_data_fn? fun(args: table): table # Optional custom data fetcher
---@field parse_single_fn? fun(entry: table): table # Optional custom parser
---@field build_table_fn? fun(entries: table, args: table): string # Optional custom table builder
---@field sort_fn? fun(a: table, b: table): boolean # Optional function to sort entries
---@field row_mapping? fun(t: table, entry: table): table # Optional function for custom row mapping

---------------------
-- Column Helpers --
---------------------
-- Import column presets and helper from funclib
local make_preset_column = funclib.make_preset_column

----------------------
-- Builder Classes --
----------------------

-- Import builders
local QueryBuilder = funclib.QueryBuilder
local ColumnBuilder = funclib.ColumnBuilder
local TableBuilder = funclib.TableBuilder

----------------------
-- Public API --
----------------------

-- Expose builders and helpers
p.QueryBuilder = QueryBuilder
p.ColumnBuilder = ColumnBuilder
p.TableBuilder = TableBuilder

-- Expose column configuration presets
p.COLUMN_PRESETS = COLUMN_PRESETS
p.make_preset_column = make_preset_column
p.make_level_column = function(options) return make_preset_column("LEVEL", options) end
p.make_members_column = function(options) return make_preset_column("MEMBERS", options) end
p.make_name_column = function(options) return make_preset_column("NAME", options) end

-- Re-export table config helpers from funclib for backward compatibility
p.make_column = funclib.make_column
p.process_column_config = funclib.process_column_config

-- Table builder utility function - use funclib's build_table
p.build_table = funclib.build_table

-- Expose convenience shortcuts from funclib
p.col = funclib.col
p.preset = funclib.preset
p.table = funclib.table
p.decode = funclib.decode
p.level_col = funclib.level_col
p.members_col = funclib.members_col
p.name_col = funclib.name_col
p.cols = funclib.cols
p.query = funclib.query

-- Simple table helpers (alternative to Tables.lua functionality)
p.add_cells = funclib.add_cells
p.add_rows = funclib.add_rows
p.simple_table = funclib.simple_table

return p
