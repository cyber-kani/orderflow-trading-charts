<!--- DOM (Depth of Market) Module - IQFeed Version --->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM - IQFeed v1</title>
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
        /* Custom scrollbar - matches sidebar theme */
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
        .header h2 {
            font-size: 24px;
            font-weight: 600;
            color: #fff;
        }
        .header p {
            color: #9ca3af;
            margin-top: 4px;
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

        .content {
            padding: 32px;
            display: flex;
            gap: 24px;
        }

        /* DOM Panel - Card Style */
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

        /* DOM Header Row */
        .dom-header {
            display: grid;
            grid-template-columns: 40px 50px 60px 70px 60px 50px 60px;
            height: 28px;
            align-items: center;
            background: #1a1a24;
            border-bottom: 1px solid #2a2a3d;
            font-size: 11px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
        }
        .dom-header > div {
            text-align: center;
        }

        /* DOM Ladder */
        .dom-ladder {
            height: 800px;
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
            grid-template-columns: 40px 50px 60px 70px 60px 50px 60px;
            height: 24px;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.3);
            font-size: 12px;
            position: relative;
        }
        .dom-row:hover {
            filter: brightness(1.1);
        }

        /* Bid side rows (below current price) - Green like screenshot */
        .dom-row.bid-level {
            background: #0d3d0d;
        }
        .dom-row.bid-level:hover {
            background: #0f4a0f;
        }

        /* Ask side rows (above current price) - Orange/brown like screenshot */
        .dom-row.ask-level {
            background: #4d2a0d;
        }
        .dom-row.ask-level:hover {
            background: #5c3510;
        }

        /* Current price level - Pink/magenta like screenshot */
        .dom-row.current-price {
            background: #9333ea;
        }

        .dom-row .bid-size {
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
        .dom-row .ask-size {
            text-align: center;
            color: #f87171;
            font-weight: 600;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 11px;
        }

        /* P&L column */
        .dom-row .pnl-col {
            text-align: center;
            font-size: 10px;
            color: #6b7280;
        }

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
        .dom-row .bid-qty {
            color: #4ade80;
        }
        .dom-row .ask-qty {
            color: #fb923c;
        }
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

        /* Volume Profile column - Orange bars like screenshot */
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
        .dom-row.bid-level .vp-bar {
            background: #22c55e;
        }
        .dom-row.ask-level .vp-bar {
            background: #ef4444;
        }
        .dom-row.current-price .vp-bar {
            background: #eab308;
        }
        .dom-row .vp-value {
            position: relative;
            z-index: 1;
            font-size: 11px;
            color: #fff;
            font-family: 'Consolas', 'Monaco', monospace;
            font-weight: 600;
            text-shadow: 0 1px 2px rgba(0,0,0,0.8);
        }

        /* Big order indicator */
        .big-order {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            font-size: 10px;
            margin-left: 2px;
        }
        .big-order.whale {
            background: #3b82f6;
            color: #fff;
        }
        .big-order.iceberg {
            background: #06b6d4;
            color: #fff;
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        /* Large orders - brighter colors like screenshot */
        .dom-row.large-bid {
            background: #156015;
        }
        .dom-row.large-ask {
            background: #6b3d12;
        }
        .dom-row.xlarge-bid, .dom-row.xlarge-ask {
            background: #7c3aed;
        }

        /* Buy/Sell Buttons */
        .dom-actions {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            padding: 16px 20px;
            background: #0a0a0f;
            border-top: 1px solid #1a1a24;
        }
        .btn-buy, .btn-sell {
            padding: 12px 16px;
            border: none;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .btn-buy {
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: #fff;
        }
        .btn-buy:hover {
            background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
            transform: translateY(-1px);
        }
        .btn-sell {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: #fff;
        }
        .btn-sell:hover {
            background: linear-gradient(135deg, #f87171 0%, #ef4444 100%);
            transform: translateY(-1px);
        }

        /* Settings */
        .dom-settings {
            display: flex;
            gap: 12px;
            align-items: center;
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
        .dom-settings select option {
            background: #1a1a24;
            color: #fff;
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

        /* Not configured state */
        .not-configured {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #6b7280;
            padding: 40px;
            text-align: center;
        }
        .not-configured svg {
            width: 48px;
            height: 48px;
            margin-bottom: 16px;
            opacity: 0.5;
        }
        .not-configured h4 {
            color: #9ca3af;
            margin-bottom: 8px;
            font-size: 16px;
            font-weight: 600;
        }
        .not-configured p {
            font-size: 13px;
            line-height: 1.5;
        }

        @media (max-width: 768px) {
            .main { margin-left: 0; }
            .content { flex-direction: column; padding: 8px; }
            .dom-panel { max-width: none; }
        }
    </style>
</head>
<body>
    <main class="main">
        <header class="header" id="headerPanel">
            <div style="display: flex; align-items: center; gap: 16px;">
                <h2>Depth of Market (IQFeed)</h2>
                <div class="status-indicator">
                    <span class="status-dot" id="statusDot"></span>
                    <span id="statusText"></span>
                </div>
            </div>
            <div class="header-right">
                <div class="dom-settings">
                    <label>Symbol:</label>
                    <select id="symbolSelect" onchange="changeSymbol(this.value)">
                        <optgroup label="Futures">
                            <option value="NQ" selected>NQ (Nasdaq 100)</option>
                            <option value="ES">ES (S&P 500)</option>
                            <option value="CL">CL (Crude Oil)</option>
                            <option value="GC">GC (Gold)</option>
                            <option value="MGC">MGC (Micro Gold)</option>
                            <option value="SI">SI (Silver)</option>
                        </optgroup>
                        <optgroup label="Crypto">
                            <option value="BTCUSDT">BTC (Bitcoin)</option>
                            <option value="ETHUSDT">ETH (Ethereum)</option>
                        </optgroup>
                    </select>
                    <label>Levels:</label>
                    <select id="levelCount" onchange="setLevelCount(this.value)">
                        <option value="10">10</option>
                        <option value="20">20</option>
                        <option value="50" selected>50</option>
                        <option value="100">100</option>
                        <option value="500">500</option>
                        <option value="1000">1000</option>
                    </select>
                    <label>Refresh:</label>
                    <select id="refreshInterval" onchange="setRefreshInterval(this.value)">
                        <option value="500">500ms</option>
                        <option value="1000" selected>1s</option>
                        <option value="2000">2s</option>
                        <option value="5000">5s</option>
                    </select>
                    <button class="btn-reset" onclick="centerOnCurrentPrice()" title="Center on current price">
                        <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        Reset
                    </button>
                </div>
            </div>
        </header>

        <div class="content" style="justify-content: center;">
            <!--- Single DOM Panel --->
            <div class="dom-panel" id="dom-panel" style="max-width: 450px;">
                <div class="dom-panel-header">
                    <h3 id="symbol-title">NQ (Nasdaq 100)</h3>
                </div>
                <div class="dom-panel-body">
                    <div class="price-info">
                        <span class="bid-info">Bid: <strong id="bid-price">--</strong></span>
                        <span class="spread-info">Spread: <strong id="spread">--</strong></span>
                        <span class="ask-info">Ask: <strong id="ask-price">--</strong></span>
                    </div>
                    <div class="dom-header">
                        <div>P&L</div>
                        <div>B</div>
                        <div>Bid</div>
                        <div>Price</div>
                        <div>Ask</div>
                        <div>S</div>
                        <div>VP</div>
                    </div>
                    <div class="dom-ladder" id="dom-ladder">
                        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; min-height: 300px; text-align: center; padding: 40px 20px;">
                            <!-- Animated Candlestick Bars -->
                            <div style="display: flex; align-items: end; gap: 6px; height: 60px; margin-bottom: 20px;">
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 60%, #1a1a24 60%); height: 100%; border-radius: 2px; animation: barPulse1 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #ef4444 70%, #1a1a24 70%); height: 80%; border-radius: 2px; animation: barPulse2 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 50%, #1a1a24 50%); height: 90%; border-radius: 2px; animation: barPulse3 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #22c55e 80%, #1a1a24 80%); height: 70%; border-radius: 2px; animation: barPulse4 1.2s ease-in-out infinite;"></div>
                                <div style="width: 8px; background: linear-gradient(to top, #ef4444 40%, #1a1a24 40%); height: 100%; border-radius: 2px; animation: barPulse5 1.2s ease-in-out infinite;"></div>
                            </div>
                            <div style="font-size: 16px; color: #9ca3af;">Connecting to market data...</div>
                        </div>
                        <style>
                            @keyframes barPulse1 { 0%, 100% { height: 100%; } 50% { height: 70%; } }
                            @keyframes barPulse2 { 0%, 100% { height: 80%; } 50% { height: 100%; } }
                            @keyframes barPulse3 { 0%, 100% { height: 90%; } 50% { height: 60%; } }
                            @keyframes barPulse4 { 0%, 100% { height: 70%; } 50% { height: 95%; } }
                            @keyframes barPulse5 { 0%, 100% { height: 100%; } 50% { height: 75%; } }
                        </style>
                    </div>
                    <div class="dom-actions">
                        <button class="btn-buy" onclick="placeBuy()">BUY</button>
                        <button class="btn-sell" onclick="placeSell()">SELL</button>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script>
        // Configuration
        var levelCount = 50;
        var currentSymbol = localStorage.getItem('dom_iqfeed_symbol') || 'GC';
        var iqfeedWs = null;
        var autoCenter = true;
        var previousDepth = { bids: {}, asks: {} };
        var icebergCandidates = {};

        // Symbol configurations - CME Futures via IQFeed
        var symbolConfig = {
            'GC': { code: 'GC', tick: 0.10, decimals: 2, name: 'GC (Gold Futures)' },
            'SI': { code: 'SI', tick: 0.005, decimals: 3, name: 'SI (Silver Futures)' },
            'CL': { code: 'CL', tick: 0.01, decimals: 2, name: 'CL (Crude Oil)' },
            'ES': { code: 'ES', tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            'NQ': { code: 'NQ', tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' }
        };

        // Initialize on page load
        function init() {
            var select = document.getElementById('symbolSelect');
            var config = symbolConfig[currentSymbol];
            if (config) {
                select.value = currentSymbol;
                document.getElementById('symbol-title').textContent = config.name;
            }
            connectIQFeed();

            // Disable auto-center on manual scroll
            var domLadder = document.getElementById('dom-ladder');
            domLadder.addEventListener('wheel', function(e) {
                e.preventDefault();
                autoCenter = false;
                domLadder.scrollTop += e.deltaY;
            }, { passive: false });
        }

        function updateStatus(status, text) {
            var dot = document.getElementById('statusDot');
            var textEl = document.getElementById('statusText');
            dot.className = 'status-dot';
            if (status === 'connected') dot.classList.add('connected');
            else if (status === 'error') dot.classList.add('error');
            textEl.textContent = text;
        }

        // Connect to IQFeed WebSocket bridge
        function connectIQFeed() {
            if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: currentSymbol }));
                return;
            }
            if (iqfeedWs && iqfeedWs.readyState === WebSocket.CONNECTING) {
                return;
            }

            var wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            var wsUrl = wsProtocol + '//' + window.location.host + '/ws/iqfeed';

            updateStatus('', 'Connecting...');

            try {
                iqfeedWs = new WebSocket(wsUrl);

                iqfeedWs.onopen = function() {
                    updateStatus('connected', 'Live (IQFeed)');
                    setTimeout(function() {
                        if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                            iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: currentSymbol }));
                        }
                    }, 10);
                };

                iqfeedWs.onmessage = function(event) {
                    try {
                        var msg = JSON.parse(event.data);
                        if (msg.type === 'orderbook' && msg.symbol === currentSymbol) {
                            processOrderbook(msg.data);
                        } else if (msg.type === 'tick' && msg.symbol === currentSymbol) {
                            processTick(msg);
                        } else if (msg.type === 'market_closed') {
                            showMarketClosed();
                        }
                    } catch (e) {
                        console.error('Error parsing message:', e);
                    }
                };

                iqfeedWs.onerror = function(error) {
                    console.error('IQFeed WebSocket error:', error);
                    updateStatus('error', 'Connection Error');
                };

                iqfeedWs.onclose = function() {
                    updateStatus('error', 'Disconnected');
                    setTimeout(connectIQFeed, 3000);
                };
            } catch (e) {
                console.error('Failed to connect to IQFeed:', e);
                updateStatus('error', 'Connection Failed');
            }
        }

        function processOrderbook(data) {
            if (!data) return;

            var config = symbolConfig[currentSymbol];
            var decimals = config ? config.decimals : 2;
            var tick = config ? config.tick : 0.10;

            var bids = data.bids || [];
            var asks = data.asks || [];

            if (bids.length === 0 && asks.length === 0) return;

            var bestBid = bids.length > 0 ? bids[0][0] : 0;
            var bestAsk = asks.length > 0 ? asks[0][0] : 0;
            var spread = bestAsk - bestBid;

            document.getElementById('bid-price').textContent = bestBid.toFixed(decimals);
            document.getElementById('ask-price').textContent = bestAsk.toFixed(decimals);
            document.getElementById('spread').textContent = spread.toFixed(decimals);

            var bidDepth = bids.map(function(level) { return { price: level[0], size: level[1] }; });
            var askDepth = asks.map(function(level) { return { price: level[0], size: level[1] }; });

            // Generate simulated depth if limited
            if (bidDepth.length < 10) {
                bidDepth = bidDepth.concat(generateSimulatedDepth(bestBid, tick, 'bid', 25));
            }
            if (askDepth.length < 10) {
                askDepth = askDepth.concat(generateSimulatedDepth(bestAsk, tick, 'ask', 25));
            }

            generateLadder(bestBid, bestAsk, bidDepth, askDepth);
        }

        function processTick(msg) {
            var config = symbolConfig[currentSymbol];
            var decimals = config ? config.decimals : 2;
            var tick = config ? config.tick : 0.10;

            var bestBid = msg.bid || 0;
            var bestAsk = msg.ask || 0;

            if (bestBid > 0 && bestAsk > 0) {
                var spread = bestAsk - bestBid;
                document.getElementById('bid-price').textContent = bestBid.toFixed(decimals);
                document.getElementById('ask-price').textContent = bestAsk.toFixed(decimals);
                document.getElementById('spread').textContent = spread.toFixed(decimals);

                var bidDepth = generateSimulatedDepth(bestBid, tick, 'bid', 25);
                var askDepth = generateSimulatedDepth(bestAsk, tick, 'ask', 25);
                generateLadder(bestBid, bestAsk, bidDepth, askDepth);
            }
        }

        function generateSimulatedDepth(price, tick, side, levels) {
            var depth = [];
            for (var i = 0; i < levels; i++) {
                var offset = (i + 1) * tick;
                var levelPrice = side === 'bid' ? price - offset : price + offset;
                var volume = Math.round(Math.random() * 100 + 10) * (1 - i * 0.03);
                depth.push({ price: levelPrice, size: Math.max(volume, 5) });
            }
            return depth;
        }

        function generateLadder(currentBid, currentAsk, bidDepth, askDepth) {
            var container = document.getElementById('dom-ladder');
            if (!container) return;

            var config = symbolConfig[currentSymbol];
            var decimals = config ? config.decimals : 2;

            var allSizes = bidDepth.map(function(d) { return d.size; }).concat(askDepth.map(function(d) { return d.size; }));
            var avgSize = allSizes.reduce(function(a, b) { return a + b; }, 0) / allSizes.length;
            var bigOrderThreshold = avgSize * 3;
            var whaleThreshold = avgSize * 10;

            var maxBidSize = 0, maxAskSize = 0;
            bidDepth.forEach(function(d) { if (d.size > maxBidSize) maxBidSize = d.size; });
            askDepth.forEach(function(d) { if (d.size > maxAskSize) maxAskSize = d.size; });
            var maxSize = Math.max(maxBidSize, maxAskSize, 1);

            var html = '';

            // Asks (high to low)
            var sortedAsks = askDepth.slice().sort(function(a, b) { return b.price - a.price; });
            sortedAsks.forEach(function(level) {
                var priceStr = level.price.toFixed(decimals);
                var qtyStr = level.size.toFixed(2);
                var qtyBarWidth = Math.min((level.size / maxSize) * 100, 100);
                var vpValue = Math.floor(level.size * 10 + Math.random() * 50);
                var vpBarWidth = Math.min((vpValue / 300) * 100, 100);
                var isLarge = level.size > maxSize * 0.5;
                var isXLarge = level.size > maxSize * 0.7;
                var isBigOrder = level.size >= bigOrderThreshold;
                var isWhale = level.size >= whaleThreshold;

                var rowClass = 'dom-row ask-level';
                if (isXLarge) rowClass += ' xlarge-ask';
                else if (isLarge) rowClass += ' large-ask';

                var indicator = '';
                if (isWhale) indicator = '<span class="big-order whale" title="Whale">W</span>';
                else if (isBigOrder) indicator = '<span class="big-order whale" title="Big Order">B</span>';

                html += '<div class="' + rowClass + '">';
                html += '<div class="pnl-col">' + indicator + '</div>';
                html += '<div class="bid-qty"></div>';
                html += '<div class="bid-col"></div>';
                html += '<div class="price">' + priceStr + '</div>';
                html += '<div class="ask-col">' + priceStr + '</div>';
                html += '<div class="ask-qty"><div class="qty-bar" style="width:' + qtyBarWidth + '%"></div><span class="qty-value">' + qtyStr + '</span></div>';
                html += '<div class="vp"><div class="vp-bar" style="width:' + vpBarWidth + '%"></div><span class="vp-value">' + vpValue + '</span></div>';
                html += '</div>';
            });

            // Current price row
            var midPrice = ((currentBid + currentAsk) / 2).toFixed(decimals);
            var midVP = Math.floor(Math.random() * 100 + 200);
            html += '<div class="dom-row current-price">';
            html += '<div class="pnl-col"></div><div class="bid-qty"></div><div class="bid-col"></div>';
            html += '<div class="price">' + midPrice + '</div>';
            html += '<div class="ask-col"></div><div class="ask-qty"></div>';
            html += '<div class="vp"><div class="vp-bar" style="width:80%"></div><span class="vp-value">' + midVP + '</span></div>';
            html += '</div>';

            // Bids (high to low)
            var sortedBids = bidDepth.slice().sort(function(a, b) { return b.price - a.price; });
            sortedBids.forEach(function(level) {
                var priceStr = level.price.toFixed(decimals);
                var qtyStr = level.size.toFixed(2);
                var qtyBarWidth = Math.min((level.size / maxSize) * 100, 100);
                var vpValue = Math.floor(level.size * 10 + Math.random() * 50);
                var vpBarWidth = Math.min((vpValue / 300) * 100, 100);
                var isLarge = level.size > maxSize * 0.5;
                var isXLarge = level.size > maxSize * 0.7;
                var isBigOrder = level.size >= bigOrderThreshold;
                var isWhale = level.size >= whaleThreshold;

                var rowClass = 'dom-row bid-level';
                if (isXLarge) rowClass += ' xlarge-bid';
                else if (isLarge) rowClass += ' large-bid';

                var indicator = '';
                if (isWhale) indicator = '<span class="big-order whale" title="Whale">W</span>';
                else if (isBigOrder) indicator = '<span class="big-order whale" title="Big Order">B</span>';

                html += '<div class="' + rowClass + '">';
                html += '<div class="pnl-col">' + indicator + '</div>';
                html += '<div class="bid-qty"><div class="qty-bar" style="width:' + qtyBarWidth + '%"></div><span class="qty-value">' + qtyStr + '</span></div>';
                html += '<div class="bid-col">' + priceStr + '</div>';
                html += '<div class="price">' + priceStr + '</div>';
                html += '<div class="ask-col"></div><div class="ask-qty"></div>';
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

        function showMarketClosed() {
            var ladder = document.getElementById('dom-ladder');
            if (ladder) {
                ladder.innerHTML = '<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; min-height: 300px; text-align: center; padding: 40px 20px;">' +
                    '<svg width="48" height="48" fill="none" stroke="#f59e0b" viewBox="0 0 24 24" style="margin-bottom: 16px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>' +
                    '<div style="color: #f59e0b; font-size: 20px; margin-bottom: 10px;">Market Closed</div>' +
                    '<div style="color: #9ca3af; font-size: 13px;">CME markets are closed.<br>Trading resumes Sunday 5:00 PM CT</div>' +
                    '</div>';
            }
            updateStatus('waiting', 'Market Closed');
        }

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            localStorage.setItem('dom_iqfeed_symbol', symbol);
            var config = symbolConfig[symbol];
            document.getElementById('symbol-title').textContent = config ? config.name : symbol;
            document.getElementById('bid-price').textContent = '--';
            document.getElementById('ask-price').textContent = '--';
            document.getElementById('spread').textContent = '--';
            document.getElementById('dom-ladder').innerHTML = '<div style="display: flex; align-items: center; justify-content: center; height: 200px; color: #9ca3af;">Loading ' + symbol + '...</div>';

            if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: symbol }));
            }
        }

        function setLevelCount(count) {
            levelCount = parseInt(count);
        }

        function centerOnCurrentPrice() {
            autoCenter = true;
            var container = document.getElementById('dom-ladder');
            var currentRow = container.querySelector('.current-price');
            if (currentRow) {
                container.scrollTop = currentRow.offsetTop - (container.clientHeight / 2) + (currentRow.clientHeight / 2);
            }
        }

        function placeBuy() { alert('Buy ' + currentSymbol + ' - Connect to trading API'); }
        function placeSell() { alert('Sell ' + currentSymbol + ' - Connect to trading API'); }

        window.addEventListener('beforeunload', function() {
            if (iqfeedWs) iqfeedWs.close();
        });

        init();
    </script>
</body>
</html>
