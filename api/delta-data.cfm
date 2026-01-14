<cfscript>
// API Endpoint: Save/Load delta data to Upstash Redis
// GET: Load delta data for a symbol/timeframe
// POST: Save delta data for a symbol/timeframe (overwrites existing)

// CORS headers
cfheader(name="Access-Control-Allow-Origin", value="*");
cfheader(name="Access-Control-Allow-Methods", value="GET, POST, OPTIONS");
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
param name="url.timeframe" default="1m";

// Validate symbol
validSymbols = ["GC", "SI", "CL", "ES", "NQ"];
if (!arrayFind(validSymbols, url.symbol)) {
    writeOutput('{"success":false,"error":"Invalid symbol"}');
    abort;
}

// Validate timeframe
validTimeframes = ["1m", "5m", "15m", "1h", "4h", "1d"];
if (!arrayFind(validTimeframes, url.timeframe)) {
    writeOutput('{"success":false,"error":"Invalid timeframe"}');
    abort;
}

// Build cache key for delta data
cacheKey = "deltaV2:#url.symbol#:#url.timeframe#";

if (cgi.request_method == "GET") {
    // GET: Load delta data from Redis
    try {
        httpService = new http();
        httpService.setMethod("GET");
        httpService.setUrl("#variables.UPSTASH_URL#/get/#cacheKey#");
        httpService.addParam(type="header", name="Authorization", value="Bearer #variables.UPSTASH_TOKEN#");
        httpService.setTimeout(10);

        result = httpService.send().getPrefix();

        if (result.statusCode contains "200") {
            redisResponse = deserializeJSON(result.fileContent);

            if (structKeyExists(redisResponse, "result") && !isNull(redisResponse.result) && len(trim(redisResponse.result)) > 2) {
                // Return the cached delta data as-is
                writeOutput('{"success":true,"symbol":"#url.symbol#","timeframe":"#url.timeframe#","data":' & redisResponse.result & '}');
            } else {
                writeOutput('{"success":true,"symbol":"#url.symbol#","timeframe":"#url.timeframe#","data":{}}');
            }
        } else {
            writeOutput('{"success":false,"error":"Redis GET failed: #result.statusCode#"}');
        }
    } catch (any e) {
        writeOutput('{"success":false,"error":"GET Error: #e.message#"}');
    }

} else if (cgi.request_method == "POST") {
    // POST: Save delta data to Redis (merge with existing)
    // If clear=1, delete all data for this symbol/timeframe
    param name="url.clear" default="0";

    try {
        // Handle clear request
        if (url.clear == "1") {
            httpService = new http();
            httpService.setMethod("GET");
            httpService.setUrl("#variables.UPSTASH_URL#/del/#cacheKey#");
            httpService.addParam(type="header", name="Authorization", value="Bearer #variables.UPSTASH_TOKEN#");
            httpService.setTimeout(10);
            result = httpService.send().getPrefix();

            if (result.statusCode contains "200") {
                writeOutput('{"success":true,"message":"Cleared all data for #url.symbol#/#url.timeframe#"}');
            } else {
                writeOutput('{"success":false,"error":"Failed to clear: #result.statusCode#"}');
            }
            abort;
        }

        requestBody = toString(getHttpRequestData().content);

        if (len(trim(requestBody)) < 3) {
            writeOutput('{"success":false,"error":"No data provided"}');
            abort;
        }

        // First get existing data
        httpService = new http();
        httpService.setMethod("GET");
        httpService.setUrl("#variables.UPSTASH_URL#/get/#cacheKey#");
        httpService.addParam(type="header", name="Authorization", value="Bearer #variables.UPSTASH_TOKEN#");
        httpService.setTimeout(10);
        result = httpService.send().getPrefix();

        existingData = {};
        if (result.statusCode contains "200") {
            redisResponse = deserializeJSON(result.fileContent);
            if (structKeyExists(redisResponse, "result") && !isNull(redisResponse.result) && len(trim(redisResponse.result)) > 2) {
                try {
                    existingData = deserializeJSON(redisResponse.result);
                } catch (any e) {
                    existingData = {};
                }
            }
        }

        // Parse incoming data
        incomingData = deserializeJSON(requestBody);

        // Merge: incoming overwrites existing
        for (key in incomingData) {
            existingData[key] = incomingData[key];
        }

        // Clean old data (keep only last 24 hours)
        twentyFourHoursAgo = dateDiff("s", createDateTime(1970,1,1,0,0,0), now()) - (24 * 60 * 60);
        keysToRemove = [];
        for (key in existingData) {
            if (isNumeric(key) && val(key) < twentyFourHoursAgo) {
                arrayAppend(keysToRemove, key);
            }
        }
        for (key in keysToRemove) {
            structDelete(existingData, key);
        }

        // Serialize merged data
        mergedJson = serializeJSON(existingData);

        // Save to Redis using URL path format (simpler, more reliable)
        encodedData = urlEncodedFormat(mergedJson);

        httpService = new http();
        httpService.setMethod("GET");
        httpService.setUrl("#variables.UPSTASH_URL#/setex/#cacheKey#/86400/#encodedData#");
        httpService.addParam(type="header", name="Authorization", value="Bearer #variables.UPSTASH_TOKEN#");
        httpService.setTimeout(15);

        result = httpService.send().getPrefix();

        if (result.statusCode contains "200") {
            writeOutput('{"success":true,"message":"Saved","count":#structCount(existingData)#}');
        } else {
            writeOutput('{"success":false,"error":"Redis SET failed: #result.statusCode#"}');
        }

    } catch (any e) {
        writeOutput('{"success":false,"error":"POST Error: #e.message#"}');
    }
} else {
    writeOutput('{"success":false,"error":"Method not allowed"}');
}
</cfscript>
