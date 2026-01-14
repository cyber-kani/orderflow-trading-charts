<cfsetting showdebugoutput="no"><cfscript>
// OrderFlowTest Database Configuration and Functions
// MSSQL Database: orderflow_signals

// Include configuration
if (!structKeyExists(variables, "dbConfig")) {
    include template="../config.cfm";
}

variables.dsn = {
    class: variables.dbConfig.driver,
    connectionString: variables.dbConfig.connectionString,
    username: variables.dbConfig.username,
    password: variables.dbConfig.password,
    connectionLimit: 20,
    connectionTimeout: 5,
    liveTimeout: 30,
    validate: true,
    alwaysSetTimeout: true
};

// Test database connection
function testConnection() {
    try {
        var test = queryExecute("SELECT 1 as test", {}, { datasource: variables.dsn });
        return test.recordCount > 0;
    } catch (any e) {
        writeLog(text="DB Connection Test FAILED: #e.message#", type="error", file="orderflowtest_db");
        return false;
    }
}

// ============================================
// DELTA DATA FUNCTIONS
// ============================================

// Save delta data for a single candle
function saveDeltaData(
    required string symbol,
    required string timeframe,
    required numeric candleTime,
    required numeric delta,
    required numeric maxDelta,
    required numeric minDelta,
    required numeric volume,
    required numeric buyVolume,
    required numeric sellVolume,
    numeric candleOpen = 0,
    numeric candleHigh = 0,
    numeric candleLow = 0,
    numeric candleClose = 0,
    boolean isEstimated = false
) {
    try {
        queryExecute("
            EXEC usp_upsert_delta_data
                @symbol = :symbol,
                @timeframe = :timeframe,
                @candle_time = :candleTime,
                @delta = :delta,
                @max_delta = :maxDelta,
                @min_delta = :minDelta,
                @volume = :volume,
                @buy_volume = :buyVolume,
                @sell_volume = :sellVolume,
                @candle_open = :candleOpen,
                @candle_high = :candleHigh,
                @candle_low = :candleLow,
                @candle_close = :candleClose,
                @is_estimated = :isEstimated
        ", {
            symbol: { value: arguments.symbol, cfsqltype: "varchar" },
            timeframe: { value: arguments.timeframe, cfsqltype: "varchar" },
            candleTime: { value: arguments.candleTime, cfsqltype: "bigint" },
            delta: { value: arguments.delta, cfsqltype: "integer" },
            maxDelta: { value: arguments.maxDelta, cfsqltype: "integer" },
            minDelta: { value: arguments.minDelta, cfsqltype: "integer" },
            volume: { value: arguments.volume, cfsqltype: "integer" },
            buyVolume: { value: arguments.buyVolume, cfsqltype: "integer" },
            sellVolume: { value: arguments.sellVolume, cfsqltype: "integer" },
            candleOpen: { value: arguments.candleOpen, cfsqltype: "decimal", null: arguments.candleOpen == 0 },
            candleHigh: { value: arguments.candleHigh, cfsqltype: "decimal", null: arguments.candleHigh == 0 },
            candleLow: { value: arguments.candleLow, cfsqltype: "decimal", null: arguments.candleLow == 0 },
            candleClose: { value: arguments.candleClose, cfsqltype: "decimal", null: arguments.candleClose == 0 },
            isEstimated: { value: arguments.isEstimated ? 1 : 0, cfsqltype: "bit" }
        }, { datasource: variables.dsn });
        return true;
    } catch (any e) {
        writeLog(text="saveDeltaData ERROR: #e.message#", type="error", file="orderflowtest_db");
        return false;
    }
}

// Save multiple delta records in batch
function saveDeltaBatch(required string symbol, required string timeframe, required array records) {
    var saved = 0;
    for (var rec in arguments.records) {
        var success = saveDeltaData(
            symbol = arguments.symbol,
            timeframe = arguments.timeframe,
            candleTime = rec.time ?: rec.candleTime ?: 0,
            delta = rec.delta ?: 0,
            maxDelta = rec.maxDelta ?: rec.delta ?: 0,
            minDelta = rec.minDelta ?: rec.delta ?: 0,
            volume = rec.volume ?: 0,
            buyVolume = rec.buyVolume ?: 0,
            sellVolume = rec.sellVolume ?: 0,
            candleOpen = rec.candle.o ?: rec.candleOpen ?: 0,
            candleHigh = rec.candle.h ?: rec.candleHigh ?: 0,
            candleLow = rec.candle.l ?: rec.candleLow ?: 0,
            candleClose = rec.candle.c ?: rec.candleClose ?: 0,
            isEstimated = rec.estimated ?: false
        );
        if (success) saved++;
    }
    return saved;
}

// Load delta data for a symbol/timeframe
function loadDeltaData(
    required string symbol,
    required string timeframe,
    numeric startTime = 0,
    numeric endTime = 0,
    numeric limit = 1000
) {
    try {
        var result = queryExecute("
            EXEC usp_get_delta_data
                @symbol = :symbol,
                @timeframe = :timeframe,
                @start_time = :startTime,
                @end_time = :endTime,
                @limit = :limit
        ", {
            symbol: { value: arguments.symbol, cfsqltype: "varchar" },
            timeframe: { value: arguments.timeframe, cfsqltype: "varchar" },
            startTime: { value: arguments.startTime, cfsqltype: "bigint", null: arguments.startTime == 0 },
            endTime: { value: arguments.endTime, cfsqltype: "bigint", null: arguments.endTime == 0 },
            limit: { value: arguments.limit, cfsqltype: "integer" }
        }, { datasource: variables.dsn });

        // Convert query to array of structs
        var data = {};
        for (var row in result) {
            data[row.candle_time] = {
                delta: row.delta,
                maxDelta: row.maxDelta,
                minDelta: row.minDelta,
                volume: row.volume,
                buyVolume: row.buyVolume,
                sellVolume: row.sellVolume,
                estimated: row.estimated == 1,
                candle: {
                    o: row.candle_open ?: 0,
                    h: row.candle_high ?: 0,
                    l: row.candle_low ?: 0,
                    c: row.candle_close ?: 0
                }
            };
        }
        return data;
    } catch (any e) {
        writeLog(text="loadDeltaData ERROR: #e.message#", type="error", file="orderflowtest_db");
        return {};
    }
}

// ============================================
// BIG ORDER FUNCTIONS
// ============================================

// Save a single big order
function saveBigOrder(
    required string symbol,
    required string timeframe,
    required numeric candleTime,
    required numeric price,
    required numeric size,
    required string side
) {
    try {
        queryExecute("
            EXEC usp_upsert_big_order
                @symbol = :symbol,
                @timeframe = :timeframe,
                @candle_time = :candleTime,
                @price = :price,
                @size = :size,
                @side = :side
        ", {
            symbol: { value: arguments.symbol, cfsqltype: "varchar" },
            timeframe: { value: arguments.timeframe, cfsqltype: "varchar" },
            candleTime: { value: arguments.candleTime, cfsqltype: "bigint" },
            price: { value: arguments.price, cfsqltype: "decimal" },
            size: { value: arguments.size, cfsqltype: "integer" },
            side: { value: arguments.side, cfsqltype: "varchar" }
        }, { datasource: variables.dsn });
        return true;
    } catch (any e) {
        writeLog(text="saveBigOrder ERROR: #e.message#", type="error", file="orderflowtest_db");
        return false;
    }
}

// Save multiple big orders in batch
function saveBigOrderBatch(required string symbol, required string timeframe, required array orders) {
    var saved = 0;
    for (var order in arguments.orders) {
        var success = saveBigOrder(
            symbol = arguments.symbol,
            timeframe = arguments.timeframe,
            candleTime = order.time ?: 0,
            price = order.price ?: 0,
            size = order.size ?: 0,
            side = order.side ?: "BUY"
        );
        if (success) saved++;
    }
    return saved;
}

// Load big orders for a symbol/timeframe
function loadBigOrders(
    required string symbol,
    required string timeframe,
    numeric startTime = 0,
    numeric endTime = 0,
    numeric limit = 500
) {
    try {
        var result = queryExecute("
            EXEC usp_get_big_orders
                @symbol = :symbol,
                @timeframe = :timeframe,
                @start_time = :startTime,
                @end_time = :endTime,
                @limit = :limit
        ", {
            symbol: { value: arguments.symbol, cfsqltype: "varchar" },
            timeframe: { value: arguments.timeframe, cfsqltype: "varchar" },
            startTime: { value: arguments.startTime, cfsqltype: "bigint", null: arguments.startTime == 0 },
            endTime: { value: arguments.endTime, cfsqltype: "bigint", null: arguments.endTime == 0 },
            limit: { value: arguments.limit, cfsqltype: "integer" }
        }, { datasource: variables.dsn });

        // Convert query to array
        var orders = [];
        for (var row in result) {
            arrayAppend(orders, {
                time: row.time,
                price: row.price,
                size: row.size,
                side: row.side
            });
        }
        return orders;
    } catch (any e) {
        writeLog(text="loadBigOrders ERROR: #e.message#", type="error", file="orderflowtest_db");
        return [];
    }
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

// Get available timeframes with data counts
function getDataStats(required string symbol) {
    try {
        var result = queryExecute("
            SELECT
                timeframe,
                COUNT(*) as delta_count,
                MIN(candle_time) as oldest_candle,
                MAX(candle_time) as newest_candle
            FROM delta_data
            WHERE symbol = :symbol
            GROUP BY timeframe
            ORDER BY timeframe
        ", {
            symbol: { value: arguments.symbol, cfsqltype: "varchar" }
        }, { datasource: variables.dsn });

        var stats = {};
        for (var row in result) {
            stats[row.timeframe] = {
                count: row.delta_count,
                oldest: row.oldest_candle,
                newest: row.newest_candle
            };
        }
        return stats;
    } catch (any e) {
        return {};
    }
}

// Cleanup old data
function cleanupOldData(numeric daysToKeep = 30) {
    try {
        var result = queryExecute("
            EXEC usp_cleanup_old_data @days_to_keep = :days
        ", {
            days: { value: arguments.daysToKeep, cfsqltype: "integer" }
        }, { datasource: variables.dsn });
        return result.deleted_count ?: 0;
    } catch (any e) {
        writeLog(text="cleanupOldData ERROR: #e.message#", type="error", file="orderflowtest_db");
        return 0;
    }
}
</cfscript>
