<!--- DOM (Depth of Market) Module - Using IQFeed Level1/Level2/MBO Data --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM - IQFeed Level 2 & MBO Data</title>
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
        /* Custom scrollbar */
        ::-webkit-scrollbar {
            width: 4px;
            height: 4px;
        }
        ::-webkit-scrollbar-track {
            background: transparent;
        }
        ::-webkit-scrollbar-thumb {
            background: rgba(139, 92, 246, 0.3);
            border-radius: 2px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(139, 92, 246, 0.5);
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

        .content {
            height: calc(100vh - 70px);
            padding: 24px;
            display: flex;
            justify-content: center;
            gap: 24px;
        }

        /* DOM Panel */
        .dom-panel {
            background: #12121a;
            border: 1px solid #1a1a24;
            border-radius: 12px;
            display: flex;
            flex-direction: column;
            width: 100%;
            max-width: 550px;
        }
        .dom-panel-header {
            padding: 16px 20px;
            border-bottom: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .dom-panel-header h3 {
            font-size: 16px;
            font-weight: 600;
            color: #fff;
        }
        .dom-panel-header .provider {
            font-size: 11px;
            color: #6b7280;
            background: #1a1a24;
            padding: 4px 8px;
            border-radius: 4px;
        }
        .dom-panel-body {
            flex: 1;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        /* Price Info Bar */
        .price-info {
            display: flex;
            justify-content: space-between;
            padding: 12px 20px;
            background: #0a0a0f;
            border-bottom: 1px solid #1a1a24;
            font-size: 13px;
        }
        .price-info .bid-info { color: #3b82f6; }
        .price-info .ask-info { color: #ef4444; }
        .price-info .spread-info { color: #a855f7; }
        .price-info .last-info { color: #f59e0b; }

        /* DOM Header Row */
        .dom-header {
            display: grid;
            grid-template-columns: 40px 55px 65px 80px 65px 55px 60px;
            height: 28px;
            align-items: center;
            background: #1a1a24;
            border-bottom: 1px solid #2a2a3d;
            font-size: 10px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
        }
        .dom-header > div {
            text-align: center;
        }

        /* DOM Ladder */
        .dom-ladder {
            flex: 1;
            overflow-y: scroll;
            overflow-x: hidden;
            background: #0d0d14;
            overscroll-behavior: contain;
            -webkit-overflow-scrolling: touch;
            touch-action: pan-y;
            position: relative;
        }
        .dom-ladder::-webkit-scrollbar { width: 6px; }
        .dom-ladder::-webkit-scrollbar-track { background: #0a0a0f; border-radius: 3px; }
        .dom-ladder::-webkit-scrollbar-thumb { background: #2a2a3d; border-radius: 3px; }
        .dom-ladder::-webkit-scrollbar-thumb:hover { background: #3a3a4d; }

        .dom-row {
            display: grid;
            grid-template-columns: 40px 55px 65px 80px 65px 55px 60px;
            height: 24px;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.3);
            font-size: 12px;
            position: relative;
        }
        .dom-row:hover {
            filter: brightness(1.1);
        }

        /* Bid side rows (below current price) - Green */
        .dom-row.bid-level {
            background: #0d3d0d;
        }
        .dom-row.bid-level:hover {
            background: #0f4a0f;
        }

        /* Ask side rows (above current price) - Orange/Red */
        .dom-row.ask-level {
            background: #4d2a0d;
        }
        .dom-row.ask-level:hover {
            background: #5c3510;
        }

        /* Current price level - Purple */
        .dom-row.current-price {
            background: #9333ea;
        }

        /* Last trade row highlighting */
        .dom-row.last-trade {
            box-shadow: inset 0 0 0 2px #f59e0b;
        }

        .dom-row .orders-col {
            text-align: center;
            font-size: 9px;
            color: #6b7280;
            font-family: 'Consolas', 'Monaco', monospace;
        }
        .dom-row .orders-col.has-orders {
            color: #a855f7;
        }

        .dom-row .bid-qty {
            position: relative;
            text-align: center;
            color: #4ade80;
            font-weight: 600;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .dom-row .bid-col {
            text-align: center;
            color: #22c55e;
            font-weight: 500;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .dom-row .price {
            text-align: center;
            font-weight: 600;
            color: #e5e7eb;
            background: #12121a;
            padding: 0 4px;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 12px;
        }
        .dom-row .ask-col {
            text-align: center;
            color: #ef4444;
            font-weight: 500;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .dom-row .ask-qty {
            position: relative;
            text-align: center;
            color: #fb923c;
            font-weight: 600;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }

        /* Volume Profile column */
        .dom-row .vp {
            position: relative;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #1a1a24;
            overflow: hidden;
        }
        .dom-row .vp-bar {
            position: absolute;
            left: 0;
            top: 1px;
            bottom: 1px;
        }
        .dom-row.bid-level .vp-bar { background: #22c55e; }
        .dom-row.ask-level .vp-bar { background: #ef4444; }
        .dom-row.current-price .vp-bar { background: #eab308; }
        .dom-row .vp-value {
            position: relative;
            z-index: 1;
            font-size: 10px;
            color: #fff;
            font-family: 'Consolas', 'Monaco', monospace;
            font-weight: 600;
            text-shadow: 0 1px 2px rgba(0,0,0,0.8);
        }

        /* Quantity bars */
        .dom-row .qty-bar {
            position: absolute;
            top: 1px;
            bottom: 1px;
            opacity: 0.4;
        }
        .dom-row .bid-qty .qty-bar {
            right: 0;
            background: #22c55e;
        }
        .dom-row .ask-qty .qty-bar {
            left: 0;
            background: #ef4444;
        }
        .dom-row .qty-value {
            position: relative;
            z-index: 1;
        }

        /* Large orders highlighting */
        .dom-row.large-bid {
            background: #156015;
        }
        .dom-row.large-ask {
            background: #6b3d12;
        }
        .dom-row.xlarge-bid, .dom-row.xlarge-ask {
            background: #7c3aed;
        }

        /* Big order indicator */
        .big-order {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            font-size: 9px;
            margin-left: 2px;
        }
        .big-order.whale { background: #3b82f6; color: #fff; }
        .big-order.iceberg { background: #06b6d4; color: #fff; animation: pulse 1.5s infinite; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        /* MBO Order count badge */
        .mbo-badge {
            font-size: 8px;
            background: #f59e0b;
            color: #000;
            padding: 1px 3px;
            border-radius: 3px;
            margin-left: 2px;
        }

        /* Settings */
        .dom-settings {
            display: flex;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
        }
        .dom-settings label {
            font-size: 12px;
            color: #9ca3af;
            font-weight: 500;
        }
        .dom-settings select {
            background: #1a1a24;
            border: 1px solid #2a2a3d;
            border-radius: 8px;
            color: #fff;
            padding: 8px 32px 8px 12px;
            font-size: 13px;
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%239ca3af'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 8px center;
            background-size: 14px;
            cursor: pointer;
            transition: border-color 0.2s;
        }
        .dom-settings select:focus {
            outline: none;
            border-color: #8b5cf6;
        }
        .btn-reset {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            background: #7c3aed;
            border: none;
            border-radius: 6px;
            color: #fff;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-reset:hover {
            background: #8b5cf6;
            transform: translateY(-1px);
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

        /* Loading state */
        .loading-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            min-height: 300px;
            text-align: center;
            padding: 40px 20px;
        }
        .loading-bars {
            display: flex;
            align-items: end;
            gap: 6px;
            height: 60px;
            margin-bottom: 20px;
        }
        .loading-bars div {
            width: 8px;
            border-radius: 2px;
        }
        @keyframes barPulse1 { 0%, 100% { height: 100%; } 50% { height: 70%; } }
        @keyframes barPulse2 { 0%, 100% { height: 80%; } 50% { height: 100%; } }
        @keyframes barPulse3 { 0%, 100% { height: 90%; } 50% { height: 60%; } }
        @keyframes barPulse4 { 0%, 100% { height: 70%; } 50% { height: 95%; } }
        @keyframes barPulse5 { 0%, 100% { height: 100%; } 50% { height: 75%; } }

        /* Trade tape / Time & Sales */
        .trade-tape {
            background: #12121a;
            border: 1px solid #1a1a24;
            border-radius: 12px;
            display: flex;
            flex-direction: column;
            width: 280px;
            max-height: 100%;
        }
        .trade-tape-header {
            padding: 12px 16px;
            border-bottom: 1px solid #1a1a24;
            font-size: 14px;
            font-weight: 600;
            color: #fff;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .trade-tape-header .trade-count {
            font-size: 11px;
            color: #6b7280;
        }
        .trade-tape-body {
            flex: 1;
            overflow-y: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .trade-row {
            display: grid;
            grid-template-columns: 60px 70px 50px;
            padding: 4px 16px;
            border-bottom: 1px solid #0a0a0f;
        }
        .trade-row:hover {
            background: #1a1a24;
        }
        .trade-row .time { color: #6b7280; }
        .trade-row .price { font-weight: 600; }
        .trade-row .size { text-align: right; }
        .trade-row.buy { background: rgba(34, 197, 94, 0.1); }
        .trade-row.buy .price { color: #22c55e; }
        .trade-row.sell { background: rgba(239, 68, 68, 0.1); }
        .trade-row.sell .price { color: #ef4444; }
        .trade-row.large { font-weight: 700; }
        .trade-row.large.buy { background: rgba(34, 197, 94, 0.25); }
        .trade-row.large.sell { background: rgba(239, 68, 68, 0.25); }

        @media (max-width: 900px) {
            .content { flex-direction: column; padding: 8px; }
            .dom-panel { max-width: none; }
            .trade-tape { width: 100%; max-height: 300px; }
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
            <h2>Depth of Market</h2>
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
            <div class="dom-settings">
                <label>Symbol:</label>
                <select id="symbolSelect" onchange="changeSymbol(this.value)">
                    <option value="@ESH25" selected>ES (S&P 500)</option>
                    <option value="@NQH25">NQ (Nasdaq 100)</option>
                    <option value="QGC#">GC (Gold)</option>
                </select>
                <label>Levels:</label>
                <select id="levelCount" onchange="setLevelCount(this.value)">
                    <option value="20">20</option>
                    <option value="50" selected>50</option>
                    <option value="100">100</option>
                </select>
                <button class="btn-reset" onclick="centerOnCurrentPrice()" title="Center on current price">
                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    Center
                </button>
            </div>
        </div>
    </header>

    <div class="content">
        <div class="dom-panel" id="dom-panel">
            <div class="dom-panel-header">
                <h3 id="symbol-title">ES (S&P 500)</h3>
                <span class="provider" id="provider-badge">IQFeed</span>
            </div>
            <div class="dom-panel-body">
                <div class="price-info">
                    <span class="bid-info">Bid: <strong id="bid-price">--</strong></span>
                    <span class="spread-info">Spread: <strong id="spread">--</strong></span>
                    <span class="ask-info">Ask: <strong id="ask-price">--</strong></span>
                    <span class="last-info">Last: <strong id="last-price">--</strong></span>
                </div>
                <div class="dom-header">
                    <div>Ord</div>
                    <div>Bid</div>
                    <div>B Price</div>
                    <div>Price</div>
                    <div>A Price</div>
                    <div>Ask</div>
                    <div>VP</div>
                </div>
                <div class="dom-ladder" id="dom-ladder">
                    <div class="loading-state">
                        <div class="loading-bars">
                            <div style="background: linear-gradient(to top, #22c55e 60%, #1a1a24 60%); height: 100%; animation: barPulse1 1.2s ease-in-out infinite;"></div>
                            <div style="background: linear-gradient(to top, #ef4444 70%, #1a1a24 70%); height: 80%; animation: barPulse2 1.2s ease-in-out infinite;"></div>
                            <div style="background: linear-gradient(to top, #22c55e 50%, #1a1a24 50%); height: 90%; animation: barPulse3 1.2s ease-in-out infinite;"></div>
                            <div style="background: linear-gradient(to top, #22c55e 80%, #1a1a24 80%); height: 70%; animation: barPulse4 1.2s ease-in-out infinite;"></div>
                            <div style="background: linear-gradient(to top, #ef4444 40%, #1a1a24 40%); height: 100%; animation: barPulse5 1.2s ease-in-out infinite;"></div>
                        </div>
                        <div style="font-size: 16px; color: #9ca3af;">Connecting to IQFeed...</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Time & Sales / Trade Tape -->
        <div class="trade-tape">
            <div class="trade-tape-header">
                <span>Time & Sales</span>
                <span class="trade-count" id="tradeCount">0 trades</span>
            </div>
            <div class="trade-tape-body" id="tradeTape">
                <!-- Trades will be inserted here -->
            </div>
        </div>
    </div>

    <script>
        var currentSymbol = '@ESH25';
        var levelCount = 50;
        var autoCenter = true;
        var ws = null;
        var reconnectTimer = null;

        // Symbol configuration
        var symbolConfig = {
            '@ESH25': { tick: 0.25, decimals: 2, name: 'ES (S&P 500)', iqfeedSymbol: '@ESH25' },
            '@NQH25': { tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)', iqfeedSymbol: '@NQH25' },
            'QGC#': { tick: 0.10, decimals: 2, name: 'GC (Gold)', iqfeedSymbol: 'QGC#' }
        };

        // Order book state from Level 2 MBO data
        var orderBook = {
            bids: {},  // price -> { size, orders: count }
            asks: {},  // price -> { size, orders: count }
            bestBid: 0,
            bestAsk: 0
        };

        // Level 1 quote data
        var level1 = {
            bid: 0,
            bidSize: 0,
            ask: 0,
            askSize: 0,
            last: 0,
            lastSize: 0
        };

        // Trade history for time & sales
        var trades = [];
        var maxTrades = 100;

        // Volume profile accumulator
        var volumeProfile = {};

        // Data feed status
        var feedStatus = {
            level1: false,
            level2: false,
            mbo: false
        };

        function init() {
            connectWebSocket();

            // Prevent DOM ladder scroll from affecting page
            var domLadder = document.getElementById('dom-ladder');
            domLadder.addEventListener('wheel', function(e) {
                e.preventDefault();
                e.stopPropagation();
                autoCenter = false;
                domLadder.scrollTop += e.deltaY;
            }, { passive: false });
        }

        function connectWebSocket() {
            var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            // Connect to IQFeed bridge via nginx proxy
            var wsUrl = protocol + '//' + window.location.hostname + '/ws/iqfeed';

            updateStatus('', 'Connecting...');

            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                updateStatus('connected', 'Live');
                // Subscribe to current symbol
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
                            // Heartbeat response
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
            }
        }

        function handleTick(msg) {
            // Level 1 tick data
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            feedStatus.level1 = true;
            updateFeedIndicator('L1', true);

            level1.last = msg.price;
            level1.lastSize = msg.size;
            level1.bid = msg.bid || level1.bid;
            level1.ask = msg.ask || level1.ask;

            // Update price display
            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            document.getElementById('last-price').textContent = level1.last.toFixed(config.decimals);
            if (msg.bid) document.getElementById('bid-price').textContent = msg.bid.toFixed(config.decimals);
            if (msg.ask) document.getElementById('ask-price').textContent = msg.ask.toFixed(config.decimals);
            if (msg.bid && msg.ask) {
                document.getElementById('spread').textContent = (msg.ask - msg.bid).toFixed(config.decimals);
            }

            // Add to trade tape
            addTrade({
                time: new Date(),
                price: msg.price,
                size: msg.size,
                side: msg.price >= msg.ask ? 'buy' : (msg.price <= msg.bid ? 'sell' : 'neutral')
            });

            // Accumulate volume profile
            var priceKey = msg.price.toFixed(config.decimals);
            volumeProfile[priceKey] = (volumeProfile[priceKey] || 0) + msg.size;

            // Re-render ladder with latest data
            renderLadder();
        }

        function handleOrderbook(msg) {
            // Level 2 / MBO orderbook data
            if (msg.symbol !== getDisplaySymbol(currentSymbol)) return;

            feedStatus.level2 = true;
            feedStatus.mbo = true;
            updateFeedIndicator('L2', true);
            updateFeedIndicator('MBO', true);

            var data = msg.data;
            if (!data) return;

            // Update order book
            orderBook.bids = {};
            orderBook.asks = {};

            // Process bids (sorted descending by price)
            if (data.bids) {
                data.bids.forEach(function(level) {
                    var price = level[0];
                    var size = level[1];
                    orderBook.bids[price] = { size: size, orders: 1 };
                });
            }

            // Process asks (sorted ascending by price)
            if (data.asks) {
                data.asks.forEach(function(level) {
                    var price = level[0];
                    var size = level[1];
                    orderBook.asks[price] = { size: size, orders: 1 };
                });
            }

            orderBook.bestBid = data.best_bid || 0;
            orderBook.bestAsk = data.best_ask || 0;

            // Update display
            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            if (orderBook.bestBid) {
                document.getElementById('bid-price').textContent = orderBook.bestBid.toFixed(config.decimals);
            }
            if (orderBook.bestAsk) {
                document.getElementById('ask-price').textContent = orderBook.bestAsk.toFixed(config.decimals);
            }
            if (orderBook.bestBid && orderBook.bestAsk) {
                document.getElementById('spread').textContent = (orderBook.bestAsk - orderBook.bestBid).toFixed(config.decimals);
            }

            renderLadder();
        }

        function getDisplaySymbol(iqfeedSymbol) {
            // Map IQFeed symbols to display names used by the bridge
            var map = {
                '@ESH25': 'ES',
                '@NQH25': 'NQ',
                'QGC#': 'GC'
            };
            return map[iqfeedSymbol] || iqfeedSymbol;
        }

        function renderLadder() {
            var container = document.getElementById('dom-ladder');
            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };
            var tick = config.tick;
            var decimals = config.decimals;
            var levels = levelCount;
            var halfLevels = Math.floor(levels / 2);

            // Determine mid price
            var midPrice = 0;
            if (orderBook.bestBid && orderBook.bestAsk) {
                midPrice = (orderBook.bestBid + orderBook.bestAsk) / 2;
            } else if (level1.last) {
                midPrice = level1.last;
            } else {
                // No data yet
                return;
            }

            // Round mid price to tick
            midPrice = Math.round(midPrice / tick) * tick;

            // Find max sizes for scaling
            var maxBidSize = 0, maxAskSize = 0, maxVP = 0;
            Object.values(orderBook.bids).forEach(function(level) {
                if (level.size > maxBidSize) maxBidSize = level.size;
            });
            Object.values(orderBook.asks).forEach(function(level) {
                if (level.size > maxAskSize) maxAskSize = level.size;
            });
            Object.values(volumeProfile).forEach(function(vol) {
                if (vol > maxVP) maxVP = vol;
            });
            var maxSize = Math.max(maxBidSize, maxAskSize, 100);
            if (maxVP === 0) maxVP = 100;

            // Calculate average size for big order detection
            var allSizes = Object.values(orderBook.bids).map(function(l) { return l.size; })
                .concat(Object.values(orderBook.asks).map(function(l) { return l.size; }));
            var avgSize = allSizes.length > 0 ?
                allSizes.reduce(function(a, b) { return a + b; }, 0) / allSizes.length : 50;
            var bigOrderThreshold = avgSize * 3;
            var whaleThreshold = avgSize * 8;

            var html = '';

            // Generate price levels from high to low
            for (var i = halfLevels; i >= -halfLevels; i--) {
                var price = midPrice + (i * tick);
                var priceStr = price.toFixed(decimals);

                // Determine if this is bid or ask side
                var isBidLevel = price < midPrice;
                var isAskLevel = price > midPrice;
                var isCurrentPrice = Math.abs(price - midPrice) < tick / 2;
                var isLastTrade = level1.last && Math.abs(price - level1.last) < tick / 2;

                // Get order book data at this price
                var bidData = orderBook.bids[price] || null;
                var askData = orderBook.asks[price] || null;
                var bidSize = bidData ? bidData.size : 0;
                var askSize = askData ? askData.size : 0;
                var bidOrders = bidData ? bidData.orders : 0;
                var askOrders = askData ? askData.orders : 0;

                // Get volume profile
                var vpVol = volumeProfile[priceStr] || 0;
                var vpBarWidth = maxVP > 0 ? Math.min((vpVol / maxVP) * 100, 100) : 0;

                // Calculate bar widths
                var bidBarWidth = bidSize > 0 ? Math.min((bidSize / maxSize) * 100, 100) : 0;
                var askBarWidth = askSize > 0 ? Math.min((askSize / maxSize) * 100, 100) : 0;

                // Determine row class
                var rowClass = 'dom-row';
                if (isCurrentPrice) {
                    rowClass += ' current-price';
                } else if (isBidLevel) {
                    rowClass += ' bid-level';
                    if (bidSize > maxSize * 0.7) rowClass += ' xlarge-bid';
                    else if (bidSize > maxSize * 0.5) rowClass += ' large-bid';
                } else if (isAskLevel) {
                    rowClass += ' ask-level';
                    if (askSize > maxSize * 0.7) rowClass += ' xlarge-ask';
                    else if (askSize > maxSize * 0.5) rowClass += ' large-ask';
                }

                if (isLastTrade) {
                    rowClass += ' last-trade';
                }

                // Order count column (from MBO data)
                var orderCount = bidOrders + askOrders;
                var orderCountHtml = orderCount > 0 ?
                    '<span class="has-orders">' + orderCount + '</span>' : '';

                // Big order indicators
                var bidIndicator = '';
                if (bidSize >= whaleThreshold) bidIndicator = '<span class="big-order whale">W</span>';
                else if (bidSize >= bigOrderThreshold) bidIndicator = '<span class="big-order whale">B</span>';

                var askIndicator = '';
                if (askSize >= whaleThreshold) askIndicator = '<span class="big-order whale">W</span>';
                else if (askSize >= bigOrderThreshold) askIndicator = '<span class="big-order whale">B</span>';

                html += '<div class="' + rowClass + '">';

                // Order count column
                html += '<div class="orders-col">' + orderCountHtml + '</div>';

                // Bid qty with bar
                html += '<div class="bid-qty">';
                if (bidSize > 0) {
                    html += '<div class="qty-bar" style="width:' + bidBarWidth + '%"></div>';
                    html += '<span class="qty-value">' + bidSize.toFixed(0) + bidIndicator + '</span>';
                }
                html += '</div>';

                // Bid price column
                html += '<div class="bid-col">' + (isBidLevel && !isCurrentPrice && bidSize > 0 ? priceStr : '') + '</div>';

                // Center price column
                html += '<div class="price">' + priceStr + '</div>';

                // Ask price column
                html += '<div class="ask-col">' + (isAskLevel && !isCurrentPrice && askSize > 0 ? priceStr : '') + '</div>';

                // Ask qty with bar
                html += '<div class="ask-qty">';
                if (askSize > 0) {
                    html += '<div class="qty-bar" style="width:' + askBarWidth + '%"></div>';
                    html += '<span class="qty-value">' + askIndicator + askSize.toFixed(0) + '</span>';
                }
                html += '</div>';

                // Volume profile column
                html += '<div class="vp">';
                if (vpVol > 0) {
                    html += '<div class="vp-bar" style="width:' + vpBarWidth + '%"></div>';
                    html += '<span class="vp-value">' + vpVol + '</span>';
                }
                html += '</div>';

                html += '</div>';
            }

            container.innerHTML = html;

            // Auto-center on current price
            if (autoCenter) {
                var currentRow = container.querySelector('.current-price');
                if (currentRow) {
                    container.scrollTop = currentRow.offsetTop - (container.clientHeight / 2) + (currentRow.clientHeight / 2);
                }
            }
        }

        function addTrade(trade) {
            trades.unshift(trade);
            if (trades.length > maxTrades) {
                trades.pop();
            }
            renderTradeTape();
        }

        function renderTradeTape() {
            var container = document.getElementById('tradeTape');
            var config = symbolConfig[currentSymbol] || { decimals: 2 };

            // Calculate average size for highlighting large trades
            var avgSize = trades.length > 0 ?
                trades.reduce(function(sum, t) { return sum + t.size; }, 0) / trades.length : 50;
            var largeThreshold = avgSize * 3;

            var html = trades.slice(0, 50).map(function(trade) {
                var timeStr = trade.time.toLocaleTimeString();
                var isLarge = trade.size >= largeThreshold;
                var sideClass = trade.side === 'buy' ? 'buy' : (trade.side === 'sell' ? 'sell' : '');
                var largeClass = isLarge ? 'large' : '';

                return '<div class="trade-row ' + sideClass + ' ' + largeClass + '">' +
                    '<span class="time">' + timeStr + '</span>' +
                    '<span class="price">' + trade.price.toFixed(config.decimals) + '</span>' +
                    '<span class="size">' + trade.size + '</span>' +
                    '</div>';
            }).join('');

            container.innerHTML = html;
            document.getElementById('tradeCount').textContent = trades.length + ' trades';
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

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            var config = symbolConfig[symbol] || symbolConfig['@ESH25'];
            document.getElementById('symbol-title').textContent = config.name || symbol;
            document.getElementById('bid-price').textContent = '--';
            document.getElementById('ask-price').textContent = '--';
            document.getElementById('spread').textContent = '--';
            document.getElementById('last-price').textContent = '--';

            // Reset data
            orderBook = { bids: {}, asks: {}, bestBid: 0, bestAsk: 0 };
            level1 = { bid: 0, bidSize: 0, ask: 0, askSize: 0, last: 0, lastSize: 0 };
            trades = [];
            volumeProfile = {};
            resetFeedIndicators();

            // Show loading state
            var ladder = document.getElementById('dom-ladder');
            ladder.innerHTML = '<div class="loading-state">' +
                '<div class="loading-bars">' +
                '<div style="background: linear-gradient(to top, #22c55e 60%, #1a1a24 60%); height: 100%; animation: barPulse1 1.2s ease-in-out infinite;"></div>' +
                '<div style="background: linear-gradient(to top, #ef4444 70%, #1a1a24 70%); height: 80%; animation: barPulse2 1.2s ease-in-out infinite;"></div>' +
                '<div style="background: linear-gradient(to top, #22c55e 50%, #1a1a24 50%); height: 90%; animation: barPulse3 1.2s ease-in-out infinite;"></div>' +
                '<div style="background: linear-gradient(to top, #22c55e 80%, #1a1a24 80%); height: 70%; animation: barPulse4 1.2s ease-in-out infinite;"></div>' +
                '<div style="background: linear-gradient(to top, #ef4444 40%, #1a1a24 40%); height: 100%; animation: barPulse5 1.2s ease-in-out infinite;"></div>' +
                '</div>' +
                '<div style="font-size: 16px; color: #9ca3af;">Loading ' + symbol + '...</div>' +
                '</div>';

            // Resubscribe
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'subscribe',
                    symbol: currentSymbol
                }));
            }
        }

        function setLevelCount(count) {
            levelCount = parseInt(count);
            renderLadder();
        }

        function centerOnCurrentPrice() {
            autoCenter = true;
            var container = document.getElementById('dom-ladder');
            var currentRow = container.querySelector('.current-price');
            if (currentRow && container) {
                container.scrollTop = currentRow.offsetTop - (container.clientHeight / 2) + (currentRow.clientHeight / 2);
            }
        }

        // Initialize on load
        window.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>
