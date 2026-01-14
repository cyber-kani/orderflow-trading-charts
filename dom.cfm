<!--- DOM (Depth of Market) Module - Using IQFeed data --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Depth of Market - ES Futures</title>
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
            height: calc(100vh - 70px);
            padding: 24px;
            display: flex;
            justify-content: center;
        }

        /* DOM Panel */
        .dom-panel {
            background: #12121a;
            border: 1px solid #1a1a24;
            border-radius: 12px;
            display: flex;
            flex-direction: column;
            width: 100%;
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
            grid-template-columns: 50px 60px 80px 60px 50px;
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
            grid-template-columns: 50px 60px 80px 60px 50px;
            height: 24px;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.3);
            font-size: 12px;
            position: relative;
        }
        .dom-row:hover {
            filter: brightness(1.1);
        }

        /* Bid side rows (below current price) */
        .dom-row.bid-level {
            background: #0d3d0d;
        }
        .dom-row.bid-level:hover {
            background: #0f4a0f;
        }

        /* Ask side rows (above current price) */
        .dom-row.ask-level {
            background: #4d2a0d;
        }
        .dom-row.ask-level:hover {
            background: #5c3510;
        }

        /* Current price level */
        .dom-row.current-price {
            background: #9333ea;
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

        /* Large orders */
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
            background: #3b82f6;
            color: #fff;
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

        @media (max-width: 768px) {
            .content { padding: 8px; }
            .dom-panel { max-width: none; }
        }
    </style>
</head>
<body>
    <header class="header">
        <div style="display: flex; align-items: center; gap: 16px;">
            <a href="chart-today2.cfm" class="back-link">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                Back to Chart
            </a>
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
                    <option value="@ESH25" selected>ES (S&P 500)</option>
                    <option value="@NQH25">NQ (Nasdaq 100)</option>
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
            </div>
            <div class="dom-panel-body">
                <div class="price-info">
                    <span class="bid-info">Bid: <strong id="bid-price">--</strong></span>
                    <span class="spread-info">Spread: <strong id="spread">--</strong></span>
                    <span class="ask-info">Ask: <strong id="ask-price">--</strong></span>
                </div>
                <div class="dom-header">
                    <div>Bid</div>
                    <div>B Price</div>
                    <div>Price</div>
                    <div>A Price</div>
                    <div>Ask</div>
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
                        <div style="font-size: 16px; color: #9ca3af;">Connecting to market data...</div>
                    </div>
                </div>
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
            '@ESH25': { tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            '@NQH25': { tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' }
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
            var wsUrl = protocol + '//' + window.location.host + '/ws/iqfeed';

            updateStatus('', 'Connecting...');

            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                updateStatus('connected', 'Live');
                // Subscribe to orderbook
                ws.send(JSON.stringify({
                    type: 'subscribe',
                    symbol: currentSymbol,
                    dataType: 'orderbook'
                }));
            };

            ws.onmessage = function(event) {
                try {
                    var msg = JSON.parse(event.data);
                    if (msg.type === 'orderbook') {
                        processOrderbook(msg.data);
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
                if (reconnectTimer) clearTimeout(reconnectTimer);
                reconnectTimer = setTimeout(connectWebSocket, 3000);
            };
        }

        function processOrderbook(data) {
            if (!data) return;

            var config = symbolConfig[currentSymbol] || { tick: 0.25, decimals: 2 };
            var decimals = config.decimals;
            var tick = config.tick;

            var bids = data.bids || [];
            var asks = data.asks || [];

            if (bids.length === 0 && asks.length === 0) return;

            var bestBid = data.best_bid || (bids.length > 0 ? bids[0][0] : 0);
            var bestAsk = data.best_ask || (asks.length > 0 ? asks[0][0] : 0);
            var spread = bestAsk - bestBid;
            var midPrice = (bestBid + bestAsk) / 2;

            // Update price display
            document.getElementById('bid-price').textContent = bestBid.toFixed(decimals);
            document.getElementById('ask-price').textContent = bestAsk.toFixed(decimals);
            document.getElementById('spread').textContent = spread.toFixed(decimals);

            // Build depth maps
            var bidDepth = {};
            var askDepth = {};

            bids.forEach(function(level) {
                bidDepth[level[0].toFixed(decimals)] = level[1];
            });
            asks.forEach(function(level) {
                askDepth[level[0].toFixed(decimals)] = level[1];
            });

            // Generate ladder
            generateLadder(bestBid, bestAsk, midPrice, bidDepth, askDepth, config);
        }

        function generateLadder(bestBid, bestAsk, midPrice, bidDepth, askDepth, config) {
            var container = document.getElementById('dom-ladder');
            var tick = config.tick;
            var decimals = config.decimals;
            var levels = levelCount;
            var halfLevels = Math.floor(levels / 2);

            // Find max size for bar scaling
            var allSizes = Object.values(bidDepth).concat(Object.values(askDepth));
            var maxSize = allSizes.length > 0 ? Math.max.apply(null, allSizes) : 100;
            var avgSize = allSizes.length > 0 ? allSizes.reduce(function(a, b) { return a + b; }, 0) / allSizes.length : 50;
            var bigOrderThreshold = avgSize * 3;

            var html = '';

            // Generate price levels from high to low
            for (var i = halfLevels; i >= -halfLevels; i--) {
                var price = midPrice + (i * tick);
                var priceStr = price.toFixed(decimals);

                // Determine if this is bid or ask side
                var isBidLevel = price <= bestBid;
                var isAskLevel = price >= bestAsk;
                var isCurrentPrice = price > bestBid && price < bestAsk;

                // Get sizes
                var bidSize = bidDepth[priceStr] || 0;
                var askSize = askDepth[priceStr] || 0;

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

                // Calculate bar widths
                var bidBarWidth = bidSize > 0 ? Math.min((bidSize / maxSize) * 100, 100) : 0;
                var askBarWidth = askSize > 0 ? Math.min((askSize / maxSize) * 100, 100) : 0;

                // Big order indicator
                var bidIndicator = bidSize >= bigOrderThreshold ? '<span class="big-order">B</span>' : '';
                var askIndicator = askSize >= bigOrderThreshold ? '<span class="big-order">B</span>' : '';

                html += '<div class="' + rowClass + '">';

                // Bid qty with bar
                html += '<div class="bid-qty">';
                if (bidSize > 0) {
                    html += '<div class="qty-bar" style="width:' + bidBarWidth + '%"></div>';
                    html += '<span class="qty-value">' + bidSize + bidIndicator + '</span>';
                }
                html += '</div>';

                // Bid price column
                html += '<div class="bid-col">' + (isBidLevel && !isCurrentPrice ? priceStr : '') + '</div>';

                // Center price column
                html += '<div class="price">' + priceStr + '</div>';

                // Ask price column
                html += '<div class="ask-col">' + (isAskLevel && !isCurrentPrice ? priceStr : '') + '</div>';

                // Ask qty with bar
                html += '<div class="ask-qty">';
                if (askSize > 0) {
                    html += '<div class="qty-bar" style="width:' + askBarWidth + '%"></div>';
                    html += '<span class="qty-value">' + askIndicator + askSize + '</span>';
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
            var config = symbolConfig[symbol] || symbolConfig['@ESH25'];
            document.getElementById('symbol-title').textContent = config.name || symbol;
            document.getElementById('bid-price').textContent = '--';
            document.getElementById('ask-price').textContent = '--';
            document.getElementById('spread').textContent = '--';

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
                    symbol: currentSymbol,
                    dataType: 'orderbook'
                }));
            }
        }

        function setLevelCount(count) {
            levelCount = parseInt(count);
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
