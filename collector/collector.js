/**
 * OrderFlow Delta & Big Order Collector
 *
 * Background service that connects to IQFeed WebSocket bridge and continuously
 * tracks delta and big orders, saving them to the database.
 *
 * Run: node collector.js
 * Or with PM2: pm2 start collector.js --name orderflow-collector
 */

const WebSocket = require('ws');
const sql = require('mssql');

// Configuration
const CONFIG = {
    wsUrl: 'ws://localhost:9010',  // IQFeed bridge WebSocket
    symbols: ['GC'],  // Symbols to track (add more: 'SI', 'CL', 'ES', 'NQ')
    bigOrderThreshold: 20,  // Minimum size for big order
    saveInterval: 5000,  // Save to DB every 5 seconds
    reconnectDelay: 5000,  // Reconnect delay on disconnect
    runDuration: 13 * 60 * 60 * 1000,  // 13 hours in milliseconds
};

// Database configuration (same as config.cfm)
const dbConfig = {
    server: process.env.OF_DB_SERVER || 'localhost',
    port: parseInt(process.env.OF_DB_PORT || '1433'),
    database: process.env.OF_DB_NAME || 'orderflow_signals',
    user: process.env.OF_DB_USER || 'sa',
    password: process.env.OF_DB_PASS || 'Sql@07072.',
    options: {
        encrypt: false,
        trustServerCertificate: true,
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

// Data storage
const deltaData = new Map();  // symbol -> Map(1mTimestamp -> deltaRecord)
const bigOrders = new Map();  // symbol -> Array of big orders
const orderflow = new Map();  // symbol -> Map(1mTimestamp -> {buyVolume, sellVolume})
const priceVolume = new Map();  // symbol -> Map(priceKey -> volume)
const seenBigOrders = new Set();  // Deduplication

let ws = null;
let dbPool = null;
let startTime = Date.now();
let isShuttingDown = false;

// Initialize database connection
async function initDatabase() {
    try {
        dbPool = await sql.connect(dbConfig);
        console.log('[DB] Connected to database');
        return true;
    } catch (err) {
        console.error('[DB] Connection failed:', err.message);
        return false;
    }
}

// Save delta data to database
async function saveDeltaToDb(symbol, timestamp, data) {
    if (!dbPool) return false;

    try {
        await dbPool.request()
            .input('symbol', sql.VarChar(20), symbol)
            .input('timeframe', sql.VarChar(10), '1m')
            .input('candle_time', sql.BigInt, timestamp)
            .input('delta', sql.Int, data.delta || 0)
            .input('max_delta', sql.Int, data.maxDelta || 0)
            .input('min_delta', sql.Int, data.minDelta || 0)
            .input('volume', sql.Int, data.volume || 0)
            .input('buy_volume', sql.Int, data.buyVolume || 0)
            .input('sell_volume', sql.Int, data.sellVolume || 0)
            .input('is_estimated', sql.Bit, 0)
            .execute('usp_upsert_delta_data');
        return true;
    } catch (err) {
        console.error('[DB] Save delta error:', err.message);
        return false;
    }
}

// Save big order to database
async function saveBigOrderToDb(symbol, order) {
    if (!dbPool) return false;

    try {
        await dbPool.request()
            .input('symbol', sql.VarChar(20), symbol)
            .input('timeframe', sql.VarChar(10), '1m')
            .input('candle_time', sql.BigInt, order.time)
            .input('price', sql.Decimal(18, 4), order.price)
            .input('size', sql.Int, order.size)
            .input('side', sql.VarChar(4), order.side)
            .execute('usp_upsert_big_order');
        return true;
    } catch (err) {
        console.error('[DB] Save big order error:', err.message);
        return false;
    }
}

// Process periodic save
async function periodicSave() {
    if (isShuttingDown) return;

    let deltaSaved = 0;
    let ordersSaved = 0;

    // Save delta data for each symbol
    for (const [symbol, symbolDelta] of deltaData) {
        for (const [timestamp, data] of symbolDelta) {
            if (await saveDeltaToDb(symbol, timestamp, data)) {
                deltaSaved++;
            }
        }
    }

    // Save big orders for each symbol
    for (const [symbol, orders] of bigOrders) {
        for (const order of orders) {
            if (await saveBigOrderToDb(symbol, order)) {
                ordersSaved++;
            }
        }
        // Clear saved orders (they're now in DB)
        bigOrders.set(symbol, []);
    }

    if (deltaSaved > 0 || ordersSaved > 0) {
        console.log(`[SAVE] Saved ${deltaSaved} delta records, ${ordersSaved} big orders`);
    }
}

// Get 1-minute bucket timestamp
function get1mBucket(timestamp) {
    return Math.floor(timestamp / 60) * 60;
}

// Process trade message
function processTrade(symbol, price, size, bid, ask) {
    if (size <= 0) return;

    const nowSeconds = Math.floor(Date.now() / 1000);
    const bucket1m = get1mBucket(nowSeconds);

    // Initialize maps for this symbol
    if (!orderflow.has(symbol)) {
        orderflow.set(symbol, new Map());
        deltaData.set(symbol, new Map());
        bigOrders.set(symbol, []);
        priceVolume.set(symbol, new Map());
    }

    const symbolFlow = orderflow.get(symbol);
    const symbolDelta = deltaData.get(symbol);
    const symbolPriceVol = priceVolume.get(symbol);
    const symbolBigOrders = bigOrders.get(symbol);

    // Initialize bucket if needed
    if (!symbolFlow.has(bucket1m)) {
        symbolFlow.set(bucket1m, { buyVolume: 0, sellVolume: 0 });
    }

    const flow = symbolFlow.get(bucket1m);

    // Classify trade as buy or sell
    let isBuy = false;
    if (ask > 0 && price >= ask) {
        flow.buyVolume += size;
        isBuy = true;
    } else if (bid > 0 && price <= bid) {
        flow.sellVolume += size;
    } else if (bid > 0 && ask > 0) {
        const midpoint = (bid + ask) / 2;
        if (price >= midpoint) {
            flow.buyVolume += size;
            isBuy = true;
        } else {
            flow.sellVolume += size;
        }
    } else {
        // Fallback - assume buy if no bid/ask context
        flow.buyVolume += size;
        isBuy = true;
    }

    // Update delta for this bucket
    const delta = flow.buyVolume - flow.sellVolume;
    let deltaRecord = symbolDelta.get(bucket1m);
    if (!deltaRecord) {
        deltaRecord = {
            delta: delta,
            maxDelta: delta,
            minDelta: delta,
            volume: size,
            buyVolume: flow.buyVolume,
            sellVolume: flow.sellVolume
        };
    } else {
        deltaRecord.delta = delta;
        deltaRecord.maxDelta = Math.max(deltaRecord.maxDelta, delta);
        deltaRecord.minDelta = Math.min(deltaRecord.minDelta, delta);
        deltaRecord.volume += size;
        deltaRecord.buyVolume = flow.buyVolume;
        deltaRecord.sellVolume = flow.sellVolume;
    }
    symbolDelta.set(bucket1m, deltaRecord);

    // Track big orders (cumulative volume at price level)
    const priceKey = `${bucket1m}_${price.toFixed(1)}_${isBuy ? 'B' : 'S'}`;
    const prevVolume = symbolPriceVol.get(priceKey) || 0;
    const newVolume = prevVolume + size;
    symbolPriceVol.set(priceKey, newVolume);

    // Check if this price level crossed the big order threshold
    if (newVolume >= CONFIG.bigOrderThreshold && prevVolume < CONFIG.bigOrderThreshold) {
        const orderKey = `${symbol}_${priceKey}`;
        if (!seenBigOrders.has(orderKey)) {
            seenBigOrders.add(orderKey);
            symbolBigOrders.push({
                time: bucket1m,
                price: price,
                size: newVolume,
                side: isBuy ? 'BUY' : 'SELL'
            });
            console.log(`[BIG ORDER] ${symbol} ${isBuy ? 'BUY' : 'SELL'} ${newVolume}@${price.toFixed(2)}`);
        }
    }
}

// Connect to IQFeed WebSocket bridge
function connectWebSocket() {
    if (isShuttingDown) return;

    console.log(`[WS] Connecting to ${CONFIG.wsUrl}...`);

    ws = new WebSocket(CONFIG.wsUrl);

    ws.on('open', () => {
        console.log('[WS] Connected to IQFeed bridge');

        // Subscribe to each symbol
        CONFIG.symbols.forEach(symbol => {
            ws.send(JSON.stringify({
                type: 'subscribe',
                symbol: symbol
            }));
            console.log(`[WS] Subscribed to ${symbol}`);
        });
    });

    ws.on('message', (data) => {
        try {
            const msg = JSON.parse(data.toString());

            // Process tick messages (trades)
            if (msg.type === 'tick' && msg.price && msg.size) {
                processTrade(
                    msg.symbol || CONFIG.symbols[0],
                    parseFloat(msg.price),
                    parseInt(msg.size),
                    parseFloat(msg.bid || 0),
                    parseFloat(msg.ask || 0)
                );
            }
        } catch (err) {
            // Ignore parse errors
        }
    });

    ws.on('close', () => {
        console.log('[WS] Disconnected');
        if (!isShuttingDown) {
            console.log(`[WS] Reconnecting in ${CONFIG.reconnectDelay / 1000}s...`);
            setTimeout(connectWebSocket, CONFIG.reconnectDelay);
        }
    });

    ws.on('error', (err) => {
        console.error('[WS] Error:', err.message);
    });
}

// Cleanup old data (keep only last 24 hours)
function cleanupOldData() {
    const cutoff = Math.floor(Date.now() / 1000) - (24 * 60 * 60);

    for (const [symbol, symbolDelta] of deltaData) {
        for (const [timestamp, _] of symbolDelta) {
            if (timestamp < cutoff) {
                symbolDelta.delete(timestamp);
            }
        }
    }

    for (const [symbol, symbolFlow] of orderflow) {
        for (const [timestamp, _] of symbolFlow) {
            if (timestamp < cutoff) {
                symbolFlow.delete(timestamp);
            }
        }
    }

    // Clear old price volume tracking
    for (const [symbol, symbolPriceVol] of priceVolume) {
        for (const [key, _] of symbolPriceVol) {
            const timestamp = parseInt(key.split('_')[0]);
            if (timestamp < cutoff) {
                symbolPriceVol.delete(key);
            }
        }
    }

    console.log('[CLEANUP] Removed data older than 24 hours');
}

// Graceful shutdown
async function shutdown() {
    console.log('\n[SHUTDOWN] Shutting down...');
    isShuttingDown = true;

    // Final save
    await periodicSave();

    // Close connections
    if (ws) {
        ws.close();
    }
    if (dbPool) {
        await dbPool.close();
    }

    console.log('[SHUTDOWN] Complete');
    process.exit(0);
}

// Main entry point
async function main() {
    console.log('========================================');
    console.log('  OrderFlow Delta & Big Order Collector');
    console.log('========================================');
    console.log(`Symbols: ${CONFIG.symbols.join(', ')}`);
    console.log(`Big order threshold: ${CONFIG.bigOrderThreshold}`);
    console.log(`Save interval: ${CONFIG.saveInterval / 1000}s`);
    console.log(`Run duration: ${CONFIG.runDuration / (60 * 60 * 1000)} hours`);
    console.log('----------------------------------------');

    // Initialize database
    const dbConnected = await initDatabase();
    if (!dbConnected) {
        console.error('[ERROR] Cannot start without database connection');
        process.exit(1);
    }

    // Connect to WebSocket
    connectWebSocket();

    // Start periodic save
    setInterval(periodicSave, CONFIG.saveInterval);

    // Cleanup old data every hour
    setInterval(cleanupOldData, 60 * 60 * 1000);

    // Auto-shutdown after configured duration
    setTimeout(() => {
        console.log('[TIMER] Run duration reached, shutting down...');
        shutdown();
    }, CONFIG.runDuration);

    // Handle graceful shutdown
    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);

    console.log('[COLLECTOR] Running... Press Ctrl+C to stop');
}

// Start the collector
main().catch(err => {
    console.error('[FATAL]', err);
    process.exit(1);
});
