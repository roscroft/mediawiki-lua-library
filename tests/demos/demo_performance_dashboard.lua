#!/usr/bin/env lua
--[[
Performance Dashboard Demonstration
Showcases the new performance monitoring and dashboard capabilities
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Load modules
local CodeStandards = require('CodeStandards')
local PerformanceDashboard = require('PerformanceDashboard')
local Array = require('Array')
local functools = require('Functools')

print("🚀 Performance Dashboard Demonstration")
print("=====================================")

-- Clear any existing metrics
CodeStandards.clearPerformanceMetrics()

print("\n1. Instrumenting modules for performance monitoring...")

-- Instrument Array module for monitoring
local MonitoredArray = PerformanceDashboard.instrumentModule(Array, 'Array')

-- Instrument some functools functions
local monitoredCompose = CodeStandards.trackPerformance('functools.compose', functools.compose)
local monitoredMemoize = CodeStandards.trackPerformance('functools.memoize', functools.memoize)

print("✅ Modules instrumented with performance monitoring")

print("\n2. Running sample operations to generate performance data...")

-- Generate test data
local testData = Array.range(1, 1000)
local smallData = { 1, 2, 3, 4, 5 }

-- Perform various operations to generate metrics
for i = 1, 50 do
    -- Array operations
    local filtered = MonitoredArray.filter(testData, function(x) return x % 2 == 0 end)
    local mapped = MonitoredArray.map(smallData, function(x) return x * x end)
    local found = MonitoredArray.find(testData, function(x) return x > 500 end)

    -- Functools operations
    local add = function(a, b) return a + b end
    local multiply = function(x) return x * 2 end
    local composed = monitoredCompose(multiply, add)

    -- Intentionally slow operation for testing
    if i % 10 == 0 then
        local slowOp = CodeStandards.trackPerformance('slow_operation', function()
            local sum = 0
            for j = 1, 10000 do
                sum = sum + j
            end
            return sum
        end)
        slowOp()
    end

    -- Memory intensive operation
    if i % 15 == 0 then
        local memoryOp = CodeStandards.trackPerformance('memory_intensive', function()
            local bigTable = {}
            for j = 1, 1000 do
                bigTable[j] = { data = "memory test " .. j, values = Array.range(1, 100) }
            end
            return #bigTable
        end)
        memoryOp()
    end
end

print("✅ Generated performance data from 50 iterations")

print("\n3. Performance Metrics Summary:")
print("==============================")

local metrics = CodeStandards.getPerformanceMetrics()
for name, data in pairs(metrics) do
    print(string.format("📊 %s:", name))
    print(string.format("   Calls: %d", data.calls))
    print(string.format("   Avg Time: %.6f seconds", data.avgTime))
    print(string.format("   Success Rate: %.1f%%", data.successRate))
    print(string.format("   Memory: %.1f KB avg", data.avgMemory))
    print("")
end

print("\n4. Performance Dashboard Report:")
print("================================")

local dashboard = CodeStandards.getPerformanceDashboard()
print(string.format("Status: %s", dashboard.status))
print(string.format("Total Functions Monitored: %d", dashboard.metrics.totalFunctions))
print(string.format("Total Calls: %d", dashboard.metrics.totalCalls))
print(string.format("Overall Success Rate: %.2f%%", dashboard.metrics.successRate))
print(string.format("Average Response Time: %.6f seconds", dashboard.metrics.avgResponseTime))
print(string.format("Calls per Second: %.2f", dashboard.metrics.callsPerSecond))

print("\n🏆 Top Performers:")
for i, perf in ipairs(dashboard.topPerformers) do
    print(string.format("%d. %s (Score: %.0f)", i, perf.name, perf.performance_score))
end

print("\n⚠️ Slowest Functions:")
for i, slow in ipairs(dashboard.slowestFunctions) do
    print(string.format("%d. %s (%.6f seconds avg)", i, slow.name, slow.avgTime))
end

print("\n📈 Most Used Functions:")
for i, used in ipairs(dashboard.mostUsedFunctions) do
    print(string.format("%d. %s (%d calls)", i, used.name, used.calls))
end

if #dashboard.alerts > 0 then
    print("\n🚨 Performance Alerts:")
    for _, alert in ipairs(dashboard.alerts) do
        print(string.format("[%s] %s: %s", alert.severity:upper(), alert.type, alert.message))
    end
else
    print("\n✅ No performance alerts")
end

print("\n5. Recent Activity (Last 20 operations):")
print("=========================================")

local activity = dashboard.recentActivity
for i, act in ipairs(activity) do
    if i <= 10 then -- Show only first 10 for brevity
        local status = act.success and "✅" or "❌"
        print(string.format("%s %s - %.4fs - %.1fKB - %s",
            status, act.function_name, act.duration, act.memory,
            os.date('%H:%M:%S', act.timestamp)))
    end
end

print("\n6. Generating HTML Dashboard:")
print("=============================")

local htmlDashboard = PerformanceDashboard.generateHTML()
print("✅ HTML Dashboard generated")
print(string.format("Dashboard size: %d characters", #htmlDashboard))

-- Save HTML dashboard to file for viewing
local file = io.open('/tmp/wiki-lua-dashboard.html', 'w')
if file then
    file:write([[
<!DOCTYPE html>
<html>
<head>
    <title>Wiki Lua Performance Dashboard</title>
    <meta charset="UTF-8">
</head>
<body>
]])
    file:write(htmlDashboard)
    file:write('</body></html>')
    file:close()
    print("📄 Dashboard saved to /tmp/wiki-lua-dashboard.html")
end

print("\n7. Performance Analysis Report:")
print("===============================")

local analysisReport = PerformanceDashboard.generateAnalysisReport()
print(string.format("Analysis timestamp: %s", os.date('%Y-%m-%d %H:%M:%S', analysisReport.timestamp)))

local healthyCount = 0
local warningCount = 0
local criticalCount = 0

for name, analysis in pairs(analysisReport.analysis) do
    if analysis.status == 'healthy' then
        healthyCount = healthyCount + 1
    elseif analysis.status == 'warning' then
        warningCount = warningCount + 1
    elseif analysis.status == 'critical' then
        criticalCount = criticalCount + 1
    end
end

print(string.format("Health Summary: ✅ %d healthy, ⚠️ %d warnings, 🚨 %d critical",
    healthyCount, warningCount, criticalCount))

if #analysisReport.bottlenecks > 0 then
    print("\nIdentified Bottlenecks:")
    for _, bottleneck in ipairs(analysisReport.bottlenecks) do
        print(string.format("• %s: %.3fs total time (%d calls)",
            bottleneck.name, bottleneck.totalTime, bottleneck.calls))
    end
end

if #analysisReport.recommendations > 0 then
    print("\nRecommendations:")
    for _, rec in ipairs(analysisReport.recommendations) do
        print("• " .. rec)
    end
end

print("\n8. Data Export Capabilities:")
print("============================")

-- Export to JSON
local jsonData = PerformanceDashboard.exportData('json')
print(string.format("JSON export size: %d characters", #jsonData))

-- Export to CSV
local csvData = PerformanceDashboard.exportData('csv')
print(string.format("CSV export size: %d characters", #csvData))

-- Save CSV for analysis
local csvFile = io.open('/tmp/wiki-lua-performance.csv', 'w')
if csvFile then
    csvFile:write(csvData)
    csvFile:close()
    print("📊 Performance data exported to /tmp/wiki-lua-performance.csv")
end

print("\n🎉 Performance Dashboard Demonstration Complete!")
print("=================================================")
print("The Performance Dashboard system is now active and collecting metrics.")
print("Key capabilities demonstrated:")
print("• Real-time performance monitoring")
print("• Comprehensive metrics collection")
print("• Visual dashboard generation")
print("• Performance analysis and alerts")
print("• Data export capabilities")
print("• Module instrumentation")
print("")
print("Next steps:")
print("• Integration with MediaWiki pages")
print("• Automated alerting system")
print("• Historical trend analysis")
print("• Performance optimization recommendations")
