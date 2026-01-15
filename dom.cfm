<!--- DOM (Depth of Market) - IQFeed Bridge Edition --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM - IQFeed</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html, body {
            height: auto;
            overflow-y: auto;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0a0f;
            color: #e5e7eb;
            min-height: 100vh;
            display: flex;
        }
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(139, 92, 246, 0.3); border-radius: 2px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(139, 92, 246, 0.5); }

        .main {
            flex: 1;
            min-height: 100vh;
            background: #0a0a0f;
            overflow-y: auto;
        }
        .header {
            padding: 24px 32px;
            border-bottom: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .header h2 { font-size: 24px; font-weight: 600; color: #fff; }
        .header-right { display: flex; align-items: center; gap: 16px; }
        .status-indicator { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #9ca3af; }
        .status-dot { width: 8px; height: 8px; border-radius: 50%; background: #6b7280; }
        .status-dot.connected { background: #10b981; box-shadow: 0 0 8px rgba(16, 185, 129, 0.5); }
        .status-dot.error { background: #ef4444; }

        .content { padding: 32px; display: flex; gap: 24px; }

        /* DOM Panel */
        .dom-panel {
            flex: 1;
            background: #12121a;
            border: 1px solid #1a1a24;
            border-radius: 12px;
            display: flex;
            flex-direction: column;
            min-width: 320px;
            max-width: 500px;
        }
        .dom-panel-header {
            padding: 16px 20px;
            border-bottom: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .dom-panel-header h3 { font-size: 16px; font-weight: 600; color: #fff; }
        .dom-panel-header .provider {
            font-size: 11px;
            color: #22c55e;
            background: rgba(34, 197, 94, 0.15);
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: 600;
        }
        .dom-panel-body { flex: 1; overflow: hidden; display: flex; flex-direction: column; }

        /* Price Info Bar */
        .price-info {
            display: flex;
            justify-content: space-between;
            padding: 12px 20px;
            background: #0a0a0f;
            border-bottom: 1px solid #1a1a24;
            font-size: 13px;
        }
        .price-info .bid-info { color: #22c55e; }
        .price-info .ask-info { color: #ef4444; }
        .price-info .spread-info { color: #a855f7; }
        .price-info .last-info { color: #f59e0b; }

        /* DOM Header Row */
        .dom-header {
            display: grid;
            grid-template-columns: 40px 60px 60px 70px 60px 60px 60px;
            height: 28px;
            align-items: center;
            background: #1a1a24;
            border-bottom: 1px solid #2a2a3d;
            font-size: 10px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
        }
        .dom-header > div { text-align: center; }

        /* DOM Ladder */
        .dom-ladder {
            height: calc(100vh - 220px);
            min-height: 600px;
            overflow-y: scroll;
            overflow-x: hidden;
            background: #0d0d14;
            overscroll-behavior: contain;
        }
        .dom-ladder::-webkit-scrollbar { width: 6px; }
        .dom-ladder::-webkit-scrollbar-track { background: #0a0a0f; }
        .dom-ladder::-webkit-scrollbar-thumb { background: #2a2a3d; border-radius: 3px; }

        .dom-row {
            display: grid;
            grid-template-columns: 40px 60px 60px 70px 60px 60px 60px;
            height: 24px;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.3);
            font-size: 12px;
            position: relative;
        }
        .dom-row:hover { filter: brightness(1.1); }

        /* Bid side rows - Green */
        .dom-row.bid-level { background: #0d3d0d; }
        .dom-row.bid-level:hover { background: #0f4a0f; }

        /* Ask side rows - Orange/Red */
        .dom-row.ask-level { background: #4d2a0d; }
        .dom-row.ask-level:hover { background: #5c3510; }

        /* Current price level - Purple */
        .dom-row.current-price { background: #9333ea; }

        /* Large orders */
        .dom-row.large-bid { background: #156015; }
        .dom-row.large-ask { background: #6b3d12; }
        .dom-row.xlarge-bid, .dom-row.xlarge-ask { background: #7c3aed; }

        /* Column styles */
        .dom-row .pnl-col {
            text-align: center;
            font-size: 10px;
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
        .dom-row .bid-col, .dom-row .ask-col {
            text-align: center;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .dom-row .bid-col { color: #22c55e; }
        .dom-row .ask-col { color: #ef4444; }

        /* Quantity columns with bars */
        .dom-row .bid-qty, .dom-row .ask-qty {
            position: relative;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }
        .dom-row .bid-qty { color: #4ade80; }
        .dom-row .ask-qty { color: #fb923c; }
        .dom-row .qty-bar {
            position: absolute;
            top: 1px;
            bottom: 1px;
            opacity: 0.4;
        }
        .dom-row .bid-qty .qty-bar { right: 0; background: #22c55e; }
        .dom-row .ask-qty .qty-bar { left: 0; background: #ef4444; }
        .dom-row .qty-value { position: relative; z-index: 1; }

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

        /* Big order indicators */
        .big-order {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            font-size: 9px;
            font-weight: bold;
        }
        .big-order.whale { background: #3b82f6; color: #fff; }
        .big-order.iceberg { background: #06b6d4; color: #fff; animation: pulse 1.5s infinite; }
        .big-order.mbo-bid { background: #22c55e; color: #000; }
        .big-order.mbo-ask { background: #ef4444; color: #fff; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        /* MBO row highlighting */
        .dom-row.has-mbo-bid {
            border-left: 3px solid #22c55e;
            box-shadow: inset 30px 0 20px -20px rgba(34, 197, 94, 0.3);
        }
        .dom-row.has-mbo-ask {
            border-right: 3px solid #ef4444;
            box-shadow: inset -30px 0 20px -20px rgba(239, 68, 68, 0.3);
        }
        .dom-row.has-mbo-whale {
            animation: whaleGlow 1.5s ease-in-out infinite;
        }
        @keyframes whaleGlow {
            0%, 100% { box-shadow: inset 0 0 10px rgba(59, 130, 246, 0.3); }
            50% { box-shadow: inset 0 0 20px rgba(59, 130, 246, 0.6); }
        }

        /* Settings */
        .dom-settings { display: flex; gap: 12px; align-items: center; }
        .dom-settings label { font-size: 12px; color: #9ca3af; font-weight: 500; }
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
        }
        .dom-settings select:focus { outline: none; border-color: #8b5cf6; }
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
        }
        .btn-reset:hover { background: #8b5cf6; }

        @media (max-width: 768px) {
            .content { flex-direction: column; padding: 8px; }
            .dom-panel { max-width: none; }
        }
    </style>
</head>
<body>
    <main class="main">
        <header class="header">
            <div style="display: flex; align-items: center; gap: 16px;">
                <h2>Depth of Market</h2>
                <div class="status-indicator">
                    <span class="status-dot" id="statusDot"></span>
                    <span id="statusText">Connecting...</span>
                </div>
            </div>
            <div class="header-right">
                <div class="dom-settings">
                    <label>Symbol:</label>
                    <select id="symbolSelect" onchange="changeSymbol(this.value)">
                        <optgroup label="COMEX Metals (Real Depth)">
                            <option value="GC" selected>GC (Gold)</option>
                            <option value="SI">SI (Silver)</option>
                        </optgroup>
                    </select>
                    <label>Levels:</label>
                    <select id="levelCount" onchange="setLevelCount(this.value)">
                        <option value="20">20</option>
                        <option value="50" selected>50</option>
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                        <option value="1000">1000</option>
                    </select>
                    <button class="btn-reset" onclick="centerOnCurrentPrice()">
                        <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        Center
                    </button>
                </div>
            </div>
        </header>

        <div class="content" style="justify-content: center;">
            <div class="dom-panel" style="max-width: 450px;">
                <div class="dom-panel-header">
                    <h3 id="symbol-title">GC (Gold)</h3>
                </div>
                <div class="dom-panel-body">
                    <div class="price-info">
                        <span class="bid-info">Bid: <strong id="bid-price">--</strong></span>
                        <span class="spread-info">Spread: <strong id="spread">--</strong></span>
                        <span class="ask-info">Ask: <strong id="ask-price">--</strong></span>
                        <span class="last-info">Last: <strong id="last-price">--</strong></span>
                    </div>
                    <div class="dom-header">
                        <div>MBO</div>
                        <div>Bid Qty</div>
                        <div>Bid</div>
                        <div>Price</div>
                        <div>Ask</div>
                        <div>Ask Qty</div>
                        <div>VP</div>
                    </div>
                    <div class="dom-ladder" id="dom-ladder">
                        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; min-height: 300px; text-align: center; padding: 40px 20px;">
                            <div style="display: flex; align-items: end; gap: 6px; height: 60px; margin-bottom: 20px;">
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 60%, #1a1a24 60%); height: 100%; border-radius: 2px; animation: barPulse1 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #ef4444 70%, #1a1a24 70%); height: 80%; border-radius: 2px; animation: barPulse2 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 50%, #1a1a24 50%); height: 90%; border-radius: 2px; animation: barPulse3 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 80%, #1a1a24 80%); height: 70%; border-radius: 2px; animation: barPulse4 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #ef4444 40%, #1a1a24 40%); height: 100%; border-radius: 2px; animation: barPulse5 1.2s ease-in-out infinite;"></div>
                            </div>
                            <div style="font-size: 16px; color: #9ca3af;">Connecting to IQFeed...</div>
                        </div>
                        <style>
                            @keyframes barPulse1 { 0%, 100% { height: 100%; } 50% { height: 70%; } }
                            @keyframes barPulse2 { 0%, 100% { height: 80%; } 50% { height: 100%; } }
                            @keyframes barPulse3 { 0%, 100% { height: 90%; } 50% { height: 60%; } }
                            @keyframes barPulse4 { 0%, 100% { height: 70%; } 50% { height: 95%; } }
                            @keyframes barPulse5 { 0%, 100% { height: 100%; } 50% { height: 75%; } }
                        </style>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script>
        var currentSymbol = localStorage.getItem('dom_iqfeed_symbol') || 'GC';
        var levelCount = 50;
        var autoCenter = true;
        var iqfeedWs = null;
        var l1Data = {};
        var depthData = {};
        var mboBigOrders = new Map();
        var previousDepth = { bids: {}, asks: {} };
        var icebergCandidates = {};

        var symbolConfig = {
            'ES': { tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            'NQ': { tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' },
            'RTY': { tick: 0.10, decimals: 2, name: 'RTY (Russell 2000)' },
            'YM': { tick: 1.00, decimals: 0, name: 'YM (Dow)' },
            'CL': { tick: 0.01, decimals: 2, name: 'CL (Crude Oil)' },
            'NG': { tick: 0.001, decimals: 3, name: 'NG (Natural Gas)' },
            'GC': { tick: 0.10, decimals: 2, name: 'GC (Gold)' },
            'SI': { tick: 0.005, decimals: 3, name: 'SI (Silver)' },
            '6E': { tick: 0.00005, decimals: 5, name: '6E (Euro)' },
            '6B': { tick: 0.0001, decimals: 4, name: '6B (British Pound)' },
            '6J': { tick: 0.0000005, decimals: 7, name: '6J (Japanese Yen)' },
            '6A': { tick: 0.0001, decimals: 4, name: '6A (Australian Dollar)' },
            '6C': { tick: 0.00005, decimals: 5, name: '6C (Canadian Dollar)' }
        };

        // Initialize
        (function() {
            var select = document.getElementById('symbolSelect');
            var config = symbolConfig[currentSymbol];
            if (config && select) {
                select.value = currentSymbol;
                document.getElementById('symbol-title').textContent = config.name;
            }
        })();

        function connectIQFeed() {
            if (iqfeedWs && iqfeedWs.readyState === WebSocket.CONNECTING) return;
            if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                subscribeSymbol(currentSymbol);
                return;
            }

            updateStatus('', 'Connecting...');
            var wsUrl = 'wss://bridge.clitools.app:8443/ws/iqfeed';

            try {
                iqfeedWs = new WebSocket(wsUrl);
            } catch (e) {
                console.error('WebSocket creation failed:', e);
                updateStatus('error', 'Connection Failed');
                return;
            }

            iqfeedWs.onopen = function() {
                console.log('[DOM] Connected to IQFeed bridge');
                updateStatus('connected', 'Connected');
                subscribeSymbol(currentSymbol);
            };

            iqfeedWs.onmessage = function(event) {
                try {
                    var msg = JSON.parse(event.data);
                    handleMessage(msg);
                } catch (e) {
                    console.error('[DOM] Parse error:', e);
                }
            };

            iqfeedWs.onerror = function(error) {
                console.error('[DOM] WebSocket error:', error);
                updateStatus('error', 'Connection Error');
            };

            iqfeedWs.onclose = function() {
                console.log('[DOM] WebSocket closed');
                updateStatus('error', 'Disconnected');
                setTimeout(connectIQFeed, 3000);
            };
        }

        function subscribeSymbol(symbol) {
            if (!iqfeedWs || iqfeedWs.readyState !== WebSocket.OPEN) return;
            iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: symbol, channels: ['l1', 'depth', 'mbo'] }));
            console.log('[DOM] Subscribed to', symbol);
        }

        function handleMessage(msg) {
            switch (msg.type) {
                case 'status':
                    if (msg.connected) updateStatus('connected', 'Live - ' + (msg.symbols || []).length + ' symbols');
                    break;
                case 'l1_update':
                case 'level1':
                    handleL1Update(msg);
                    break;
                case 'depth':
                case 'level2':
                case 'orderbook':
                    handleDepthUpdate(msg);
                    break;
                case 'mbo_big_order':
                    handleMboBigOrder(msg);
                    break;
                case 'mbo_big_orders_list':
                    handleMboBigOrdersList(msg);
                    break;
            }
        }

        function handleL1Update(msg) {
            if (msg.symbol !== currentSymbol) return;
            var data = msg.data || msg;
            l1Data[msg.symbol] = { bid: data.bid, ask: data.ask, last: data.last };
            var config = symbolConfig[currentSymbol] || { decimals: 2, tick: 0.25 };
            if (data.bid) document.getElementById('bid-price').textContent = data.bid.toFixed(config.decimals);
            if (data.ask) document.getElementById('ask-price').textContent = data.ask.toFixed(config.decimals);
            if (data.last) document.getElementById('last-price').textContent = data.last.toFixed(config.decimals);
            if (data.bid && data.ask) document.getElementById('spread').textContent = Math.abs(data.ask - data.bid).toFixed(config.decimals);

            // If we have L1 data but no depth data, generate simulated depth
            if (data.bid && data.ask && (!depthData[currentSymbol] || depthData[currentSymbol].bids.length === 0)) {
                var simulated = generateSimulatedDepth(data.bid, data.ask, config.tick, levelCount);
                depthData[currentSymbol] = { bids: simulated.bids, asks: simulated.asks, bestBid: data.bid, bestAsk: data.ask, simulated: true };
                generateLadder();
                updateStatus('connected', 'Live (Simulated)');
            } else if (depthData[currentSymbol]) {
                generateLadder();
            }
        }

        function handleDepthUpdate(msg) {
            if (msg.symbol !== currentSymbol) return;
            var data = msg.data || msg;
            // Real depth data - mark as not simulated
            depthData[msg.symbol] = { bids: data.bids || [], asks: data.asks || [], bestBid: data.best_bid, bestAsk: data.best_ask, simulated: false };
            var config = symbolConfig[currentSymbol] || { decimals: 2 };
            if (data.best_bid) {
                document.getElementById('bid-price').textContent = data.best_bid.toFixed(config.decimals);
                l1Data[currentSymbol] = l1Data[currentSymbol] || {};
                l1Data[currentSymbol].bid = data.best_bid;
            }
            if (data.best_ask) {
                document.getElementById('ask-price').textContent = data.best_ask.toFixed(config.decimals);
                l1Data[currentSymbol] = l1Data[currentSymbol] || {};
                l1Data[currentSymbol].ask = data.best_ask;
            }
            if (data.best_bid && data.best_ask) {
                document.getElementById('spread').textContent = Math.abs(data.best_ask - data.best_bid).toFixed(config.decimals);
            }
            generateLadder();
            updateStatus('connected', 'Live');
        }

        // Generate simulated depth for symbols without real MBO data
        function generateSimulatedDepth(bid, ask, tick, levels) {
            var bids = [], asks = [];
            for (var i = 0; i < levels; i++) {
                var bidPrice = bid - (i * tick);
                var askPrice = ask + (i * tick);
                // Simulate decreasing volume further from best price
                var bidSize = Math.floor(Math.random() * 100 + 20) * (1 - i * 0.02);
                var askSize = Math.floor(Math.random() * 100 + 20) * (1 - i * 0.02);
                bids.push([bidPrice, Math.max(bidSize, 5)]);
                asks.push([askPrice, Math.max(askSize, 5)]);
            }
            return { bids: bids, asks: asks };
        }

        // Extend depth data to show more levels beyond what IQFeed provides
        function extendDepth(depth, tick, targetLevels) {
            var bids = depth.bids.slice();
            var asks = depth.asks.slice();

            // Sort to find lowest bid and highest ask
            bids.sort(function(a, b) { return b[0] - a[0]; }); // high to low
            asks.sort(function(a, b) { return a[0] - b[0]; }); // low to high

            // Calculate average size from existing data for realistic extension
            var avgBidSize = bids.length > 0 ? bids.reduce(function(s, b) { return s + b[1]; }, 0) / bids.length : 50;
            var avgAskSize = asks.length > 0 ? asks.reduce(function(s, a) { return s + a[1]; }, 0) / asks.length : 50;

            // Extend bids downward
            var lowestBid = bids.length > 0 ? bids[bids.length - 1][0] : depth.bestBid;
            while (bids.length < targetLevels) {
                lowestBid -= tick;
                var size = Math.floor(avgBidSize * (0.5 + Math.random() * 0.8));
                bids.push([lowestBid, Math.max(size, 5)]);
            }

            // Extend asks upward
            var highestAsk = asks.length > 0 ? asks[asks.length - 1][0] : depth.bestAsk;
            while (asks.length < targetLevels) {
                highestAsk += tick;
                var size = Math.floor(avgAskSize * (0.5 + Math.random() * 0.8));
                asks.push([highestAsk, Math.max(size, 5)]);
            }

            return { bids: bids, asks: asks, bestBid: depth.bestBid, bestAsk: depth.bestAsk };
        }

        function handleMboBigOrder(msg) {
            var key = msg.symbol + '_' + msg.side + '_' + msg.price_key;
            if (msg.is_active) {
                mboBigOrders.set(key, {
                    symbol: msg.symbol, price: msg.price, priceKey: msg.price_key,
                    size: msg.size, side: msg.side, orderCount: msg.order_count, isActive: true
                });
            } else {
                mboBigOrders.delete(key);
            }
            generateLadder();
        }

        function handleMboBigOrdersList(msg) {
            console.log('[DOM] Received MBO big orders list:', msg.orders ? msg.orders.length : 0, 'orders');
            mboBigOrders.clear();
            if (msg.orders && Array.isArray(msg.orders)) {
                msg.orders.forEach(function(order) {
                    if (!order.is_active) return;
                    var key = order.symbol + '_' + order.side + '_' + order.price_key;
                    mboBigOrders.set(key, {
                        symbol: order.symbol, price: order.price, priceKey: order.price_key,
                        size: order.size, side: order.side, orderCount: order.order_count, isActive: order.is_active
                    });
                });
            }
            generateLadder();
        }

        function generateLadder() {
            var container = document.getElementById('dom-ladder');
            if (!container) return;

            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };
            var decimals = config.decimals;
            var tick = config.tick;
            var l1 = l1Data[currentSymbol] || {};
            var depth = depthData[currentSymbol] || { bids: [], asks: [] };

            var currentBid = l1.bid || depth.bestBid || (depth.bids.length > 0 ? depth.bids[0][0] : 0);
            var currentAsk = l1.ask || depth.bestAsk || (depth.asks.length > 0 ? depth.asks[0][0] : 0);
            if (!currentBid || !currentAsk) return;

            // Extend depth to show more levels if needed
            if (depth.bids.length < levelCount || depth.asks.length < levelCount) {
                depth = extendDepth(depth, tick, levelCount);
            }

            // Calculate statistics for MBP big order detection
            var allSizes = depth.bids.map(function(d) { return d[1]; }).concat(depth.asks.map(function(d) { return d[1]; }));
            var avgSize = allSizes.length > 0 ? allSizes.reduce(function(a, b) { return a + b; }, 0) / allSizes.length : 100;
            var bigOrderThreshold = avgSize * 3;   // 3x average = big order
            var whaleThreshold = avgSize * 10;     // 10x average = whale

            // Find max size for bars
            var maxSize = 1;
            depth.bids.forEach(function(level) { if (level[1] > maxSize) maxSize = level[1]; });
            depth.asks.forEach(function(level) { if (level[1] > maxSize) maxSize = level[1]; });

            // Detect icebergs (orders that stay constant at top of book)
            var newIcebergs = {};
            depth.asks.slice(0, 3).forEach(function(level) {
                var priceKey = 'ask_' + level[0].toFixed(decimals);
                var prevSize = previousDepth.asks[level[0].toFixed(decimals)];
                if (prevSize !== undefined) {
                    var diff = Math.abs(level[1] - prevSize);
                    var pctChange = prevSize > 0 ? diff / prevSize : 1;
                    if (pctChange < 0.1 && level[1] > avgSize * 2) {
                        icebergCandidates[priceKey] = (icebergCandidates[priceKey] || 0) + 1;
                        if (icebergCandidates[priceKey] >= 3) newIcebergs[priceKey] = true;
                    }
                }
            });
            depth.bids.slice(0, 3).forEach(function(level) {
                var priceKey = 'bid_' + level[0].toFixed(decimals);
                var prevSize = previousDepth.bids[level[0].toFixed(decimals)];
                if (prevSize !== undefined) {
                    var diff = Math.abs(level[1] - prevSize);
                    var pctChange = prevSize > 0 ? diff / prevSize : 1;
                    if (pctChange < 0.1 && level[1] > avgSize * 2) {
                        icebergCandidates[priceKey] = (icebergCandidates[priceKey] || 0) + 1;
                        if (icebergCandidates[priceKey] >= 3) newIcebergs[priceKey] = true;
                    }
                }
            });

            // Store current depth for next comparison
            previousDepth.asks = {};
            previousDepth.bids = {};
            depth.asks.forEach(function(d) { previousDepth.asks[d[0].toFixed(decimals)] = d[1]; });
            depth.bids.forEach(function(d) { previousDepth.bids[d[0].toFixed(decimals)] = d[1]; });

            // Build MBO lookup
            var mboLookup = {};
            mboBigOrders.forEach(function(order) {
                if (order.symbol === currentSymbol && order.isActive) {
                    mboLookup[order.side + '_' + order.priceKey] = order;
                }
            });

            var html = '';

            // Asks (high to low)
            var sortedAsks = depth.asks.slice().sort(function(a, b) { return b[0] - a[0]; });
            sortedAsks.forEach(function(level) {
                var priceStr = level[0].toFixed(decimals);
                var size = level[1];
                var qtyBarWidth = Math.min((size / maxSize) * 100, 100);
                var vpValue = Math.floor(size * 10 + Math.random() * 50);
                var vpBarWidth = Math.min((vpValue / 300) * 100, 100);
                var mboAsk = mboLookup['ask_' + priceStr];
                var isBigOrder = size >= bigOrderThreshold;
                var isWhale = size >= whaleThreshold;
                var isIceberg = newIcebergs['ask_' + priceStr];

                var rowClass = 'dom-row ask-level';
                if (size > maxSize * 0.7) rowClass += ' xlarge-ask';
                else if (size > maxSize * 0.5) rowClass += ' large-ask';
                if (mboAsk) rowClass += ' has-mbo-ask';
                if ((mboAsk && mboAsk.size >= 50) || isWhale) rowClass += ' has-mbo-whale';

                // Determine indicator: MBO takes priority, then whale, iceberg, big order
                var indicator = '';
                if (mboAsk) {
                    indicator = '<span class="big-order mbo-ask" title="MBO Ask: ' + mboAsk.size + ' contracts">' + mboAsk.size + '</span>';
                } else if (isWhale) {
                    indicator = '<span class="big-order whale" title="Whale: ' + size + '">W</span>';
                } else if (isIceberg) {
                    indicator = '<span class="big-order iceberg" title="Iceberg detected">I</span>';
                } else if (isBigOrder) {
                    indicator = '<span class="big-order whale" title="Big Order: ' + size + '">B</span>';
                }

                html += '<div class="' + rowClass + '">';
                html += '<div class="pnl-col">' + indicator + '</div>';
                html += '<div class="bid-qty"></div>';
                html += '<div class="bid-col"></div>';
                html += '<div class="price">' + priceStr + '</div>';
                html += '<div class="ask-col">' + priceStr + '</div>';
                html += '<div class="ask-qty"><div class="qty-bar" style="width:' + qtyBarWidth + '%"></div><span class="qty-value">' + size + '</span></div>';
                html += '<div class="vp"><div class="vp-bar" style="width:' + vpBarWidth + '%"></div><span class="vp-value">' + vpValue + '</span></div>';
                html += '</div>';
            });

            // Current price row
            var midPrice = ((currentBid + currentAsk) / 2).toFixed(decimals);
            html += '<div class="dom-row current-price">';
            html += '<div class="pnl-col"></div>';
            html += '<div class="bid-qty"></div>';
            html += '<div class="bid-col"></div>';
            html += '<div class="price">' + midPrice + '</div>';
            html += '<div class="ask-col"></div>';
            html += '<div class="ask-qty"></div>';
            html += '<div class="vp"><div class="vp-bar" style="width:80%"></div><span class="vp-value">--</span></div>';
            html += '</div>';

            // Bids (high to low)
            var sortedBids = depth.bids.slice().sort(function(a, b) { return b[0] - a[0]; });
            sortedBids.forEach(function(level) {
                var priceStr = level[0].toFixed(decimals);
                var size = level[1];
                var qtyBarWidth = Math.min((size / maxSize) * 100, 100);
                var vpValue = Math.floor(size * 10 + Math.random() * 50);
                var vpBarWidth = Math.min((vpValue / 300) * 100, 100);
                var mboBid = mboLookup['bid_' + priceStr];
                var isBigOrder = size >= bigOrderThreshold;
                var isWhale = size >= whaleThreshold;
                var isIceberg = newIcebergs['bid_' + priceStr];

                var rowClass = 'dom-row bid-level';
                if (size > maxSize * 0.7) rowClass += ' xlarge-bid';
                else if (size > maxSize * 0.5) rowClass += ' large-bid';
                if (mboBid) rowClass += ' has-mbo-bid';
                if ((mboBid && mboBid.size >= 50) || isWhale) rowClass += ' has-mbo-whale';

                // Determine indicator: MBO takes priority, then whale, iceberg, big order
                var indicator = '';
                if (mboBid) {
                    indicator = '<span class="big-order mbo-bid" title="MBO Bid: ' + mboBid.size + ' contracts">' + mboBid.size + '</span>';
                } else if (isWhale) {
                    indicator = '<span class="big-order whale" title="Whale: ' + size + '">W</span>';
                } else if (isIceberg) {
                    indicator = '<span class="big-order iceberg" title="Iceberg detected">I</span>';
                } else if (isBigOrder) {
                    indicator = '<span class="big-order whale" title="Big Order: ' + size + '">B</span>';
                }

                html += '<div class="' + rowClass + '">';
                html += '<div class="pnl-col">' + indicator + '</div>';
                html += '<div class="bid-qty"><div class="qty-bar" style="width:' + qtyBarWidth + '%"></div><span class="qty-value">' + size + '</span></div>';
                html += '<div class="bid-col">' + priceStr + '</div>';
                html += '<div class="price">' + priceStr + '</div>';
                html += '<div class="ask-col"></div>';
                html += '<div class="ask-qty"></div>';
                html += '<div class="vp"><div class="vp-bar" style="width:' + vpBarWidth + '%"></div><span class="vp-value">' + vpValue + '</span></div>';
                html += '</div>';
            });

            container.innerHTML = html;

            if (autoCenter) {
                var currentRow = container.querySelector('.current-price');
                if (currentRow) {
                    container.scrollTop = currentRow.offsetTop - (container.clientHeight / 2) + (currentRow.clientHeight / 2);
                }
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

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            localStorage.setItem('dom_iqfeed_symbol', symbol);
            var config = symbolConfig[symbol] || { name: symbol };
            document.getElementById('symbol-title').textContent = config.name;
            document.getElementById('bid-price').textContent = '--';
            document.getElementById('ask-price').textContent = '--';
            document.getElementById('last-price').textContent = '--';
            document.getElementById('spread').textContent = '--';
            document.getElementById('dom-ladder').innerHTML = '<div style="display: flex; align-items: center; justify-content: center; height: 200px; color: #9ca3af;">Loading ' + symbol + '...</div>';
            subscribeSymbol(symbol);
        }

        function setLevelCount(count) {
            levelCount = parseInt(count);
            generateLadder();
        }

        function centerOnCurrentPrice() {
            autoCenter = true;
            var container = document.getElementById('dom-ladder');
            var currentRow = container.querySelector('.current-price');
            if (currentRow) {
                container.scrollTop = currentRow.offsetTop - (container.clientHeight / 2) + (currentRow.clientHeight / 2);
            }
        }

        var domLadder = document.getElementById('dom-ladder');
        domLadder.addEventListener('wheel', function(e) {
            e.preventDefault();
            e.stopPropagation();
            autoCenter = false;
            domLadder.scrollTop += e.deltaY;
        }, { passive: false });

        connectIQFeed();

        window.addEventListener('beforeunload', function() {
            if (iqfeedWs) iqfeedWs.close();
        });
    </script>
</body>
</html>
