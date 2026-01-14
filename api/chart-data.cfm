<cfscript>
// API Endpoint: Get chart data from Upstash Redis
// Frontend pulls ONLY from this endpoint (Redis cached data)

// CORS headers
cfheader(name="Access-Control-Allow-Origin", value="*");
cfheader(name="Access-Control-Allow-Methods", value="GET, OPTIONS");
cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
cfheader(name="Content-Type", value="application/json");

// Handle OPTIONS preflight
if (cgi.request_method == "OPTIONS") {
    cfheader(statuscode="204", statustext="No Content");
    abort;
}

// Upstash Redis REST API configuration
variables.UPSTASH_URL = "https://expert-marlin-11581.upstash.io";
variables.UPSTASH_TOKEN = "AS09AAIncDI0YWZiZTM1ZThiYTA0NzcxYTg4Y2M3YTUwYjM1ZjY3OXAyMTE1ODE";

// Get parameters
param name="url.symbol" default="GC";
param name="url.timeframe" default="1h";
param name="url.from" default="0";  // Optional: filter from timestamp
param name="url.limit" default="0";  // Optional: limit number of candles

// Validate symbol
validSymbols = ["GC", "SI", "CL", "ES", "NQ"];
if (!arrayFind(validSymbols, url.symbol)) {
    writeOutput(serializeJSON({
        "success": false,
        "error": "Invalid symbol. Valid symbols: " & arrayToList(validSymbols)
    }));
    abort;
}

// Validate timeframe
validTimeframes = ["1m", "5m", "15m", "1h", "4h", "1d"];
if (!arrayFind(validTimeframes, url.timeframe)) {
    writeOutput(serializeJSON({
        "success": false,
        "error": "Invalid timeframe. Valid timeframes: " & arrayToList(validTimeframes)
    }));
    abort;
}

// Build cache key
cacheKey = "chart:#url.symbol#:#url.timeframe#:1year";

// Fetch from Upstash Redis
try {
    httpService = new http();
    httpService.setMethod("GET");
    httpService.setUrl("#variables.UPSTASH_URL#/get/#cacheKey#");
    httpService.addParam(type="header", name="Authorization", value="Bearer #variables.UPSTASH_TOKEN#");
    httpService.setTimeout(10);

    result = httpService.send().getPrefix();

    if (result.statusCode contains "200") {
        redisResponse = deserializeJSON(result.fileContent);

        if (structKeyExists(redisResponse, "result") && !isNull(redisResponse.result)) {
            // Parse the cached data
            cachedData = deserializeJSON(redisResponse.result);

            // Apply filters if specified
            candles = cachedData.candles;

            // Filter by 'from' timestamp
            if (val(url.from) > 0) {
                fromTs = val(url.from);
                filtered = [];
                for (c in candles) {
                    if (c.time >= fromTs) {
                        arrayAppend(filtered, c);
                    }
                }
                candles = filtered;
            }

            // Apply limit
            if (val(url.limit) > 0 && arrayLen(candles) > val(url.limit)) {
                // Return most recent candles
                startIdx = arrayLen(candles) - val(url.limit) + 1;
                candles = candles.subList(startIdx - 1, arrayLen(candles));
            }

            // Return response
            response = {
                "success": true,
                "symbol": cachedData.symbol,
                "timeframe": cachedData.timeframe,
                "candles": candles,
                "count": arrayLen(candles),
                "last_update": cachedData.last_update ?: 0,
                "cached": true,
                "cache_key": cacheKey
            };

            writeOutput(serializeJSON(response));
        } else {
            // No data in cache
            writeOutput(serializeJSON({
                "success": false,
                "error": "No cached data available for #url.symbol# #url.timeframe#. Sync service may not be running.",
                "cache_key": cacheKey
            }));
        }
    } else {
        writeOutput(serializeJSON({
            "success": false,
            "error": "Redis request failed: " & result.statusCode
        }));
    }
} catch (any e) {
    writeOutput(serializeJSON({
        "success": false,
        "error": "Error fetching from Redis: " & e.message
    }));
}
</cfscript>
