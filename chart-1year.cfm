<!--- TradingView-Grade Chart - Redis Only (No WebSocket in Frontend) --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DeepTrades - Professional Chart</title>
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <style>
        :root {
            --bg-primary: #0a0a0f;
            --bg-secondary: #0d0d12;
            --bg-tertiary: #1a1a24;
            --border-color: #2a2a3d;
            --text-primary: #e5e7eb;
            --text-secondary: #9ca3af;
            --text-muted: #6b7280;
            --accent-purple: #8b5cf6;
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-gold: #f59e0b;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { height: 100%; overflow: hidden; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
        }

        .container { height: 100%; display: flex; flex-direction: column; }

        .header {
            padding: 8px 16px;
            border-bottom: 1px solid var(--border-color);
            background: var(--bg-secondary);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
        }

        .header-left { display: flex; align-items: center; gap: 12px; }

        .symbol-selector {
            background: var(--bg-tertiary);
            padding: 6px 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
        }
        .symbol-selector select {
            background: transparent;
            border: none;
            color: var(--accent-gold);
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            outline: none;
        }
        .symbol-selector select option {
            background: var(--bg-tertiary);
            color: var(--text-primary);
        }

        .price-info { display: flex; align-items: center; gap: 16px; }
        .current-price {
            font-size: 24px;
            font-weight: 700;
            font-family: 'SF Mono', 'Consolas', monospace;
            color: var(--accent-green);
        }
        .current-price.down { color: var(--accent-red); }

        .price-change { display: flex; flex-direction: column; align-items: flex-end; }
        .price-change .value { font-size: 13px; font-weight: 600; color: var(--accent-green); }
        .price-change .value.down { color: var(--accent-red); }
        .price-change .percent { font-size: 11px; color: var(--text-muted); }

        .header-center { display: flex; align-items: center; gap: 8px; }

        .timeframe-bar {
            display: flex;
            background: var(--bg-tertiary);
            border-radius: 6px;
            padding: 3px;
            border: 1px solid var(--border-color);
        }
        .timeframe-bar button {
            background: transparent;
            border: none;
            color: var(--text-muted);
            padding: 5px 12px;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            border-radius: 4px;
        }
        .timeframe-bar button:hover { color: var(--text-primary); }
        .timeframe-bar button.active { background: var(--accent-purple); color: white; }

        .header-right { display: flex; align-items: center; gap: 12px; }

        .data-badge {
            display: flex;
            align-items: center;
            gap: 6px;
            background: var(--bg-tertiary);
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            border: 1px solid var(--accent-purple);
        }
        .data-badge .dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--accent-gold);
            animation: pulse 2s infinite;
        }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }

        .ohlc-bar {
            padding: 6px 16px;
            background: var(--bg-secondary);
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 20px;
            font-family: 'SF Mono', 'Consolas', monospace;
            font-size: 12px;
        }
        .ohlc-item { display: flex; align-items: center; gap: 4px; }
        .ohlc-item .label { color: var(--text-muted); font-weight: 500; }
        .ohlc-item .value { font-weight: 600; }
        .ohlc-item .value.open { color: var(--text-primary); }
        .ohlc-item .value.high { color: var(--accent-green); }
        .ohlc-item .value.low { color: var(--accent-red); }
        .ohlc-item .value.close { color: var(--accent-gold); }
        .ohlc-item .value.volume { color: var(--accent-purple); }
        .range-info { margin-left: auto; color: var(--text-muted); font-size: 11px; }

        .chart-wrapper { flex: 1; position: relative; min-height: 0; overflow: hidden; }
        #chart { width: 100%; height: 100%; }

        .data-panel {
            position: absolute;
            top: 12px;
            left: 12px;
            background: rgba(13, 13, 18, 0.95);
            padding: 10px 14px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            font-size: 11px;
            z-index: 50;
        }
        .data-panel .title { color: var(--accent-purple); font-weight: 600; margin-bottom: 4px; }
        .data-panel .info { color: var(--text-muted); line-height: 1.5; }
        .data-panel .cache-status { color: var(--accent-gold); margin-top: 4px; }

        .loading-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(10, 10, 15, 0.98);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 100;
            transition: opacity 0.3s, visibility 0.3s;
        }
        .loading-overlay.hidden { opacity: 0; visibility: hidden; }
        .loading-spinner {
            width: 48px;
            height: 48px;
            border: 3px solid var(--bg-tertiary);
            border-top-color: var(--accent-purple);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .loading-text { margin-top: 16px; color: var(--text-secondary); font-size: 14px; }
        .loading-progress { margin-top: 8px; color: var(--accent-purple); font-size: 12px; }

        .toast {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%) translateY(100px);
            background: var(--bg-tertiary);
            border: 1px solid var(--border-color);
            padding: 12px 20px;
            border-radius: 8px;
            color: var(--text-primary);
            font-size: 13px;
            z-index: 1000;
            opacity: 0;
            transition: all 0.3s;
        }
        .toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }
        .toast.success { border-color: var(--accent-green); }
        .toast.error { border-color: var(--accent-red); }

        @media (max-width: 768px) {
            .price-info, .ohlc-bar, .data-panel { display: none; }
            .header { padding: 6px 10px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="header-left">
                <div class="symbol-selector">
                    <select id="symbolSelect" onchange="changeSymbol(this.value)">
                        <option value="GC">GC - Gold</option>
                        <option value="SI">SI - Silver</option>
                        <option value="CL">CL - Crude Oil</option>
                        <option value="ES">ES - S&P 500</option>
                        <option value="NQ">NQ - Nasdaq</option>
                    </select>
                </div>
                <div class="price-info">
                    <div class="current-price" id="currentPrice">--</div>
                    <div class="price-change">
                        <div class="value" id="priceChange">--</div>
                        <div class="percent" id="pricePercent">--</div>
                    </div>
                </div>
            </div>

            <div class="header-center">
                <div class="timeframe-bar">
                    <button data-tf="1h" class="active" onclick="setTimeframe('1h')">1H</button>
                    <button data-tf="4h" onclick="setTimeframe('4h')">4H</button>
                    <button data-tf="1d" onclick="setTimeframe('1d')">1D</button>
                </div>
            </div>

            <div class="header-right">
                <div class="data-badge" id="dataBadge">
                    <div class="dot"></div>
                    <span id="badgeText">Loading from Redis...</span>
                </div>
            </div>
        </header>

        <div class="ohlc-bar">
            <div class="ohlc-item"><span class="label">O</span><span class="value open" id="ohlcOpen">--</span></div>
            <div class="ohlc-item"><span class="label">H</span><span class="value high" id="ohlcHigh">--</span></div>
            <div class="ohlc-item"><span class="label">L</span><span class="value low" id="ohlcLow">--</span></div>
            <div class="ohlc-item"><span class="label">C</span><span class="value close" id="ohlcClose">--</span></div>
            <div class="ohlc-item"><span class="label">Vol</span><span class="value volume" id="ohlcVol">--</span></div>
            <div class="range-info" id="rangeInfo">-- bars | --</div>
        </div>

        <div class="chart-wrapper">
            <div id="chart"></div>
            <div class="data-panel">
                <div class="title" id="panelTitle">1 Year History</div>
                <div class="info" id="panelInfo">Loading...</div>
                <div class="cache-status" id="cacheStatus">Source: Upstash Redis</div>
            </div>
            <div class="loading-overlay" id="loadingOverlay">
                <div class="loading-spinner"></div>
                <div class="loading-text" id="loadingText">Loading from Redis...</div>
                <div class="loading-progress" id="loadingProgress"></div>
            </div>
        </div>
    </div>

    <div class="toast" id="toast"></div>

    <script>
        // ==================== UPSTASH REDIS CONFIG ====================
        const UPSTASH_URL = 'https://expert-marlin-11581.upstash.io';
        const UPSTASH_TOKEN = 'AS09AAIncDI0YWZiZTM1ZThiYTA0NzcxYTg4Y2M3YTUwYjM1ZjY3OXAyMTE1ODE';

        // Poll interval for live updates
        const POLL_INTERVAL = 5000; // 5 seconds

        const symbolConfig = {
            'GC': { name: 'Gold', decimals: 2 },
            'SI': { name: 'Silver', decimals: 3 },
            'CL': { name: 'Crude Oil', decimals: 2 },
            'ES': { name: 'S&P 500', decimals: 2 },
            'NQ': { name: 'Nasdaq', decimals: 2 }
        };

        // ==================== STATE ====================
        let currentSymbol = 'GC';
        let currentTimeframe = '1h';
        let candleData = [];
        let pollTimer = null;
        let lastTimestamp = 0;

        // ==================== REDIS HELPERS ====================
        function getCacheKey(symbol, tf) {
            return `chart:${symbol}:${tf}:1year`;
        }

        function getLiveKey(symbol, tf) {
            return `live:${symbol}:${tf}`;
        }

        async function getFromRedis(key) {
            try {
                const response = await fetch(`${UPSTASH_URL}/get/${key}`, {
                    headers: { 'Authorization': `Bearer ${UPSTASH_TOKEN}` }
                });
                const data = await response.json();
                if (data.result) {
                    return JSON.parse(data.result);
                }
            } catch (e) {
                console.error('Redis GET error:', e);
            }
            return null;
        }

        // ==================== CHART SETUP ====================
        const chartContainer = document.getElementById('chart');
        const chart = LightweightCharts.createChart(chartContainer, {
            layout: {
                background: { type: 'solid', color: '#0a0a0f' },
                textColor: '#9ca3af',
            },
            grid: {
                vertLines: { color: '#1a1a24' },
                horzLines: { color: '#1a1a24' },
            },
            crosshair: {
                mode: LightweightCharts.CrosshairMode.Normal,
                vertLine: { color: '#8b5cf680', width: 1, style: 2, labelBackgroundColor: '#8b5cf6' },
                horzLine: { color: '#8b5cf680', width: 1, style: 2, labelBackgroundColor: '#8b5cf6' },
            },
            rightPriceScale: { borderColor: '#2a2a3d', scaleMargins: { top: 0.1, bottom: 0.2 } },
            timeScale: {
                borderColor: '#2a2a3d',
                timeVisible: true,
                secondsVisible: false,
                rightOffset: 10,
                barSpacing: 8,
                minBarSpacing: 3,
            },
            handleScroll: { mouseWheel: true, pressedMouseMove: true, horzTouchDrag: true },
            handleScale: { axisPressedMouseMove: true, mouseWheel: true, pinch: true },
        });

        const colors = { up: '#22c55e', down: '#ef4444' };

        const candleSeries = chart.addCandlestickSeries({
            upColor: colors.up,
            downColor: colors.down,
            borderDownColor: colors.down,
            borderUpColor: colors.up,
            wickDownColor: colors.down,
            wickUpColor: colors.up,
        });

        const volumeSeries = chart.addHistogramSeries({
            color: '#8b5cf6',
            priceFormat: { type: 'volume' },
            priceScaleId: 'volume',
        });
        volumeSeries.priceScale().applyOptions({ scaleMargins: { top: 0.85, bottom: 0 } });

        chart.subscribeCrosshairMove(param => {
            if (param.time) {
                const candle = param.seriesData.get(candleSeries);
                const volume = param.seriesData.get(volumeSeries);
                if (candle) updateOHLC(candle, volume?.value);
            }
        });

        function resizeChart() {
            const w = chartContainer.clientWidth;
            const h = chartContainer.clientHeight;
            if (w > 0 && h > 0) chart.applyOptions({ width: w, height: h });
        }
        window.addEventListener('resize', resizeChart);
        setTimeout(resizeChart, 50);

        // ==================== HELPERS ====================
        function getDecimals() { return symbolConfig[currentSymbol]?.decimals || 2; }

        function fmt(num, dec) {
            return num.toLocaleString('en-US', { minimumFractionDigits: dec, maximumFractionDigits: dec });
        }

        function fmtVol(v) {
            if (v >= 1e6) return (v / 1e6).toFixed(1) + 'M';
            if (v >= 1e3) return (v / 1e3).toFixed(1) + 'K';
            return v.toString();
        }

        function fmtDate(ts) {
            return new Date(ts * 1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
        }

        function volColor(bullish) {
            return bullish ? 'rgba(34, 197, 94, 0.5)' : 'rgba(239, 68, 68, 0.5)';
        }

        // ==================== UI UPDATES ====================
        function updateOHLC(candle, volume) {
            const d = getDecimals();
            document.getElementById('ohlcOpen').textContent = fmt(candle.open, d);
            document.getElementById('ohlcHigh').textContent = fmt(candle.high, d);
            document.getElementById('ohlcLow').textContent = fmt(candle.low, d);
            document.getElementById('ohlcClose').textContent = fmt(candle.close, d);
            document.getElementById('ohlcVol').textContent = volume ? fmtVol(volume) : '--';
        }

        function updatePrice(price, prev) {
            const d = getDecimals();
            const el = document.getElementById('currentPrice');
            const chgEl = document.getElementById('priceChange');
            const pctEl = document.getElementById('pricePercent');

            el.textContent = fmt(price, d);

            if (prev) {
                const chg = price - prev;
                const pct = (chg / prev) * 100;
                const sign = chg >= 0 ? '+' : '';
                el.className = 'current-price' + (chg < 0 ? ' down' : '');
                chgEl.textContent = sign + fmt(chg, d);
                chgEl.className = 'value' + (chg < 0 ? ' down' : '');
                pctEl.textContent = sign + pct.toFixed(2) + '%';
            }
        }

        function updateRange(count, first, last) {
            document.getElementById('rangeInfo').textContent = count.toLocaleString() + ' bars | ' + fmtDate(first) + ' - ' + fmtDate(last);
            document.getElementById('panelInfo').textContent = fmtDate(first) + ' - ' + fmtDate(last);
        }

        function showLoading(show, text = '', progress = '') {
            document.getElementById('loadingOverlay').classList.toggle('hidden', !show);
            if (text) document.getElementById('loadingText').textContent = text;
            document.getElementById('loadingProgress').textContent = progress;
        }

        function showToast(msg, type = 'info', dur = 3000) {
            const t = document.getElementById('toast');
            t.textContent = msg;
            t.className = 'toast ' + type + ' show';
            setTimeout(() => t.classList.remove('show'), dur);
        }

        // ==================== DATA LOADING (REDIS ONLY) ====================
        async function loadFromRedis() {
            showLoading(true, 'Loading from Redis...', '');
            document.getElementById('badgeText').textContent = 'Loading...';

            const key = getCacheKey(currentSymbol, currentTimeframe);
            const data = await getFromRedis(key);

            if (data && data.candles && data.candles.length > 0) {
                displayChart(data.candles);

                const age = Math.floor(Date.now() / 1000 - (data.timestamp || 0));
                const ageText = age < 60 ? age + 's ago' : age < 3600 ? Math.floor(age / 60) + 'm ago' : Math.floor(age / 3600) + 'h ago';

                document.getElementById('badgeText').textContent = data.candles.length.toLocaleString() + ' bars';
                document.getElementById('cacheStatus').textContent = 'Redis | Updated ' + ageText;
                lastTimestamp = data.timestamp || 0;

                showLoading(false);
                showToast('Loaded ' + data.candles.length.toLocaleString() + ' bars from Redis', 'success');

                // Start polling for updates
                startPolling();
            } else {
                showLoading(true, 'No data in Redis', 'Sync service may not be running');
                document.getElementById('badgeText').textContent = 'No data';
                showToast('No data available - sync service may be offline', 'error');
            }
        }

        function displayChart(candles) {
            const candleMap = new Map();
            const oneYearAgo = Math.floor((Date.now() - 365 * 24 * 60 * 60 * 1000) / 1000);

            candles.forEach(c => {
                const ts = c.time > 1e12 ? Math.floor(c.time / 1000) : c.time;
                if (ts >= oneYearAgo) {
                    candleMap.set(ts, {
                        time: ts,
                        open: c.open,
                        high: c.high,
                        low: c.low,
                        close: c.close,
                        volume: c.volume || 0
                    });
                }
            });

            candleData = Array.from(candleMap.values()).sort((a, b) => a.time - b.time);
            if (candleData.length === 0) return;

            candleSeries.setData(candleData);
            volumeSeries.setData(candleData.map(c => ({
                time: c.time,
                value: c.volume,
                color: volColor(c.close >= c.open)
            })));

            const first = candleData[0];
            const last = candleData[candleData.length - 1];
            const prev = candleData.length > 1 ? candleData[candleData.length - 2] : first;

            updatePrice(last.close, prev.close);
            updateOHLC(last, last.volume);
            updateRange(candleData.length, first.time, last.time);
            updatePriceLine(last.close);

            setTimeout(() => chart.timeScale().fitContent(), 50);
        }

        let priceLine = null;
        function updatePriceLine(price) {
            if (priceLine) candleSeries.removePriceLine(priceLine);
            priceLine = candleSeries.createPriceLine({
                price,
                color: '#f59e0b',
                lineWidth: 1,
                lineStyle: LightweightCharts.LineStyle.Dashed,
                axisLabelVisible: true,
                title: '',
            });
        }

        // ==================== POLLING FOR LIVE UPDATES ====================
        function startPolling() {
            if (pollTimer) clearInterval(pollTimer);

            pollTimer = setInterval(async () => {
                // Check for live candle update
                const liveKey = getLiveKey(currentSymbol, currentTimeframe);
                const liveCandle = await getFromRedis(liveKey);

                if (liveCandle && liveCandle.time) {
                    const ts = liveCandle.time > 1e12 ? Math.floor(liveCandle.time / 1000) : liveCandle.time;
                    const newCandle = {
                        time: ts,
                        open: liveCandle.open,
                        high: liveCandle.high,
                        low: liveCandle.low,
                        close: liveCandle.close,
                        volume: liveCandle.volume || 0
                    };

                    // Update or append
                    const existing = candleData.find(c => c.time === ts);
                    if (existing) {
                        Object.assign(existing, newCandle);
                    } else if (candleData.length > 0 && ts > candleData[candleData.length - 1].time) {
                        candleData.push(newCandle);
                    }

                    candleSeries.update(newCandle);
                    volumeSeries.update({
                        time: ts,
                        value: newCandle.volume,
                        color: volColor(newCandle.close >= newCandle.open)
                    });

                    const prev = candleData.length > 1 ? candleData[candleData.length - 2] : newCandle;
                    updatePrice(newCandle.close, prev.close);
                    updatePriceLine(newCandle.close);
                }

                // Also check if full data was updated
                const key = getCacheKey(currentSymbol, currentTimeframe);
                const data = await getFromRedis(key);
                if (data && data.timestamp && data.timestamp > lastTimestamp) {
                    // Full data was updated, refresh
                    lastTimestamp = data.timestamp;
                    const age = Math.floor(Date.now() / 1000 - data.timestamp);
                    document.getElementById('cacheStatus').textContent = 'Redis | Updated ' + age + 's ago';
                }
            }, POLL_INTERVAL);
        }

        // ==================== USER ACTIONS ====================
        async function changeSymbol(symbol) {
            currentSymbol = symbol;
            candleData = [];
            candleSeries.setData([]);
            volumeSeries.setData([]);
            document.getElementById('panelTitle').textContent = symbol + ' - 1 Year';
            await loadFromRedis();
        }

        async function setTimeframe(tf) {
            currentTimeframe = tf;
            candleData = [];
            candleSeries.setData([]);
            volumeSeries.setData([]);

            document.querySelectorAll('.timeframe-bar button').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tf === tf);
            });

            await loadFromRedis();
        }

        // ==================== INIT ====================
        document.addEventListener('DOMContentLoaded', async () => {
            await loadFromRedis();
            resizeChart();
        });
    </script>
</body>
</html>
