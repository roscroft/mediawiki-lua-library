--[[
Lazy Evaluation Examples

This module demonstrates lazy evaluation techniques to optimize performance
when working with large datasets in MediaWiki Lua environments.
]] --

local LazyEvaluation = {}

-- Import dependencies
local Array = require('Module:Array')
local CodeStandards = require('Module:CodeStandards')

--[[
Lazy Iterator - only computes values when needed
]] --
function LazyEvaluation.createLazyIterator(generator, count)
    local iterator = {
        generator = generator,
        count = count or math.huge,
        computed = {},
        index = 0
    }

    function iterator:next()
        self.index = self.index + 1
        if self.index > self.count then
            return nil
        end

        if not self.computed[self.index] then
            self.computed[self.index] = self.generator(self.index)
        end

        return self.computed[self.index]
    end

    function iterator:take(n)
        local results = Array.new()
        for i = 1, n do
            local value = self:next()
            if value == nil then break end
            results:push(value)
        end
        return results
    end

    function iterator:skip(n)
        for i = 1, n do
            self:next()
        end
        return self
    end

    return iterator
end

--[[
Lazy Map - transforms values only when accessed
]] --
function LazyEvaluation.lazyMap(array, transformFn)
    local lazyArray = {
        source = array,
        transform = transformFn,
        cache = {}
    }

    function lazyArray:get(index)
        if not self.cache[index] then
            local sourceValue = self.source:get(index)
            if sourceValue ~= nil then
                self.cache[index] = self.transform(sourceValue)
            end
        end
        return self.cache[index]
    end

    function lazyArray:materialize(maxItems)
        local result = Array.new()
        local limit = math.min(maxItems or self.source:length(), self.source:length())

        for i = 1, limit do
            local value = self:get(i)
            if value ~= nil then
                result:push(value)
            end
        end

        return result
    end

    return lazyArray
end

--[[
Lazy Filter - only evaluates filter condition when needed
]] --
function LazyEvaluation.lazyFilter(array, predicateFn)
    local lazyFilter = {
        source = array,
        predicate = predicateFn,
        filtered_indices = nil
    }

    function lazyFilter:_computeIndices()
        if self.filtered_indices then return end

        self.filtered_indices = Array.new()
        for i = 1, self.source:length() do
            local value = self.source:get(i)
            if self.predicate(value) then
                self.filtered_indices:push(i)
            end
        end
    end

    function lazyFilter:get(index)
        self:_computeIndices()
        local sourceIndex = self.filtered_indices:get(index)
        return sourceIndex and self.source:get(sourceIndex) or nil
    end

    function lazyFilter:length()
        self:_computeIndices()
        return self.filtered_indices:length()
    end

    function lazyFilter:materialize()
        local result = Array.new()
        for i = 1, self:length() do
            result:push(self:get(i))
        end
        return result
    end

    return lazyFilter
end

--[[
Demonstration: Process large dataset lazily
]] --
function LazyEvaluation.demonstrateLazyProcessing()
    local success, result = CodeStandards.handleError(function()
        local report = Array.new()

        report:push("=== Lazy Evaluation Demonstration ===")

        -- Create a large dataset generator (without actually creating the data)
        local largeDataGenerator = function(index)
            -- Simulate expensive computation
            return {
                id = index,
                value = math.random(1, 1000),
                computed = index * index,
                expensive_calc = function()
                    -- Simulate expensive operation
                    local result = 0
                    for i = 1, 100 do
                        result = result + math.sin(index * i)
                    end
                    return result
                end
            }
        end

        -- Create lazy iterator for 10000 items (but don't compute them yet)
        local lazyData = LazyEvaluation.createLazyIterator(largeDataGenerator, 10000)

        report:push("✓ Created lazy iterator for 10,000 items (no computation yet)")

        -- Take only first 5 items (only these get computed)
        local firstFive = lazyData:take(5)
        report:push(string.format("✓ Computed first 5 items: %s",
            firstFive:map(function(item) return tostring(item.id) end):join(", ")))

        -- Skip some items and take more
        lazyData:skip(95) -- Skip to item 100
        local nextFive = lazyData:take(5)
        report:push(string.format("✓ Skipped to items 101-105: %s",
            nextFive:map(function(item) return tostring(item.id) end):join(", ")))

        -- Demonstrate lazy map transformation
        local sourceArray = Array.new({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
        local lazySquares = LazyEvaluation.lazyMap(sourceArray, function(x)
            return x * x
        end)

        -- Only compute squares for indices we actually access
        local someSquares = Array.new({
            lazySquares:get(3), -- 9
            lazySquares:get(7), -- 49
            lazySquares:get(10) -- 100
        })

        report:push(string.format("✓ Lazy map computed only accessed squares: %s",
            someSquares:join(", ")))

        -- Demonstrate lazy filter
        local numbers = Array.new()
        for i = 1, 1000 do
            numbers:push(math.random(1, 100))
        end

        local lazyLargeNumbers = LazyEvaluation.lazyFilter(numbers, function(x)
            return x > 80
        end)

        -- Only compute filter when we need the results
        local firstTenLarge = Array.new()
        for i = 1, math.min(10, lazyLargeNumbers:length()) do
            firstTenLarge:push(lazyLargeNumbers:get(i))
        end

        report:push(string.format("✓ Lazy filter found %d large numbers, showing first 10: %s",
            lazyLargeNumbers:length(),
            firstTenLarge:join(", ")))

        report:push("")
        report:push("=== Performance Benefits ===")
        report:push("• Only computed values that were actually needed")
        report:push("• Saved memory by not storing unnecessary intermediate results")
        report:push("• Enabled processing of 'infinite' or very large datasets")
        report:push("• Improved responsiveness by avoiding upfront computation")

        return report:join("\n")
    end, "Lazy evaluation demonstration")

    return success and result or ("Error in lazy evaluation demo: " .. tostring(result))
end

--[[
Memory-efficient batch processing
]] --
function LazyEvaluation.efficientBatchProcessing(dataSize, batchSize)
    local success, result = CodeStandards.handleError(function()
        dataSize = dataSize or 1000
        batchSize = batchSize or 50

        local report = Array.new()
        local totalProcessed = 0
        local batchCount = 0

        report:push(string.format("=== Batch Processing: %d items in batches of %d ===",
            dataSize, batchSize))

        -- Create data generator that simulates large dataset
        local dataGenerator = function(startIndex, count)
            local batch = Array.new()
            for i = startIndex, math.min(startIndex + count - 1, dataSize) do
                batch:push({
                    id = i,
                    data = string.format("item_%d", i),
                    processed = false
                })
            end
            return batch
        end

        -- Process in batches
        for startIndex = 1, dataSize, batchSize do
            batchCount = batchCount + 1
            local batch = dataGenerator(startIndex, batchSize)

            -- Process this batch
            local processedBatch = batch:map(function(item)
                return {
                    id = item.id,
                    data = string.upper(item.data),
                    processed = true,
                    batch_number = batchCount
                }
            end)

            totalProcessed = totalProcessed + processedBatch:length()

            -- Only keep summary statistics, not the actual data
            if batchCount <= 3 or batchCount % 10 == 0 then
                report:push(string.format("Batch %d: processed %d items (total: %d)",
                    batchCount, processedBatch:length(), totalProcessed))
            end
        end

        report:push(string.format("✓ Completed processing %d items in %d batches",
            totalProcessed, batchCount))
        report:push("✓ Memory usage kept constant (only one batch in memory at a time)")

        return report:join("\n")
    end, "Batch processing")

    return success and result or ("Error in batch processing: " .. tostring(result))
end

return LazyEvaluation
