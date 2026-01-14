<!--- Heatmap Module - Order book visualization using IQFeed Level1/Level2/MBO Data --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Book Heatmap - IQFeed Level 2</title>
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

        /* Data feed indicators */
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
        .feed-indicator.l1 { color: #3b82f6; }
        .feed-indicator.l2 { color: #8b5cf6; }
        .feed-indicator.mbo { color: #f59e0b; }

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

        /* Heatmap Container */
        .heatmap-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: #0d0d14;
            overflow: hidden;
        }

        /* Canvas container */
        .heatmap-canvas-container {
            position: relative;
            flex: 1;
            min-height: 0;
        }
        #heatmapCanvas {
            position: absolute;
            left: 45px;
            top: 0;
        }

        /* Left Scale Bar */
        .scale-bar {
            position: absolute;
            left: 0;
            top: 0;
            bottom: 30px;
            width: 45px;
            background: #12121a;
            border-right: 1px solid #1a1a24;
            z-index: 20;
        }
        .scale-bar .label {
            position: absolute;
            top: 5px;
            left: 3px;
            font-size: 9px;
            color: #9ca3af;
            text-transform: uppercase;
        }
        .scale-bar .max-label {
            position: absolute;
            top: 18px;
            left: 3px;
            font-size: 10px;
            color: #3b82f6;
            font-family: Consolas, monospace;
            font-weight: bold;
        }
        /* Ask gradient (top half) */
        .scale-bar .ask-gradient {
            position: absolute;
            top: 38px;
            left: 8px;
            height: calc(50% - 50px);
            width: 22px;
            border-radius: 3px 3px 0 0;
            background: linear-gradient(to bottom, #fca5a5, #ef4444, #7f1d1d);
        }
        /* Bid gradient (bottom half) */
        .scale-bar .bid-gradient {
            position: absolute;
            top: calc(50% - 12px);
            left: 8px;
            height: calc(50% - 50px);
            width: 22px;
            border-radius: 0 0 3px 3px;
            background: linear-gradient(to bottom, #14532d, #22c55e, #4ade80);
        }
        .scale-bar .ask-label {
            position: absolute;
            top: 38px;
            right: 3px;
            font-size: 8px;
            color: #ef4444;
        }
        .scale-bar .bid-label {
            position: absolute;
            bottom: 30px;
            right: 3px;
            font-size: 8px;
            color: #22c55e;
        }

        /* Depth Histogram */
        .depth-histogram {
            position: absolute;
            right: 80px;
            top: 0;
            bottom: 30px;
            width: 120px;
            background: #0d0d14;
            border-left: 1px solid #1a1a24;
            z-index: 20;
        }
        .depth-histogram .title {
            position: absolute;
            top: 5px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 9px;
            color: #9ca3af;
            text-transform: uppercase;
        }
        .depth-histogram .bid-label {
            position: absolute;
            top: 18px;
            left: 5px;
            font-size: 8px;
            color: #22c55e;
        }
        .depth-histogram .ask-label {
            position: absolute;
            top: 18px;
            right: 5px;
            font-size: 8px;
            color: #ef4444;
        }
        #histogramCanvas {
            width: 100%;
            height: 100%;
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
            padding: 8px 90px 8px 50px;
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
        .stat-item .stat-value.bid { color: #22c55e; }
        .stat-item .stat-value.ask { color: #ef4444; }
        .stat-item .stat-value.neutral { color: #fff; }

        /* Legend */
        .heatmap-legend {
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
        .legend-color.bid-low { background: #14532d; }
        .legend-color.bid-med { background: #22c55e; }
        .legend-color.bid-high { background: #4ade80; }
        .legend-color.ask-low { background: #7f1d1d; }
        .legend-color.ask-med { background: #ef4444; }
        .legend-color.ask-high { background: #fca5a5; }
        .legend-color.whale { background: #3b82f6; }
        .legend-color.mbo { background: #f59e0b; }

        /* Crosshair */
        #crosshairY {
            display: none;
            position: absolute;
            left: 45px;
            right: 200px;
            height: 1px;
            background: rgba(245, 158, 11, 0.7);
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
        #heatmapTooltip {
            display: none;
            position: absolute;
            background: rgba(0,0,0,0.9);
            border: 1px solid #7c3aed;
            border-radius: 6px;
            padding: 8px 12px;
            font-size: 12px;
            font-family: Consolas, monospace;
            pointer-events: none;
            z-index: 100;
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
            .heatmap-canvas-container { min-height: 400px; }
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
            <h2>Order Book Heatmap</h2>
            <div class="status-indicator">
                <span class="status-dot" id="statusDot"></span>
                <span id="statusText">Connecting...</span>
            </div>
            <div class="feed-indicators">
                <div class="feed-indicator l1" id="feedL1">
                    <span class="dot"></span>
                    <span>Level 1</span>
                </div>
                <div class="feed-indicator l2" id="feedL2">
                    <span class="dot"></span>
                    <span>Level 2</span>
                </div>
                <div class="feed-indicator mbo" id="feedMBO">
                    <span class="dot"></span>
                    <span>MBO</span>
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
                <label>Depth:</label>
                <select id="depthSelect" onchange="setDepth(this.value)">
                    <option value="20">20 levels</option>
                    <option value="50" selected>50 levels</option>
                    <option value="100">100 levels</option>
                </select>
                <label>Speed:</label>
                <select id="speedSelect" onchange="setSpeed(this.value)">
                    <option value="250">Fast (250ms)</option>
                    <option value="500" selected>Normal (500ms)</option>
                    <option value="1000">Slow (1s)</option>
                </select>
            </div>
        </div>
    </header>

    <div class="content">
        <div class="heatmap-container">
            <div class="heatmap-canvas-container">
                <!-- Loading overlay -->
                <div class="loading-overlay" id="loadingOverlay">
                    <div style="width: 40px; height: 40px; border: 3px solid #2a2a3d; border-top-color: #7c3aed; border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: 16px;"></div>
                    <div style="color: #9ca3af; font-size: 14px;">Connecting to IQFeed...</div>
                </div>

                <!-- Left Scale Bar -->
                <div class="scale-bar">
                    <div class="label">Vol</div>
                    <div class="max-label" id="scaleMaxLabel">0</div>
                    <div class="ask-gradient"></div>
                    <div class="bid-gradient"></div>
                    <div class="ask-label">Ask</div>
                    <div class="bid-label">Bid</div>
                </div>

                <!-- Main Heatmap Canvas -->
                <canvas id="heatmapCanvas"></canvas>

                <!-- Depth Histogram -->
                <div class="depth-histogram">
                    <div class="title">Depth</div>
                    <div class="bid-label">Bid</div>
                    <div class="ask-label">Ask</div>
                    <canvas id="histogramCanvas"></canvas>
                </div>

                <!-- Price Axis -->
                <div class="price-axis" id="priceAxis">
                    <!-- Price labels will be generated -->
                </div>

                <!-- Crosshair -->
                <div id="crosshairY">
                    <div id="crosshairPrice"></div>
                </div>

                <!-- Tooltip -->
                <div id="heatmapTooltip">
                    <div id="tooltipPrice" style="color: #f59e0b; font-weight: 600;"></div>
                    <div id="tooltipInfo" style="color: #9ca3af; margin-top: 4px;"></div>
                </div>
            </div>

            <div class="time-axis" id="timeAxis">
                <!-- Time labels will be generated -->
            </div>

            <!-- Stats -->
            <div class="stats-bar">
                <div class="stat-item">
                    <div class="stat-label">Best Bid</div>
                    <div class="stat-value bid" id="bestBid">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Best Ask</div>
                    <div class="stat-value ask" id="bestAsk">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Spread</div>
                    <div class="stat-value neutral" id="spread">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Total Bid Vol</div>
                    <div class="stat-value bid" id="totalBidVol">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Total Ask Vol</div>
                    <div class="stat-value ask" id="totalAskVol">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Imbalance</div>
                    <div class="stat-value neutral" id="imbalance">--</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">Order Count</div>
                    <div class="stat-value neutral" id="orderCount">--</div>
                </div>
            </div>

            <!-- Legend -->
            <div class="heatmap-legend">
                <div class="legend-item">
                    <div class="legend-color bid-low"></div>
                    <span>Bid (Low)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color bid-med"></div>
                    <span>Bid (Med)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color bid-high"></div>
                    <span>Bid (High)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color ask-low"></div>
                    <span>Ask (Low)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color ask-med"></div>
                    <span>Ask (Med)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color ask-high"></div>
                    <span>Ask (High)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color whale"></div>
                    <span>Whale Order</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color mbo"></div>
                    <span>MBO Data</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Configuration
        var currentSymbol = '@ESH25';
        var depthLevels = 50;
        var updateSpeed = 500;

        // WebSocket connection
        var ws = null;
        var reconnectTimer = null;

        // Heatmap data storage
        var heatmapHistory = []; // Array of snapshots
        var maxHistoryLength = 300; // 5 minutes at 1s = 300 snapshots
        var priceRange = { min: 0, max: 0, mid: 0 };

        // Canvas
        var canvas, ctx;
        var canvasWidth, canvasHeight;
        var histCanvas, histCtx;

        // Symbol configs
        var symbolConfig = {
            '@ESH25': { tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            '@NQH25': { tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' },
            'QGC#': { tick: 0.10, decimals: 2, name: 'GC (Gold)' }
        };

        // Data feed status
        var feedStatus = {
            level1: false,
            level2: false,
            mbo: false
        };

        // Level 1 quote data
        var level1 = {
            bid: 0,
            ask: 0,
            last: 0,
            bidSize: 0,
            askSize: 0
        };

        // Initialize
        function init() {
            canvas = document.getElementById('heatmapCanvas');
            ctx = canvas.getContext('2d');
            histCanvas = document.getElementById('histogramCanvas');
            histCtx = histCanvas.getContext('2d');

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
                hideLoading();
                // Subscribe to symbol
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
                        case 'orderbook':
                            handleOrderbook(msg);
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
                resetFeedIndicators();
                // Reconnect after 3 seconds
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

        function handleStatus(msg) {
            if (msg.connected) {
                updateStatus('connected', 'Live');
                hideLoading();
            }
        }

        function handleTick(msg) {
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            feedStatus.level1 = true;
            updateFeedIndicator('L1', true);

            level1.last = msg.price;
            level1.bid = msg.bid || level1.bid;
            level1.ask = msg.ask || level1.ask;

            // Update price range for heatmap
            if (level1.bid && level1.ask) {
                var mid = (level1.bid + level1.ask) / 2;
                if (priceRange.mid === 0) {
                    priceRange.mid = mid;
                    priceRange.min = mid - 10;
                    priceRange.max = mid + 10;
                }
            }
        }

        function handleOrderbook(msg) {
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            feedStatus.level2 = true;
            feedStatus.mbo = true;
            updateFeedIndicator('L2', true);
            updateFeedIndicator('MBO', true);

            var data = msg.data;
            if (!data || !data.bids || !data.asks) return;

            hideLoading();

            var bids = data.bids || [];
            var asks = data.asks || [];

            if (bids.length === 0 && asks.length === 0) return;

            var bestBid = data.best_bid || (bids.length > 0 ? bids[0][0] : 0);
            var bestAsk = data.best_ask || (asks.length > 0 ? asks[0][0] : 0);
            var midPrice = (bestBid + bestAsk) / 2;

            // Build bid/ask levels
            var bidLevels = {};
            var askLevels = {};
            var totalBidVol = 0, totalAskVol = 0;
            var orderCount = 0;

            bids.forEach(function(level) {
                var price = level[0];
                var size = level[1];
                bidLevels[price] = size;
                totalBidVol += size;
                orderCount++;
            });

            asks.forEach(function(level) {
                var price = level[0];
                var size = level[1];
                askLevels[price] = size;
                totalAskVol += size;
                orderCount++;
            });

            // Update price range
            var allPrices = Object.keys(bidLevels).concat(Object.keys(askLevels)).map(parseFloat);
            if (allPrices.length > 0) {
                priceRange.min = Math.min.apply(null, allPrices);
                priceRange.max = Math.max.apply(null, allPrices);
                priceRange.mid = midPrice;
            }

            // Create snapshot
            var snapshot = {
                timestamp: Date.now(),
                midPrice: midPrice,
                bestBid: bestBid,
                bestAsk: bestAsk,
                bids: bidLevels,
                asks: askLevels,
                totalBidVol: totalBidVol,
                totalAskVol: totalAskVol,
                orderCount: orderCount
            };

            // Add to history
            heatmapHistory.push(snapshot);
            if (heatmapHistory.length > maxHistoryLength) {
                heatmapHistory.shift();
            }

            // Update UI
            updateStats(snapshot);
            renderHeatmap();
            renderHistogram(snapshot);
            updatePriceAxis();
            updateTimeAxis();
        }

        function getDisplaySymbol(iqfeedSymbol) {
            var map = {
                '@ESH25': 'ES',
                '@NQH25': 'NQ',
                'QGC#': 'GC'
            };
            return map[iqfeedSymbol] || iqfeedSymbol;
        }

        function updateStats(snapshot) {
            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            document.getElementById('bestBid').textContent = snapshot.bestBid.toFixed(config.decimals);
            document.getElementById('bestAsk').textContent = snapshot.bestAsk.toFixed(config.decimals);
            document.getElementById('spread').textContent = (snapshot.bestAsk - snapshot.bestBid).toFixed(config.decimals);
            document.getElementById('totalBidVol').textContent = snapshot.totalBidVol.toFixed(0);
            document.getElementById('totalAskVol').textContent = snapshot.totalAskVol.toFixed(0);

            var total = snapshot.totalBidVol + snapshot.totalAskVol;
            var imbalance = total > 0 ? ((snapshot.totalBidVol - snapshot.totalAskVol) / total * 100).toFixed(1) : 0;
            var imbalanceEl = document.getElementById('imbalance');
            imbalanceEl.textContent = (imbalance >= 0 ? '+' : '') + imbalance + '%';
            imbalanceEl.style.color = imbalance > 0 ? '#22c55e' : (imbalance < 0 ? '#ef4444' : '#fff');

            document.getElementById('orderCount').textContent = snapshot.orderCount;
        }

        function renderHeatmap() {
            if (heatmapHistory.length === 0) return;

            ctx.fillStyle = '#0d0d14';
            ctx.fillRect(0, 0, canvasWidth, canvasHeight);

            // Center on mid price
            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            if (halfRange === 0) halfRange = 10;
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;

            var colWidth = canvasWidth / Math.max(heatmapHistory.length, 1);

            // Find max volume for color scaling
            var maxVol = 0;
            heatmapHistory.forEach(function(snap) {
                Object.values(snap.bids).forEach(function(v) { if (v > maxVol) maxVol = v; });
                Object.values(snap.asks).forEach(function(v) { if (v > maxVol) maxVol = v; });
            });
            if (maxVol === 0) maxVol = 1;

            // Update scale label
            document.getElementById('scaleMaxLabel').textContent = maxVol.toFixed(0);

            // Draw each snapshot
            heatmapHistory.forEach(function(snap, colIdx) {
                var x = colIdx * colWidth;

                // Draw bids (green)
                Object.keys(snap.bids).forEach(function(priceStr) {
                    var price = parseFloat(priceStr);
                    var vol = snap.bids[priceStr];
                    var intensity = vol / maxVol;

                    var y = ((viewMax - price) / (viewMax - viewMin)) * canvasHeight;
                    var rowHeight = Math.max(2, canvasHeight / depthLevels);

                    // Green color gradient based on intensity
                    var r = Math.floor(20 + 100 * (1 - intensity));
                    var g = Math.floor(83 + 150 * intensity);
                    var b = Math.floor(45 + 80 * (1 - intensity));
                    ctx.fillStyle = 'rgb(' + r + ',' + g + ',' + b + ')';
                    ctx.fillRect(x, y - rowHeight/2, colWidth - 1, rowHeight);

                    // Whale orders (extra bright)
                    if (intensity > 0.7) {
                        ctx.fillStyle = 'rgba(74, 222, 128, 0.8)';
                        ctx.fillRect(x, y - rowHeight/2, colWidth - 1, rowHeight);
                    }
                });

                // Draw asks (red)
                Object.keys(snap.asks).forEach(function(priceStr) {
                    var price = parseFloat(priceStr);
                    var vol = snap.asks[priceStr];
                    var intensity = vol / maxVol;

                    var y = ((viewMax - price) / (viewMax - viewMin)) * canvasHeight;
                    var rowHeight = Math.max(2, canvasHeight / depthLevels);

                    // Red color gradient based on intensity
                    var r = Math.floor(127 + 120 * intensity);
                    var g = Math.floor(29 + 100 * (1 - intensity));
                    var b = Math.floor(29 + 100 * (1 - intensity));
                    ctx.fillStyle = 'rgb(' + r + ',' + g + ',' + b + ')';
                    ctx.fillRect(x, y - rowHeight/2, colWidth - 1, rowHeight);

                    // Whale orders
                    if (intensity > 0.7) {
                        ctx.fillStyle = 'rgba(252, 165, 165, 0.8)';
                        ctx.fillRect(x, y - rowHeight/2, colWidth - 1, rowHeight);
                    }
                });

                // Draw mid price line
                var midY = ((viewMax - snap.midPrice) / (viewMax - viewMin)) * canvasHeight;
                ctx.fillStyle = '#f59e0b';
                ctx.fillRect(x, midY - 1, colWidth - 1, 2);
            });
        }

        function renderHistogram(snapshot) {
            if (!histCtx) return;

            var container = histCanvas.parentElement;
            histCanvas.width = container.clientWidth;
            histCanvas.height = container.clientHeight - 30;

            histCtx.fillStyle = '#0d0d14';
            histCtx.fillRect(0, 0, histCanvas.width, histCanvas.height);

            if (!snapshot) return;

            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            if (halfRange === 0) halfRange = 10;
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;

            var maxVol = Math.max(snapshot.totalBidVol, snapshot.totalAskVol, 1) / depthLevels;
            var halfWidth = histCanvas.width / 2;

            // Draw bid bars (left side, green)
            Object.keys(snapshot.bids).forEach(function(priceStr) {
                var price = parseFloat(priceStr);
                var vol = snapshot.bids[priceStr];
                var barWidth = (vol / maxVol) * halfWidth;

                var y = ((viewMax - price) / (viewMax - viewMin)) * histCanvas.height;
                var barHeight = Math.max(2, histCanvas.height / depthLevels);

                histCtx.fillStyle = '#22c55e';
                histCtx.fillRect(halfWidth - barWidth, y - barHeight/2, barWidth, barHeight - 1);
            });

            // Draw ask bars (right side, red)
            Object.keys(snapshot.asks).forEach(function(priceStr) {
                var price = parseFloat(priceStr);
                var vol = snapshot.asks[priceStr];
                var barWidth = (vol / maxVol) * halfWidth;

                var y = ((viewMax - price) / (viewMax - viewMin)) * histCanvas.height;
                var barHeight = Math.max(2, histCanvas.height / depthLevels);

                histCtx.fillStyle = '#ef4444';
                histCtx.fillRect(halfWidth, y - barHeight/2, barWidth, barHeight - 1);
            });

            // Draw center line
            histCtx.fillStyle = '#1a1a24';
            histCtx.fillRect(halfWidth - 1, 0, 2, histCanvas.height);
        }

        function updatePriceAxis() {
            var axis = document.getElementById('priceAxis');
            if (heatmapHistory.length === 0) return;

            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            if (halfRange === 0) halfRange = 10;
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;

            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            var labels = [];
            var numLabels = 10;

            for (var i = 0; i <= numLabels; i++) {
                var price = viewMax - (i / numLabels) * (viewMax - viewMin);
                var isMid = Math.abs(price - midPrice) < (viewMax - viewMin) / numLabels;
                labels.push('<div class="price-label' + (isMid ? ' current-price' : '') + '">' + price.toFixed(config.decimals) + '</div>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateTimeAxis() {
            var axis = document.getElementById('timeAxis');
            if (heatmapHistory.length === 0) return;

            var now = Date.now();
            var oldest = heatmapHistory[0].timestamp;
            var duration = now - oldest;

            var labels = [];
            var numLabels = 6;

            for (var i = 0; i <= numLabels; i++) {
                var time = new Date(oldest + (i / numLabels) * duration);
                labels.push('<span>' + time.toLocaleTimeString() + '</span>');
            }

            axis.innerHTML = labels.join('');
        }

        function handleMouseMove(e) {
            var rect = canvas.getBoundingClientRect();
            var x = e.clientX - rect.left;
            var y = e.clientY - rect.top;

            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            if (halfRange === 0) return;
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;

            var price = viewMax - (y / canvasHeight) * (viewMax - viewMin);
            var config = symbolConfig[currentSymbol] || { decimals: 2 };

            // Show tooltip
            var tooltip = document.getElementById('heatmapTooltip');
            var tooltipPrice = document.getElementById('tooltipPrice');
            var tooltipInfo = document.getElementById('tooltipInfo');
            var crosshair = document.getElementById('crosshairY');

            tooltipPrice.textContent = 'Price: $' + price.toFixed(config.decimals);

            if (heatmapHistory.length > 0) {
                var latest = heatmapHistory[heatmapHistory.length - 1];
                var diff = price - latest.midPrice;
                var pct = (diff / latest.midPrice * 100).toFixed(2);

                // Find volume at this price level
                var bidVol = 0, askVol = 0;
                var priceThreshold = (viewMax - viewMin) / 50;

                Object.keys(latest.bids).forEach(function(p) {
                    if (Math.abs(parseFloat(p) - price) < priceThreshold) {
                        bidVol += latest.bids[p];
                    }
                });
                Object.keys(latest.asks).forEach(function(p) {
                    if (Math.abs(parseFloat(p) - price) < priceThreshold) {
                        askVol += latest.asks[p];
                    }
                });

                var volInfo = '';
                if (bidVol > 0) volInfo = '<span style="color:#22c55e">Bid Vol: ' + bidVol.toFixed(0) + '</span>';
                else if (askVol > 0) volInfo = '<span style="color:#ef4444">Ask Vol: ' + askVol.toFixed(0) + '</span>';
                else volInfo = '<span style="color:#6b7280">No orders at level</span>';

                tooltipInfo.innerHTML = '<span style="color:#9ca3af">' + (diff >= 0 ? '+' : '') + pct + '% from mid</span><br>' + volInfo;
            }

            // Position tooltip
            tooltip.style.display = 'block';
            tooltip.style.left = (x + 60) + 'px';
            tooltip.style.top = (y - 10) + 'px';

            // Show crosshair
            crosshair.style.display = 'block';
            crosshair.style.top = y + 'px';
            document.getElementById('crosshairPrice').textContent = price.toFixed(config.decimals);
        }

        function handleMouseOut() {
            document.getElementById('heatmapTooltip').style.display = 'none';
            document.getElementById('crosshairY').style.display = 'none';
        }

        function resizeCanvas() {
            var container = canvas.parentElement;
            var extraLeft = 45; // Scale bar
            var extraRight = 200; // Histogram + price axis

            canvas.width = container.clientWidth - extraRight - extraLeft;
            canvas.height = container.clientHeight - 30; // Account for time axis
            canvasWidth = canvas.width;
            canvasHeight = canvas.height;

            if (heatmapHistory.length > 0) {
                renderHeatmap();
                renderHistogram(heatmapHistory[heatmapHistory.length - 1]);
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

        function resetFeedIndicators() {
            feedStatus.level1 = false;
            feedStatus.level2 = false;
            feedStatus.mbo = false;
            updateFeedIndicator('L1', false);
            updateFeedIndicator('L2', false);
            updateFeedIndicator('MBO', false);
        }

        function hideLoading() {
            document.getElementById('loadingOverlay').classList.add('hidden');
        }

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            heatmapHistory = [];
            priceRange = { min: 0, max: 0, mid: 0 };
            resetFeedIndicators();

            // Show loading
            document.getElementById('loadingOverlay').classList.remove('hidden');

            // Clear canvas
            if (ctx) {
                ctx.fillStyle = '#0d0d14';
                ctx.fillRect(0, 0, canvasWidth, canvasHeight);
            }

            // Resubscribe
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'subscribe',
                    symbol: currentSymbol
                }));
            }
        }

        function setDepth(levels) {
            depthLevels = parseInt(levels);
        }

        function setSpeed(speed) {
            updateSpeed = parseInt(speed);
        }

        // Initialize on load
        window.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>
