--[[
------------------------------------------------------------------------------------
--                         Performance Dashboard                                  --
--                                                                                --
-- Real-time performance monitoring and visualization for MediaWiki Lua modules  --
-- Provides comprehensive performance analytics, alerts, and optimization        --
-- insights based on data collected by CodeStandards.                            --
------------------------------------------------------------------------------------
--]]

local CodeStandards = require('CodeStandards')
local Array = require('Array')

---@class PerformanceDashboard
local dashboard = {}

-- Dashboard configuration
local config = {
    refreshInterval = 5, -- seconds
    historyRetention = 3600, -- 1 hour
    alertThresholds = {
        slowFunction = 1.0, -- seconds
        lowSuccessRate = 95, -- percentage
        highMemory = 10240, -- KB
        highCallVolume = 1000 -- calls per minute
    }
}

--[[
------------------------------------------------------------------------------------
-- DASHBOARD VISUALIZATION
------------------------------------------------------------------------------------
--]]

-- Simple HTML builder for demo (replaces mw.html in standalone environment)
local function createSimpleHtmlBuilder(tagName)
    local element = {
        tagName = tagName,
        classes = {},
        attributes = {},
        children = {},
        text = ""
    }
    
    function element:addClass(class)
        table.insert(self.classes, class)
        return self
    end
    
    function element:attr(name, value)
        self.attributes[name] = value
        return self
    end
    
    function element:css(name, value)
        if not self.attributes.style then
            self.attributes.style = ""
        end
        self.attributes.style = self.attributes.style .. name .. ":" .. value .. ";"
        return self
    end
    
    function element:wikitext(text)
        self.text = tostring(text)
        return self
    end
    
    function element:tag(childTagName)
        local child = createSimpleHtmlBuilder(childTagName)
        table.insert(self.children, child)
        return child
    end
    
    function element:tostring()
        local attrs = {}
        if #self.classes > 0 then
            table.insert(attrs, 'class="' .. table.concat(self.classes, " ") .. '"')
        end
        for name, value in pairs(self.attributes) do
            table.insert(attrs, name .. '="' .. tostring(value) .. '"')
        end
        
        local attrStr = #attrs > 0 and " " .. table.concat(attrs, " ") or ""
        local html = "<" .. self.tagName .. attrStr .. ">"
        
        if self.text ~= "" then
            html = html .. self.text
        end
        
        for _, child in ipairs(self.children) do
            html = html .. child:tostring()
        end
        
        html = html .. "</" .. self.tagName .. ">"
        return html
    end
    
    return element
end

-- Mock mw.html for standalone environment
local mw = mw or {}
mw.html = mw.html or {}
mw.html.create = function(tag)
    return createSimpleHtmlBuilder(tag)
end

---Generate HTML dashboard for MediaWiki display
---@return string html Complete HTML dashboard
function dashboard.generateHTML()
    local dashboardData = CodeStandards.getPerformanceDashboard()
    
    local html = mw.html.create('div')
        :addClass('performance-dashboard')
        :attr('id', 'wiki-lua-performance-dashboard')
    
    -- Header with status
    local header = html:tag('div'):addClass('dashboard-header')
    header:tag('h2'):wikitext('📊 MediaWiki Lua Performance Dashboard')
    
    local statusBadge = header:tag('span')
        :addClass('status-badge')
        :addClass(dashboardData.status == 'active' and 'status-active' or 'status-inactive')
        :wikitext(dashboardData.status:upper())
    
    header:tag('span')
        :addClass('uptime')
        :wikitext(string.format('Uptime: %s', dashboard.formatDuration(dashboardData.uptime)))
    
    -- Metrics overview
    local metricsRow = html:tag('div'):addClass('metrics-row')
    
    dashboard.addMetricCard(metricsRow, 'Total Functions', dashboardData.metrics.totalFunctions, '🔧')
    dashboard.addMetricCard(metricsRow, 'Total Calls', dashboardData.metrics.totalCalls, '📞')
    dashboard.addMetricCard(metricsRow, 'Success Rate', 
        string.format('%.1f%%', dashboardData.metrics.successRate), '✅')
    dashboard.addMetricCard(metricsRow, 'Avg Response', 
        dashboard.formatTime(dashboardData.metrics.avgResponseTime), '⚡')
    dashboard.addMetricCard(metricsRow, 'Calls/Second', 
        string.format('%.2f', dashboardData.metrics.callsPerSecond), '🚀')
    
    -- Alerts section
    if #dashboardData.alerts > 0 then
        local alertsSection = html:tag('div'):addClass('alerts-section')
        alertsSection:tag('h3'):wikitext('⚠️ Performance Alerts')
        
        local alertsList = alertsSection:tag('ul'):addClass('alerts-list')
        for _, alert in ipairs(dashboardData.alerts) do
            local alertItem = alertsList:tag('li')
                :addClass('alert-item')
                :addClass('alert-' .. alert.severity)
            alertItem:tag('span'):addClass('alert-type'):wikitext(alert.type:gsub('_', ' '):upper())
            alertItem:tag('span'):addClass('alert-message'):wikitext(alert.message)
        end
    end
    
    -- Performance charts section
    local chartsSection = html:tag('div'):addClass('charts-section')
    
    -- Top performers chart
    dashboard.addPerformanceChart(chartsSection, 'Top Performers', 
        dashboardData.topPerformers, 'performance_score')
    
    -- Slowest functions chart
    dashboard.addPerformanceChart(chartsSection, 'Slowest Functions', 
        dashboardData.slowestFunctions, 'avgTime')
    
    -- Most used functions chart
    dashboard.addPerformanceChart(chartsSection, 'Most Used Functions', 
        dashboardData.mostUsedFunctions, 'calls')
    
    -- Recent activity
    local activitySection = html:tag('div'):addClass('activity-section')
    activitySection:tag('h3'):wikitext('🕐 Recent Activity')
    
    local activityTable = activitySection:tag('table')
        :addClass('activity-table')
        :addClass('wikitable')
    
    local headerRow = activityTable:tag('tr')
    headerRow:tag('th'):wikitext('Function')
    headerRow:tag('th'):wikitext('Duration')
    headerRow:tag('th'):wikitext('Memory')
    headerRow:tag('th'):wikitext('Status')
    headerRow:tag('th'):wikitext('Time')
    
    for _, activity in ipairs(dashboardData.recentActivity) do
        local row = activityTable:tag('tr')
        row:tag('td'):wikitext(activity.function_name)
        row:tag('td'):wikitext(dashboard.formatTime(activity.duration))
        row:tag('td'):wikitext(string.format('%.1f KB', activity.memory))
        row:tag('td'):wikitext(activity.success and '✅' or '❌')
        row:tag('td'):wikitext(os.date('%H:%M:%S', activity.timestamp))
    end
    
    -- Add CSS styles
    html:tag('style'):wikitext(dashboard.getCSS())
    
    -- Add refresh script
    html:tag('script'):wikitext(dashboard.getJavaScript())
    
    return html:tostring()
end

---Add a metric card to the dashboard
---@param container any HTML container
---@param title string Metric title
---@param value any Metric value
---@param icon string Icon for the metric
function dashboard.addMetricCard(container, title, value, icon)
    local card = container:tag('div'):addClass('metric-card')
    card:tag('div'):addClass('metric-icon'):wikitext(icon)
    card:tag('div'):addClass('metric-value'):wikitext(tostring(value))
    card:tag('div'):addClass('metric-title'):wikitext(title)
end

---Add a performance chart to the dashboard
---@param container any HTML container
---@param title string Chart title
---@param data table Chart data
---@param valueField string Field to chart
function dashboard.addPerformanceChart(container, title, data, valueField)
    local chartSection = container:tag('div'):addClass('chart-section')
    chartSection:tag('h4'):wikitext(title)
    
    if #data == 0 then
        chartSection:tag('p'):wikitext('No data available')
        return
    end
    
    local chart = chartSection:tag('div'):addClass('performance-chart')
    
    -- Simple horizontal bar chart
    local maxValue = 0
    for _, item in ipairs(data) do
        if item[valueField] > maxValue then
            maxValue = item[valueField]
        end
    end
    
    for _, item in ipairs(data) do
        local bar = chart:tag('div'):addClass('chart-bar')
        local percentage = maxValue > 0 and (item[valueField] / maxValue) * 100 or 0
        
        bar:tag('div'):addClass('bar-label'):wikitext(item.name)
        local barFill = bar:tag('div'):addClass('bar-fill')
            :css('width', percentage .. '%')
        barFill:tag('span'):addClass('bar-value')
            :wikitext(dashboard.formatMetricValue(item[valueField], valueField))
    end
end

--[[
------------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------------------------------------------
--]]

---Format duration in human-readable format
---@param seconds number Duration in seconds
---@return string formatted Formatted duration
function dashboard.formatDuration(seconds)
    if seconds < 60 then
        return string.format('%ds', math.floor(seconds))
    elseif seconds < 3600 then
        return string.format('%dm %ds', math.floor(seconds / 60), math.floor(seconds % 60))
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format('%dh %dm', hours, minutes)
    end
end

---Format time value for display
---@param time number Time in seconds
---@return string formatted Formatted time
function dashboard.formatTime(time)
    if time < 0.001 then
        return string.format('%.1fμs', time * 1000000)
    elseif time < 1 then
        return string.format('%.2fms', time * 1000)
    else
        return string.format('%.3fs', time)
    end
end

---Format metric value based on field type
---@param value number Value to format
---@param field string Field type
---@return string formatted Formatted value
function dashboard.formatMetricValue(value, field)
    if field == 'avgTime' or field == 'minTime' or field == 'maxTime' then
        return dashboard.formatTime(value)
    elseif field == 'successRate' then
        return string.format('%.1f%%', value)
    elseif field == 'performance_score' then
        return string.format('%.0f', value)
    else
        return tostring(value)
    end
end

---Get CSS styles for the dashboard
---@return string css CSS styles
function dashboard.getCSS()
    return [[
.performance-dashboard {
    font-family: Arial, sans-serif;
    margin: 20px 0;
    background: #f9f9f9;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 20px;
}

.dashboard-header {
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 20px;
    border-bottom: 2px solid #eee;
    padding-bottom: 15px;
}

.status-badge {
    padding: 5px 10px;
    border-radius: 15px;
    font-size: 12px;
    font-weight: bold;
}

.status-active {
    background: #4CAF50;
    color: white;
}

.status-inactive {
    background: #f44336;
    color: white;
}

.uptime {
    color: #666;
    font-size: 14px;
}

.metrics-row {
    display: flex;
    gap: 15px;
    margin-bottom: 25px;
    flex-wrap: wrap;
}

.metric-card {
    background: white;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 15px;
    text-align: center;
    min-width: 120px;
    flex: 1;
}

.metric-icon {
    font-size: 24px;
    margin-bottom: 8px;
}

.metric-value {
    font-size: 20px;
    font-weight: bold;
    color: #333;
    margin-bottom: 5px;
}

.metric-title {
    font-size: 12px;
    color: #666;
    text-transform: uppercase;
}

.alerts-section {
    background: #fff3cd;
    border: 1px solid #ffeaa7;
    border-radius: 6px;
    padding: 15px;
    margin-bottom: 20px;
}

.alerts-list {
    margin: 10px 0 0 0;
    padding: 0;
    list-style: none;
}

.alert-item {
    padding: 8px 12px;
    margin-bottom: 8px;
    border-radius: 4px;
    display: flex;
    gap: 10px;
}

.alert-warning {
    background: #fff3cd;
    border-left: 4px solid #ffc107;
}

.alert-error {
    background: #f8d7da;
    border-left: 4px solid #dc3545;
}

.alert-type {
    font-weight: bold;
    font-size: 12px;
    color: #666;
}

.charts-section {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-bottom: 25px;
}

.chart-section {
    background: white;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 15px;
}

.performance-chart {
    margin-top: 15px;
}

.chart-bar {
    margin-bottom: 10px;
}

.bar-label {
    font-size: 12px;
    color: #666;
    margin-bottom: 4px;
}

.bar-fill {
    background: #e3f2fd;
    height: 20px;
    border-radius: 10px;
    position: relative;
    background: linear-gradient(90deg, #2196F3, #1976D2);
}

.bar-value {
    position: absolute;
    right: 8px;
    top: 50%;
    transform: translateY(-50%);
    color: white;
    font-size: 11px;
    font-weight: bold;
}

.activity-section {
    background: white;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 15px;
}

.activity-table {
    width: 100%;
    margin-top: 15px;
}

.activity-table th,
.activity-table td {
    padding: 8px 12px;
    border: 1px solid #ddd;
    font-size: 12px;
}

.activity-table th {
    background: #f5f5f5;
    font-weight: bold;
}
]]
end

---Get JavaScript for dashboard interactivity
---@return string javascript JavaScript code
function dashboard.getJavaScript()
    return string.format([[
(function() {
    function refreshDashboard() {
        // In a real MediaWiki environment, this would make an AJAX call
        // to refresh the dashboard data
        console.log('Dashboard refresh triggered');
    }
    
    // Auto-refresh every %d seconds
    setInterval(refreshDashboard, %d000);
    
    // Add click handlers for interactive elements
    document.querySelectorAll('.metric-card').forEach(function(card) {
        card.style.cursor = 'pointer';
        card.addEventListener('click', function() {
            alert('Metric details: ' + this.querySelector('.metric-title').textContent);
        });
    });
})();
]], config.refreshInterval, config.refreshInterval)
end

--[[
------------------------------------------------------------------------------------
-- REPORTING AND ANALYSIS
------------------------------------------------------------------------------------
--]]

---Generate performance analysis report
---@return table report Comprehensive analysis report
function dashboard.generateAnalysisReport()
    local performanceData = CodeStandards.getPerformanceMetrics()
    local report = {
        timestamp = os.time(),
        analysis = {},
        recommendations = {},
        trends = {},
        bottlenecks = {}
    }
    
    -- Analyze each function
    for name, metrics in pairs(performanceData) do
        local analysis = {
            name = name,
            status = 'healthy',
            issues = {},
            recommendations = {}
        }
        
        -- Performance analysis
        if metrics.avgTime > 0.5 then
            analysis.status = 'warning'
            table.insert(analysis.issues, 'High average response time')
            table.insert(analysis.recommendations, 'Consider optimization or caching')
        end
        
        if metrics.successRate < 98 then
            analysis.status = 'critical'
            table.insert(analysis.issues, 'Low success rate')
            table.insert(analysis.recommendations, 'Review error handling and validation')
        end
        
        if metrics.avgMemory > 5120 then -- 5MB
            analysis.status = 'warning'
            table.insert(analysis.issues, 'High memory usage')
            table.insert(analysis.recommendations, 'Optimize memory allocation')
        end
        
        -- Identify bottlenecks
        if metrics.totalTime > 10 then -- Functions consuming >10s total
            table.insert(report.bottlenecks, {
                name = name,
                totalTime = metrics.totalTime,
                calls = metrics.calls,
                avgTime = metrics.avgTime,
                impact = 'high'
            })
        end
        
        report.analysis[name] = analysis
    end
    
    -- Generate global recommendations
    if #report.bottlenecks > 0 then
        table.insert(report.recommendations, 
            'Focus optimization efforts on identified bottlenecks')
    end
    
    local totalCalls = 0
    for _, metrics in pairs(performanceData) do
        totalCalls = totalCalls + metrics.calls
    end
    
    if totalCalls > 10000 then
        table.insert(report.recommendations,
            'Consider implementing more aggressive caching strategies')
    end
    
    return report
end

---Export performance data for external analysis
---@param format? string Export format ('json', 'csv', 'xml')
---@return string data Exported data
function dashboard.exportData(format)
    format = format or 'json'
    local data = CodeStandards.getPerformanceMetrics()
    
    if format == 'json' then
        return mw.text.jsonEncode(data)
    elseif format == 'csv' then
        local csv = "Function,Calls,TotalTime,AvgTime,MinTime,MaxTime,SuccessRate,AvgMemory\n"
        for name, metrics in pairs(data) do
            csv = csv .. string.format('%s,%d,%.6f,%.6f,%.6f,%.6f,%.2f,%.2f\n',
                name, metrics.calls, metrics.totalTime, metrics.avgTime,
                metrics.minTime == math.huge and 0 or metrics.minTime,
                metrics.maxTime, metrics.successRate, metrics.avgMemory)
        end
        return csv
    else
        return 'Unsupported format: ' .. format
    end
end

--[[
------------------------------------------------------------------------------------
-- MODULE INTEGRATION
------------------------------------------------------------------------------------
--]]

---Initialize performance monitoring for a module
---@param module table Module to monitor
---@param moduleName string Name of the module
---@return table wrappedModule Module with performance monitoring
function dashboard.instrumentModule(module, moduleName)
    local wrapped = {}
    
    for name, func in pairs(module) do
        if type(func) == 'function' then
            wrapped[name] = CodeStandards.trackPerformance(
                moduleName .. '.' .. name, func)
        else
            wrapped[name] = func
        end
    end
    
    return wrapped
end

---Get dashboard configuration
---@return table config Current configuration
function dashboard.getConfig()
    return config
end

---Update dashboard configuration
---@param newConfig table New configuration settings
function dashboard.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
end

return dashboard
