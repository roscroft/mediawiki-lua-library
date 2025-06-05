--[[
------------------------------------------------------------------------------------
--                             CodeStandards                                      --
--                                                                                --
-- Comprehensive validation, error handling, and standards enforcement            --
-- for MediaWiki Lua modules.                                                     --
--                                                                                --
-- This module includes all functionality from the former ErrorHandler module,    --
-- which is now deprecated.                                                       --
------------------------------------------------------------------------------------
--]]

local libraryUtil = require('libraryUtil')

---@class CodeStandards
local standards = {}

-- Performance metrics storage
local performanceMetrics = {}
local performanceHistory = {}
local metricsStartTime = os.time()

-- Constants
standards.ERROR_LEVELS = {
    FATAL = 1,
    WARNING = 2,
    INFO = 3,
    DEBUG = 4
}

standards.ERROR_LEVEL_NAMES = {
    [1] = "FATAL",
    [2] = "WARNING",
    [3] = "INFO",
    [4] = "DEBUG"
}

-- Local utility functions
local function isNil(value)
    return value == nil
end

local function isEmptyString(value)
    return type(value) == 'string' and not string.find(value, '%S')
end

--[[
------------------------------------------------------------------------------------
-- ERROR HANDLING (MIGRATED FROM ErrorHandler)
------------------------------------------------------------------------------------
--]]

---Create a structured error object
---@param level number Error severity level (1=fatal, 2=warning, 3=info, 4=debug)
---@param message string Error message
---@param source? string Source of the error (module, function)
---@param details? table Additional error details
---@return table error Structured error object
function standards.createError(level, message, source, details)
    if type(level) ~= 'number' or level < 1 or level > 4 then
        level = standards.ERROR_LEVELS.FATAL
    end

    return {
        level = level,
        levelName = standards.ERROR_LEVEL_NAMES[level] or "UNKNOWN",
        message = tostring(message or "Unknown error"),
        source = source and tostring(source) or "unknown",
        details = details or {},
        timestamp = os.time()
    }
end

---Format an error object as a string
---@param err table Error object from createError
---@param includeDetails? boolean Whether to include details in output
---@param colorize? boolean Whether to add wiki markup colors
---@return string formattedError Human-readable error message
function standards.formatError(err, includeDetails, colorize)
    local color
    if colorize then
        if err.level == standards.ERROR_LEVELS.FATAL then
            color = "#FF0000" -- Red
        elseif err.level == standards.ERROR_LEVELS.WARNING then
            color = "#FFA500" -- Orange
        elseif err.level == standards.ERROR_LEVELS.INFO then
            color = "#0000FF" -- Blue
        else
            color = "#808080" -- Gray
        end
    end

    local result = string.format("[%s] %s", err.levelName, err.message)

    if err.source and err.source ~= "unknown" then
        result = result .. string.format(" (in %s)", err.source)
    end

    if includeDetails and type(err.details) == 'table' and next(err.details) ~= nil then
        result = result .. ":\n"
        for k, v in pairs(err.details) do
            result = result .. string.format("  %s: %s\n", tostring(k), tostring(v))
        end
    end

    if colorize then
        result = string.format('<span style="color:%s">%s</span>', color, result)
    end

    return result
end

---Log an error to MediaWiki's logging system
---@param err table|string Error object or simple message string
---@param level? number Optional level override if err is a string
---@return nil
function standards.logError(err, level)
    if type(err) == 'string' then
        err = standards.createError(level or standards.ERROR_LEVELS.WARNING, err)
    end

    local formatted = standards.formatError(err, true)
    mw.log(formatted)

    -- For fatal errors, consider writing to a persistent log or database
    if err.level == standards.ERROR_LEVELS.FATAL then
        -- Implement persistent logging here if needed
    end
end

---Throw a formatted error that halts execution
---@param err table|string Error object or string message
---@param level? number Optional level override if err is a string
function standards.throwError(err, level)
    if type(err) == 'string' then
        err = standards.createError(level or standards.ERROR_LEVELS.FATAL, err)
    end

    local formatted = standards.formatError(err, true)
    error(formatted, 2) -- Use level 2 to exclude this function from stack trace
end

--[[
------------------------------------------------------------------------------------
-- FUNCTION WRAPPING AND VALIDATION
------------------------------------------------------------------------------------
--]]

---Wrap a function with error handling
---@param name string Function name for error reporting
---@param func function Function to wrap
---@param options? table Options for error handling
---@return any Function result or error
function standards.wrapFunction(name, func, options)
    options = options or {}

    return function(...)
        local success, result = pcall(func, ...)

        if not success then
            local errObj = standards.createError(
                standards.ERROR_LEVELS.FATAL,
                result, -- pcall returns the error message as result on failure
                name,
                {arguments = {...}}
            )

            if options.logOnly then
                standards.logError(errObj)
                return nil
            else
                standards.throwError(errObj)
            end
        end

        return result
    end
end

---Function parameter validation
---@param name string Function name for error messages
---@param parameters table Parameter specifications
---@param args table Actual arguments to validate
---@return boolean isValid Whether validation passed
---@return string? errorMessage Error message if validation failed
function standards.validateParameters(name, parameters, args)
    for i, param in ipairs(parameters) do
        local value = args[i]

        -- Skip validation for optional parameters that are not provided or are nil
        if not param.required and (value == nil or i > #args) then
            -- Optional parameter not provided, skip validation
        else
            -- Use isValid for comprehensive validation
            local valid, msg = standards.isValid(value, param)
            if not valid then
                return false, string.format("Parameter #%d (%s) in %s: %s",
                    i, param.name or "unnamed", name, msg)
            end
        end
    end

    return true
end

--[[
------------------------------------------------------------------------------------
-- DATA VALIDATION UTILITIES
------------------------------------------------------------------------------------
--]]

---Check if a value is empty (nil, empty string, or empty table)
---@param value any Value to check
---@return boolean isEmpty Whether the value is empty
function standards.isEmpty(value)
    if value == nil then
        return true
    elseif type(value) == 'string' then
        return not string.find(value, '%S')
    elseif type(value) == 'table' then
        return next(value) == nil
    else
        return false
    end
end

---Check if a value is valid
---@param value any Value to check
---@param options table Validation options
---@return boolean isValid Whether the value is valid
---@return string? errorMessage Error message if invalid
function standards.isValid(value, options)
    options = options or {}

    -- Required check
    if options.required and standards.isEmpty(value) then
        return false, "Value is required but empty"
    end

    -- Type checking
    if options.type and type(value) ~= options.type then
        return false, string.format("Expected %s, got %s", options.type, type(value))
    end

    -- Pattern validation for strings
    if type(value) == 'string' and options.pattern and not string.match(value, options.pattern) then
        return false, options.patternMessage or "String doesn't match required pattern"
    end

    -- Range validation for numbers
    if type(value) == 'number' then
        if options.min and value < options.min then
            return false, string.format("Value %s is below minimum %s", value, options.min)
        end
        if options.max and value > options.max then
            return false, string.format("Value %s is above maximum %s", value, options.max)
        end
    end

    -- Length validation for strings and tables
    if (type(value) == 'string' or type(value) == 'table') and (options.minLength or options.maxLength) then
        local len = type(value) == 'string' and #value or #value
        if options.minLength and len < options.minLength then
            return false, string.format("Length %d is below minimum %d", len, options.minLength)
        end
        if options.maxLength and len > options.maxLength then
            return false, string.format("Length %d is above maximum %d", len, options.maxLength)
        end
    end

    -- Custom validation function
    if options.validate and type(options.validate) == 'function' then
        local isValid, message = options.validate(value)
        if not isValid then
            return false, message or "Failed custom validation"
        end
    end

    return true
end

---Get all keys from a table
---@param t table Table to get keys from
---@return table keys Array of all keys
function standards.tableKeys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

---Create an error-handling version of a module
---@param module table Original module
---@param options? table Error handling options
---@return table wrappedModule Module with error handling
function standards.wrapModule(module, options)
    options = options or {}
    local wrapped = {}

    for name, func in pairs(module) do
        if type(func) == 'function' then
            wrapped[name] = standards.wrapFunction(name, func, options)
        else
            wrapped[name] = func
        end
    end

    return wrapped
end

--[[
------------------------------------------------------------------------------------
-- TRACKING AND DEBUGGING UTILITIES
------------------------------------------------------------------------------------
--]]

---Performance tracking utility with detailed metrics collection
---@param name string Function or operation name
---@param func function Function to measure
---@return function wrappedFunc Function with performance tracking
function standards.trackPerformance(name, func)
    return function(...)
        local args = {...}
        local startTime = os.clock()
        local startCPU = os.time()
        local argCount = select('#', ...)

        -- Capture all return values in a table (Lua 5.1 compatible)
        local success, results = pcall(function() return {func(unpack(args))} end)
        local endTime = os.clock()
        local endCPU = os.time()

        local duration = endTime - startTime
        local wallTime = endCPU - startCPU

        -- Store detailed performance metrics
        standards.recordMetric(name, {
            duration = duration,
            wallTime = wallTime,
            argumentCount = argCount,
            success = success,
            timestamp = os.time(),
            memory = collectgarbage("count")
        })

        -- Log performance info (existing functionality)
        mw.log(string.format("PERF: %s took %.6f seconds", name, duration))

        if not success then
            error(results) -- results contains the error message on failure
        end

        -- Return all values using unpack (Lua 5.1 compatible)
        return unpack(results)
    end
end

---Create debug information about a value
---@param value any Value to inspect
---@param options? table Options for debug output
---@return string debugInfo Formatted debug information
function standards.debugInfo(value, options)
    options = options or {}
    local maxDepth = options.maxDepth or 2
    local prefix = options.prefix or ""

    local function _debugInfo(val, depth, path)
        local result = ""

        if type(val) == "table" and depth < maxDepth then
            result = result .. type(val) .. " {\n"
            for k, v in pairs(val) do
                local newPath = path .. "." .. tostring(k)
                result = result .. string.rep("  ", depth + 1) .. tostring(k) .. " = "
                result = result .. _debugInfo(v, depth + 1, newPath) .. "\n"
            end
            result = result .. string.rep("  ", depth) .. "}"
        else
            result = tostring(val) .. " (" .. type(val) .. ")"
        end

        return result
    end

    return prefix .. _debugInfo(value, 0, "value")
end

--[[
------------------------------------------------------------------------------------
-- PERFORMANCE DASHBOARD SYSTEM
------------------------------------------------------------------------------------
--]]

---Record a performance metric
---@param name string Function or operation name
---@param metric table Performance metric data
function standards.recordMetric(name, metric)
    -- Initialize metrics for this function if not exists
    if not performanceMetrics[name] then
        performanceMetrics[name] = {
            calls = 0,
            totalTime = 0,
            minTime = math.huge,
            maxTime = 0,
            avgTime = 0,
            successRate = 0,
            successCount = 0,
            errorCount = 0,
            lastCalled = 0,
            totalMemory = 0,
            avgMemory = 0
        }
        performanceHistory[name] = {}
    end

    local metrics = performanceMetrics[name]
    local history = performanceHistory[name]

    -- Update counters
    metrics.calls = metrics.calls + 1
    metrics.totalTime = metrics.totalTime + metric.duration
    metrics.totalMemory = metrics.totalMemory + metric.memory
    metrics.lastCalled = metric.timestamp

    -- Update min/max times
    if metric.duration < metrics.minTime then
        metrics.minTime = metric.duration
    end
    if metric.duration > metrics.maxTime then
        metrics.maxTime = metric.duration
    end

    -- Update averages
    metrics.avgTime = metrics.totalTime / metrics.calls
    metrics.avgMemory = metrics.totalMemory / metrics.calls

    -- Update success rate
    if metric.success then
        metrics.successCount = metrics.successCount + 1
    else
        metrics.errorCount = metrics.errorCount + 1
    end
    metrics.successRate = (metrics.successCount / metrics.calls) * 100

    -- Store in history (keep last 100 calls)
    table.insert(history, {
        timestamp = metric.timestamp,
        duration = metric.duration,
        memory = metric.memory,
        success = metric.success,
        argumentCount = metric.argumentCount
    })

    -- Limit history size
    if #history > 100 then
        table.remove(history, 1)
    end
end

---Get performance metrics for all functions
---@return table metrics Complete performance metrics
function standards.getPerformanceMetrics()
    return performanceMetrics
end

---Get performance history for a specific function
---@param name string Function name
---@return table history Performance history
function standards.getPerformanceHistory(name)
    return performanceHistory[name] or {}
end

---Generate a comprehensive performance report
---@return table report Formatted performance report
function standards.generatePerformanceReport()
    local report = {
        timestamp = os.time(),
        uptime = os.time() - metricsStartTime,
        totalFunctions = 0,
        totalCalls = 0,
        totalTime = 0,
        overallSuccessRate = 0,
        functions = {},
        topPerformers = {},
        slowestFunctions = {},
        mostUsedFunctions = {},
        summary = {}
    }

    local allFunctions = {}

    -- Process each function's metrics
    for name, metrics in pairs(performanceMetrics) do
        report.totalFunctions = report.totalFunctions + 1
        report.totalCalls = report.totalCalls + metrics.calls
        report.totalTime = report.totalTime + metrics.totalTime

        local functionReport = {
            name = name,
            calls = metrics.calls,
            totalTime = metrics.totalTime,
            avgTime = metrics.avgTime,
            minTime = metrics.minTime == math.huge and 0 or metrics.minTime,
            maxTime = metrics.maxTime,
            successRate = metrics.successRate,
            avgMemory = metrics.avgMemory,
            lastCalled = metrics.lastCalled,
            performance_score = metrics.calls / (metrics.avgTime + 0.001) -- Higher is better
        }

        report.functions[name] = functionReport
        table.insert(allFunctions, functionReport)
    end

    -- Calculate overall success rate
    local totalSuccessful = 0
    for name, metrics in pairs(performanceMetrics) do
        totalSuccessful = totalSuccessful + metrics.successCount
    end
    report.overallSuccessRate = report.totalCalls > 0 and (totalSuccessful / report.totalCalls) * 100 or 0

    -- Sort functions for different categories
    table.sort(allFunctions, function(a, b) return a.performance_score > b.performance_score end)
    for i = 1, math.min(5, #allFunctions) do
        table.insert(report.topPerformers, allFunctions[i])
    end

    table.sort(allFunctions, function(a, b) return a.avgTime > b.avgTime end)
    for i = 1, math.min(5, #allFunctions) do
        table.insert(report.slowestFunctions, allFunctions[i])
    end

    table.sort(allFunctions, function(a, b) return a.calls > b.calls end)
    for i = 1, math.min(5, #allFunctions) do
        table.insert(report.mostUsedFunctions, allFunctions[i])
    end

    -- Generate summary
    report.summary = {
        avgCallsPerFunction = report.totalFunctions > 0 and report.totalCalls / report.totalFunctions or 0,
        avgTimePerCall = report.totalCalls > 0 and report.totalTime / report.totalCalls or 0,
        uptimeHours = report.uptime / 3600,
        callsPerSecond = report.uptime > 0 and report.totalCalls / report.uptime or 0
    }

    return report
end

---Clear all performance metrics
function standards.clearPerformanceMetrics()
    performanceMetrics = {}
    performanceHistory = {}
    metricsStartTime = os.time()
end

---Get real-time performance dashboard data
---@return table dashboard Dashboard data structure
function standards.getPerformanceDashboard()
    local report = standards.generatePerformanceReport()

    return {
        status = "active",
        timestamp = os.time(),
        uptime = report.uptime,
        metrics = {
            totalFunctions = report.totalFunctions,
            totalCalls = report.totalCalls,
            totalTime = report.totalTime,
            successRate = report.overallSuccessRate,
            avgResponseTime = report.summary.avgTimePerCall,
            callsPerSecond = report.summary.callsPerSecond
        },
        topPerformers = report.topPerformers,
        slowestFunctions = report.slowestFunctions,
        mostUsedFunctions = report.mostUsedFunctions,
        recentActivity = standards.getRecentActivity(),
        alerts = standards.getPerformanceAlerts()
    }
end

---Get recent performance activity
---@return table activity Recent activity data
function standards.getRecentActivity()
    local activity = {}
    local now = os.time()

    for name, history in pairs(performanceHistory) do
        for _, call in ipairs(history) do
            if now - call.timestamp < 300 then -- Last 5 minutes
                table.insert(activity, {
                    function_name = name,
                    timestamp = call.timestamp,
                    duration = call.duration,
                    success = call.success,
                    memory = call.memory
                })
            end
        end
    end

    -- Sort by timestamp (most recent first)
    table.sort(activity, function(a, b) return a.timestamp > b.timestamp end)

    -- Return last 20 activities
    local result = {}
    for i = 1, math.min(20, #activity) do
        table.insert(result, activity[i])
    end

    return result
end

---Generate performance alerts
---@return table alerts Performance alerts
function standards.getPerformanceAlerts()
    local alerts = {}

    for name, metrics in pairs(performanceMetrics) do
        -- Alert for slow functions (>1 second average)
        if metrics.avgTime > 1.0 then
            table.insert(alerts, {
                type = "slow_function",
                severity = "warning",
                message = string.format("%s is averaging %.3f seconds per call", name, metrics.avgTime),
                function_name = name,
                value = metrics.avgTime
            })
        end

        -- Alert for low success rate (<95%)
        if metrics.successRate < 95 and metrics.calls > 10 then
            table.insert(alerts, {
                type = "low_success_rate",
                severity = "error",
                message = string.format("%s has only %.1f%% success rate", name, metrics.successRate),
                function_name = name,
                value = metrics.successRate
            })
        end

        -- Alert for high memory usage (>10MB average)
        if metrics.avgMemory > 10240 then
            table.insert(alerts, {
                type = "high_memory",
                severity = "warning",
                message = string.format("%s is using %.1f MB on average", name, metrics.avgMemory / 1024),
                function_name = name,
                value = metrics.avgMemory
            })
        end
    end

    return alerts
end

return standards