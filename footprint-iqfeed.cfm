<!--- Footprint Chart Module - Candle footprint visualization using IQFeed Level1/Level2/MBO Data --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Footprint Chart - IQFeed Data</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html, body {
            height: 100%;
            overflow: hidden;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0a0f;
            color: #e5e7eb;
        }

        .header {
            padding: 16px 24px;
            border-bottom: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
            background: #12121a;
        }
        .header h2 {
            font-size: 20px;
            font-weight: 600;
            color: #fff;
            margin: 0;
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .header-right {
            display: flex;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
        }
        .status-indicator {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            color: #9ca3af;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #6b7280;
        }
        .status-dot.connected { background: #10b981; box-shadow: 0 0 8px rgba(16, 185, 129, 0.5); }
        .status-dot.error { background: #ef4444; }

        /* Feed indicators */
        .feed-indicators {
            display: flex;
            gap: 12px;
            font-size: 11px;
        }
        .feed-indicator {
            display: flex;
            align-items: center;
            gap: 4px;
            padding: 4px 8px;
            background: #1a1a24;
            border-radius: 4px;
        }
        .feed-indicator .dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: #6b7280;
        }
        .feed-indicator.active .dot {
            background: #10b981;
            box-shadow: 0 0 6px rgba(16, 185, 129, 0.5);
        }

        .controls {
            display: flex;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
        }
        .controls label {
            font-size: 12px;
            color: #9ca3af;
        }
        .controls select {
            background: #1a1a24;
            border: 1px solid #2a2a3d;
            border-radius: 6px;
            color: #fff;
            padding: 6px 12px;
            font-size: 12px;
            cursor: pointer;
        }
        .controls select:focus {
            outline: none;
            border-color: #7c3aed;
        }

        .content {
            height: calc(100vh - 70px);
            display: flex;
            flex-direction: column;
        }

        /* Chart Container */
        .chart-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: #0d0d14;
            overflow: hidden;
            position: relative;
        }

        /* Canvas container */
        .canvas-container {
            position: relative;
            flex: 1;
            min-height: 0;
        }
        #footprintCanvas {
            position: absolute;
            left: 0;
            top: 0;
        }

        /* Price axis */
        .price-axis {
            position: absolute;
            right: 0;
            top: 0;
            bottom: 30px;
            width: 80px;
            background: #12121a;
            border-left: 1px solid #1a1a24;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 10px 8px;
            font-size: 11px;
            font-family: 'Consolas', monospace;
            color: #9ca3af;
            z-index: 20;
        }
        .price-axis .price-label {
            text-align: right;
        }
        .price-axis .current-price {
            color: #f59e0b;
            font-weight: 600;
        }

        /* Time axis */
        .time-axis {
            height: 30px;
            background: #12121a;
            border-top: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            padding: 8px 90px 8px 20px;
            font-size: 10px;
            color: #6b7280;
        }

        /* Stats bar */
        .stats-bar {
            padding: 12px 20px;
            background: #12121a;
            border-top: 1px solid #1a1a24;
            display: flex;
            justify-content: space-around;
            font-size: 12px;
            flex-wrap: wrap;
            gap: 16px;
        }
        .stat-item {
            text-align: center;
        }
        .stat-item .stat-label {
            color: #6b7280;
            font-size: 10px;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        .stat-item .stat-value {
            font-weight: 600;
            font-family: 'Consolas', monospace;
        }
        .stat-item .stat-value.positive { color: #22c55e; }
        .stat-item .stat-value.negative { color: #ef4444; }
        .stat-item .stat-value.neutral { color: #fff; }

        /* Legend */
        .chart-legend {
            padding: 10px 20px;
            background: #0a0a0f;
            border-top: 1px solid #1a1a24;
            display: flex;
            justify-content: center;
            gap: 24px;
            font-size: 11px;
            flex-wrap: wrap;
        }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .legend-color {
            width: 20px;
            height: 12px;
            border-radius: 2px;
        }
        .legend-color.bid { background: #22c55e; }
        .legend-color.ask { background: #ef4444; }
        .legend-color.delta-pos { background: linear-gradient(90deg, #1a1a24, #22c55e); }
        .legend-color.delta-neg { background: linear-gradient(90deg, #1a1a24, #ef4444); }
        .legend-color.imbalance { background: #f59e0b; }

        /* Crosshair */
        #crosshairX {
            display: none;
            position: absolute;
            top: 0;
            bottom: 30px;
            width: 1px;
            background: rgba(245, 158, 11, 0.5);
            pointer-events: none;
            z-index: 30;
        }
        #crosshairY {
            display: none;
            position: absolute;
            left: 0;
            right: 80px;
            height: 1px;
            background: rgba(245, 158, 11, 0.5);
            pointer-events: none;
            z-index: 30;
        }
        #crosshairPrice {
            position: absolute;
            right: -75px;
            top: -8px;
            background: #f59e0b;
            color: #000;
            font-size: 10px;
            font-weight: bold;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: Consolas, monospace;
        }

        /* Tooltip */
        #chartTooltip {
            display: none;
            position: absolute;
            background: rgba(0,0,0,0.95);
            border: 1px solid #7c3aed;
            border-radius: 8px;
            padding: 12px 16px;
            font-size: 12px;
            font-family: Consolas, monospace;
            pointer-events: none;
            z-index: 100;
            min-width: 200px;
        }
        #chartTooltip .tooltip-header {
            font-size: 14px;
            font-weight: 600;
            color: #fff;
            margin-bottom: 8px;
            padding-bottom: 8px;
            border-bottom: 1px solid #2a2a3d;
        }
        #chartTooltip .tooltip-row {
            display: flex;
            justify-content: space-between;
            margin: 4px 0;
        }
        #chartTooltip .tooltip-row .label {
            color: #9ca3af;
        }

        /* Back link */
        .back-link {
            color: #9ca3af;
            text-decoration: none;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .back-link:hover {
            color: #fff;
        }

        /* Loading overlay */
        .loading-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(13, 13, 20, 0.9);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 100;
        }
        .loading-overlay.hidden {
            display: none;
        }
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        @media (max-width: 768px) {
            .canvas-container { min-height: 400px; }
            .header { padding: 12px 16px; }
            .controls { flex-wrap: wrap; }
        }
    </style>
</head>
<body>
    <header class="header">
        <div class="header-left">
            <a href="chart-today2.cfm" class="back-link">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                Back to Chart
            </a>
            <h2>Footprint Chart</h2>
            <div class="status-indicator">
                <span class="status-dot" id="statusDot"></span>
                <span id="statusText">Connecting...</span>
            </div>
            <div class="feed-indicators">
                <div class="feed-indicator" id="feedL1">
                    <span class="dot"></span>
                    <span>Level 1</span>
                </div>
                <div class="feed-indicator" id="feedDelta">
                    <span class="dot"></span>
                    <span>Delta</span>
                </div>
            </div>
        </div>
        <div class="header-right">
            <div class="controls">
                <label>Symbol:</label>
                <select id="symbolSelect" onchange="changeSymbol(this.value)">
                    <option value="@ESH25" selected>ES (S&P 500)</option>
                    <option value="@NQH25">NQ (Nasdaq 100)</option>
                    <option value="QGC#">GC (Gold)</option>
                </select>
                <label>Timeframe:</label>
                <select id="timeframeSelect" onchange="changeTimeframe(this.value)">
                    <option value="1m">1 Minute</option>
                    <option value="5m" selected>5 Minutes</option>
                    <option value="15m">15 Minutes</option>
                    <option value="1h">1 Hour</option>
                </select>
                <label>Bars:</label>
                <select id="barsSelect" onchange="setBars(this.value)">
                    <option value="20">20</option>
                    <option value="30" selected>30</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
            </div>
        </div>
    </header>

    <div class="content">
        <div class="chart-container">
            <div class="canvas-container">
                <!-- Loading overlay -->
                <div class="loading-overlay" id="loadingOverlay">
                    <div style="width: 40px; height: 40px; border: 3px solid #2a2a3d; border-top-color: #7c3aed; border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: 16px;"></div>
                    <div style="color: #9ca3af; font-size: 14px;">Loading footprint data...</div>
                </div>

                <!-- Main Chart Canvas -->
                <canvas id="footprintCanvas"></canvas>

                <!-- Price Axis -->
                <div class="price-axis" id="priceAxis">
                    <!-- Price labels will be generated -->
                </div>

                <!-- Crosshairs -->
                <div id="crosshairX"></div>
                <div id="crosshairY">
                    <div id="crosshairPrice"></div>
                </div>

                <!-- Tooltip -->
                <div id="chartTooltip">
                    <div class="tooltip-header" id="tooltipHeader"></div>
                    <div class="tooltip-content" id="tooltipContent"></div>
                </div>
            </div>

            <div class="time-axis" id="timeAxis">
                <!-- Time labels will be generated -->
            </div>

            <!-- Stats -->
            <div class="stats-bar">
                <div class="stat-item">
                    <div class="stat-label">Last Price</div>
                    <div class="stat-value neutral" id="lastPrice">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Session Delta</div>
                    <div class="stat-value neutral" id="sessionDelta">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Cumulative Delta</div>
                    <div class="stat-value neutral" id="cumDelta">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Buy Volume</div>
                    <div class="stat-value positive" id="buyVolume">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Sell Volume</div>
                    <div class="stat-value negative" id="sellVolume">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Imbalances</div>
                    <div class="stat-value neutral" id="imbalanceCount">--</div>
                </div>
            </div>

            <!-- Legend -->
            <div class="chart-legend">
                <div class="legend-item">
                    <div class="legend-color bid"></div>
                    <span>Bid Volume (Buy)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color ask"></div>
                    <span>Ask Volume (Sell)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color delta-pos"></div>
                    <span>Positive Delta</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color delta-neg"></div>
                    <span>Negative Delta</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color imbalance"></div>
                    <span>Imbalance</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Configuration
        var currentSymbol = '@ESH25';
        var currentTimeframe = '5m';
        var barsToShow = 30;

        // WebSocket connection
        var ws = null;
        var reconnectTimer = null;

        // Chart data
        var candles = [];          // Historical candles from IQFeed
        var footprintData = {};    // Footprint data per candle: { [time]: { [price]: { bid: x, ask: y } } }
        var currentCandle = null;  // Current live candle being built

        // Price range for chart
        var priceRange = { min: 0, max: 0 };

        // Canvas
        var canvas, ctx;
        var canvasWidth, canvasHeight;

        // Symbol configs
        var symbolConfig = {
            '@ESH25': { tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            '@NQH25': { tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' },
            'QGC#': { tick: 0.10, decimals: 2, name: 'GC (Gold)' }
        };

        // Stats
        var stats = {
            sessionDelta: 0,
            cumDelta: 0,
            buyVolume: 0,
            sellVolume: 0,
            imbalanceCount: 0
        };

        // Initialize
        function init() {
            canvas = document.getElementById('footprintCanvas');
            ctx = canvas.getContext('2d');

            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);

            // Mouse events
            canvas.addEventListener('mousemove', handleMouseMove);
            canvas.addEventListener('mouseout', handleMouseOut);

            // Connect to IQFeed bridge
            connectWebSocket();
        }

        function connectWebSocket() {
            var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            // Connect to IQFeed bridge via nginx proxy
            var wsUrl = protocol + '//' + window.location.hostname + '/ws/iqfeed';

            updateStatus('', 'Connecting...');

            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                updateStatus('connected', 'Live');
                // Request historical data
                requestHistoricalData();
                // Subscribe to live updates
                ws.send(JSON.stringify({
                    type: 'subscribe',
                    symbol: currentSymbol
                }));
            };

            ws.onmessage = function(event) {
                try {
                    var msg = JSON.parse(event.data);

                    switch (msg.type) {
                        case 'status':
                            handleStatus(msg);
                            break;
                        case 'tick':
                            handleTick(msg);
                            break;
                        case 'candle':
                            handleCandle(msg);
                            break;
                        case 'historical_candles':
                            handleHistoricalCandles(msg);
                            break;
                        case 'pong':
                            break;
                    }
                } catch (e) {
                    console.error('Parse error:', e);
                }
            };

            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
                updateStatus('error', 'Connection Error');
            };

            ws.onclose = function() {
                updateStatus('error', 'Disconnected');
                updateFeedIndicator('L1', false);
                updateFeedIndicator('Delta', false);
                if (reconnectTimer) clearTimeout(reconnectTimer);
                reconnectTimer = setTimeout(connectWebSocket, 3000);
            };

            // Send periodic heartbeats
            setInterval(function() {
                if (ws && ws.readyState === WebSocket.OPEN) {
                    ws.send(JSON.stringify({ type: 'ping' }));
                }
            }, 30000);
        }

        function requestHistoricalData() {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'get_history',
                    symbol: getDisplaySymbol(currentSymbol),
                    timeframe: currentTimeframe,
                    bars: barsToShow
                }));
            }
        }

        function handleStatus(msg) {
            if (msg.connected) {
                updateStatus('connected', 'Live');
            }
        }

        function handleHistoricalCandles(msg) {
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            hideLoading();
            updateFeedIndicator('L1', true);

            candles = msg.candles || [];

            // Initialize footprint data for each candle
            footprintData = {};
            candles.forEach(function(candle) {
                footprintData[candle.time] = initFootprintForCandle(candle);
            });

            // Calculate price range
            calculatePriceRange();

            // Render chart
            renderChart();
            updatePriceAxis();
            updateTimeAxis();
            updateStats();
        }

        function handleCandle(msg) {
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;
            if (msg.timeframe !== currentTimeframe) return;

            updateFeedIndicator('L1', true);

            var candle = msg.data;

            // Check if this updates the last candle or is a new one
            if (candles.length > 0 && candles[candles.length - 1].time === candle.time) {
                // Update existing candle
                candles[candles.length - 1] = candle;
            } else {
                // New candle
                candles.push(candle);
                // Remove oldest if exceeds limit
                if (candles.length > barsToShow) {
                    var removed = candles.shift();
                    delete footprintData[removed.time];
                }
                // Initialize footprint for new candle
                footprintData[candle.time] = initFootprintForCandle(candle);
            }

            calculatePriceRange();
            renderChart();
            updatePriceAxis();
            updateTimeAxis();
        }

        function handleTick(msg) {
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            updateFeedIndicator('L1', true);
            updateFeedIndicator('Delta', true);

            // Update last price display
            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            document.getElementById('lastPrice').textContent = msg.price.toFixed(config.decimals);

            // Determine trade side based on bid/ask
            var side = 'neutral';
            if (msg.bid && msg.ask) {
                if (msg.price >= msg.ask) side = 'buy';
                else if (msg.price <= msg.bid) side = 'sell';
            }

            // Update stats
            if (side === 'buy') {
                stats.buyVolume += msg.size;
                stats.sessionDelta += msg.size;
                stats.cumDelta += msg.size;
            } else if (side === 'sell') {
                stats.sellVolume += msg.size;
                stats.sessionDelta -= msg.size;
                stats.cumDelta -= msg.size;
            }

            // Add to current candle's footprint
            if (candles.length > 0) {
                var currentTime = candles[candles.length - 1].time;
                var fp = footprintData[currentTime];
                if (fp) {
                    var priceKey = roundPrice(msg.price);
                    if (!fp[priceKey]) {
                        fp[priceKey] = { bid: 0, ask: 0 };
                    }
                    if (side === 'buy') {
                        fp[priceKey].bid += msg.size;
                    } else if (side === 'sell') {
                        fp[priceKey].ask += msg.size;
                    }
                }
            }

            updateStats();

            // Re-render periodically (not on every tick for performance)
            if (!handleTick.throttled) {
                handleTick.throttled = true;
                setTimeout(function() {
                    handleTick.throttled = false;
                    renderChart();
                }, 100);
            }
        }

        function getDisplaySymbol(iqfeedSymbol) {
            var map = {
                '@ESH25': 'ES',
                '@NQH25': 'NQ',
                'QGC#': 'GC'
            };
            return map[iqfeedSymbol] || iqfeedSymbol;
        }

        function initFootprintForCandle(candle) {
            // Initialize footprint with OHLC prices
            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };
            var fp = {};

            // Generate price levels within the candle range
            var low = Math.floor(candle.low / config.tick) * config.tick;
            var high = Math.ceil(candle.high / config.tick) * config.tick;

            for (var price = low; price <= high; price += config.tick) {
                var priceKey = roundPrice(price);
                // Initialize with simulated volume distributed across the candle
                fp[priceKey] = {
                    bid: Math.floor(candle.volume / ((high - low) / config.tick + 1) * Math.random() * 0.5),
                    ask: Math.floor(candle.volume / ((high - low) / config.tick + 1) * Math.random() * 0.5)
                };
            }

            return fp;
        }

        function roundPrice(price) {
            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };
            return (Math.round(price / config.tick) * config.tick).toFixed(config.decimals);
        }

        function calculatePriceRange() {
            if (candles.length === 0) return;

            var min = Infinity, max = -Infinity;
            candles.forEach(function(candle) {
                if (candle.low < min) min = candle.low;
                if (candle.high > max) max = candle.high;
            });

            // Add some padding
            var padding = (max - min) * 0.1;
            priceRange.min = min - padding;
            priceRange.max = max + padding;
        }

        function renderChart() {
            if (!ctx || candles.length === 0) return;

            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };

            // Clear canvas
            ctx.fillStyle = '#0d0d14';
            ctx.fillRect(0, 0, canvasWidth, canvasHeight);

            // Calculate dimensions
            var candleWidth = (canvasWidth - 80) / barsToShow; // 80px for price axis
            var candleSpacing = 4;
            var footprintCellWidth = candleWidth - candleSpacing;

            // Price to Y coordinate
            function priceToY(price) {
                return ((priceRange.max - price) / (priceRange.max - priceRange.min)) * canvasHeight;
            }

            // Find max volume for scaling
            var maxVol = 1;
            Object.values(footprintData).forEach(function(fp) {
                Object.values(fp).forEach(function(level) {
                    if (level.bid > maxVol) maxVol = level.bid;
                    if (level.ask > maxVol) maxVol = level.ask;
                });
            });

            // Draw each candle's footprint
            candles.forEach(function(candle, idx) {
                var x = idx * candleWidth + candleSpacing / 2;
                var fp = footprintData[candle.time];
                if (!fp) return;

                // Determine candle color
                var isGreen = candle.close >= candle.open;

                // Draw candle body outline
                var openY = priceToY(candle.open);
                var closeY = priceToY(candle.close);
                var highY = priceToY(candle.high);
                var lowY = priceToY(candle.low);

                var bodyTop = Math.min(openY, closeY);
                var bodyHeight = Math.abs(closeY - openY) || 1;

                // Draw wick
                ctx.strokeStyle = isGreen ? '#22c55e' : '#ef4444';
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(x + footprintCellWidth / 2, highY);
                ctx.lineTo(x + footprintCellWidth / 2, lowY);
                ctx.stroke();

                // Draw candle body border
                ctx.strokeStyle = isGreen ? '#22c55e' : '#ef4444';
                ctx.lineWidth = 2;
                ctx.strokeRect(x + 1, bodyTop, footprintCellWidth - 2, bodyHeight);

                // Draw footprint cells within the candle body
                var rowHeight = Math.max(2, canvasHeight / 50); // Min 2px per row

                Object.keys(fp).forEach(function(priceKey) {
                    var price = parseFloat(priceKey);
                    var level = fp[priceKey];
                    var y = priceToY(price);

                    // Only draw if within the candle range
                    if (price < candle.low - config.tick || price > candle.high + config.tick) return;

                    var bidWidth = (level.bid / maxVol) * (footprintCellWidth / 2 - 2);
                    var askWidth = (level.ask / maxVol) * (footprintCellWidth / 2 - 2);

                    // Bid bar (left side, green)
                    if (level.bid > 0) {
                        var bidIntensity = Math.min(1, level.bid / maxVol * 2);
                        ctx.fillStyle = 'rgba(34, 197, 94, ' + (0.3 + bidIntensity * 0.7) + ')';
                        ctx.fillRect(x + footprintCellWidth / 2 - bidWidth - 1, y - rowHeight / 2, bidWidth, rowHeight - 1);
                    }

                    // Ask bar (right side, red)
                    if (level.ask > 0) {
                        var askIntensity = Math.min(1, level.ask / maxVol * 2);
                        ctx.fillStyle = 'rgba(239, 68, 68, ' + (0.3 + askIntensity * 0.7) + ')';
                        ctx.fillRect(x + footprintCellWidth / 2 + 1, y - rowHeight / 2, askWidth, rowHeight - 1);
                    }

                    // Delta value in center
                    var delta = level.bid - level.ask;
                    if (Math.abs(delta) > maxVol * 0.1) {
                        ctx.font = '8px Consolas';
                        ctx.textAlign = 'center';
                        ctx.fillStyle = delta > 0 ? '#4ade80' : '#f87171';
                        var deltaText = delta > 0 ? '+' + delta : delta.toString();
                        ctx.fillText(deltaText, x + footprintCellWidth / 2, y + 3);
                    }

                    // Imbalance indicator (3:1 ratio)
                    if (level.bid > level.ask * 3 && level.ask > 0) {
                        ctx.fillStyle = '#f59e0b';
                        ctx.beginPath();
                        ctx.arc(x + 5, y, 3, 0, Math.PI * 2);
                        ctx.fill();
                        stats.imbalanceCount++;
                    } else if (level.ask > level.bid * 3 && level.bid > 0) {
                        ctx.fillStyle = '#f59e0b';
                        ctx.beginPath();
                        ctx.arc(x + footprintCellWidth - 5, y, 3, 0, Math.PI * 2);
                        ctx.fill();
                        stats.imbalanceCount++;
                    }
                });

                // Draw delta at bottom of candle
                var candleDelta = 0;
                Object.values(fp).forEach(function(level) {
                    candleDelta += level.bid - level.ask;
                });
                ctx.font = 'bold 10px Consolas';
                ctx.textAlign = 'center';
                ctx.fillStyle = candleDelta >= 0 ? '#22c55e' : '#ef4444';
                ctx.fillText((candleDelta >= 0 ? '+' : '') + candleDelta, x + footprintCellWidth / 2, lowY + 12);
            });
        }

        function updatePriceAxis() {
            var axis = document.getElementById('priceAxis');
            if (candles.length === 0) return;

            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            var labels = [];
            var numLabels = 10;

            for (var i = 0; i <= numLabels; i++) {
                var price = priceRange.max - (i / numLabels) * (priceRange.max - priceRange.min);
                labels.push('<div class="price-label">' + price.toFixed(config.decimals) + '</div>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateTimeAxis() {
            var axis = document.getElementById('timeAxis');
            if (candles.length === 0) return;

            var labels = [];
            var step = Math.max(1, Math.floor(candles.length / 6));

            for (var i = 0; i < candles.length; i += step) {
                var time = new Date(candles[i].time);
                var timeStr = time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                labels.push('<span>' + timeStr + '</span>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateStats() {
            document.getElementById('sessionDelta').textContent = (stats.sessionDelta >= 0 ? '+' : '') + stats.sessionDelta;
            document.getElementById('sessionDelta').className = 'stat-value ' + (stats.sessionDelta >= 0 ? 'positive' : 'negative');

            document.getElementById('cumDelta').textContent = (stats.cumDelta >= 0 ? '+' : '') + stats.cumDelta;
            document.getElementById('cumDelta').className = 'stat-value ' + (stats.cumDelta >= 0 ? 'positive' : 'negative');

            document.getElementById('buyVolume').textContent = stats.buyVolume.toLocaleString();
            document.getElementById('sellVolume').textContent = stats.sellVolume.toLocaleString();
            document.getElementById('imbalanceCount').textContent = stats.imbalanceCount;
        }

        function handleMouseMove(e) {
            var rect = canvas.getBoundingClientRect();
            var x = e.clientX - rect.left;
            var y = e.clientY - rect.top;

            var config = symbolConfig[currentSymbol] || { decimals: 2 };

            // Calculate price from Y
            var price = priceRange.max - (y / canvasHeight) * (priceRange.max - priceRange.min);

            // Calculate candle index from X
            var candleWidth = (canvasWidth - 80) / barsToShow;
            var candleIdx = Math.floor(x / candleWidth);

            // Show crosshairs
            document.getElementById('crosshairX').style.display = 'block';
            document.getElementById('crosshairX').style.left = x + 'px';
            document.getElementById('crosshairY').style.display = 'block';
            document.getElementById('crosshairY').style.top = y + 'px';
            document.getElementById('crosshairPrice').textContent = price.toFixed(config.decimals);

            // Show tooltip if over a candle
            if (candleIdx >= 0 && candleIdx < candles.length) {
                var candle = candles[candleIdx];
                var fp = footprintData[candle.time];

                var tooltip = document.getElementById('chartTooltip');
                var header = document.getElementById('tooltipHeader');
                var content = document.getElementById('tooltipContent');

                var time = new Date(candle.time);
                header.textContent = time.toLocaleString();

                var candleDelta = 0;
                var candleBuyVol = 0;
                var candleSellVol = 0;
                if (fp) {
                    Object.values(fp).forEach(function(level) {
                        candleDelta += level.bid - level.ask;
                        candleBuyVol += level.bid;
                        candleSellVol += level.ask;
                    });
                }

                content.innerHTML =
                    '<div class="tooltip-row"><span class="label">Open:</span><span>' + candle.open.toFixed(config.decimals) + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">High:</span><span>' + candle.high.toFixed(config.decimals) + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">Low:</span><span>' + candle.low.toFixed(config.decimals) + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">Close:</span><span>' + candle.close.toFixed(config.decimals) + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">Volume:</span><span>' + candle.volume.toLocaleString() + '</span></div>' +
                    '<div style="border-top: 1px solid #2a2a3d; margin: 8px 0;"></div>' +
                    '<div class="tooltip-row"><span class="label">Buy Vol:</span><span style="color:#22c55e">' + candleBuyVol + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">Sell Vol:</span><span style="color:#ef4444">' + candleSellVol + '</span></div>' +
                    '<div class="tooltip-row"><span class="label">Delta:</span><span style="color:' + (candleDelta >= 0 ? '#22c55e' : '#ef4444') + '">' + (candleDelta >= 0 ? '+' : '') + candleDelta + '</span></div>';

                tooltip.style.display = 'block';
                tooltip.style.left = Math.min(x + 20, canvasWidth - 220) + 'px';
                tooltip.style.top = Math.min(y + 20, canvasHeight - 200) + 'px';
            }
        }

        function handleMouseOut() {
            document.getElementById('crosshairX').style.display = 'none';
            document.getElementById('crosshairY').style.display = 'none';
            document.getElementById('chartTooltip').style.display = 'none';
        }

        function resizeCanvas() {
            var container = canvas.parentElement;
            canvas.width = container.clientWidth - 80; // 80px for price axis
            canvas.height = container.clientHeight - 30; // 30px for time axis
            canvasWidth = canvas.width;
            canvasHeight = canvas.height;

            if (candles.length > 0) {
                renderChart();
            }
        }

        function updateStatus(status, text) {
            var dot = document.getElementById('statusDot');
            var textEl = document.getElementById('statusText');
            dot.className = 'status-dot';
            if (status === 'connected') dot.classList.add('connected');
            else if (status === 'error') dot.classList.add('error');
            textEl.textContent = text;
        }

        function updateFeedIndicator(feed, active) {
            var el = document.getElementById('feed' + feed);
            if (el) {
                if (active) {
                    el.classList.add('active');
                } else {
                    el.classList.remove('active');
                }
            }
        }

        function hideLoading() {
            document.getElementById('loadingOverlay').classList.add('hidden');
        }

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            candles = [];
            footprintData = {};
            stats = { sessionDelta: 0, cumDelta: 0, buyVolume: 0, sellVolume: 0, imbalanceCount: 0 };

            // Show loading
            document.getElementById('loadingOverlay').classList.remove('hidden');

            // Clear canvas
            if (ctx) {
                ctx.fillStyle = '#0d0d14';
                ctx.fillRect(0, 0, canvasWidth, canvasHeight);
            }

            // Resubscribe and request history
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'subscribe',
                    symbol: currentSymbol
                }));
                requestHistoricalData();
            }
        }

        function changeTimeframe(timeframe) {
            currentTimeframe = timeframe;
            candles = [];
            footprintData = {};
            stats = { sessionDelta: 0, cumDelta: 0, buyVolume: 0, sellVolume: 0, imbalanceCount: 0 };

            // Show loading
            document.getElementById('loadingOverlay').classList.remove('hidden');

            // Request new history
            requestHistoricalData();
        }

        function setBars(bars) {
            barsToShow = parseInt(bars);

            // Trim candles if needed
            while (candles.length > barsToShow) {
                var removed = candles.shift();
                delete footprintData[removed.time];
            }

            calculatePriceRange();
            renderChart();
            updatePriceAxis();
            updateTimeAxis();
        }

        // Initialize on load
        window.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>
