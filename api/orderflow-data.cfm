<cfsetting showdebugoutput="no" requesttimeout="30">
<cfheader name="Content-Type" value="application/json">
<cfheader name="Access-Control-Allow-Origin" value="*">
<cfheader name="Access-Control-Allow-Methods" value="GET, POST, OPTIONS">
<cfheader name="Access-Control-Allow-Headers" value="Content-Type">

<cfif cgi.request_method EQ "OPTIONS">
    <cfoutput>{"status":"ok"}</cfoutput>
    <cfabort>
</cfif>

<cfscript>
// OrderFlow Data API - Delta and Big Orders
// Supports both database and Redis storage

include template="../db/db.cfm";

// Parse request
var method = cgi.request_method;
var action = url.action ?: "";
var symbol = url.symbol ?: "GC";
var timeframe = url.timeframe ?: "1m";
var response = { success: false, error: "" };

try {
    switch (lCase(action)) {

        // ============================================
        // GET DELTA DATA
        // ============================================
        case "get_delta":
            var startTime = val(url.start ?: 0);
            var endTime = val(url.end ?: 0);
            var limit = val(url.limit ?: 1000);

            var deltaData = loadDeltaData(
                symbol = symbol,
                timeframe = timeframe,
                startTime = startTime,
                endTime = endTime,
                limit = limit
            );

            response = {
                success: true,
                symbol: symbol,
                timeframe: timeframe,
                count: structCount(deltaData),
                data: deltaData
            };
            break;

        // ============================================
        // GET BIG ORDERS
        // ============================================
        case "get_big_orders":
            var startTime = val(url.start ?: 0);
            var endTime = val(url.end ?: 0);
            var limit = val(url.limit ?: 500);

            var bigOrders = loadBigOrders(
                symbol = symbol,
                timeframe = timeframe,
                startTime = startTime,
                endTime = endTime,
                limit = limit
            );

            response = {
                success: true,
                symbol: symbol,
                timeframe: timeframe,
                count: arrayLen(bigOrders),
                data: bigOrders
            };
            break;

        // ============================================
        // GET BOTH DELTA AND BIG ORDERS
        // ============================================
        case "get_all":
            var startTime = val(url.start ?: 0);
            var endTime = val(url.end ?: 0);
            var deltaLimit = val(url.delta_limit ?: 1000);
            var orderLimit = val(url.order_limit ?: 500);

            var deltaData = loadDeltaData(
                symbol = symbol,
                timeframe = timeframe,
                startTime = startTime,
                endTime = endTime,
                limit = deltaLimit
            );

            var bigOrders = loadBigOrders(
                symbol = symbol,
                timeframe = timeframe,
                startTime = startTime,
                endTime = endTime,
                limit = orderLimit
            );

            response = {
                success: true,
                symbol: symbol,
                timeframe: timeframe,
                delta: {
                    count: structCount(deltaData),
                    data: deltaData
                },
                bigOrders: {
                    count: arrayLen(bigOrders),
                    data: bigOrders
                }
            };
            break;

        // ============================================
        // SAVE DELTA DATA (POST)
        // ============================================
        case "save_delta":
            if (method != "POST") {
                response.error = "POST method required";
                break;
            }

            // Parse JSON body
            var requestBody = toString(getHttpRequestData().content);
            if (len(requestBody) == 0) {
                response.error = "No data provided";
                break;
            }

            var payload = deserializeJSON(requestBody);
            var records = payload.data ?: [];

            if (!isArray(records) || arrayLen(records) == 0) {
                response.error = "No delta records in data array";
                break;
            }

            var saved = saveDeltaBatch(
                symbol = payload.symbol ?: symbol,
                timeframe = payload.timeframe ?: timeframe,
                records = records
            );

            response = {
                success: true,
                saved: saved,
                total: arrayLen(records)
            };
            break;

        // ============================================
        // SAVE BIG ORDERS (POST)
        // ============================================
        case "save_big_orders":
            if (method != "POST") {
                response.error = "POST method required";
                break;
            }

            var requestBody = toString(getHttpRequestData().content);
            if (len(requestBody) == 0) {
                response.error = "No data provided";
                break;
            }

            var payload = deserializeJSON(requestBody);
            var orders = payload.data ?: [];

            if (!isArray(orders) || arrayLen(orders) == 0) {
                response.error = "No orders in data array";
                break;
            }

            var saved = saveBigOrderBatch(
                symbol = payload.symbol ?: symbol,
                timeframe = payload.timeframe ?: timeframe,
                orders = orders
            );

            response = {
                success: true,
                saved: saved,
                total: arrayLen(orders)
            };
            break;

        // ============================================
        // SAVE BOTH DELTA AND BIG ORDERS (POST)
        // ============================================
        case "save_all":
            if (method != "POST") {
                response.error = "POST method required";
                break;
            }

            var requestBody = toString(getHttpRequestData().content);
            if (len(requestBody) == 0) {
                response.error = "No data provided";
                break;
            }

            var payload = deserializeJSON(requestBody);
            var sym = payload.symbol ?: symbol;
            var tf = payload.timeframe ?: timeframe;

            var deltaSaved = 0;
            var ordersSaved = 0;

            // Save delta data
            if (structKeyExists(payload, "delta") && isArray(payload.delta)) {
                deltaSaved = saveDeltaBatch(symbol = sym, timeframe = tf, records = payload.delta);
            }

            // Save big orders
            if (structKeyExists(payload, "bigOrders") && isArray(payload.bigOrders)) {
                ordersSaved = saveBigOrderBatch(symbol = sym, timeframe = tf, orders = payload.bigOrders);
            }

            response = {
                success: true,
                deltaSaved: deltaSaved,
                ordersSaved: ordersSaved
            };
            break;

        // ============================================
        // GET DATA STATS
        // ============================================
        case "stats":
            var stats = getDataStats(symbol);
            response = {
                success: true,
                symbol: symbol,
                timeframes: stats
            };
            break;

        // ============================================
        // TEST CONNECTION
        // ============================================
        case "test":
            response = {
                success: testConnection(),
                message: testConnection() ? "Database connected" : "Database connection failed"
            };
            break;

        // ============================================
        // CLEANUP OLD DATA
        // ============================================
        case "cleanup":
            var days = val(url.days ?: 30);
            var deleted = cleanupOldData(days);
            response = {
                success: true,
                deleted: deleted,
                daysKept: days
            };
            break;

        default:
            response.error = "Unknown action. Available: get_delta, get_big_orders, get_all, save_delta, save_big_orders, save_all, stats, test, cleanup";
    }

} catch (any e) {
    response.success = false;
    response.error = e.message;
    writeLog(text="API ERROR: #e.message# - #e.detail#", type="error", file="orderflowtest_api");
}

writeOutput(serializeJSON(response));
</cfscript>
