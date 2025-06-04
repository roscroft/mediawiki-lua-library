--[[
Memory Profiler for MediaWiki Lua Modules

This module provides tools for analyzing memory usage patterns in MediaWiki Lua code,
helping identify memory leaks and optimization opportunities.
]] --

local MemoryProfiler = {}

-- Import dependencies
local Array = require('Module:Array')
local CodeStandards = require('Module:CodeStandards')

--[[
Memory snapshot structure
]] --
local function createSnapshot(label)
    return {
        label = label or "Snapshot",
        timestamp = os.time(),
        memory_kb = collectgarbage("count"),
        raw_memory = collectgarbage("count") * 1024
    }
end

--[[
Memory profiler class
]] --
function MemoryProfiler.new()
    local profiler = {
        snapshots = Array.new(),
        baseline = nil,
        active = false
    }

    function profiler:start(label)
        self.active = true
        self.baseline = createSnapshot(label or "Baseline")
        self.snapshots:push(self.baseline)
        return self
    end

    function profiler:snapshot(label)
        if not self.active then
            return self
        end

        local snap = createSnapshot(label)
        self.snapshots:push(snap)
        return snap
    end

    function profiler:stop()
        self.active = false
        local final = createSnapshot("Final")
        self.snapshots:push(final)
        return final
    end

    function profiler:analyze()
        if self.snapshots:length() < 2 then
            return { error = "Need at least 2 snapshots to analyze" }
        end

        local analysis = {
            total_snapshots = self.snapshots:length(),
            memory_growth = {},
            peak_memory = 0,
            average_memory = 0,
            memory_efficiency = {}
        }

        -- Calculate memory growth between snapshots
        for i = 2, self.snapshots:length() do
            local prev = self.snapshots:get(i - 1)
            local curr = self.snapshots:get(i)
            local growth = curr.memory_kb - prev.memory_kb

            table.insert(analysis.memory_growth, {
                from = prev.label,
                to = curr.label,
                growth_kb = growth,
                growth_percent = (growth / prev.memory_kb) * 100
            })

            if curr.memory_kb > analysis.peak_memory then
                analysis.peak_memory = curr.memory_kb
            end
        end

        -- Calculate average memory usage
        local total_memory = self.snapshots:reduce(function(sum, snap)
            return sum + snap.memory_kb
        end, 0)
        analysis.average_memory = total_memory / self.snapshots:length()

        -- Memory efficiency analysis
        local baseline_memory = self.baseline.memory_kb
        local final_memory = self.snapshots:get(self.snapshots:length()).memory_kb

        analysis.memory_efficiency = {
            baseline_kb = baseline_memory,
            final_kb = final_memory,
            net_growth_kb = final_memory - baseline_memory,
            growth_ratio = final_memory / baseline_memory
        }

        return analysis
    end

    function profiler:report()
        local analysis = self:analyze()

        if analysis.error then
            return analysis.error
        end

        local report = Array.new()

        report:push("=== Memory Profile Report ===")
        report:push(string.format("Total Snapshots: %d", analysis.total_snapshots))
        report:push(string.format("Peak Memory: %.2f KB", analysis.peak_memory))
        report:push(string.format("Average Memory: %.2f KB", analysis.average_memory))
        report:push("")

        report:push("=== Memory Growth Analysis ===")
        for _, growth in ipairs(analysis.memory_growth) do
            report:push(string.format(
                "%s → %s: %+.2f KB (%+.1f%%)",
                growth.from,
                growth.to,
                growth.growth_kb,
                growth.growth_percent
            ))
        end
        report:push("")

        report:push("=== Memory Efficiency ===")
        local eff = analysis.memory_efficiency
        report:push(string.format("Baseline: %.2f KB", eff.baseline_kb))
        report:push(string.format("Final: %.2f KB", eff.final_kb))
        report:push(string.format("Net Growth: %+.2f KB", eff.net_growth_kb))
        report:push(string.format("Growth Ratio: %.2fx", eff.growth_ratio))

        return report:join("\n")
    end

    return profiler
end

--[[
Convenient function to profile a function execution
]] --
function MemoryProfiler.profile(func, label)
    local success, result = CodeStandards.handleError(function()
        local profiler = MemoryProfiler.new()
        profiler:start(label or "Function Execution")

        local func_result = func()

        profiler:stop()

        return {
            result = func_result,
            profile = profiler:analyze(),
            report = profiler:report()
        }
    end, "Memory profiling")

    return success and result or { error = result }
end

--[[
Batch memory testing - compare multiple implementations
]] --
function MemoryProfiler.compareImplementations(implementations)
    local results = Array.new()

    for name, func in pairs(implementations) do
        local profile_result = MemoryProfiler.profile(func, name)

        if not profile_result.error then
            results:push({
                name = name,
                peak_memory = profile_result.profile.peak_memory,
                growth = profile_result.profile.memory_efficiency.net_growth_kb,
                efficiency = profile_result.profile.memory_efficiency.growth_ratio
            })
        else
            results:push({
                name = name,
                error = profile_result.error
            })
        end
    end

    -- Sort by memory efficiency (lower growth ratio is better)
    results = results:sort(function(a, b)
        if a.error or b.error then return false end
        return a.efficiency < b.efficiency
    end)

    local report = Array.new()
    report:push("=== Implementation Comparison ===")

    for i = 1, results:length() do
        local impl = results:get(i)
        if impl.error then
            report:push(string.format("%s: ERROR - %s", impl.name, impl.error))
        else
            report:push(string.format(
                "%d. %s: %.2f KB peak, %+.2f KB growth (%.2fx ratio)",
                i, impl.name, impl.peak_memory, impl.growth, impl.efficiency
            ))
        end
    end

    return {
        results = results:toTable(),
        report = report:join("\n")
    }
end

--[[
Memory leak detection utility
]] --
function MemoryProfiler.detectLeaks(func, iterations)
    iterations = iterations or 10
    local profiler = MemoryProfiler.new()

    profiler:start("Leak Detection")

    for i = 1, iterations do
        func()
        profiler:snapshot("Iteration " .. i)

        -- Force garbage collection between iterations
        collectgarbage("collect")
    end

    profiler:stop()

    local analysis = profiler:analyze()

    -- Check for consistent memory growth (potential leak)
    local growth_pattern = Array.new()
    for _, growth in ipairs(analysis.memory_growth) do
        if growth.growth_kb > 0 then
            growth_pattern:push(growth.growth_kb)
        end
    end

    local leak_detected = false
    if growth_pattern:length() > 3 then
        -- Check if memory consistently grows
        local consistent_growth = growth_pattern:reduce(function(acc, growth)
            return acc and growth > 0.1 -- 0.1 KB threshold
        end, true)

        leak_detected = consistent_growth
    end

    return {
        leak_detected = leak_detected,
        analysis = analysis,
        report = profiler:report(),
        recommendation = leak_detected and
            "Potential memory leak detected. Review variable scoping and references." or
            "No obvious memory leaks detected."
    }
end

return MemoryProfiler
