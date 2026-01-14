<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GC Gold Futures - Live Chart</title>
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0f;
            color: #e4e4e7;
            height: 100vh;
            overflow: hidden;
        }
        .container {
            display: flex;
            flex-direction: column;
            height: 100vh;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 20px;
            background: #111118;
            border-bottom: 1px solid #1f1f2e;
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .symbol-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .symbol-name {
            font-size: 20px;
            font-weight: 600;
            color: #f4f4f5;
        }
        .symbol-badge {
            background: #22c55e20;
            color: #22c55e;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
        }
        .price-display {
            display: flex;
            align-items: baseline;
            gap: 12px;
        }
        .current-price {
            font-size: 28px;
            font-weight: 700;
            color: #22c55e;
            font-family: 'SF Mono', Monaco, monospace;
        }
        .current-price.down { color: #ef4444; }
        .price-change {
            font-size: 14px;
            color: #22c55e;
        }
        .price-change.down { color: #ef4444; }
        .ohlc-display {
            display: flex;
            gap: 16px;
            font-size: 13px;
            color: #9ca3af;
        }
        .ohlc-item span:first-child {
            color: #6b7280;
            margin-right: 4px;
        }
        .header-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .status {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #6b7280;
        }
        .status-dot.connected { background: #22c55e; }
        .status-dot.error { background: #ef4444; }
        .status-dot.connecting { background: #f59e0b; animation: pulse 1s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        .chart-container {
            flex: 1;
            position: relative;
        }
        #chart {
            width: 100%;
            height: 100%;
        }
        .loading-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: #0a0a0f;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 100;
        }
        .loading-overlay.hidden { display: none; }
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 3px solid #1f1f2e;
            border-top-color: #22c55e;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 16px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .loading-text {
            color: #9ca3af;
            font-size: 14px;
        }
        .bar-count {
            font-size: 12px;
            color: #6b7280;
            margin-left: 12px;
        }
        .time-display {
            border-left: 1px solid #2a2a3a;
            padding-left: 12px;
            margin-left: 4px;
        }
        .time-display span:last-child {
            color: #60a5fa;
            font-family: 'SF Mono', Monaco, monospace;
        }
        .timeframe-selector {
            display: flex;
            gap: 4px;
            background: #1a1a24;
            padding: 4px;
            border-radius: 6px;
        }
        .tf-btn {
            background: transparent;
            border: none;
            color: #6b7280;
            padding: 6px 12px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .tf-btn:hover {
            background: #2a2a3a;
            color: #9ca3af;
        }
        .tf-btn.active {
            background: #22c55e20;
            color: #22c55e;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <div class="symbol-info">
                    <span class="symbol-name">GC Gold Futures</span>
                    <span class="symbol-badge" id="timeframeBadge">1 MIN</span>
                </div>
                <div class="timeframe-selector">
                    <button class="tf-btn active" data-tf="1m" data-label="1 MIN">1m</button>
                    <button class="tf-btn" data-tf="5m" data-label="5 MIN">5m</button>
                    <button class="tf-btn" data-tf="15m" data-label="15 MIN">15m</button>
                    <button class="tf-btn" data-tf="1h" data-label="1 HR">1h</button>
                    <button class="tf-btn" data-tf="4h" data-label="4 HR">4h</button>
                    <button class="tf-btn" data-tf="1d" data-label="1 DAY">1d</button>
                    <button class="tf-btn" data-tf="1w" data-label="1 WK">1w</button>
                </div>
                <div class="price-display">
                    <span class="current-price" id="currentPrice">--</span>
                    <span class="price-change" id="priceChange">--</span>
                </div>
                <div class="ohlc-display">
                    <div class="ohlc-item"><span>O</span><span id="ohlcOpen">--</span></div>
                    <div class="ohlc-item"><span>H</span><span id="ohlcHigh">--</span></div>
                    <div class="ohlc-item"><span>L</span><span id="ohlcLow">--</span></div>
                    <div class="ohlc-item"><span>C</span><span id="ohlcClose">--</span></div>
                    <div class="ohlc-item"><span>V</span><span id="ohlcVol">--</span></div>
                    <div class="ohlc-item time-display"><span>UTC</span><span id="timeUTC">--:--</span></div>
                    <div class="ohlc-item time-display"><span>Local</span><span id="timeLocal">--:--</span></div>
                </div>
            </div>
            <div class="header-right">
                <span class="bar-count" id="barCount">0 bars</span>
                <div class="status">
                    <div class="status-dot connecting" id="statusDot"></div>
                    <span id="statusText">Connecting...</span>
                </div>
            </div>
        </div>
        <div class="chart-container">
            <div id="chart"></div>
            <div class="loading-overlay" id="loadingOverlay">
                <div class="loading-spinner"></div>
                <div class="loading-text">Connecting to live data...</div>
            </div>
        </div>
    </div>

    <script>
        // Configuration
        const SYMBOL = 'GC';  // Bridge maps QGC# -> GC
        let TIMEFRAME = '1m';
        const DECIMALS = 1;
        const DEBUG = true;  // Enable debug logging

        // Redis configuration for historical data
        const UPSTASH_URL = 'https://expert-marlin-11581.upstash.io';
        const UPSTASH_TOKEN = 'AS09AAIncDI0YWZiZTM1ZThiYTA0NzcxYTg4Y2M3YTUwYjM1ZjY3OXAyMTE1ODE';

        // Timeframe minutes mapping
        const TIMEFRAME_MINUTES = {
            '1m': 1,
            '5m': 5,
            '15m': 15,
            '1h': 60,
            '4h': 240,
            '1d': 1440,
            '1w': 10080
        };

        // State
        let ws = null;
        let chart = null;
        let candleSeries = null;
        let volumeSeries = null;
        let candleData = [];  // Array of {time, open, high, low, close, volume}
        let currentPrice = 0;
        let sessionOpen = 0;
        let historicalLoaded = false;

        // Big trade tracking - persistent markers
        const BIG_TRADE_MIN_SIZE = 2;  // Minimum trade size to mark (micro contracts are small)
        let bigTradeMarkers = [];  // Persistent array of big trade markers

        // Initialize chart
        function initChart() {
            const container = document.getElementById('chart');

            chart = LightweightCharts.createChart(container, {
                layout: {
                    background: { type: 'solid', color: '#0a0a0f' },
                    textColor: '#9ca3af',
                },
                grid: {
                    vertLines: { color: '#1a1a24' },
                    horzLines: { color: '#1a1a24' },
                },
                rightPriceScale: {
                    borderColor: '#1f1f2e',
                    scaleMargins: { top: 0.1, bottom: 0.2 },
                },
                timeScale: {
                    borderColor: '#1f1f2e',
                    timeVisible: true,
                    secondsVisible: false,
                    rightOffset: 5,
                    barSpacing: 8,
                    tickMarkFormatter: (time) => {
                        // Time is in UTC seconds
                        const utcDate = new Date(time * 1000);
                        const utcHours = utcDate.getUTCHours().toString().padStart(2, '0');
                        const utcMins = utcDate.getUTCMinutes().toString().padStart(2, '0');
                        return `${utcHours}:${utcMins}`;
                    },
                },
                localization: {
                    timeFormatter: (time) => {
                        // Show both UTC and local time on crosshair
                        const utcDate = new Date(time * 1000);
                        const utcHours = utcDate.getUTCHours().toString().padStart(2, '0');
                        const utcMins = utcDate.getUTCMinutes().toString().padStart(2, '0');
                        const localHours = utcDate.getHours().toString().padStart(2, '0');
                        const localMins = utcDate.getMinutes().toString().padStart(2, '0');
                        return `${utcHours}:${utcMins} UTC | ${localHours}:${localMins} Local`;
                    },
                },
                crosshair: {
                    mode: LightweightCharts.CrosshairMode.Normal,
                    vertLine: { color: '#4b5563', width: 1, style: 2 },
                    horzLine: { color: '#4b5563', width: 1, style: 2 },
                },
            });

            // Candlestick series
            candleSeries = chart.addCandlestickSeries({
                upColor: '#22c55e',
                downColor: '#ef4444',
                borderDownColor: '#ef4444',
                borderUpColor: '#22c55e',
                wickDownColor: '#ef4444',
                wickUpColor: '#22c55e',
            });

            // Volume series
            volumeSeries = chart.addHistogramSeries({
                color: '#22c55e',
                priceFormat: { type: 'volume' },
                priceScaleId: 'volume',
            });

            volumeSeries.priceScale().applyOptions({
                scaleMargins: { top: 0.85, bottom: 0 },
            });

            // Store markers for big orders
            window.mboMarkers = [];

            // Crosshair move handler
            chart.subscribeCrosshairMove(param => {
                if (param.time) {
                    const data = param.seriesData.get(candleSeries);
                    if (data) {
                        updateOHLCDisplay(data);
                    }
                } else if (candleData.length > 0) {
                    updateOHLCDisplay(candleData[candleData.length - 1]);
                }
            });

            // Resize handler
            window.addEventListener('resize', () => {
                chart.applyOptions({
                    width: container.clientWidth,
                    height: container.clientHeight,
                });
            });

            chart.applyOptions({
                width: container.clientWidth,
                height: container.clientHeight,
            });
        }

        // Load historical data from Redis
        async function loadHistoricalFromRedis() {
            const cacheKey = `chart:${SYMBOL}:${TIMEFRAME}:1year`;
            try {
                document.getElementById('loadingOverlay').querySelector('.loading-text').textContent = 'Loading historical data...';

                const response = await fetch(`${UPSTASH_URL}/get/${cacheKey}`, {
                    headers: { 'Authorization': `Bearer ${UPSTASH_TOKEN}` }
                });
                const data = await response.json();

                if (data.result) {
                    const parsed = JSON.parse(data.result);
                    if (parsed.candles && parsed.candles.length > 0) {
                        handleHistoricalCandles(parsed.candles);
                        historicalLoaded = true;
                        return true;
                    }
                }
            } catch (e) {
                // Redis fetch error
            }
            return false;
        }

        // Connect to WebSocket for LIVE updates only
        function connectWebSocket() {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${wsProtocol}//${window.location.host}/ws/iqfeed`;

            updateStatus('connecting', 'Connecting...');

            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                console.log('WebSocket connected');
                updateStatus('connected', 'Live');

                // Always request historical from IQFeed (skip Redis due to CSP)
                console.log('Requesting history for', SYMBOL, TIMEFRAME);
                ws.send(JSON.stringify({
                    type: 'get_history',
                    symbol: SYMBOL,
                    timeframe: TIMEFRAME,
                    bars: 10000
                }));
            };

            let msgCount = 0;
            let gcCount = 0;

            ws.onmessage = function(event) {
                try {
                    const msg = JSON.parse(event.data);
                    msgCount++;

                    // Log every 100th message to see what's coming
                    if (msgCount <= 5 || msgCount % 100 === 0) {
                        console.log(`Msg #${msgCount}:`, msg.type, msg.symbol || '');
                    }

                    // Count GC messages
                    if (msg.symbol === SYMBOL) {
                        gcCount++;
                        if (gcCount <= 5) {
                            console.log(`${SYMBOL} #${gcCount}:`, msg.type, msg.type === 'tick' ? msg.price : msg.data?.close);
                        }
                    }

                    handleMessage(msg);
                } catch (e) {
                    console.error('Parse error:', e);
                }
            };

            ws.onerror = function(err) {
                updateStatus('error', 'Connection error');
            };

            ws.onclose = function() {
                updateStatus('connecting', 'Reconnecting...');
                setTimeout(connectWebSocket, 3000);
            };
        }

        // Handle incoming messages
        function handleMessage(msg) {
            switch (msg.type) {
                case 'status':
                    updateStatus(msg.connected ? 'connected' : 'connecting', msg.message || 'Connected');
                    break;

                case 'historical_candles':
                    console.log('Received historical:', msg.symbol, msg.timeframe, msg.candles?.length, 'candles');
                    if (msg.symbol === SYMBOL && msg.timeframe === TIMEFRAME) {
                        handleHistoricalCandles(msg.candles);
                    }
                    break;

                case 'candle':
                    if (msg.symbol === SYMBOL && msg.timeframe === TIMEFRAME) {
                        handleLiveCandle(msg.data);
                    }
                    break;

                case 'tick':
                    if (msg.symbol === SYMBOL) {
                        handleTick(msg.price, msg.size);
                    }
                    break;

                case 'orderbook':
                    if (msg.symbol === SYMBOL) {
                        handleOrderbook(msg.data);
                    }
                    break;

                case 'market_closed':
                    updateStatus('connected', 'Market Closed');
                    break;
            }
        }

        // Handle historical candles - RAW DATA, NO FILTERING
        function handleHistoricalCandles(candles) {
            if (!candles || candles.length === 0) {
                return;
            }

            // Convert and deduplicate candles - NO FILTERING, use raw data
            const candleMap = new Map();

            candles.forEach(c => {
                // Databento sends time in milliseconds, Lightweight Charts needs seconds
                const timeSeconds = Math.floor(c.time / 1000);
                const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                const candleMinute = Math.floor(timeSeconds / intervalSeconds) * intervalSeconds;

                // If candle already exists for this minute, merge the data
                if (candleMap.has(candleMinute)) {
                    const existing = candleMap.get(candleMinute);
                    candleMap.set(candleMinute, {
                        time: candleMinute,
                        open: existing.open,  // Keep first open
                        high: Math.max(existing.high, c.high),
                        low: Math.min(existing.low, c.low),
                        close: c.close,  // Use latest close
                        volume: (existing.volume || 0) + (c.volume || 0)
                    });
                } else {
                    candleMap.set(candleMinute, {
                        time: candleMinute,
                        open: c.open,
                        high: c.high,
                        low: c.low,
                        close: c.close,
                        volume: c.volume || 0
                    });
                }
            });

            // Convert to sorted array - NO continuity enforcement, show real gaps
            candleData = Array.from(candleMap.values()).sort((a, b) => a.time - b.time);

            // Set data on chart
            candleSeries.setData(candleData);
            volumeSeries.setData(candleData.map(c => ({
                time: c.time,
                value: c.volume,
                color: c.close >= c.open ? '#22c55e40' : '#ef444440'
            })));

            // Update displays
            if (candleData.length > 0) {
                const lastCandle = candleData[candleData.length - 1];
                currentPrice = lastCandle.close;
                sessionOpen = candleData[0].open;

                updatePriceDisplay(currentPrice);
                updateOHLCDisplay(lastCandle);
                updateBarCount();
            }

            // Hide loading overlay
            document.getElementById('loadingOverlay').classList.add('hidden');

            // Fit content and scroll to end
            chart.timeScale().fitContent();
        }

        // Handle live candle update - RAW DATA, NO FILTERING
        let liveUpdateCount = 0;
        function handleLiveCandle(candle) {
            if (!candle) return;

            // Convert time from milliseconds to seconds, floor to timeframe boundary
            const timeSeconds = Math.floor(candle.time / 1000);
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const candleMinute = Math.floor(timeSeconds / intervalSeconds) * intervalSeconds;

            // Find if this candle exists
            const existingIndex = candleData.findIndex(c => c.time === candleMinute);
            const lastCandleTime = candleData.length > 0 ? candleData[candleData.length - 1].time : 0;

            // Debug: log first few updates
            liveUpdateCount++;
            if (liveUpdateCount <= 5) {
                console.log('LiveCandle:', {
                    rawTime: candle.time,
                    candleMinute,
                    lastCandleTime,
                    existingIndex,
                    close: candle.close
                });
            }

            let updatedCandle;

            if (existingIndex >= 0) {
                // Update existing candle - keep original open, merge high/low
                const existing = candleData[existingIndex];
                updatedCandle = {
                    time: candleMinute,
                    open: existing.open,
                    high: Math.max(existing.high, candle.high),
                    low: Math.min(existing.low, candle.low),
                    close: candle.close,
                    volume: candle.volume || 0
                };
                candleData[existingIndex] = updatedCandle;

                if (candleMinute >= lastCandleTime) {
                    candleSeries.update(updatedCandle);
                    volumeSeries.update({
                        time: candleMinute,
                        value: updatedCandle.volume,
                        color: updatedCandle.close >= updatedCandle.open ? '#22c55e40' : '#ef444440'
                    });
                }
            } else if (candleMinute > lastCandleTime) {
                // New candle - use actual open from data, no continuity enforcement
                updatedCandle = {
                    time: candleMinute,
                    open: candle.open,
                    high: candle.high,
                    low: candle.low,
                    close: candle.close,
                    volume: candle.volume || 0
                };
                candleData.push(updatedCandle);
                updateBarCount();

                candleSeries.update(updatedCandle);
                volumeSeries.update({
                    time: candleMinute,
                    value: updatedCandle.volume,
                    color: updatedCandle.close >= updatedCandle.open ? '#22c55e40' : '#ef444440'
                });
            } else {
                return;
            }

            currentPrice = updatedCandle.close;
            updatePriceDisplay(currentPrice);
            updateOHLCDisplay(updatedCandle);
        }

        // Handle tick data - RAW DATA, NO FILTERING
        function handleTick(price, size) {
            if (!price) return;

            currentPrice = price;
            updatePriceDisplay(price);

            // Track big trades - add persistent marker
            if (size >= BIG_TRADE_MIN_SIZE && candleData.length > 0) {
                const nowSeconds = Math.floor(Date.now() / 1000);
                const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                const candleTime = Math.floor(nowSeconds / intervalSeconds) * intervalSeconds;

                // Determine if this looks like a buy or sell based on price vs last candle
                const lastCandle = candleData[candleData.length - 1];
                const isBuy = price >= lastCandle.close;

                bigTradeMarkers.push({
                    time: candleTime,
                    position: isBuy ? 'belowBar' : 'aboveBar',
                    color: isBuy ? '#22c55e' : '#ef4444',
                    shape: 'circle',
                    size: Math.min(3, Math.ceil(size / 3)),
                    text: `${size}@${price.toFixed(1)}`
                });

                // Limit markers to last 100 to avoid memory issues
                if (bigTradeMarkers.length > 100) {
                    bigTradeMarkers = bigTradeMarkers.slice(-100);
                }

                // Update chart markers
                candleSeries.setMarkers(bigTradeMarkers);
                console.log(`Big trade: ${size}@${price} (${isBuy ? 'BUY' : 'SELL'})`);
            }

            // Get current timeframe boundary (in seconds)
            const nowSeconds = Math.floor(Date.now() / 1000);
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const currentMinute = Math.floor(nowSeconds / intervalSeconds) * intervalSeconds;

            if (candleData.length > 0) {
                const lastCandle = candleData[candleData.length - 1];

                if (lastCandle.time === currentMinute) {
                    // Update existing candle
                    lastCandle.close = price;
                    lastCandle.high = Math.max(lastCandle.high, price);
                    lastCandle.low = Math.min(lastCandle.low, price);
                    lastCandle.volume += (size || 1);

                    candleSeries.update(lastCandle);
                    volumeSeries.update({
                        time: lastCandle.time,
                        value: lastCandle.volume,
                        color: lastCandle.close >= lastCandle.open ? '#22c55e40' : '#ef444440'
                    });

                    updateOHLCDisplay(lastCandle);
                } else if (currentMinute > lastCandle.time) {
                    // New candle - use price as open (no continuity enforcement)
                    const newCandle = {
                        time: currentMinute,
                        open: price,
                        high: price,
                        low: price,
                        close: price,
                        volume: size || 1
                    };

                    candleData.push(newCandle);
                    updateBarCount();

                    candleSeries.update(newCandle);
                    volumeSeries.update({
                        time: currentMinute,
                        value: newCandle.volume,
                        color: '#22c55e40'
                    });

                    updateOHLCDisplay(newCandle);
                }
            }
        }

        // Handle orderbook data - track and aggregate big MBO orders per candle
        let seenBigOrders = new Set();  // Track individual orders we've counted
        let aggregatedOrders = new Map();  // Key: "time_side" -> {count, totalSize, avgPrice}

        function handleOrderbook(data) {
            if (!data) return;

            // Use mid price if no recent tick
            const mid = (data.best_bid + data.best_ask) / 2;
            if (mid > 0 && currentPrice === 0) {
                currentPrice = mid;
                updatePriceDisplay(mid);
            }

            if (candleData.length === 0) return;

            const nowSeconds = Math.floor(Date.now() / 1000);
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const candleTime = Math.floor(nowSeconds / intervalSeconds) * intervalSeconds;

            let markersUpdated = false;

            // Check for big bid orders (green - buy side)
            if (data.bids && data.bids.length > 0) {
                data.bids
                    .filter(b => b[1] >= BIG_TRADE_MIN_SIZE)
                    .forEach(b => {
                        const orderKey = `B_${b[0]}_${b[1]}`;
                        if (!seenBigOrders.has(orderKey)) {
                            seenBigOrders.add(orderKey);

                            // Aggregate by candle time + side
                            const aggKey = `${candleTime}_BID`;
                            const existing = aggregatedOrders.get(aggKey) || { count: 0, totalSize: 0, priceSum: 0 };
                            existing.count += 1;
                            existing.totalSize += b[1];
                            existing.priceSum += b[0] * b[1];  // Weighted by size
                            aggregatedOrders.set(aggKey, existing);

                            console.log(`Big BID: ${b[1]}@${b[0].toFixed(1)} (total: ${existing.count} orders, ${existing.totalSize} contracts)`);
                            markersUpdated = true;
                        }
                    });
            }

            // Check for big ask orders (red - sell side)
            if (data.asks && data.asks.length > 0) {
                data.asks
                    .filter(a => a[1] >= BIG_TRADE_MIN_SIZE)
                    .forEach(a => {
                        const orderKey = `A_${a[0]}_${a[1]}`;
                        if (!seenBigOrders.has(orderKey)) {
                            seenBigOrders.add(orderKey);

                            // Aggregate by candle time + side
                            const aggKey = `${candleTime}_ASK`;
                            const existing = aggregatedOrders.get(aggKey) || { count: 0, totalSize: 0, priceSum: 0 };
                            existing.count += 1;
                            existing.totalSize += a[1];
                            existing.priceSum += a[0] * a[1];  // Weighted by size
                            aggregatedOrders.set(aggKey, existing);

                            console.log(`Big ASK: ${a[1]}@${a[0].toFixed(1)} (total: ${existing.count} orders, ${existing.totalSize} contracts)`);
                            markersUpdated = true;
                        }
                    });
            }

            // Rebuild markers from aggregated data when there are updates
            if (markersUpdated) {
                bigTradeMarkers = [];

                aggregatedOrders.forEach((agg, key) => {
                    const [time, side] = key.split('_');
                    const candleTimeNum = parseInt(time);
                    const avgPrice = agg.priceSum / agg.totalSize;

                    // Ball size scales with total contracts (1-3)
                    const ballSize = Math.min(3, Math.max(1, Math.ceil(agg.totalSize / 5)));

                    bigTradeMarkers.push({
                        time: candleTimeNum,
                        position: side === 'BID' ? 'belowBar' : 'aboveBar',
                        color: side === 'BID' ? '#22c55e' : '#ef4444',
                        shape: 'circle',
                        size: ballSize,
                        text: `${agg.count}x ${agg.totalSize}@${avgPrice.toFixed(1)}`
                    });
                });

                // Sort markers by time
                bigTradeMarkers.sort((a, b) => a.time - b.time);

                // Limit to last 100 candles worth of markers
                if (bigTradeMarkers.length > 100) {
                    bigTradeMarkers = bigTradeMarkers.slice(-100);
                }

                // Update chart with aggregated markers
                candleSeries.setMarkers(bigTradeMarkers);
            }
        }

        // Update price display
        function updatePriceDisplay(price) {
            const priceEl = document.getElementById('currentPrice');
            const changeEl = document.getElementById('priceChange');

            priceEl.textContent = price.toFixed(DECIMALS);

            if (sessionOpen > 0) {
                const change = price - sessionOpen;
                const changePct = (change / sessionOpen) * 100;
                const sign = change >= 0 ? '+' : '';

                changeEl.textContent = `${sign}${change.toFixed(DECIMALS)} (${sign}${changePct.toFixed(2)}%)`;
                changeEl.className = 'price-change' + (change < 0 ? ' down' : '');
                priceEl.className = 'current-price' + (change < 0 ? ' down' : '');
            }
        }

        // Update OHLC display
        function updateOHLCDisplay(candle) {
            if (!candle) return;

            document.getElementById('ohlcOpen').textContent = candle.open.toFixed(DECIMALS);
            document.getElementById('ohlcHigh').textContent = candle.high.toFixed(DECIMALS);
            document.getElementById('ohlcLow').textContent = candle.low.toFixed(DECIMALS);
            document.getElementById('ohlcClose').textContent = candle.close.toFixed(DECIMALS);
            document.getElementById('ohlcVol').textContent = (candle.volume || 0).toLocaleString();

            // Update time displays (candle.time is in UTC seconds)
            if (candle.time) {
                const utcDate = new Date(candle.time * 1000);
                const utcHours = utcDate.getUTCHours().toString().padStart(2, '0');
                const utcMins = utcDate.getUTCMinutes().toString().padStart(2, '0');
                const localHours = utcDate.getHours().toString().padStart(2, '0');
                const localMins = utcDate.getMinutes().toString().padStart(2, '0');

                document.getElementById('timeUTC').textContent = `${utcHours}:${utcMins}`;
                document.getElementById('timeLocal').textContent = `${localHours}:${localMins}`;
            }
        }

        // Update status indicator
        function updateStatus(status, text) {
            const dot = document.getElementById('statusDot');
            const textEl = document.getElementById('statusText');

            dot.className = 'status-dot ' + status;
            textEl.textContent = text;
        }

        // Update bar count
        function updateBarCount() {
            document.getElementById('barCount').textContent = `${candleData.length} bars`;
        }

        // Switch timeframe
        async function switchTimeframe(newTimeframe, label) {
            if (newTimeframe === TIMEFRAME) return;

            TIMEFRAME = newTimeframe;
            historicalLoaded = false;

            // Update UI
            document.getElementById('timeframeBadge').textContent = label;
            document.querySelectorAll('.tf-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tf === newTimeframe);
            });

            // Clear existing data
            candleData = [];
            currentPrice = 0;
            sessionOpen = 0;

            // Clear chart
            candleSeries.setData([]);
            volumeSeries.setData([]);

            // Show loading
            document.getElementById('loadingOverlay').classList.remove('hidden');
            document.getElementById('barCount').textContent = '0 bars';

            // Reset OHLC display
            document.getElementById('ohlcOpen').textContent = '--';
            document.getElementById('ohlcHigh').textContent = '--';
            document.getElementById('ohlcLow').textContent = '--';
            document.getElementById('ohlcClose').textContent = '--';
            document.getElementById('ohlcVol').textContent = '--';
            document.getElementById('timeUTC').textContent = '--:--';
            document.getElementById('timeLocal').textContent = '--:--';

            // Try Redis first, fallback to WebSocket
            const loaded = await loadHistoricalFromRedis();
            if (!loaded && ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'get_history',
                    symbol: SYMBOL,
                    timeframe: TIMEFRAME,
                    bars: 10000
                }));
            }
        }

        // Initialize timeframe buttons
        function initTimeframeButtons() {
            document.querySelectorAll('.tf-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                    switchTimeframe(btn.dataset.tf, btn.dataset.label);
                });
            });
        }

        // Initialize on page load
        document.addEventListener('DOMContentLoaded', async function() {
            initChart();
            initTimeframeButtons();

            // Load historical data from Redis first
            await loadHistoricalFromRedis();

            // Then connect WebSocket for live updates
            connectWebSocket();
        });
    </script>
</body>
</html>
