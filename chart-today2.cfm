<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>GC Gold Futures - Orderflow Chart v157</title>
    <script src="https://unpkg.com/lightweight-charts@4.1.0/dist/lightweight-charts.standalone.production.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0f;
            color: #e4e4e7;
            height: 100%;
            width: 100%;
            overflow: hidden;
        }
        .container {
            display: flex;
            flex-direction: column;
            height: 100%;
            width: 100%;
        }

        /* Header */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 16px;
            background: #111118;
            border-bottom: 1px solid #1f1f2e;
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .symbol-name {
            font-size: 18px;
            font-weight: 600;
            color: #f4f4f5;
        }
        .timeframe-selector {
            display: flex;
            gap: 2px;
            background: #1a1a24;
            padding: 3px;
            border-radius: 6px;
        }
        .tf-btn {
            background: transparent;
            border: none;
            color: #6b7280;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .tf-btn:hover { background: #2a2a3a; color: #9ca3af; }
        .tf-btn.active { background: #22c55e20; color: #22c55e; }

        .toggle-selector {
            display: flex;
            gap: 2px;
            background: #1a1a24;
            padding: 3px;
            border-radius: 6px;
            margin-left: 12px;
        }
        .toggle-btn {
            background: transparent;
            border: none;
            color: #6b7280;
            padding: 5px 8px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .toggle-btn:hover { background: #2a2a3a; color: #9ca3af; }
        .toggle-btn.active { background: #3b82f620; color: #3b82f6; }

        .settings-btn {
            background: transparent;
            border: 1px solid #3f3f46;
            color: #6b7280;
            padding: 4px 8px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
        }
        .settings-btn:hover { background: #2a2a3a; color: #9ca3af; }

        .settings-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.7);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .settings-modal.show { display: flex; }
        .settings-content {
            background: #1a1a2e;
            border: 1px solid #3f3f46;
            border-radius: 8px;
            padding: 20px;
            min-width: 300px;
            max-width: 400px;
        }
        .settings-title {
            font-size: 16px;
            font-weight: 600;
            color: #e5e7eb;
            margin-bottom: 16px;
            padding-bottom: 8px;
            border-bottom: 1px solid #3f3f46;
        }
        .settings-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }
        .settings-label {
            color: #9ca3af;
            font-size: 13px;
        }
        .settings-input {
            background: #0f0f1a;
            border: 1px solid #3f3f46;
            color: #e5e7eb;
            padding: 6px 10px;
            border-radius: 4px;
            width: 80px;
            text-align: right;
            font-size: 13px;
            -moz-appearance: textfield;
        }
        .settings-input::-webkit-inner-spin-button,
        .settings-input::-webkit-outer-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }
        .settings-input:focus {
            outline: none;
            border-color: #3b82f6;
        }
        .settings-buttons {
            display: flex;
            gap: 8px;
            margin-top: 16px;
            justify-content: flex-end;
        }
        .settings-save {
            background: #22c55e;
            color: #000;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 500;
        }
        .settings-save:hover { background: #16a34a; }
        .settings-cancel {
            background: #3f3f46;
            color: #e5e7eb;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
        }
        .settings-cancel:hover { background: #52525b; }

        .price-display {
            display: flex;
            align-items: baseline;
            gap: 10px;
        }
        .current-price {
            font-size: 24px;
            font-weight: 700;
            color: #22c55e;
            font-family: 'SF Mono', Monaco, monospace;
        }
        .current-price.down { color: #ef4444; }
        .price-change {
            font-size: 12px;
            color: #22c55e;
        }
        .price-change.down { color: #ef4444; }

        .ohlc-display {
            display: flex;
            gap: 12px;
            font-size: 12px;
            color: #9ca3af;
        }
        .ohlc-item span:first-child {
            color: #6b7280;
            margin-right: 3px;
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        /* Orderflow Stats Panel */
        .orderflow-stats {
            display: flex;
            gap: 12px;
            font-size: 11px;
            background: #1a1a24;
            padding: 6px 10px;
            border-radius: 6px;
        }
        .stat-item {
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .stat-label { color: #6b7280; }
        .stat-value { font-weight: 600; font-family: 'SF Mono', Monaco, monospace; }
        .stat-value.positive { color: #22c55e; }
        .stat-value.negative { color: #ef4444; }
        .stat-value.neutral { color: #60a5fa; }

        .status {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 11px;
        }
        .status-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: #6b7280;
        }
        .status-dot.connected { background: #22c55e; }
        .status-dot.error { background: #ef4444; }
        .status-dot.connecting { background: #f59e0b; animation: pulse 1s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

        /* Chart Area - v157 simple approach */
        .chart-container {
            flex: 1;
            position: relative;
            overflow: hidden;
            background: #0a0a0f;
        }
        #chart {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            /* height set by JS */
        }
        #deltaWrapper {
            position: absolute;
            left: 0;
            right: 0;
            bottom: 0;
            height: 155px;
        }

        .loading-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: #0a0a0f;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 100;
        }
        .loading-overlay.hidden { display: none; }
        .loading-spinner {
            width: 36px;
            height: 36px;
            border: 3px solid #1f1f2e;
            border-top-color: #22c55e;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 12px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .loading-text { color: #9ca3af; font-size: 13px; }

        /* Legend */
        .legend {
            position: absolute;
            bottom: 60px;
            left: 16px;
            background: #111118ee;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 10px;
            display: flex;
            gap: 12px;
            z-index: 10;
        }
        .legend.hidden { display: none; }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .legend-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
        }
        .legend-dot.bid { background: #22c55e; }
        .legend-dot.ask { background: #ef4444; }
        .legend-dot.imbalance { background: #f59e0b; }

        /* Delta Tooltip below candle */
        .delta-tooltip {
            position: absolute;
            display: none;
            padding: 2px 6px;
            background: rgba(0, 0, 0, 0.8);
            border-radius: 3px;
            font-size: 11px;
            font-weight: 700;
            font-family: 'SF Mono', Monaco, monospace;
            color: #e5e7eb;
            pointer-events: none;
            z-index: 100;
            text-align: center;
        }
        .delta-tooltip .delta-value.positive { color: #22c55e; }
        .delta-tooltip .delta-value.negative { color: #ef4444; }

        /* Delta Grid Table */
        #deltaGrid {
            position: absolute;
            top: 0;
            left: 0;
            right: 55px; /* Leave space for labels panel */
            height: 100%;
            background: #0d0d12;
            border-top: 1px solid #1f1f2e;
            font-size: 10px;
            font-family: 'SF Mono', Monaco, monospace;
            overflow-x: hidden;
            overflow-y: hidden;
        }
        /* Right-side labels panel (below price scale) */
        #deltaLabels {
            position: absolute;
            top: 0;
            right: 0;
            width: 55px;
            height: 100%;
            background: #0d0d12;
            border-top: 1px solid #1f1f2e;
            border-left: 1px solid #1f1f2e;
            z-index: 20;
            display: flex;
            flex-direction: column;
        }
        #deltaLabels .label-row {
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #f59e0b;
            font-weight: 500;
            font-size: 9px;
            font-family: 'SF Mono', Monaco, monospace;
        }
        #deltaGrid.delta-hidden {
            display: none !important;
        }
        #deltaGrid.delta-visible {
            display: block !important;
        }

        #deltaGrid table {
            border-collapse: collapse;
            table-layout: fixed;
            box-sizing: border-box;
        }
        #deltaGrid * {
            box-sizing: border-box;
        }
        #deltaGrid tr {
            height: 24px;
        }
        #deltaGrid th {
            display: none; /* Labels moved to right-side panel */
        }
        #deltaGrid td {
            text-align: center;
            padding: 0;
            white-space: nowrap;
            color: #9ca3af;
            border-right: 1px solid #1a1a24;
            box-sizing: border-box;
        }
        #deltaGrid td.positive {
            background: rgba(34, 197, 94, 0.3);
            color: #22c55e;
            font-weight: 600;
        }
        #deltaGrid td.negative {
            background: rgba(239, 68, 68, 0.3);
            color: #ef4444;
            font-weight: 600;
        }
        #deltaGrid td.strong-positive {
            background: rgba(34, 197, 94, 0.5);
            color: #4ade80;
            font-weight: 700;
        }
        #deltaGrid td.strong-negative {
            background: rgba(239, 68, 68, 0.5);
            color: #f87171;
            font-weight: 700;
        }

        /* Context Menu */
        .context-menu {
            display: none;
            position: fixed;
            z-index: 1001;
            background: #1a1a2e;
            border: 1px solid #3f3f46;
            border-radius: 6px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
            min-width: 180px;
            max-height: calc(100vh - 20px);
            overflow-y: auto;
            padding: 4px 0;
        }
        .context-menu.show { display: block; }
        .context-menu-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 14px;
            color: #e5e7eb;
            font-size: 12px;
            cursor: pointer;
            transition: background 0.15s;
        }
        .context-menu-item:hover {
            background: #2a2a3a;
        }
        .context-menu-item .icon {
            width: 16px;
            text-align: center;
            opacity: 0.7;
        }
        .context-menu-separator {
            height: 1px;
            background: #3f3f46;
            margin: 4px 0;
        }
        .context-menu-item.danger {
            color: #ef4444;
        }
        .context-menu-item.danger:hover {
            background: rgba(239, 68, 68, 0.15);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <span class="symbol-name">GC Gold Futures</span>
                <div class="timeframe-selector">
                    <button class="tf-btn active" data-tf="1m">1m</button>
                    <button class="tf-btn" data-tf="5m">5m</button>
                    <button class="tf-btn" data-tf="15m">15m</button>
                    <button class="tf-btn" data-tf="1h">1h</button>
                    <button class="tf-btn" data-tf="4h">4h</button>
                    <button class="tf-btn" data-tf="1d">1D</button>
                </div>
                <div class="toggle-selector">
                    <button class="toggle-btn" id="toggleVol" title="Toggle Volume">VOL</button>
                    <button class="toggle-btn" id="toggleMA" title="Toggle MA20">MA</button>
                    <button class="toggle-btn active" id="toggleDelta" title="Toggle Delta Stats" onclick="if(typeof toggleDeltaStats==='function'){toggleDeltaStats();}return false;">Δ</button>
                    <button class="toggle-btn active" id="toggleBigOrders" title="Toggle Big Orders">BIG</button>
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
                </div>
            </div>
            <div class="header-right">
                <span style="font-size:11px;color:#6b7280" id="barCount">0 bars</span>
                <button class="settings-btn" id="settingsBtn" title="Settings">⚙</button>
                <span style="font-size:14px;color:#ff0000;font-weight:bold;background:#ffff00;padding:2px 6px;border-radius:3px" id="version">v157</span>
                <div class="status">
                    <div class="status-dot connecting" id="statusDot"></div>
                    <span id="statusText">Connecting...</span>
                </div>
            </div>
        </div>

        <!-- Settings Modal -->
        <div class="settings-modal" id="settingsModal">
            <div class="settings-content">
                <div class="settings-title">Chart Settings</div>
                <div class="settings-row">
                    <span class="settings-label">Big Order Min Size (contracts)</span>
                    <input type="number" class="settings-input" id="settingBigOrderSize" min="1" max="1000" value="20">
                </div>
                <div class="settings-row">
                    <span class="settings-label">Big Order Display (candles)</span>
                    <input type="number" class="settings-input" id="settingBigOrderCandles" min="1" max="100" value="15">
                </div>
                <div class="settings-row">
                    <span class="settings-label">Delta Data TTL (hours)</span>
                    <input type="number" class="settings-input" id="settingDeltaTTL" min="1" max="48" value="6">
                </div>
                <div class="settings-buttons">
                    <button class="settings-cancel" id="settingsClearData" style="background:#ef4444;color:#fff;">Clear All Data</button>
                    <button class="settings-cancel" id="settingsCancel">Cancel</button>
                    <button class="settings-save" id="settingsSave">Save</button>
                </div>
            </div>
        </div>

        <div class="chart-container">
            <div id="chart"></div>
            <div id="deltaWrapper" style="display:none;">
                <div id="deltaGrid">
                    <table>
                        <tbody id="deltaGridBody">
                            <tr id="rowTime"><th>Time</th></tr>
                            <tr id="rowDelta"><th>Delta</th></tr>
                            <tr id="rowDeltaChange"><th>Chg</th></tr>
                            <tr id="rowMaxDelta"><th>Max</th></tr>
                            <tr id="rowMinDelta"><th>Min</th></tr>
                            <tr id="rowVolume"><th>Vol</th></tr>
                        </tbody>
                    </table>
                </div>
                <div id="deltaLabels">
                    <div class="label-row">Time</div>
                    <div class="label-row">Delta</div>
                    <div class="label-row">Chg</div>
                    <div class="label-row">Max</div>
                    <div class="label-row">Min</div>
                    <div class="label-row">Vol</div>
                </div>
            </div>
            <div id="deltaTooltip" class="delta-tooltip"></div>
            <div class="legend" id="chartLegend" style="display: none;">
                <div class="legend-item"><div class="legend-dot bid"></div><span>Big Bid</span></div>
                <div class="legend-item"><div class="legend-dot ask"></div><span>Big Ask</span></div>
            </div>
            <div class="loading-overlay" id="loadingOverlay">
                <div class="loading-spinner"></div>
                <div class="loading-text">Loading market data...</div>
            </div>
            <!-- Context Menu -->
            <div class="context-menu" id="contextMenu">
                <div class="context-menu-item" data-action="fitContent">
                    <span class="icon">⬜</span>
                    <span>Fit Content</span>
                </div>
                <div class="context-menu-item" data-action="zoomLast25">
                    <span class="icon">🔍</span>
                    <span>Zoom Last 25 Bars</span>
                </div>
                <div class="context-menu-item" data-action="screenshot">
                    <span class="icon">📷</span>
                    <span>Save Screenshot</span>
                </div>
                <div class="context-menu-item" data-action="resetChart">
                    <span class="icon">↺</span>
                    <span>Reset Chart</span>
                </div>
                <div class="context-menu-separator"></div>
                <div class="context-menu-item" data-action="toggleVolume">
                    <span class="icon" id="ctxVolCheck">☐</span>
                    <span>Show Volume</span>
                </div>
                <div class="context-menu-item" data-action="toggleMA">
                    <span class="icon" id="ctxMACheck">☐</span>
                    <span>Show MA20</span>
                </div>
                <div class="context-menu-item" data-action="toggleDelta">
                    <span class="icon" id="ctxDeltaCheck">☑</span>
                    <span>Show Delta Grid</span>
                </div>
                <div class="context-menu-item" data-action="toggleBigOrders">
                    <span class="icon" id="ctxBigCheck">☑</span>
                    <span>Show Big Orders</span>
                </div>
                <div class="context-menu-item" data-action="toggleAutoScroll">
                    <span class="icon" id="ctxAutoScrollCheck">☑</span>
                    <span>Auto Scroll</span>
                </div>
                <div class="context-menu-separator"></div>
                <div class="context-menu-item" data-action="settings">
                    <span class="icon">⚙</span>
                    <span>Settings</span>
                </div>
                <div class="context-menu-separator"></div>
                <div class="context-menu-item danger" data-action="clearData">
                    <span class="icon">🗑</span>
                    <span>Clear All Data</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        //=============================================================================
        // CONFIGURATION (with localStorage persistence)
        //=============================================================================
        function loadSettings() {
            const saved = localStorage.getItem('chartSettings');
            if (saved) {
                try {
                    return JSON.parse(saved);
                } catch (e) {
                    console.warn('Failed to load settings:', e);
                }
            }
            return {};
        }
        const savedSettings = loadSettings();

        const CONFIG = {
            symbol: 'GC',
            decimals: 1,
            // Big order detection (MBO) - editable via settings
            bigOrderMinSize: savedSettings.bigOrderMinSize || 20,
            // How many candles to show big orders (0 = forever) - editable via settings
            bigOrderDisplayCandles: savedSettings.bigOrderDisplayCandles || 15,
            // Delta TTL in hours - editable via settings
            deltaTTLHours: savedSettings.deltaTTLHours || 6,
            // Imbalance detection
            imbalanceRatio: 3.0,
            imbalanceMinVolume: 5,
            // Marker limits
            maxMarkers: 150,
        };

        const TIMEFRAME_MINUTES = { '1m': 1, '5m': 5, '15m': 15, '1h': 60, '4h': 240, '1d': 1440 };

        //=============================================================================
        // STATE
        //=============================================================================
        let TIMEFRAME = savedSettings.timeframe || '1m';
        let ws = null;
        let chart = null;
        let candleSeries = null;
        let volumeSeries = null;
        let volumeMA20Series = null;

        // Toggle states
        // Delta and Volume/MA are mutually exclusive
        // Default: show delta grid, hide volume/MA
        let showVolume = savedSettings.showVolume === true ? true : false;
        let showMA = savedSettings.showMA !== undefined ? savedSettings.showMA : false;
        let showDeltaStats = savedSettings.showDeltaStats !== undefined ? savedSettings.showDeltaStats : true;
        let showBigOrders = savedSettings.showBigOrders === true ? true : false;
        let autoScroll = savedSettings.autoScroll !== undefined ? savedSettings.autoScroll : true;
        let initialZoomComplete = false;  // Flag to prevent delta grid updates before zoom animation completes

        // Track user preferences for auto-hide on zoom out
        let userWantsDelta = showDeltaStats;
        let userWantsBigOrders = showBigOrders;
        let zoomedOutHidden = false;  // True when auto-hidden due to zoom > threshold
        // Auto-hide threshold per timeframe (number of visible candles)
        const ZOOM_OUT_THRESHOLDS = {
            '1m': 50,
            '5m': 60,
            '15m': 70,
            '1h': 80,
            '4h': 90,
            '1d': 100
        };
        const ZOOM_OUT_THRESHOLD = ZOOM_OUT_THRESHOLDS[TIMEFRAME] || 50;

        let candleData = [];
        let savedCandles = new Map();  // Candles saved with delta data (for persistence)
        let currentPrice = 0;
        let sessionOpen = 0;

        // Orderflow tracking per candle
        // Key: candleTime -> { buyVolume, sellVolume, bigBids, bigAsks, delta }
        let candleOrderflow = new Map();

        // Current best bid/ask from orderbook (for trade classification)
        let currentBestBid = 0;
        let currentBestAsk = 0;

        // MBO order tracking
        let seenMBOOrders = new Set();

        // Cumulative volume per price level per candle
        // Key: "candleTime_price_side" -> cumulative size
        let priceVolumeMap = new Map();

        // Individual big order trades - stored with exact price for circle rendering
        // Array of { time, price, size, side: 'BUY'|'SELL' }
        let bigOrderTrades = [];

        // Aggregated big orders per candle (legacy - kept for data persistence)
        // Key: "candleTime_SIDE" -> { count, totalSize, avgPrice }
        let aggregatedBigOrders = new Map();

        // All markers for the chart (no longer used for big orders - using canvas overlay)
        let chartMarkers = [];

        // Canvas overlay for big order circles
        let bigOrderCanvas = null;
        let bigOrderCtx = null;

        // Session totals
        let sessionStats = {
            totalBuyVolume: 0,   // Volume from trades at ask (buyer aggressor)
            totalSellVolume: 0,  // Volume from trades at bid (seller aggressor)
            bigOrderCount: 0,
        };

        // Delta data per candle for grid display
        // Key: candleTime -> { delta, deltaChange, maxDelta, minDelta, volume }
        let candleDeltaData = new Map();

        // 1m delta data - ALWAYS tracked regardless of viewing timeframe
        // This ensures we capture granular data for all timeframe aggregation
        let oneMinuteDeltaData = new Map();
        let oneMinuteOrderflow = new Map();  // 1m orderflow accumulation

        // Delta data API endpoints
        const DELTA_API_URL = '/orderflowtest/api/delta-data.cfm';  // Redis (legacy)
        const DB_API_URL = '/orderflowtest/api/orderflow-data.cfm'; // Database (persistent)

        // Debounce timer for saving
        let saveDeltaTimeout = null;

        //=============================================================================
        // DELTA DATA PERSISTENCE (Redis via API)
        //=============================================================================
        function saveDeltaData() {
            // Debounce saves to avoid hammering the API
            if (saveDeltaTimeout) {
                clearTimeout(saveDeltaTimeout);
            }
            saveDeltaTimeout = setTimeout(() => {
                saveDeltaDataNow();
            }, 2000);  // Save at most every 2 seconds
        }

        async function saveDeltaDataNow() {
            try {
                const data = {};

                // Log bigOrderTrades state at save time
                console.log(`[SAVE] bigOrderTrades.length = ${bigOrderTrades.length}`);
                if (bigOrderTrades.length > 0) {
                    console.log(`[SAVE] First 3 bigOrderTrades:`, JSON.stringify(bigOrderTrades.slice(0, 3)));
                }

                // First, add all delta data
                candleDeltaData.forEach((value, key) => {
                    // Only save real data (not estimated)
                    if (!value.estimated) {
                        // Find matching candle to save with delta
                        const keyNum = Number(key);
                        const candle = candleData.find(c => c.time === keyNum);
                        // Get individual big order trades for this candle (exact prices)
                        // Use Number() to ensure type match
                        const tradesForCandle = bigOrderTrades.filter(t => Number(t.time) === keyNum);
                        // Build record - only include bigOrderTrades if we have some
                        // (don't send null as it would overwrite existing data in Redis)
                        const record = {
                            ...value,
                            candle: candle ? { o: candle.open, h: candle.high, l: candle.low, c: candle.close, v: candle.volume } : null
                        };
                        if (tradesForCandle.length > 0) {
                            record.bigOrderTrades = tradesForCandle;
                        }
                        data[key] = record;
                    }
                });

                // Also save any big orders that don't have delta data yet
                const candleTimesWithBigOrders = new Set(bigOrderTrades.map(t => Number(t.time)));
                console.log(`[SAVE] Unique big order timestamps: ${[...candleTimesWithBigOrders].join(', ')}`);
                candleTimesWithBigOrders.forEach(candleTime => {
                    const candleTimeKey = String(candleTime);
                    if (!data[candleTimeKey]) {
                        // Create minimal record for this candle with just big orders
                        const candle = candleData.find(c => c.time === candleTime);
                        const tradesForCandle = bigOrderTrades.filter(t => Number(t.time) === candleTime);
                        console.log(`[SAVE] Creating new record for timestamp ${candleTime} with ${tradesForCandle.length} big orders`);
                        data[candleTimeKey] = {
                            delta: 0,
                            volume: 0,
                            buyVolume: 0,
                            sellVolume: 0,
                            candle: candle ? { o: candle.open, h: candle.high, l: candle.low, c: candle.close, v: candle.volume } : null,
                            bigOrderTrades: tradesForCandle
                        };
                    }
                });

                // Debug: log bigOrderTrades timestamps vs candleDeltaData keys
                if (bigOrderTrades.length > 0) {
                    const bigOrderTimes = [...new Set(bigOrderTrades.map(t => Number(t.time)))];
                    const deltaDataKeys = [...candleDeltaData.keys()].map(k => Number(k));
                    console.log(`[SAVE] BigOrders timestamps: ${bigOrderTimes.join(', ')}`);
                    console.log(`[SAVE] DeltaData keys (last 3): ${deltaDataKeys.slice(-3).join(', ')}`);
                    // Check overlap
                    const matchedKeys = bigOrderTimes.filter(t => deltaDataKeys.includes(t));
                    console.log(`[SAVE] Matched timestamps: ${matchedKeys.length}/${bigOrderTimes.length}`);
                }

                const bigOrderCount = [...Object.values(data)].filter(d => d.bigOrderTrades && d.bigOrderTrades.length > 0).length;
                if (bigOrderCount > 0) {
                    console.log(`Saving ${Object.keys(data).length} records (${bigOrderCount} candles with big orders, ${bigOrderTrades.length} total trades)`);
                    // Log sample for debugging
                    const sampleKey = Object.keys(data).find(k => data[k].bigOrderTrades && data[k].bigOrderTrades.length > 0);
                    if (sampleKey) {
                        console.log('Save sample:', sampleKey, JSON.stringify(data[sampleKey].bigOrderTrades?.slice(0, 2)));
                    }
                } else if (bigOrderTrades.length > 0) {
                    console.log(`WARNING: ${bigOrderTrades.length} bigOrderTrades exist but none matched data keys!`);
                }

                if (Object.keys(data).length === 0) return;

                const response = await fetch(`${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=${TIMEFRAME}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });

                if (!response.ok) {
                    console.warn('Failed to save delta data: HTTP', response.status);
                    return;
                }

                const text = await response.text();
                if (text) {
                    try {
                        const result = JSON.parse(text);
                        if (result.success) {
                            console.log(`Saved ${result.count} delta records to Redis`);
                        } else {
                            console.warn('Failed to save delta data:', result.error);
                        }
                    } catch (e) {
                        console.warn('Invalid JSON response from save:', text.substring(0, 100));
                    }
                }

                // ALWAYS save 1m data to Redis (for aggregation into any timeframe)
                if (TIMEFRAME !== '1m' && oneMinuteDeltaData.size > 0) {
                    const data1m = {};
                    oneMinuteDeltaData.forEach((value, key) => {
                        const keyNum = Number(key);
                        // Include big orders that belong to this 1m bucket
                        const tradesFor1m = bigOrderTrades.filter(t => Number(t.time) === keyNum);
                        data1m[key] = {
                            ...value,
                            bigOrderTrades: tradesFor1m.length > 0 ? tradesFor1m : undefined
                        };
                    });
                    // Also add big orders that might not have delta data yet
                    bigOrderTrades.forEach(order => {
                        const key = String(order.time);
                        if (!data1m[key]) {
                            data1m[key] = {
                                delta: 0, volume: 0, buyVolume: 0, sellVolume: 0,
                                bigOrderTrades: [order]
                            };
                        }
                    });
                    if (Object.keys(data1m).length > 0) {
                        try {
                            const response1m = await fetch(`${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=1m`, {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify(data1m)
                            });
                            if (response1m.ok) {
                                const result1m = await response1m.json();
                                if (result1m.success) {
                                    console.log(`[1m] Also saved ${result1m.count} 1m delta records with big orders`);
                                }
                            }
                        } catch (e1m) {
                            console.warn('[1m] Failed to save 1m data:', e1m.message);
                        }
                    }
                }

                // Also save to database for persistent storage (all timeframes)
                await saveToDatabaseAsync(data);

            } catch (e) {
                console.warn('Failed to save delta data:', e.message);
            }
        }

        // Save to database API (persistent storage for all timeframes)
        async function saveToDatabaseAsync(data) {
            try {
                // Convert data format for database API
                const deltaRecords = [];
                const bigOrders = [];

                Object.keys(data).forEach(key => {
                    const record = data[key];
                    const candleTime = parseInt(key);

                    // Add delta record
                    deltaRecords.push({
                        time: candleTime,
                        delta: record.delta || 0,
                        maxDelta: record.maxDelta || record.delta || 0,
                        minDelta: record.minDelta || record.delta || 0,
                        volume: record.volume || 0,
                        buyVolume: record.buyVolume || 0,
                        sellVolume: record.sellVolume || 0,
                        candle: record.candle || null,
                        estimated: record.estimated || false
                    });

                    // Add big orders if present
                    if (record.bigOrderTrades && Array.isArray(record.bigOrderTrades)) {
                        record.bigOrderTrades.forEach(trade => {
                            bigOrders.push({
                                time: Number(trade.time || candleTime),
                                price: Number(trade.price),
                                size: Number(trade.size),
                                side: trade.side
                            });
                        });
                    }
                });

                if (deltaRecords.length === 0) return;

                const payload = {
                    symbol: CONFIG.symbol,
                    timeframe: TIMEFRAME,
                    delta: deltaRecords,
                    bigOrders: bigOrders
                };

                const dbResponse = await fetch(`${DB_API_URL}?action=save_all`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });

                if (dbResponse.ok) {
                    const dbResult = await dbResponse.json();
                    if (dbResult.success) {
                        console.log(`[DB] Saved ${dbResult.deltaSaved} delta, ${dbResult.ordersSaved} big orders`);
                    }
                }
            } catch (e) {
                console.warn('[DB] Failed to save to database:', e.message);
            }
        }

        async function loadDeltaData() {
            try {
                console.log(`Loading delta data for ${CONFIG.symbol}/${TIMEFRAME}...`);
                var ver = document.getElementById('version');
                if (ver) ver.textContent = 'v157 LOADING...';

                // Version tracking (no longer clears data on version change)
                const dataVersion = localStorage.getItem('mboDataVersion');
                if (dataVersion !== 'v157') {
                    console.log('[Version] Upgrading to v157 - preserving existing data');
                    localStorage.setItem('mboDataVersion', 'v157');
                }

                // First load the native timeframe data
                const response = await fetch(`${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=${TIMEFRAME}`);

                if (!response.ok) {
                    console.warn('Failed to load delta data: HTTP', response.status);
                    if (ver) ver.textContent = 'v157 LOAD ERR';
                    return;
                }

                const text = await response.text();
                let loadedCount = 0;
                let candleCount = 0;
                let bigOrderCount = 0;
                savedCandles.clear();

                if (text) {
                    try {
                        const result = JSON.parse(text);
                        if (result.success && result.data) {
                            // Debug: check for bigOrderTrades in any record
                            const allKeys = Object.keys(result.data);
                            const keysWithBigOrders = allKeys.filter(k => {
                                const trades = result.data[k].bigOrderTrades || result.data[k].BIGORDERTRADES;
                                return trades && Array.isArray(trades) && trades.length > 0;
                            });
                            console.log(`[Redis ${TIMEFRAME}] Total records: ${allKeys.length}, records with bigOrders: ${keysWithBigOrders.length}`);
                            if (keysWithBigOrders.length > 0) {
                                const sample = result.data[keysWithBigOrders[0]].bigOrderTrades || result.data[keysWithBigOrders[0]].BIGORDERTRADES;
                                console.log(`[Redis ${TIMEFRAME}] Sample big order:`, JSON.stringify(sample[0]));
                            }
                            Object.keys(result.data).forEach(key => {
                                const timestamp = parseInt(key);
                                const record = result.data[key];
                                // Extract candle data if present (handle CF uppercase keys)
                                const candle = record.candle || record.CANDLE;
                                if (candle) {
                                    savedCandles.set(timestamp, {
                                        time: timestamp,
                                        open: candle.o || candle.O,
                                        high: candle.h || candle.H,
                                        low: candle.l || candle.L,
                                        close: candle.c || candle.C,
                                        volume: candle.v || candle.V || 0
                                    });
                                    candleCount++;
                                }
                                // Load individual big order trades with exact prices
                                const trades = record.bigOrderTrades || record.BIGORDERTRADES;
                                if (trades && Array.isArray(trades) && trades.length > 0) {
                                    if (bigOrderCount === 0) {
                                        console.log(`[LOAD 1m] First record with big orders at ${timestamp}:`, JSON.stringify(trades[0]));
                                    }
                                    trades.forEach(trade => {
                                        // Handle CF uppercase keys and ensure numeric values
                                        const t = {
                                            time: Number(trade.time || trade.TIME || timestamp),
                                            price: Number(trade.price || trade.PRICE),
                                            size: Number(trade.size || trade.SIZE),
                                            side: trade.side || trade.SIDE
                                        };
                                        if (t.price && t.size && t.side && !isNaN(t.price) && !isNaN(t.size)) {
                                            // Add to seenMBOOrders to prevent duplicates when live data arrives
                                            // Key format: B/A_price_size (B=bids/BUY, A=asks/SELL)
                                            const sidePrefix = t.side === 'BUY' ? 'B' : 'A';
                                            const orderKey = `${sidePrefix}_${t.price}_${t.size}`;
                                            if (!seenMBOOrders.has(orderKey)) {
                                                seenMBOOrders.add(orderKey);
                                                bigOrderTrades.push(t);
                                                bigOrderCount++;
                                            }
                                        }
                                    });
                                } else if (record.bigOrderTrades !== null && record.bigOrderTrades !== undefined) {
                                    console.log('bigOrderTrades exists but not array:', typeof record.bigOrderTrades, record.bigOrderTrades);
                                }
                                // Store delta data (normalize CF uppercase keys to lowercase)
                                const deltaOnly = {
                                    delta: record.delta || record.DELTA || 0,
                                    maxDelta: record.maxDelta || record.MAXDELTA || 0,
                                    minDelta: record.minDelta || record.MINDELTA || 0,
                                    volume: record.volume || record.VOLUME || 0,
                                    buyVolume: record.buyVolume || record.BUYVOLUME || 0,
                                    sellVolume: record.sellVolume || record.SELLVOLUME || 0
                                };
                                candleDeltaData.set(timestamp, deltaOnly);
                                loadedCount++;
                            });
                            console.log(`Loaded ${loadedCount} native ${TIMEFRAME} delta records, ${bigOrderCount} big order trades, ${candleCount} candles`);
                        }
                    } catch (e) {
                        console.warn('Invalid JSON response from load:', text.substring(0, 100));
                    }
                }

                // For higher timeframes, also aggregate 1m data
                if (TIMEFRAME !== '1m') {
                    try {
                        const response1m = await fetch(`${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=1m`);
                        if (response1m.ok) {
                            const text1m = await response1m.text();
                            if (text1m) {
                                const result1m = JSON.parse(text1m);
                                if (result1m.success && result1m.data) {
                                    const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                                    const aggregated = new Map();
                                    let aggregatedFrom1m = 0;
                                    let skippedExisting = 0;
                                    const oneM_keys = Object.keys(result1m.data);

                                    console.log(`1m aggregation: processing ${oneM_keys.length} 1m records into ${TIMEFRAME} buckets (${intervalSeconds}s interval)`);

                                    // Aggregate 1m deltas into current timeframe buckets
                                    oneM_keys.forEach(key => {
                                        const ts1m = parseInt(key);
                                        const record = result1m.data[key];
                                        // Calculate which candle bucket this 1m delta belongs to
                                        const bucketTime = Math.floor(ts1m / intervalSeconds) * intervalSeconds;

                                        // Skip if we already have native data for this bucket
                                        if (candleDeltaData.has(bucketTime)) {
                                            skippedExisting++;
                                            return;
                                        }

                                        if (!aggregated.has(bucketTime)) {
                                            aggregated.set(bucketTime, {
                                                delta: 0,
                                                maxDelta: -Infinity,
                                                minDelta: Infinity,
                                                volume: 0,
                                                buyVolume: 0,
                                                sellVolume: 0
                                            });
                                        }
                                        const agg = aggregated.get(bucketTime);
                                        agg.delta += (record.delta || 0);
                                        agg.maxDelta = Math.max(agg.maxDelta, agg.delta);
                                        agg.minDelta = Math.min(agg.minDelta, agg.delta);
                                        agg.volume += (record.volume || 0);
                                        agg.buyVolume += (record.buyVolume || 0);
                                        agg.sellVolume += (record.sellVolume || 0);
                                    });

                                    // Add aggregated data to candleDeltaData
                                    aggregated.forEach((data, bucketTime) => {
                                        if (!candleDeltaData.has(bucketTime)) {
                                            // Fix Infinity values
                                            if (data.maxDelta === -Infinity) data.maxDelta = data.delta;
                                            if (data.minDelta === Infinity) data.minDelta = data.delta;
                                            candleDeltaData.set(bucketTime, data);
                                            aggregatedFrom1m++;
                                        }
                                    });

                                    console.log(`1m aggregation result: ${aggregatedFrom1m} new buckets, ${skippedExisting} skipped (had native), ${aggregated.size} unique buckets from 1m`);
                                    loadedCount += aggregatedFrom1m;

                                    // ALSO load big orders from 1m data and map to current timeframe
                                    let bigOrdersFrom1m = 0;
                                    let recordsWithBigOrders = 0;
                                    oneM_keys.forEach(key => {
                                        const ts1m = parseInt(key);
                                        const record = result1m.data[key];
                                        const bucketTime = Math.floor(ts1m / intervalSeconds) * intervalSeconds;

                                        // Load big orders from 1m record
                                        const trades = record.bigOrderTrades || record.BIGORDERTRADES;
                                        if (trades && Array.isArray(trades) && trades.length > 0) {
                                            recordsWithBigOrders++;
                                            trades.forEach(trade => {
                                                const t = {
                                                    time: bucketTime,  // Map to current TF bucket
                                                    price: Number(trade.price || trade.PRICE),
                                                    size: Number(trade.size || trade.SIZE),
                                                    side: trade.side || trade.SIDE
                                                };
                                                if (t.price && t.size && t.side && !isNaN(t.price) && !isNaN(t.size)) {
                                                    const sidePrefix = t.side === 'BUY' ? 'B' : 'A';
                                                    const orderKey = `${sidePrefix}_${t.price}_${t.size}_${bucketTime}`;
                                                    if (!seenMBOOrders.has(orderKey)) {
                                                        seenMBOOrders.add(orderKey);
                                                        bigOrderTrades.push(t);
                                                        bigOrdersFrom1m++;
                                                    }
                                                }
                                            });
                                        }
                                    });
                                    console.log(`[1m->TF] Checked ${oneM_keys.length} 1m records, ${recordsWithBigOrders} had big orders, loaded ${bigOrdersFrom1m} orders for ${TIMEFRAME}`);
                                    if (bigOrdersFrom1m > 0) {
                                        bigOrderCount += bigOrdersFrom1m;
                                    }
                                }
                            }
                        }
                    } catch (e) {
                        console.warn('Failed to aggregate 1m data:', e.message);
                    }
                }

                // ALWAYS load from database to get historical data from collector
                // This supplements Redis data with longer-term historical data
                console.log('[DB] Loading historical data from database...');
                const dbLoaded = await loadFromDatabaseAsync();
                loadedCount += dbLoaded.deltaCount;
                bigOrderCount += dbLoaded.bigOrderCount;

                if (ver) ver.textContent = 'v157 (' + loadedCount + ' deltas)';
                if (loadedCount > 0) {
                    const keys = Array.from(candleDeltaData.keys()).sort((a, b) => a - b);
                    const sampleKey = keys[0];
                    const sampleDate = new Date(sampleKey * 1000);
                    console.log(`Sample delta timestamp: ${sampleKey} = ${sampleDate.toISOString()}`);
                } else {
                    console.log('No delta data in Redis or database for this symbol/timeframe');
                }

                // Log big orders status
                console.log(`=== BIG ORDERS SUMMARY for ${TIMEFRAME} ===`);
                console.log(`Total bigOrderTrades: ${bigOrderTrades.length}`);
                if (bigOrderTrades.length > 0) {
                    // Show sample trades for debugging
                    const sampleTrades = bigOrderTrades.slice(0, 5);
                    sampleTrades.forEach((t, i) => {
                        const date = new Date(t.time * 1000);
                        console.log(`  [${i+1}] ${t.side} ${t.size}@${t.price} at ${date.toLocaleTimeString()} (time=${t.time})`);
                    });
                    // Show unique bucket times
                    const uniqueTimes = [...new Set(bigOrderTrades.map(t => t.time))];
                    console.log(`  Unique candle times: ${uniqueTimes.length} buckets`);
                } else {
                    console.log('No big orders found - check if bigOrderMinSize is too high or if data exists in Redis');
                }
            } catch (e) {
                console.warn('Failed to load delta data:', e.message);
                var ver = document.getElementById('version');
                if (ver) ver.textContent = 'v157 FETCH ERR';
            }
        }

        // Load from database API (fallback and for historical data)
        async function loadFromDatabaseAsync() {
            try {
                // Calculate time range (last 24 hours for historical data)
                const now = Math.floor(Date.now() / 1000);
                const twentyFourHoursAgo = now - (24 * 60 * 60);

                // ALWAYS load 1m data from database (for aggregation into any timeframe)
                const response = await fetch(
                    `${DB_API_URL}?action=get_all&symbol=${CONFIG.symbol}&timeframe=1m&start=${twentyFourHoursAgo}&delta_limit=10000&order_limit=2000`
                );

                if (!response.ok) {
                    console.warn('[DB] Failed to load from database: HTTP', response.status);
                    return { deltaCount: 0, bigOrderCount: 0 };
                }

                const result = await response.json();
                let deltaCount = 0;
                let bigOrderCount = 0;

                if (result.success) {
                    const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;

                    // Load and aggregate 1m delta data into current timeframe
                    if (result.delta && result.delta.data) {
                        const aggregated = new Map();

                        Object.keys(result.delta.data).forEach(key => {
                            const ts1m = parseInt(key);
                            const record = result.delta.data[key];

                            // Calculate which bucket this 1m record belongs to
                            const bucketTime = Math.floor(ts1m / intervalSeconds) * intervalSeconds;

                            // Skip if we already have native data for this bucket
                            if (candleDeltaData.has(bucketTime)) {
                                return;
                            }

                            if (!aggregated.has(bucketTime)) {
                                aggregated.set(bucketTime, {
                                    delta: 0,
                                    maxDelta: -Infinity,
                                    minDelta: Infinity,
                                    volume: 0,
                                    buyVolume: 0,
                                    sellVolume: 0
                                });
                            }

                            const agg = aggregated.get(bucketTime);
                            agg.delta += (record.delta || 0);
                            agg.maxDelta = Math.max(agg.maxDelta, agg.delta);
                            agg.minDelta = Math.min(agg.minDelta, agg.delta);
                            agg.volume += (record.volume || 0);
                            agg.buyVolume += (record.buyVolume || 0);
                            agg.sellVolume += (record.sellVolume || 0);
                        });

                        // Add aggregated data to candleDeltaData
                        aggregated.forEach((data, bucketTime) => {
                            if (!candleDeltaData.has(bucketTime)) {
                                if (data.maxDelta === -Infinity) data.maxDelta = data.delta;
                                if (data.minDelta === Infinity) data.minDelta = data.delta;
                                candleDeltaData.set(bucketTime, data);
                                deltaCount++;
                            }
                        });
                    }

                    // Load big orders and map to current timeframe buckets
                    if (result.bigOrders && result.bigOrders.data) {
                        result.bigOrders.data.forEach(order => {
                            const ts1m = Number(order.time);
                            // Map to current timeframe bucket
                            const bucketTime = Math.floor(ts1m / intervalSeconds) * intervalSeconds;

                            const t = {
                                time: bucketTime,  // Use bucket time for display alignment
                                price: Number(order.price),
                                size: Number(order.size),
                                side: order.side
                            };
                            if (t.price && t.size && t.side) {
                                const sidePrefix = t.side === 'BUY' ? 'B' : 'A';
                                const orderKey = `${sidePrefix}_${t.price}_${t.size}_${bucketTime}`;
                                if (!seenMBOOrders.has(orderKey)) {
                                    seenMBOOrders.add(orderKey);
                                    bigOrderTrades.push(t);
                                    bigOrderCount++;
                                }
                            }
                        });
                    }

                    console.log(`[DB] Loaded ${deltaCount} delta records, ${bigOrderCount} big orders from database (aggregated to ${TIMEFRAME})`);
                }

                return { deltaCount, bigOrderCount };
            } catch (e) {
                console.warn('[DB] Failed to load from database:', e.message);
                return { deltaCount: 0, bigOrderCount: 0 };
            }
        }

        function clearOldDeltaData() {
            // Keep only last 6 hours of delta data
            const sixHoursAgo = Math.floor(Date.now() / 1000) - (6 * 60 * 60);
            let removed = 0;
            candleDeltaData.forEach((value, key) => {
                if (key < sixHoursAgo) {
                    candleDeltaData.delete(key);
                    removed++;
                }
            });
            if (removed > 0) {
                console.log(`Cleared ${removed} old delta records (older than 6 hours)`);
            }
        }

        //=============================================================================
        // LAYOUT HELPER - v157 explicit height and display
        //=============================================================================
        function updateLayout() {
            const container = document.querySelector('.chart-container');
            const chartDiv = document.getElementById('chart');
            const deltaWrapper = document.getElementById('deltaWrapper');
            if (!container || !chartDiv || !deltaWrapper) return;

            // Get container height
            const containerHeight = container.clientHeight;
            const containerWidth = container.clientWidth;

            // Calculate chart height and set delta visibility
            let chartHeight;
            if (showDeltaStats) {
                chartHeight = containerHeight - 155;
                deltaWrapper.style.display = 'flex';
            } else {
                chartHeight = containerHeight;
                deltaWrapper.style.display = 'none';
            }

            // Set explicit pixel height on chart div
            chartDiv.style.height = chartHeight + 'px';

            console.log('v157 updateLayout: delta=' + showDeltaStats +
                        ', container=' + containerHeight +
                        ', chart=' + chartHeight);

            // Resize the LightweightCharts instance
            if (chart && containerWidth > 0 && chartHeight > 0) {
                chart.resize(containerWidth, chartHeight);
            }

            // Resize canvas for big orders (use pane dimensions if available)
            if (bigOrderCanvas && window._bigOrderOverlayParent) {
                const pane = window._bigOrderOverlayParent;
                const w = pane.clientWidth;
                const h = pane.clientHeight;
                bigOrderCanvas.width = w;
                bigOrderCanvas.height = h;
                bigOrderCanvas.style.width = w + 'px';
                bigOrderCanvas.style.height = h + 'px';
            }

            // Redraw big orders (only if chart is stable)
            if (showBigOrders && initialZoomComplete && typeof renderBigOrderCircles === 'function') {
                // Delay slightly to let chart stabilize after resize
                setTimeout(() => renderBigOrderCircles(), 50);
            }
        }

        //=============================================================================
        // CHART INITIALIZATION
        //=============================================================================
        function initChart() {
            const container = document.getElementById('chart');

            // Get actual dimensions after CSS layout
            const containerRect = container.getBoundingClientRect();
            console.log('v157 initChart rect:', containerRect.width, 'x', containerRect.height);

            // Create chart with autoSize
            chart = LightweightCharts.createChart(container, {
                autoSize: true,
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
                    scaleMargins: { top: 0.05, bottom: 0.25 },
                },
                timeScale: {
                    borderColor: '#1f1f2e',
                    timeVisible: true,
                    secondsVisible: false,
                    rightOffset: 5,
                    barSpacing: 8,
                },
                localization: {
                    timeFormatter: (time) => {
                        const date = new Date(time * 1000);
                        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
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

            // Volume series - base: 0 ensures bars start from bottom
            // Initialize with correct visibility based on showVolume
            volumeSeries = chart.addHistogramSeries({
                priceFormat: { type: 'volume' },
                priceScaleId: 'volume',
                base: 0,  // Bars start from 0
                visible: showVolume,  // Only visible if user has volume enabled
            });
            volumeSeries.priceScale().applyOptions({
                scaleMargins: { top: 0.75, bottom: 0 },  // Volume at bottom 25%
            });

            // Volume MA 20 line
            volumeMA20Series = chart.addLineSeries({
                color: '#f59e0b',
                lineWidth: 1,
                priceScaleId: 'volume',
                lastValueVisible: false,
                priceLineVisible: false,
                visible: showMA,  // Only visible if user has MA enabled
            });

            // Crosshair handler with delta tooltip below candle
            const deltaTooltip = document.getElementById('deltaTooltip');
            const chartContainer = document.getElementById('chart');

            chart.subscribeCrosshairMove(param => {
                if (param.time) {
                    const data = param.seriesData.get(candleSeries);
                    if (data) {
                        updateOHLCDisplay(data);
                    }

                    // Show delta tooltip below the candle
                    const deltaData = candleDeltaData.get(param.time);
                    if (deltaData && param.point) {
                        const delta = deltaData.delta || 0;
                        const deltaClass = delta > 0 ? 'positive' : delta < 0 ? 'negative' : '';

                        // Get the candle's low price coordinate (bottom of candle)
                        const candleLow = data ? data.low : 0;
                        const lowY = candleSeries.priceToCoordinate(candleLow);

                        deltaTooltip.innerHTML = `<span class="delta-value ${deltaClass}">${delta > 0 ? '+' : ''}${delta}</span>`;
                        deltaTooltip.style.display = 'block';

                        // Position below the candle (centered on x, below the low)
                        const tooltipWidth = deltaTooltip.offsetWidth || 40;
                        deltaTooltip.style.left = (param.point.x - tooltipWidth/2) + 'px';
                        deltaTooltip.style.top = (lowY + 10) + 'px';
                    } else {
                        deltaTooltip.style.display = 'none';
                    }
                } else {
                    deltaTooltip.style.display = 'none';
                    if (candleData.length > 0) {
                        const last = candleData[candleData.length - 1];
                        updateOHLCDisplay(last);
                    }
                }
            });

            // Create canvas overlay for big order circles
            // IMPORTANT: We need to attach to the PANE element, not chartElement
            // priceToCoordinate/timeToCoordinate return coords relative to the pane
            // The pane is inside a table structure in LightweightCharts v4
            const chartElement = chart.chartElement();

            // Find the pane element - it's the cell that contains the canvas for candles
            // In LWC v4, structure is: chartElement > table > tbody > tr > td (pane)
            // The pane td has position:relative and contains the actual chart canvases
            let paneElement = null;
            const tables = chartElement.querySelectorAll('table');
            for (const table of tables) {
                const cells = table.querySelectorAll('td');
                for (const cell of cells) {
                    // The pane cell has canvases inside it
                    if (cell.querySelector('canvas') && getComputedStyle(cell).position === 'relative') {
                        paneElement = cell;
                        break;
                    }
                }
                if (paneElement) break;
            }

            // Fallback: if we can't find pane, try the first relative-positioned element with canvas
            if (!paneElement) {
                const allElements = chartElement.querySelectorAll('*');
                for (const el of allElements) {
                    if (el.querySelector('canvas') && getComputedStyle(el).position === 'relative') {
                        paneElement = el;
                        break;
                    }
                }
            }

            // Final fallback to chartElement
            const overlayParent = paneElement || chartElement;
            console.log('BigOrder v157: pane found:', !!paneElement, 'using:', overlayParent.tagName);

            bigOrderCanvas = document.createElement('canvas');
            bigOrderCanvas.style.position = 'absolute';
            bigOrderCanvas.style.top = '0';
            bigOrderCanvas.style.left = '0';
            bigOrderCanvas.style.pointerEvents = 'none';
            bigOrderCanvas.style.zIndex = '1000';

            // Use the pane dimensions for canvas
            const canvasWidth = overlayParent.clientWidth;
            const canvasHeight = overlayParent.clientHeight;
            bigOrderCanvas.width = canvasWidth;
            bigOrderCanvas.height = canvasHeight;
            bigOrderCanvas.style.width = canvasWidth + 'px';
            bigOrderCanvas.style.height = canvasHeight + 'px';

            overlayParent.appendChild(bigOrderCanvas);
            bigOrderCtx = bigOrderCanvas.getContext('2d');
            console.log('BigOrder canvas v157: attached to', overlayParent.tagName, 'size:', bigOrderCanvas.width, 'x', bigOrderCanvas.height);

            // Store reference to overlayParent for resize
            window._bigOrderOverlayParent = overlayParent;

            // ResizeObserver - resize chart and canvas when container size changes
            const resizeObserver = new ResizeObserver(entries => {
                for (let entry of entries) {
                    const { width, height } = entry.contentRect;
                    console.log('v157 ResizeObserver:', Math.round(width), 'x', Math.round(height));
                    if (width > 0 && height > 0) {
                        // Resize the chart
                        chart.resize(width, height);
                        // Update canvas size to match pane (after chart resize)
                        if (bigOrderCanvas && window._bigOrderOverlayParent) {
                            const pane = window._bigOrderOverlayParent;
                            const w = pane.clientWidth;
                            const h = pane.clientHeight;
                            bigOrderCanvas.width = w;
                            bigOrderCanvas.height = h;
                            bigOrderCanvas.style.width = w + 'px';
                            bigOrderCanvas.style.height = h + 'px';
                        }
                        // Redraw big orders if visible
                        if (showBigOrders && !zoomedOutHidden) {
                            renderBigOrderCircles();
                        }
                    }
                }
            });
            resizeObserver.observe(container);

            // Sync delta grid and big order circles with chart's visible range
            // Smooth rendering during mouse/touch drag
            let isDragging = false;
            let animationFrameId = null;
            let zoomDebounceTimer = null;

            function smoothRenderLoop() {
                if (isDragging && showBigOrders && !zoomedOutHidden) {
                    renderBigOrderCircles();
                }
                if (isDragging) {
                    animationFrameId = requestAnimationFrame(smoothRenderLoop);
                }
            }

            // Debounced render for zoom - waits for zoom to stabilize
            function debouncedRender() {
                if (zoomDebounceTimer) {
                    clearTimeout(zoomDebounceTimer);
                }
                // Use setTimeout(0) to let chart update, then RAF to sync with paint
                zoomDebounceTimer = setTimeout(() => {
                    requestAnimationFrame(() => {
                        requestAnimationFrame(() => {
                            if (showDeltaStats && initialZoomComplete && !zoomedOutHidden) {
                                updateDeltaGrid();
                            }
                            if (showBigOrders && !zoomedOutHidden) {
                                renderBigOrderCircles();
                            }
                        });
                    });
                }, 0);
            }

            container.addEventListener('mousedown', () => {
                isDragging = true;
                if (showBigOrders && !zoomedOutHidden) {
                    smoothRenderLoop();
                }
            });
            container.addEventListener('mouseup', () => {
                isDragging = false;
                if (animationFrameId) {
                    cancelAnimationFrame(animationFrameId);
                    animationFrameId = null;
                }
                if (showBigOrders && !zoomedOutHidden) {
                    requestAnimationFrame(() => renderBigOrderCircles());
                }
            });
            container.addEventListener('mouseleave', () => {
                isDragging = false;
                if (animationFrameId) {
                    cancelAnimationFrame(animationFrameId);
                    animationFrameId = null;
                }
            });
            container.addEventListener('touchstart', () => {
                isDragging = true;
                if (showBigOrders && !zoomedOutHidden) {
                    smoothRenderLoop();
                }
            });
            container.addEventListener('touchend', () => {
                isDragging = false;
                if (animationFrameId) {
                    cancelAnimationFrame(animationFrameId);
                    animationFrameId = null;
                }
                if (showBigOrders && !zoomedOutHidden) {
                    requestAnimationFrame(() => renderBigOrderCircles());
                }
            });

            // Wheel scroll - use debounced render to wait for zoom to stabilize
            container.addEventListener('wheel', () => {
                if (showBigOrders && !zoomedOutHidden && bigOrderTrades.length > 0) {
                    debouncedRender();
                }
            }, { passive: true });

            chart.timeScale().subscribeVisibleLogicalRangeChange(() => {
                // Check how many candles are visible
                const logicalRange = chart.timeScale().getVisibleLogicalRange();
                if (logicalRange) {
                    const visibleCandles = Math.ceil(logicalRange.to - logicalRange.from);

                    // Auto-hide when zoomed out beyond threshold
                    if (visibleCandles > ZOOM_OUT_THRESHOLD && !zoomedOutHidden) {
                        zoomedOutHidden = true;
                        // Hide delta grid if it was showing
                        if (showDeltaStats) {
                            const savedDelta = showDeltaStats;
                            showDeltaStats = false;
                            updateLayout();
                            showDeltaStats = savedDelta;  // Restore flag but visually hidden
                            document.getElementById('toggleDelta').classList.remove('active');
                        }
                        // Clear big order circles if showing
                        if (showBigOrders) {
                            if (bigOrderCtx && bigOrderCanvas) {
                                bigOrderCtx.clearRect(0, 0, bigOrderCanvas.width, bigOrderCanvas.height);
                            }
                            document.getElementById('toggleBigOrders').classList.remove('active');
                        }
                        console.log(`Zoom out: ${visibleCandles} candles, hiding delta & big orders`);
                    }
                    // Auto-show when zoomed back in
                    else if (visibleCandles <= ZOOM_OUT_THRESHOLD && zoomedOutHidden) {
                        zoomedOutHidden = false;
                        // Restore delta grid ONLY if user had it enabled (showDeltaStats tracks this)
                        if (showDeltaStats) {
                            updateLayout();
                            setTimeout(updateDeltaGrid, 50);
                            document.getElementById('toggleDelta').classList.add('active');
                        }
                        // Restore big order circles ONLY if user had them enabled (showBigOrders tracks this)
                        if (showBigOrders) {
                            setTimeout(renderBigOrderCircles, 100);
                            document.getElementById('toggleBigOrders').classList.add('active');
                        }
                        console.log(`Zoom in: ${visibleCandles} candles, restored user preferences`);
                    }
                }

                // Normal updates when not zoomed out
                if (!zoomedOutHidden) {
                    // During drag, render immediately (smoothRenderLoop handles it)
                    // Otherwise use debounced render for zoom stability
                    if (isDragging) {
                        // Already handled by smoothRenderLoop
                    } else {
                        debouncedRender();
                    }
                }
            });

            // Subscribe to crosshair move - fires frequently and in sync with chart
            chart.subscribeCrosshairMove((param) => {
                if (isDragging && showBigOrders && !zoomedOutHidden) {
                    renderBigOrderCircles();
                }
            });
        }

        //=============================================================================
        // WEBSOCKET CONNECTION
        //=============================================================================
        function connectWebSocket() {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${wsProtocol}//${window.location.host}/ws/iqfeed`;

            updateStatus('connecting', 'Connecting...');
            ws = new WebSocket(wsUrl);

            ws.onopen = () => {
                console.log('WebSocket connected');
                updateStatus('connected', 'Live');

                // Request historical data
                ws.send(JSON.stringify({
                    type: 'get_history',
                    symbol: CONFIG.symbol,
                    timeframe: TIMEFRAME,
                    bars: 10000
                }));

                // Periodically sync volume from historical data (every 5 seconds)
                // This ensures live volume matches IQFeed's actual volume
                setInterval(() => {
                    if (ws.readyState === WebSocket.OPEN) {
                        ws.send(JSON.stringify({
                            type: 'get_history',
                            symbol: CONFIG.symbol,
                            timeframe: TIMEFRAME,
                            bars: 3  // Just get last 3 candles to sync volume
                        }));
                    }
                }, 5000);

                // Periodically save delta data to Redis (every 10 seconds)
                setInterval(() => {
                    saveDeltaDataNow();
                }, 10000);
            };

            ws.onmessage = (event) => {
                try {
                    const msg = JSON.parse(event.data);
                    // Debug: log message types received
                    if (!window.msgTypeCount) window.msgTypeCount = {};
                    window.msgTypeCount[msg.type] = (window.msgTypeCount[msg.type] || 0) + 1;
                    if (window.msgTypeCount[msg.type] <= 3) {
                        console.log(`WS msg type: ${msg.type}`, msg.type === 'tick' ? msg : '');
                    }
                    handleMessage(msg);
                } catch (e) {
                    console.error('Parse error:', e);
                }
            };

            ws.onerror = () => updateStatus('error', 'Error');
            ws.onclose = () => {
                updateStatus('connecting', 'Reconnecting...');
                setTimeout(connectWebSocket, 3000);
            };
        }

        //=============================================================================
        // MESSAGE HANDLING
        //=============================================================================
        function handleMessage(msg) {
            if (msg.symbol && msg.symbol !== CONFIG.symbol) return;

            switch (msg.type) {
                case 'historical_candles':
                    if (msg.timeframe === TIMEFRAME) {
                        handleHistoricalCandles(msg.candles);
                    }
                    break;

                case 'candle':
                    if (msg.timeframe === TIMEFRAME) {
                        handleLiveCandle(msg.data);
                    }
                    break;

                case 'tick':
                    handleTick(msg.price, msg.size, msg.bid, msg.ask);
                    break;

                case 'orderbook':
                    handleOrderbook(msg.data);
                    break;
            }
        }

        //=============================================================================
        // HISTORICAL DATA
        // Handles both initial load and periodic volume sync
        //=============================================================================
        let initialLoadDone = false;
        let isTimeframeChange = false;  // Track if we're switching timeframes
        let savedTimeRange = null;  // Preserve zoom level across timeframe changes

        function handleHistoricalCandles(candles) {
            if (!candles || candles.length === 0) return;

            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const isVolumeSync = initialLoadDone && candles.length <= 10;

            if (isVolumeSync) {
                // Volume sync - ONLY update CURRENT candle, previous candles are LOCKED
                const lastCandleTime = candleData.length > 0 ? candleData[candleData.length - 1].time : 0;

                candles.forEach(c => {
                    const timeSeconds = Math.floor(c.time / 1000);
                    const candleTime = Math.floor(timeSeconds / intervalSeconds) * intervalSeconds;

                    // Only process current candle - previous candles are completely LOCKED
                    if (candleTime === lastCandleTime) {
                        const existingIndex = candleData.findIndex(cd => cd.time === candleTime);
                        if (existingIndex >= 0) {
                            const existing = candleData[existingIndex];
                            // Update current candle's volume if historical is higher
                            const newVolume = Math.max(c.volume || 0, existing.volume || 0);
                            if (newVolume !== existing.volume) {
                                existing.volume = newVolume;
                                updateVolumeBar(existing);
                            }
                        }
                    }
                    // Previous candles: DO NOT UPDATE - they are LOCKED
                });

                if (candleData.length > 0) {
                    updateOHLCDisplay(candleData[candleData.length - 1]);
                }
                return;
            }

            // Initial load - build full candle data
            const candleMap = new Map();
            const processedRawTimes = new Set(); // Track processed candle times to avoid duplicates

            candles.forEach(c => {
                const rawTimeMs = c.time;
                // Skip if we've already processed this exact raw time
                if (processedRawTimes.has(rawTimeMs)) {
                    return;
                }
                processedRawTimes.add(rawTimeMs);

                const timeSeconds = Math.floor(c.time / 1000);
                const candleTime = Math.floor(timeSeconds / intervalSeconds) * intervalSeconds;

                if (candleMap.has(candleTime)) {
                    const existing = candleMap.get(candleTime);
                    candleMap.set(candleTime, {
                        time: candleTime,
                        open: existing.open,
                        high: Math.max(existing.high, c.high),
                        low: Math.min(existing.low, c.low),
                        close: c.close,
                        volume: (existing.volume || 0) + (c.volume || 0)
                    });
                } else {
                    candleMap.set(candleTime, {
                        time: candleTime,
                        open: c.open,
                        high: c.high,
                        low: c.low,
                        close: c.close,
                        volume: c.volume || 0
                    });
                }
            });

            candleData = Array.from(candleMap.values()).sort((a, b) => a.time - b.time);

            // Check for volume anomalies (spikes > 10x average)
            if (candleData.length > 20) {
                const volumes = candleData.map(c => c.volume || 0);
                const avgVolume = volumes.reduce((a, b) => a + b, 0) / volumes.length;
                const anomalies = candleData.filter(c => (c.volume || 0) > avgVolume * 10);
                if (anomalies.length > 0) {
                    console.warn(`Volume anomaly check: ${anomalies.length} candles with volume > 10x average (${avgVolume.toFixed(0)})`);
                    anomalies.slice(0, 5).forEach(c => {
                        console.warn(`  ${new Date(c.time * 1000).toISOString()}: volume=${c.volume} (${(c.volume/avgVolume).toFixed(1)}x avg)`);
                    });
                }
            }

            // Force continuity: each candle's open = previous candle's close
            // BUT preserve gaps between different days (weekend, overnight)
            for (let i = 1; i < candleData.length; i++) {
                const prevTime = new Date(candleData[i - 1].time * 1000);
                const currTime = new Date(candleData[i].time * 1000);

                // Check if same trading day (same date)
                const sameDay = prevTime.getUTCFullYear() === currTime.getUTCFullYear() &&
                                prevTime.getUTCMonth() === currTime.getUTCMonth() &&
                                prevTime.getUTCDate() === currTime.getUTCDate();

                if (sameDay) {
                    // Same day: apply continuity
                    const prevClose = candleData[i - 1].close;
                    candleData[i].open = prevClose;
                    candleData[i].high = Math.max(candleData[i].high, prevClose);
                    candleData[i].low = Math.min(candleData[i].low, prevClose);
                }
                // Different day: keep original open (preserve gap)
            }

            // Verify data is sorted and no duplicates before setting
            let sortIssues = 0;
            let duplicates = 0;
            for (let i = 1; i < candleData.length; i++) {
                if (candleData[i].time < candleData[i-1].time) {
                    sortIssues++;
                    console.error(`Sort issue at index ${i}: ${candleData[i-1].time} > ${candleData[i].time}`);
                }
                if (candleData[i].time === candleData[i-1].time) {
                    duplicates++;
                    console.error(`Duplicate time at index ${i}: ${candleData[i].time}`);
                }
            }
            if (sortIssues > 0 || duplicates > 0) {
                console.warn(`Data issues: ${sortIssues} sort problems, ${duplicates} duplicates. Re-sorting and deduping...`);
                // Remove duplicates and re-sort
                const deduped = new Map();
                candleData.forEach(c => deduped.set(c.time, c));
                candleData = Array.from(deduped.values()).sort((a, b) => a.time - b.time);
            }

            // Set candle data
            candleSeries.setData(candleData);

            // Set volume with colors based on candle direction (80% opacity)
            // Only if volume is enabled (delta and volume are mutually exclusive)
            if (showVolume) {
                volumeSeries.setData(candleData.map(c => ({
                    time: c.time,
                    value: c.volume,
                    color: c.close >= c.open ? '#22c55ecc' : '#ef4444cc'
                })));
            }


            if (candleData.length > 0) {
                const last = candleData[candleData.length - 1];
                currentPrice = last.close;
                sessionOpen = candleData[0].open;
                updatePriceDisplay(currentPrice);
                updateOHLCDisplay(last);
                updateBarCount();
            }

            // Update MA20 if enabled (delta and MA are mutually exclusive)
            if (showMA) {
                updateVolumeMA20();
            }

            // Hide loading overlay after data is set
            document.getElementById('loadingOverlay').classList.add('hidden');
            initialLoadDone = true;

            // Zoom AFTER chart renders data (use requestAnimationFrame for smooth transition)
            requestAnimationFrame(() => {
                if (candleData.length === 0) return;

                const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                const lastCandleTime = candleData[candleData.length - 1].time;
                const firstCandleTime = candleData[0].time;

                // Preserve time range across timeframe changes
                if (isTimeframeChange && savedTimeRange) {
                    // Only restore if we have enough historical data (firstCandleTime should be before our saved range)
                    // If firstCandleTime is after savedTimeRange.from, we don't have full history yet - wait
                    if (firstCandleTime <= savedTimeRange.from || candleData.length > 50) {
                        // We have enough data to restore the range
                        const clampedFrom = Math.max(savedTimeRange.from, firstCandleTime);
                        const clampedTo = Math.min(savedTimeRange.to, lastCandleTime + intervalSeconds);

                        console.log(`[TF] Restoring time range: ${new Date(clampedFrom * 1000).toLocaleTimeString()} - ${new Date(clampedTo * 1000).toLocaleTimeString()} (${candleData.length} candles)`);

                        chart.timeScale().setVisibleRange({
                            from: clampedFrom,
                            to: clampedTo
                        });

                        savedTimeRange = null;
                        isTimeframeChange = false;
                    } else {
                        console.log(`[TF] Waiting for more data: firstCandle=${new Date(firstCandleTime * 1000).toLocaleTimeString()}, savedFrom=${new Date(savedTimeRange.from * 1000).toLocaleTimeString()}, candles=${candleData.length}`);
                        // Don't clear savedTimeRange - wait for next historical_candles call
                    }
                } else if (!isTimeframeChange) {
                    // Normal zoom for initial load or periodic sync
                    const deltaZoomBars = showDeltaStats ? 40 : 100;
                    let barsToShow = deltaZoomBars;

                    if (showDeltaStats) {
                        barsToShow = Math.min(40, candleData.length);
                    } else if (showBigOrders) {
                        barsToShow = 25;
                    } else {
                        barsToShow = Math.min(100, candleData.length);
                    }

                    const fromTime = lastCandleTime - (barsToShow * intervalSeconds);
                    chart.timeScale().setVisibleRange({
                        from: fromTime,
                        to: lastCandleTime + intervalSeconds
                    });
                }
                // If isTimeframeChange but no savedTimeRange, wait for next historical_candles

                // Reset zoomedOutHidden since we just zoomed in
                // Also restore button states and render big orders
                zoomedOutHidden = false;
                if (userWantsDelta && showDeltaStats) {
                    document.getElementById('toggleDelta').classList.add('active');
                    updateLayout();
                }
                if (userWantsBigOrders && showBigOrders) {
                    document.getElementById('toggleBigOrders').classList.add('active');
                    renderBigOrderCircles();
                }
            });

            // Merge saved candles (from Redis) with historical candles
            if (savedCandles.size > 0 && candleData.length > 0) {
                const existingTimes = new Set(candleData.map(c => c.time));
                let injectedCount = 0;
                savedCandles.forEach((candle, ts) => {
                    if (!existingTimes.has(ts)) {
                        candleData.push(candle);
                        injectedCount++;
                    }
                });
                if (injectedCount > 0) {
                    // Re-sort by time after injection
                    candleData.sort((a, b) => a.time - b.time);
                    // Re-render chart with merged data
                    candleSeries.setData(candleData);
                    // Only set volume data if volume is enabled
                    if (showVolume) {
                        volumeSeries.setData(candleData.map(c => ({
                            time: c.time,
                            value: c.volume || 0,
                            color: c.close >= c.open ? '#22c55ecc' : '#ef4444cc'
                        })));
                    }
                    console.log(`Injected ${injectedCount} saved candles from Redis`);
                }
            }

            // Log candle timestamps for debugging
            if (candleData.length > 0) {
                const firstCandle = candleData[0];
                const lastCandle = candleData[candleData.length - 1];
                console.log(`Total ${candleData.length} candles after merge`);
                console.log(`First candle: ${firstCandle.time} = ${new Date(firstCandle.time * 1000).toISOString()}`);
                console.log(`Last candle: ${lastCandle.time} = ${new Date(lastCandle.time * 1000).toISOString()}`);

                // Realign delta data to match actual candle timestamps
                // This fixes mismatches caused by timezone/rounding differences
                const candleTimeSet = new Set(candleData.map(c => c.time));
                const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                const realignedDelta = new Map();
                let exactMatches = 0;
                let realignedCount = 0;
                let futureCount = 0;
                let pastCount = 0;

                candleDeltaData.forEach((data, deltaTs) => {
                    if (candleTimeSet.has(deltaTs)) {
                        // Exact match - keep as is
                        realignedDelta.set(deltaTs, data);
                        exactMatches++;
                    } else if (deltaTs > lastCandle.time) {
                        // Future timestamp - keep for when market opens
                        realignedDelta.set(deltaTs, data);
                        futureCount++;
                    } else if (deltaTs < firstCandle.time) {
                        // Too old - discard
                        pastCount++;
                    } else {
                        // Within candle range but no exact match - find closest
                        let closestCandle = null;
                        let minDiff = Infinity;
                        candleData.forEach(c => {
                            const diff = Math.abs(c.time - deltaTs);
                            if (diff < minDiff && diff <= intervalSeconds) {
                                minDiff = diff;
                                closestCandle = c.time;
                            }
                        });
                        if (closestCandle !== null && !realignedDelta.has(closestCandle)) {
                            realignedDelta.set(closestCandle, data);
                            realignedCount++;
                        }
                    }
                });

                // Replace original delta data with realigned data
                candleDeltaData.clear();
                realignedDelta.forEach((data, ts) => candleDeltaData.set(ts, data));

                console.log(`Delta alignment: ${exactMatches} exact, ${realignedCount} realigned, ${futureCount} future (waiting for candles), ${pastCount} too old (discarded)`);

                // Check how many deltas match existing candles
                let matchCount = 0;
                candleData.forEach(c => {
                    if (candleDeltaData.has(c.time)) matchCount++;
                });

                console.log(`Delta data showing: ${matchCount}/${candleData.length} candles have delta data`);
            }

            // Update delta grid with all candles (only real saved data shown, no estimates)
            // Use setTimeout to wait for chart zoom animation to complete before calculating alignment
            setTimeout(() => {
                updateDeltaGrid();
            }, 100);

            // Log big order count (don't render yet - wait for chart to stabilize)
            // Note: Zoom is already handled above based on showBigOrders/showDeltaStats
            if (bigOrderTrades.length > 0 && showBigOrders) {
                console.log(`Big orders loaded: ${bigOrderTrades.length} trades (will render after chart stabilizes)`);
            } else if (showBigOrders) {
                console.log(`BIG is on but no big orders loaded from Redis (bigOrderTrades.length = ${bigOrderTrades.length})`);
            }

            // Ensure delta grid alignment after chart is fully rendered
            // Set initialZoomComplete first, then render big orders
            if (showDeltaStats) {
                setTimeout(() => updateDeltaGrid(), 100);
                setTimeout(() => {
                    updateDeltaGrid();
                    initialZoomComplete = true;  // Enable subscription handler BEFORE render
                    if (showBigOrders) renderBigOrderCircles();
                }, 250);
                // Second pass for stability
                setTimeout(() => {
                    if (showBigOrders) renderBigOrderCircles();
                }, 500);
            } else {
                // Set flag first, then render big orders
                setTimeout(() => {
                    initialZoomComplete = true;  // Enable BEFORE render
                    if (showBigOrders) renderBigOrderCircles();
                }, 250);
                // Second pass for stability
                setTimeout(() => {
                    if (showBigOrders) renderBigOrderCircles();
                }, 500);
            }
        }

        //=============================================================================
        // VOLUME BAR HELPER - Single function to update volume bar
        // Ensures consistent color and value across all updates
        //=============================================================================
        function updateVolumeBar(candle) {
            if (!candle || !showVolume) return;

            // Green if close >= open (bullish), Red if close < open (bearish)
            const isBullish = candle.close >= candle.open;
            // Using 80% opacity (cc in hex) for better visibility
            const color = isBullish ? '#22c55ecc' : '#ef4444cc';

            volumeSeries.update({
                time: candle.time,
                value: candle.volume || 0,
                color: color
            });
        }

        //=============================================================================
        // LIVE CANDLE UPDATES
        // Uses bridge volume for CURRENT candle (historical doesn't have it yet)
        // Historical sync will correct older candles
        //=============================================================================
        function handleLiveCandle(candle) {
            if (!candle) return;

            const timeSeconds = Math.floor(candle.time / 1000);
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const candleTime = Math.floor(timeSeconds / intervalSeconds) * intervalSeconds;

            const existingIndex = candleData.findIndex(c => c.time === candleTime);
            const lastCandleTime = candleData.length > 0 ? candleData[candleData.length - 1].time : 0;

            let updatedCandle;

            if (existingIndex >= 0) {
                // Updating existing candle
                const existing = candleData[existingIndex];
                const isCurrentCandle = (candleTime === lastCandleTime);

                // Only update CURRENT candle - previous candles are LOCKED
                if (!isCurrentCandle) {
                    return;
                }

                // Update current candle
                existing.high = Math.max(existing.high, candle.high);
                existing.low = Math.min(existing.low, candle.low);
                existing.close = candle.close;
                existing.volume = Math.max(candle.volume || 0, existing.volume || 0);

                updatedCandle = existing;

                // Update chart - candle and volume use SAME object
                candleSeries.update(updatedCandle);
                updateVolumeBar(updatedCandle);

            } else if (candleTime > lastCandleTime) {
                // New candle starting - save delta data for previous candle
                saveDeltaDataNow();

                const prevCandle = candleData[candleData.length - 1];
                let useActualOpen = true;

                if (prevCandle) {
                    const prevTime = new Date(prevCandle.time * 1000);
                    const currTime = new Date(candleTime * 1000);

                    // Check if same trading day
                    const sameDay = prevTime.getUTCFullYear() === currTime.getUTCFullYear() &&
                                    prevTime.getUTCMonth() === currTime.getUTCMonth() &&
                                    prevTime.getUTCDate() === currTime.getUTCDate();

                    if (sameDay) {
                        // Same day: LOCK previous candle at new candle's open
                        // IMPORTANT: Only change OHLC, NEVER change volume
                        const lockedVolume = prevCandle.volume;  // Preserve volume
                        prevCandle.close = candle.open;
                        prevCandle.high = Math.max(prevCandle.high, candle.open);
                        prevCandle.low = Math.min(prevCandle.low, candle.open);
                        prevCandle.volume = lockedVolume;  // Ensure volume unchanged

                        candleSeries.update(prevCandle);
                        // Update volume bar color only (volume value is locked)
                        updateVolumeBar(prevCandle);

                        useActualOpen = false;
                    }
                }

                // Create new candle
                // If same day: use previous candle's close as open (continuity)
                // If different day: use actual candle.open (preserve gap)
                const openPrice = useActualOpen ? candle.open : (prevCandle ? prevCandle.close : candle.open);
                updatedCandle = {
                    time: candleTime,
                    open: openPrice,
                    high: Math.max(candle.high, openPrice),
                    low: Math.min(candle.low, openPrice),
                    close: candle.close,
                    volume: candle.volume || 0
                };
                candleData.push(updatedCandle);
                updateBarCount();

                candleSeries.update(updatedCandle);
                updateVolumeBar(updatedCandle);

                // Auto-scroll to keep latest candle visible
                if (autoScroll) {
                    chart.timeScale().scrollToRealTime();
                }

            } else {
                return;
            }

            currentPrice = updatedCandle.close;
            updatePriceDisplay(currentPrice);
            updateOHLCDisplay(updatedCandle);

            // Update delta grid when candle changes
            updateDeltaGrid();
        }

        //=============================================================================
        // TICK DATA
        // Updates price display AND tracks delta (buy vs sell volume)
        // Each tick is classified as buy (at ask) or sell (at bid)
        //=============================================================================
        function handleTick(price, size, tickBid, tickAsk) {
            if (!price) return;

            currentPrice = price;
            updatePriceDisplay(price);

            // Use bid/ask from tick message (preferred) or fall back to orderbook
            const bid = tickBid > 0 ? tickBid : currentBestBid;
            const ask = tickAsk > 0 ? tickAsk : currentBestAsk;

            // Update global bid/ask if tick provided them
            if (tickBid > 0) currentBestBid = tickBid;
            if (tickAsk > 0) currentBestAsk = tickAsk;

            // Debug: log first few ticks to verify data
            if (!window.tickDebugCount) window.tickDebugCount = 0;
            if (window.tickDebugCount < 10) {
                console.log(`Tick #${window.tickDebugCount}: price=${price}, size=${size}, bid=${bid}, ask=${ask}, candles=${candleData.length}`);
                window.tickDebugCount++;
            }

            if (size > 0 && (bid > 0 || ask > 0) && candleData.length > 0) {
                // Use the CURRENT candle's actual timestamp from candleData
                // This ensures delta data aligns with candle timestamps
                const lastCandle = candleData[candleData.length - 1];
                const candleTime = lastCandle.time;

                // Initialize orderflow for this candle if needed
                if (!candleOrderflow.has(candleTime)) {
                    candleOrderflow.set(candleTime, {
                        buyVolume: 0,
                        sellVolume: 0,
                        bigBids: 0,
                        bigAsks: 0,
                    });
                }
                const flow = candleOrderflow.get(candleTime);

                // Classify trade as buy or sell using bid/ask from tick
                // Buy = executed at/above ask (buyer aggressor lifting offers)
                // Sell = executed at/below bid (seller aggressor hitting bids)
                let isBuy = false;
                if (ask > 0 && price >= ask) {
                    // Trade at or above ask = buyer aggressor (buying)
                    flow.buyVolume += size;
                    sessionStats.totalBuyVolume += size;
                    isBuy = true;
                } else if (bid > 0 && price <= bid) {
                    // Trade at or below bid = seller aggressor (selling)
                    flow.sellVolume += size;
                    sessionStats.totalSellVolume += size;
                } else if (bid > 0 && ask > 0) {
                    // Trade between bid and ask - classify by proximity
                    const midpoint = (bid + ask) / 2;
                    if (price >= midpoint) {
                        flow.buyVolume += size;
                        sessionStats.totalBuyVolume += size;
                        isBuy = true;
                    } else {
                        flow.sellVolume += size;
                        sessionStats.totalSellVolume += size;
                    }
                } else {
                    // Fallback - use tick direction
                    if (price >= currentPrice) {
                        flow.buyVolume += size;
                        sessionStats.totalBuyVolume += size;
                        isBuy = true;
                    } else {
                        flow.sellVolume += size;
                        sessionStats.totalSellVolume += size;
                    }
                }

                // ALWAYS track 1m data regardless of viewing timeframe
                // This ensures we have granular data for all timeframe aggregation
                const nowSeconds = Math.floor(Date.now() / 1000);
                const oneMinTime = Math.floor(nowSeconds / 60) * 60;  // 1m bucket
                if (!oneMinuteOrderflow.has(oneMinTime)) {
                    oneMinuteOrderflow.set(oneMinTime, { buyVolume: 0, sellVolume: 0 });
                }
                const flow1m = oneMinuteOrderflow.get(oneMinTime);
                if (isBuy) {
                    flow1m.buyVolume += size;
                } else {
                    flow1m.sellVolume += size;
                }
                // Update 1m delta data
                const delta1m = flow1m.buyVolume - flow1m.sellVolume;
                let deltaData1m = oneMinuteDeltaData.get(oneMinTime);
                if (!deltaData1m) {
                    deltaData1m = { delta: delta1m, maxDelta: delta1m, minDelta: delta1m, volume: 0, buyVolume: flow1m.buyVolume, sellVolume: flow1m.sellVolume };
                } else {
                    deltaData1m.delta = delta1m;
                    deltaData1m.maxDelta = Math.max(deltaData1m.maxDelta, delta1m);
                    deltaData1m.minDelta = Math.min(deltaData1m.minDelta, delta1m);
                    deltaData1m.buyVolume = flow1m.buyVolume;
                    deltaData1m.sellVolume = flow1m.sellVolume;
                }
                oneMinuteDeltaData.set(oneMinTime, deltaData1m);

                // Accumulate volume per price level within each candle
                // When cumulative volume at a price exceeds threshold, show big order
                const priceKey = `${candleTime}_${price.toFixed(1)}_${isBuy ? 'B' : 'S'}`;
                const prevVolume = priceVolumeMap.get(priceKey) || 0;
                const newVolume = prevVolume + size;
                priceVolumeMap.set(priceKey, newVolume);

                // Check if this price level just crossed the threshold
                const wasAboveThreshold = prevVolume >= CONFIG.bigOrderMinSize;
                const isAboveThreshold = newVolume >= CONFIG.bigOrderMinSize;

                if (isAboveThreshold && !wasAboveThreshold) {
                    // First time crossing threshold for this price level
                    // ALWAYS use 1m timestamp for storage (can be mapped to any timeframe on display)
                    bigOrderTrades.push({
                        time: oneMinTime,  // Use 1m bucket for cross-timeframe compatibility
                        price: price,
                        size: newVolume,
                        side: isBuy ? 'BUY' : 'SELL',
                        source: 'trade'
                    });
                    sessionStats.bigOrderCount++;
                    console.log(`BIG VOLUME ${isBuy ? 'BUY' : 'SELL'}: ${newVolume}@${price.toFixed(CONFIG.decimals)} (1m time: ${oneMinTime})`);
                    if (showBigOrders) {
                        renderBigOrderCircles();
                    }
                } else if (isAboveThreshold) {
                    // Update existing big order size
                    const existingOrder = bigOrderTrades.find(o =>
                        o.time === oneMinTime &&
                        o.price.toFixed(1) === price.toFixed(1) &&
                        o.side === (isBuy ? 'BUY' : 'SELL')
                    );
                    if (existingOrder) {
                        existingOrder.size = newVolume;
                    }
                }

                // Calculate delta for this candle
                const delta = flow.buyVolume - flow.sellVolume;

                // Update delta data using the candle's actual timestamp
                let deltaData = candleDeltaData.get(candleTime);
                if (!deltaData) {
                    deltaData = {
                        delta: delta,
                        deltaChange: 0,
                        maxDelta: delta,
                        minDelta: delta,
                        volume: lastCandle.volume || 0
                    };
                } else {
                    deltaData.delta = delta;
                    deltaData.maxDelta = Math.max(deltaData.maxDelta, delta);
                    deltaData.minDelta = Math.min(deltaData.minDelta, delta);
                    deltaData.volume = lastCandle.volume || 0;
                }

                candleDeltaData.set(candleTime, deltaData);

                // Log delta recording (first few times per candle)
                if (!deltaData.logged || deltaData.logged < 3) {
                    console.log(`Delta recorded: time=${candleTime} (${new Date(candleTime * 1000).toLocaleTimeString()}), delta=${delta}, buy=${flow.buyVolume}, sell=${flow.sellVolume}`);
                    deltaData.logged = (deltaData.logged || 0) + 1;
                }

                // Save periodically (not every tick to reduce overhead)
                if (size >= 5) {
                    saveDeltaData();
                }

                // Update grid
                updateDeltaGrid();
            }

            const nowSeconds = Math.floor(Date.now() / 1000);
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            const candleTime = Math.floor(nowSeconds / intervalSeconds) * intervalSeconds;

            if (candleData.length === 0) return;

            const lastCandle = candleData[candleData.length - 1];

            if (lastCandle.time === candleTime) {
                // Update price only - volume comes from candle messages
                lastCandle.close = price;
                lastCandle.high = Math.max(lastCandle.high, price);
                lastCandle.low = Math.min(lastCandle.low, price);

                candleSeries.update(lastCandle);
                updateVolumeBar(lastCandle);  // Use same candle object
                updateOHLCDisplay(lastCandle);

            } else if (candleTime > lastCandle.time) {
                // New candle starting from tick
                const prevTime = new Date(lastCandle.time * 1000);
                const currTime = new Date(candleTime * 1000);

                const sameDay = prevTime.getUTCFullYear() === currTime.getUTCFullYear() &&
                                prevTime.getUTCMonth() === currTime.getUTCMonth() &&
                                prevTime.getUTCDate() === currTime.getUTCDate();

                if (sameDay) {
                    // Same day: LOCK previous candle
                    // IMPORTANT: Only change OHLC, NEVER change volume
                    const lockedVolume = lastCandle.volume;  // Preserve volume
                    lastCandle.close = price;
                    lastCandle.high = Math.max(lastCandle.high, price);
                    lastCandle.low = Math.min(lastCandle.low, price);
                    lastCandle.volume = lockedVolume;  // Ensure volume unchanged

                    candleSeries.update(lastCandle);
                    updateVolumeBar(lastCandle);
                }

                // Create new candle
                const newCandle = {
                    time: candleTime,
                    open: price,
                    high: price,
                    low: price,
                    close: price,
                    volume: 0
                };
                candleData.push(newCandle);
                updateBarCount();

                candleSeries.update(newCandle);
                updateVolumeBar(newCandle);
                updateOHLCDisplay(newCandle);

                // Auto-scroll to show latest candle when new candle is created
                if (autoScroll) {
                    chart.timeScale().scrollToRealTime();
                }
            }
        }

        //=============================================================================
        // ORDERBOOK / MBO DATA - Big Order Detection & Aggregation
        //=============================================================================
        function handleOrderbook(data) {
            if (!data) return;

            // Update best bid/ask for trade classification in handleTick
            // These are used to determine if a trade was a buy (at ask) or sell (at bid)
            if (data.best_bid > 0) {
                currentBestBid = data.best_bid;
            }
            if (data.best_ask > 0) {
                currentBestAsk = data.best_ask;
            }

            // Note: Delta is now calculated from EXECUTED TRADES in handleTick()
            // Not from resting orders in the orderbook
            // This is the correct way to calculate delta:
            // - Buy (positive delta) = trade at/above ask price (buyer aggressor)
            // - Sell (negative delta) = trade at/below bid price (seller aggressor)

            // Big order detection from orderbook (resting orders/walls)
            // Since IQFeed sends tick size=1, we detect large resting orders instead
            if (candleData.length === 0) return;

            const lastCandle = candleData[candleData.length - 1];
            const candleTime = lastCandle.time;

            let ordersAdded = false;

            // DISABLED: MBO orderbook-based big orders - they cluster at support/resistance levels
            // Instead, we detect big orders from actual executed trades in handleTick()
            // This ensures balls appear at actual trade prices, not orderbook levels
            /*
            // Check bids for large resting orders
            // BIDS = BUY orders = support (below current price) = GREEN
            if (data.bids && data.bids.length > 0) {
                // Debug first bid
                if (!window._bidDebugDone) {
                    console.log('[MBO DEBUG] First bid entry:', data.bids[0], 'type:', typeof data.bids[0][0]);
                    window._bidDebugDone = true;
                }
                data.bids.forEach(([price, size]) => {
                    // Ensure price is a number
                    const numPrice = Number(price);
                    const numSize = Number(size);
                    if (numSize >= CONFIG.bigOrderMinSize) {
                        // Key WITHOUT candleTime - each unique price+size is only added ONCE
                        // MBO orders are resting limit orders that persist across candles
                        const orderKey = `B_${numPrice}_${numSize}`;
                        if (!seenMBOOrders.has(orderKey)) {
                            seenMBOOrders.add(orderKey);

                            // Bids are BUY orders (support) - GREEN balls
                            bigOrderTrades.push({
                                time: candleTime,
                                price: numPrice,
                                size: numSize,
                                side: 'BUY'
                            });
                            console.log(`[MBO] Added BUY (bid) at ${numPrice.toFixed(1)}, time=${candleTime}, total bigOrderTrades=${bigOrderTrades.length}`);

                            // Also update aggregated data
                            const aggKey = `${candleTime}_BID`;
                            const agg = aggregatedBigOrders.get(aggKey) || { count: 0, totalSize: 0, priceSum: 0 };
                            agg.count++;
                            agg.totalSize += size;
                            agg.priceSum += price * size;
                            aggregatedBigOrders.set(aggKey, agg);

                            sessionStats.bigOrderCount++;
                            console.log(`BIG BUY (support): ${size}@${price.toFixed(1)}`);
                            ordersAdded = true;
                        }
                    }
                });
            }

            // Check asks for large resting orders
            // ASKS = SELL orders = resistance (above current price) = RED
            if (data.asks && data.asks.length > 0) {
                // Debug first ask
                if (!window._askDebugDone) {
                    console.log('[MBO DEBUG] First ask entry:', data.asks[0], 'type:', typeof data.asks[0][0]);
                    window._askDebugDone = true;
                }
                data.asks.forEach(([price, size]) => {
                    // Ensure price is a number
                    const numPrice = Number(price);
                    const numSize = Number(size);
                    if (numSize >= CONFIG.bigOrderMinSize) {
                        // Key WITHOUT candleTime - each unique price+size is only added ONCE
                        // MBO orders are resting limit orders that persist across candles
                        const orderKey = `A_${numPrice}_${numSize}`;
                        if (!seenMBOOrders.has(orderKey)) {
                            seenMBOOrders.add(orderKey);

                            // Asks are SELL orders (resistance) - RED balls
                            bigOrderTrades.push({
                                time: candleTime,
                                price: numPrice,
                                size: numSize,
                                side: 'SELL'
                            });
                            console.log(`[MBO] Added SELL (ask) at ${numPrice.toFixed(1)}, time=${candleTime}, total bigOrderTrades=${bigOrderTrades.length}`);

                            // Also update aggregated data
                            const aggKey = `${candleTime}_ASK`;
                            const agg = aggregatedBigOrders.get(aggKey) || { count: 0, totalSize: 0, priceSum: 0 };
                            agg.count++;
                            agg.totalSize += size;
                            agg.priceSum += price * size;
                            aggregatedBigOrders.set(aggKey, agg);

                            sessionStats.bigOrderCount++;
                            console.log(`BIG SELL (resistance): ${size}@${price.toFixed(1)}`);
                            ordersAdded = true;
                        }
                    }
                });
            }

            // Render circles if any new orders found
            if (ordersAdded && showBigOrders) {
                renderBigOrderCircles();
            }
            */
            // MBO orderbook processing disabled - using tick-based big trade detection only
        }

        //=============================================================================
        // DELTA GRID UPDATE - Table aligned with chart
        //=============================================================================
        function updateDeltaGrid() {
            const deltaGrid = document.getElementById('deltaGrid');

            if (!showDeltaStats || candleData.length === 0 || !deltaGrid || !chart) {
                return;
            }

            // Get visible candles from chart's logical range
            const logicalRange = chart.timeScale().getVisibleLogicalRange();
            if (!logicalRange) return;

            // Use ceiling for from and floor for to to only get fully visible candles
            const fromIndex = Math.max(0, Math.ceil(logicalRange.from));
            const toIndex = Math.min(candleData.length - 1, Math.floor(logicalRange.to));
            if (fromIndex > toIndex) return;

            const visibleCandles = candleData.slice(fromIndex, toIndex + 1);

            // Get bar spacing - cells must match exactly for alignment
            const barSpacing = chart.timeScale().options().barSpacing || 8;
            const cellWidth = barSpacing; // Exact match for alignment

            // Calculate offset to center cells under candle wicks
            // timeToCoordinate returns the CENTER of the candle
            const firstCandleX = chart.timeScale().timeToCoordinate(visibleCandles[0].time);

            // To center cell under candle: cell center should be at firstCandleX
            // Cell left edge = firstCandleX - cellWidth/2
            // No label column on left anymore (labels moved to right panel)
            const leftOffset = firstCandleX !== null ? Math.max(0, firstCandleX - cellWidth/2) : 0;

            console.log('Alignment: barSpacing=' + barSpacing + ', cellWidth=' + cellWidth + ', firstCandleX=' + Math.round(firstCandleX) + ', leftOffset=' + Math.round(leftOffset));

            // Get rows
            const rowTime = document.getElementById('rowTime');
            const rowDelta = document.getElementById('rowDelta');
            const rowDeltaChange = document.getElementById('rowDeltaChange');
            const rowMaxDelta = document.getElementById('rowMaxDelta');
            const rowMinDelta = document.getElementById('rowMinDelta');
            const rowVolume = document.getElementById('rowVolume');

            // Clear existing cells (keep th)
            [rowTime, rowDelta, rowDeltaChange, rowMaxDelta, rowMinDelta, rowVolume].forEach(row => {
                while (row.children.length > 1) row.removeChild(row.lastChild);
            });

            // Add spacer cell for alignment
            if (leftOffset > 0) {
                [rowTime, rowDelta, rowDeltaChange, rowMaxDelta, rowMinDelta, rowVolume].forEach(row => {
                    const spacer = document.createElement('td');
                    spacer.style.width = leftOffset + 'px';
                    spacer.style.minWidth = leftOffset + 'px';
                    spacer.style.padding = '0';
                    spacer.style.border = 'none';
                    row.appendChild(spacer);
                });
            }

            let prevDelta = null;
            let matchedCount = 0;

            visibleCandles.forEach((candle) => {
                const time = candle.time;
                const deltaData = candleDeltaData.get(time);
                const hasData = !!deltaData;
                if (hasData) matchedCount++;

                const timeStr = new Date(time * 1000).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });

                // Time
                const tdTime = document.createElement('td');
                tdTime.textContent = timeStr;
                tdTime.style.width = cellWidth + 'px';
                tdTime.style.minWidth = cellWidth + 'px';
                tdTime.style.maxWidth = cellWidth + 'px';
                tdTime.style.padding = '0';
                tdTime.style.color = '#6b7280';
                tdTime.style.fontSize = '8px';
                tdTime.style.overflow = 'hidden';
                rowTime.appendChild(tdTime);

                // Helper to set fixed cell width
                const setFixedWidth = (td) => {
                    td.style.width = cellWidth + 'px';
                    td.style.minWidth = cellWidth + 'px';
                    td.style.maxWidth = cellWidth + 'px';
                    td.style.padding = '0';
                    td.style.overflow = 'hidden';
                    td.style.fontSize = '9px';
                };

                // Delta
                const tdDelta = document.createElement('td');
                setFixedWidth(tdDelta);
                if (hasData) {
                    tdDelta.textContent = deltaData.delta;
                    const abs = Math.abs(deltaData.delta);
                    if (deltaData.delta > 0) tdDelta.className = abs >= 50 ? 'strong-positive' : 'positive';
                    else if (deltaData.delta < 0) tdDelta.className = abs >= 50 ? 'strong-negative' : 'negative';
                } else {
                    tdDelta.textContent = '-';
                }
                rowDelta.appendChild(tdDelta);

                // Delta Change
                const tdChg = document.createElement('td');
                setFixedWidth(tdChg);
                if (hasData && prevDelta !== null) {
                    const chg = deltaData.delta - prevDelta;
                    tdChg.textContent = chg;
                    const abs = Math.abs(chg);
                    if (chg > 0) tdChg.className = abs >= 30 ? 'strong-positive' : 'positive';
                    else if (chg < 0) tdChg.className = abs >= 30 ? 'strong-negative' : 'negative';
                } else {
                    tdChg.textContent = '-';
                }
                rowDeltaChange.appendChild(tdChg);

                // Max Delta
                const tdMax = document.createElement('td');
                setFixedWidth(tdMax);
                if (hasData) {
                    tdMax.textContent = deltaData.maxDelta;
                    const abs = Math.abs(deltaData.maxDelta);
                    if (deltaData.maxDelta > 0) tdMax.className = abs >= 50 ? 'strong-positive' : 'positive';
                    else if (deltaData.maxDelta < 0) tdMax.className = abs >= 50 ? 'strong-negative' : 'negative';
                } else {
                    tdMax.textContent = '-';
                }
                rowMaxDelta.appendChild(tdMax);

                // Min Delta
                const tdMin = document.createElement('td');
                setFixedWidth(tdMin);
                if (hasData) {
                    tdMin.textContent = deltaData.minDelta;
                    const abs = Math.abs(deltaData.minDelta);
                    if (deltaData.minDelta < 0) tdMin.className = abs >= 50 ? 'strong-negative' : 'negative';
                    else if (deltaData.minDelta > 0) tdMin.className = abs >= 50 ? 'strong-positive' : 'positive';
                } else {
                    tdMin.textContent = '-';
                }
                rowMinDelta.appendChild(tdMin);

                // Volume
                const tdVol = document.createElement('td');
                setFixedWidth(tdVol);
                const vol = candle.volume || 0;
                tdVol.textContent = vol > 0 ? vol.toLocaleString() : '-';
                rowVolume.appendChild(tdVol);

                if (hasData) prevDelta = deltaData.delta;
            });

            // Add right-side spacer to account for chart's rightOffset
            const rightOffset = chart.timeScale().options().rightOffset || 5;
            const rightPadding = rightOffset * barSpacing;
            if (rightPadding > 0) {
                [rowTime, rowDelta, rowDeltaChange, rowMaxDelta, rowMinDelta, rowVolume].forEach(row => {
                    const spacer = document.createElement('td');
                    spacer.style.width = rightPadding + 'px';
                    spacer.style.minWidth = rightPadding + 'px';
                    spacer.style.padding = '0';
                    spacer.style.border = 'none';
                    row.appendChild(spacer);
                });
            }

            // Reset scroll position (alignment is handled by spacer)
            deltaGrid.scrollLeft = 0;

            // Update version
            const ver = document.getElementById('version');
            if (ver) {
                ver.textContent = 'v157 (' + matchedCount + '/' + visibleCandles.length + ')';
            }
        }

        //=============================================================================
        // BIG ORDER CIRCLES - Render individual circles at actual price levels
        // Each big order gets its own ball at its exact price
        //=============================================================================
        let lastRenderX = null;
        function renderBigOrderCircles() {
            // Reduced logging - only log occasionally
            if (Math.random() < 0.1) {
                console.log('[RENDER] Called');
            }

            if (!bigOrderCtx || !bigOrderCanvas) {
                console.log('[RENDER] No canvas!');
                return;
            }

            // Clear canvas
            bigOrderCtx.clearRect(0, 0, bigOrderCanvas.width, bigOrderCanvas.height);

            // Skip rendering if big orders are off, zoomed out, or chart not ready
            if (!showBigOrders || zoomedOutHidden || !initialZoomComplete) {
                return;
            }

            // Skip if no big orders or no candle data
            if (bigOrderTrades.length === 0 || candleData.length === 0) {
                console.log(`[RENDER] Skipping: bigOrderTrades=${bigOrderTrades.length}, candleData=${candleData.length}`);
                return;
            }

            // Calculate cutoff time
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            console.log(`[RENDER] ${TIMEFRAME}: ${bigOrderTrades.length} trades, interval=${intervalSeconds}s, minSize=${CONFIG.bigOrderMinSize}`);

            // Debug: show sample timestamps for 1m
            if (TIMEFRAME === '1m' && bigOrderTrades.length > 0) {
                const sampleOrders = bigOrderTrades.slice(0, 3);
                const sampleCandles = candleData.slice(-3);
                console.log('[RENDER 1m] Sample order times:', sampleOrders.map(o => o.time).join(', '));
                console.log('[RENDER 1m] Sample candle times:', sampleCandles.map(c => c.time).join(', '));
                console.log('[RENDER 1m] Sample order sizes:', sampleOrders.map(o => o.size).join(', '));
            }

            let cutoffTime = 0;
            if (candleData.length > 0 && CONFIG.bigOrderDisplayCandles > 0) {
                const lastCandleTime = candleData[candleData.length - 1].time;
                cutoffTime = lastCandleTime - (CONFIG.bigOrderDisplayCandles * intervalSeconds);
            }

            // Scale based on bigOrderMinSize setting
            // Orders at minSize get smallest ball, orders at 10x minSize get largest ball
            const baseSize = CONFIG.bigOrderMinSize;
            const maxScaleSize = baseSize * 10;  // 10x min size = max radius
            const minRadius = 6;
            const maxRadius = 25;

            // Helper function to draw a circle
            function drawCircle(x, y, size, isBuy) {
                // Validate inputs are finite numbers
                if (!Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(size)) {
                    return;
                }

                // Scale from minSize to maxScaleSize - ensure clampedSize >= baseSize
                const clampedSize = Math.max(baseSize, Math.min(size, maxScaleSize));
                const denominator = maxScaleSize - baseSize;
                const sizeRatio = denominator > 0 ? Math.sqrt((clampedSize - baseSize) / denominator) : 0;
                const radius = minRadius + sizeRatio * (maxRadius - minRadius);

                // Final validation - radius must be finite and positive
                if (!Number.isFinite(radius) || radius <= 0) {
                    return;
                }

                // Green: base [34, 197, 94], outline [25, 160, 70]
                // Red: base [239, 68, 68], outline [200, 60, 60]
                const baseColor = isBuy ? [34, 197, 94] : [239, 68, 68];
                const outlineColor = isBuy ? [25, 160, 70] : [200, 60, 60];

                // Draw outline using darker shade of same color
                bigOrderCtx.beginPath();
                bigOrderCtx.arc(x, y, radius + 2, 0, Math.PI * 2);
                bigOrderCtx.fillStyle = `rgb(${outlineColor[0]}, ${outlineColor[1]}, ${outlineColor[2]})`;
                bigOrderCtx.fill();

                // Draw main circle with solid color
                bigOrderCtx.beginPath();
                bigOrderCtx.arc(x, y, radius, 0, Math.PI * 2);
                bigOrderCtx.fillStyle = `rgb(${baseColor[0]}, ${baseColor[1]}, ${baseColor[2]})`;
                bigOrderCtx.fill();

                // Add inner highlight for 3D effect (subtle, using lighter shade)
                bigOrderCtx.beginPath();
                bigOrderCtx.arc(x - radius/4, y - radius/4, radius/3, 0, Math.PI * 2);
                bigOrderCtx.fillStyle = isBuy ? 'rgba(100, 255, 150, 0.4)' : 'rgba(255, 120, 120, 0.4)';
                bigOrderCtx.fill();
            }

            // Draw big orders from executed trades at their candle time (X) and trade price (Y)
            let renderedCount = 0;
            let skippedSize = 0;
            let skippedCutoff = 0;
            let skippedCoord = 0;

            // Get visible range for coordinate validation
            const visibleRange = chart.timeScale().getVisibleRange();
            const logicalRange = chart.timeScale().getVisibleLogicalRange();
            const barSpacing = chart.timeScale().options().barSpacing;

            // Build a map of candle times for exact matching
            const candleTimeSet = new Set(candleData.map(c => c.time));

            bigOrderTrades.forEach(order => {
                // Filter by current minSize setting
                if (order.size < CONFIG.bigOrderMinSize) {
                    skippedSize++;
                    return;
                }

                // Map 1m timestamp to current timeframe bucket for display
                let displayTime = Math.floor(order.time / intervalSeconds) * intervalSeconds;

                // Find the closest actual candle time for exact alignment
                if (!candleTimeSet.has(displayTime)) {
                    // Look for nearest candle within one interval
                    let bestMatch = null;
                    let bestDiff = Infinity;
                    for (const candleTime of candleTimeSet) {
                        const diff = Math.abs(candleTime - displayTime);
                        if (diff < bestDiff && diff <= intervalSeconds) {
                            bestDiff = diff;
                            bestMatch = candleTime;
                        }
                    }
                    if (bestMatch !== null) {
                        displayTime = bestMatch;
                    }
                }

                // Skip old orders (time-based cutoff)
                if (cutoffTime > 0 && displayTime < cutoffTime) {
                    skippedCutoff++;
                    return;
                }

                // Skip if outside visible time range (with small margin for edge orders)
                if (visibleRange) {
                    const timeMargin = intervalSeconds * 2;  // Allow 2 candles margin
                    if (displayTime < visibleRange.from - timeMargin || displayTime > visibleRange.to + timeMargin) {
                        skippedCoord++;
                        return;
                    }
                }

                // Get X coordinate from actual candle time
                const x = chart.timeScale().timeToCoordinate(displayTime);
                if (x === null || !Number.isFinite(x) || x < -50 || x > bigOrderCanvas.width + 50) {
                    skippedCoord++;
                    return;
                }

                // Get Y coordinate from trade price
                const y = candleSeries.priceToCoordinate(order.price);
                if (y === null || !Number.isFinite(y) || y < -50 || y > bigOrderCanvas.height + 50) {
                    skippedCoord++;
                    return;
                }

                // Log coordinate changes to debug drag issue
                if (renderedCount === 0 && lastRenderX !== null && Math.abs(x - lastRenderX) > 0.5) {
                    console.log(`[COORD] X moved: ${lastRenderX.toFixed(1)} -> ${x.toFixed(1)}`);
                }
                if (renderedCount === 0) {
                    lastRenderX = x;
                }

                // Draw the circle
                drawCircle(x, y, order.size, order.side === 'BUY');
                renderedCount++;
            });

            // Log render stats
            const visibleCandles = logicalRange ? Math.ceil(logicalRange.to - logicalRange.from) : 0;
            if (TIMEFRAME === '1m' || renderedCount === 0 || visibleCandles > 50) {
                console.log(`[RENDER] Rendered ${renderedCount}, skipped: size=${skippedSize}, cutoff=${skippedCutoff}, coords=${skippedCoord}, visible=${visibleCandles} candles, barSpacing=${barSpacing?.toFixed(1)}`);
            }
        }

        //=============================================================================
        // CHART MARKERS - Legacy rebuild (now just clears markers, using canvas instead)
        //=============================================================================
        function rebuildChartMarkers() {
            // Clear legacy markers - we use canvas overlay now
            candleSeries.setMarkers([]);

            // Render circles on canvas overlay
            renderBigOrderCircles();

            if (!showBigOrders) return;

            // Calculate cutoff time - only DISPLAY markers for last N candles (don't delete old ones)
            const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
            let cutoffTime = 0;
            if (candleData.length > 0 && CONFIG.bigOrderDisplayCandles > 0) {
                const lastCandleTime = candleData[candleData.length - 1].time;
                cutoffTime = lastCandleTime - (CONFIG.bigOrderDisplayCandles * intervalSeconds);
            }

            // Count for logging
            let displayedCount = 0;
            let hiddenCount = 0;

            // Count from aggregatedBigOrders for logging
            aggregatedBigOrders.forEach((agg, key) => {
                const [timeStr, side] = key.split('_');
                const candleTime = parseInt(timeStr);

                if (cutoffTime > 0 && candleTime < cutoffTime) {
                    hiddenCount++;
                } else {
                    displayedCount++;
                }
            });

            console.log(`Big orders: ${bigOrderTrades.length} trades, ${aggregatedBigOrders.size} aggregated, ${displayedCount} displayed, ${hiddenCount} hidden`);
        }

        //=============================================================================
        // UI UPDATES
        //=============================================================================
        function updatePriceDisplay(price) {
            const priceEl = document.getElementById('currentPrice');
            const changeEl = document.getElementById('priceChange');

            priceEl.textContent = price.toFixed(CONFIG.decimals);

            if (sessionOpen > 0) {
                const change = price - sessionOpen;
                const changePct = (change / sessionOpen) * 100;
                const sign = change >= 0 ? '+' : '';

                changeEl.textContent = `${sign}${change.toFixed(CONFIG.decimals)} (${sign}${changePct.toFixed(2)}%)`;
                changeEl.className = 'price-change' + (change < 0 ? ' down' : '');
                priceEl.className = 'current-price' + (change < 0 ? ' down' : '');
            }
        }

        function updateOHLCDisplay(candle) {
            if (!candle) return;
            document.getElementById('ohlcOpen').textContent = candle.open.toFixed(CONFIG.decimals);
            document.getElementById('ohlcHigh').textContent = candle.high.toFixed(CONFIG.decimals);
            document.getElementById('ohlcLow').textContent = candle.low.toFixed(CONFIG.decimals);
            document.getElementById('ohlcClose').textContent = candle.close.toFixed(CONFIG.decimals);
            document.getElementById('ohlcVol').textContent = (candle.volume || 0).toLocaleString();
        }

        function updateStatus(status, text) {
            document.getElementById('statusDot').className = 'status-dot ' + status;
            document.getElementById('statusText').textContent = text;
        }

        function updateBarCount() {
            document.getElementById('barCount').textContent = `${candleData.length} bars`;
        }

        //=============================================================================
        // TIMEFRAME SWITCHING
        //=============================================================================
        async function switchTimeframe(newTimeframe) {
            if (newTimeframe === TIMEFRAME) return;

            // Save current visible time range before switching
            const visibleRange = chart.timeScale().getVisibleRange();
            if (visibleRange) {
                savedTimeRange = { from: visibleRange.from, to: visibleRange.to };
                console.log(`[TF] Saving time range: ${new Date(savedTimeRange.from * 1000).toLocaleTimeString()} - ${new Date(savedTimeRange.to * 1000).toLocaleTimeString()}`);
            }

            TIMEFRAME = newTimeframe;

            // Save timeframe to localStorage
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.timeframe = newTimeframe;
            localStorage.setItem('chartSettings', JSON.stringify(settings));

            // Update UI
            document.querySelectorAll('.tf-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tf === newTimeframe);
            });

            // Clear runtime data (but preserve persisted delta data)
            candleData = [];
            currentPrice = 0;
            sessionOpen = 0;
            currentBestBid = 0;
            currentBestAsk = 0;
            initialLoadDone = false;  // Reset so next historical load is treated as full load
            isTimeframeChange = true;  // Flag to fitContent after history loads
            initialZoomComplete = false;  // Reset so circles wait for chart to be ready
            candleOrderflow.clear();
            seenMBOOrders.clear();
            priceVolumeMap.clear();
            aggregatedBigOrders.clear();
            bigOrderTrades = [];

            // Clear big order canvas immediately
            if (bigOrderCtx && bigOrderCanvas) {
                bigOrderCtx.clearRect(0, 0, bigOrderCanvas.width, bigOrderCanvas.height);
            }
            chartMarkers = [];
            // Reload delta data from Redis for this timeframe
            candleDeltaData.clear();
            savedCandles.clear();
            sessionStats = {
                totalBuyVolume: 0,
                totalSellVolume: 0,
                bigOrderCount: 0
            };

            // Clear chart
            candleSeries.setData([]);
            volumeSeries.setData([]);
            volumeMA20Series.setData([]);
            candleSeries.setMarkers([]);

            // Reset UI
            document.getElementById('loadingOverlay').classList.remove('hidden');
            document.getElementById('barCount').textContent = '0 bars';

            // Clear delta grid rows
            ['rowTime', 'rowDelta', 'rowDeltaChange', 'rowMaxDelta', 'rowMinDelta', 'rowVolume'].forEach(rowId => {
                const row = document.getElementById(rowId);
                while (row.children.length > 1) {
                    row.removeChild(row.lastChild);
                }
            });

            // Load delta data FIRST before requesting history (await to prevent race condition)
            await loadDeltaData();

            // Request new data after delta is loaded
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'get_history',
                    symbol: CONFIG.symbol,
                    timeframe: TIMEFRAME,
                    bars: 10000
                }));
            }
        }

        //=============================================================================
        // MA20 CALCULATION
        //=============================================================================
        function updateVolumeMA20() {
            if (!showMA) return;

            const ma20Data = [];
            const period = 20;

            for (let i = 0; i < candleData.length; i++) {
                if (i >= period - 1) {
                    let sum = 0;
                    for (let j = i - period + 1; j <= i; j++) {
                        sum += candleData[j].volume || 0;
                    }
                    ma20Data.push({
                        time: candleData[i].time,
                        value: sum / period
                    });
                }
            }

            volumeMA20Series.setData(ma20Data);
        }

        //=============================================================================
        // TOGGLE FUNCTIONS
        //=============================================================================
        function toggleVolume() {
            showVolume = !showVolume;
            document.getElementById('toggleVol').classList.toggle('active', showVolume);

            if (showVolume) {
                // Hide delta when showing volume
                if (showDeltaStats) {
                    showDeltaStats = false;
                    var chartDiv = document.getElementById('chart');
                    document.getElementById('toggleDelta').className = 'toggle-btn';
                    document.getElementById('chartLegend').style.display = 'flex';
                    document.getElementById('version').textContent = 'v157 OFF';

                    // Update layout via CSS class
                    updateLayout();
                    setTimeout(updateLayout, 100);
                }
                if (volumeSeries && candleData.length > 0) {
                    // Restore volume scale area
                    volumeSeries.priceScale().applyOptions({
                        scaleMargins: { top: 0.75, bottom: 0 }
                    });
                    volumeSeries.applyOptions({ visible: true });
                    volumeSeries.setData(candleData.map(function(c) {
                        return { time: c.time, value: c.volume, color: c.close >= c.open ? '#22c55ecc' : '#ef4444cc' };
                    }));
                    // Restore big order markers if BIG toggle is on
                    if (showBigOrders) {
                        rebuildChartMarkers();
                    }
                }
            } else {
                if (volumeSeries) {
                    volumeSeries.setData([]);
                    volumeSeries.applyOptions({ visible: false });
                    // Only collapse scale if MA is also off
                    if (!showMA) {
                        volumeSeries.priceScale().applyOptions({
                            scaleMargins: { top: 1, bottom: 0 }
                        });
                    }
                }
                // Also hide big order markers when volume is off
                candleSeries.setMarkers([]);
            }

            // Save state to localStorage
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.showVolume = showVolume;
            settings.showMA = showMA;
            settings.showDeltaStats = showDeltaStats;
            localStorage.setItem('chartSettings', JSON.stringify(settings));
        }

        function toggleMA() {
            showMA = !showMA;
            document.getElementById('toggleMA').classList.toggle('active', showMA);

            if (showMA) {
                // MA uses 'volume' price scale - ensure it has visible area
                if (volumeSeries) {
                    volumeSeries.priceScale().applyOptions({
                        scaleMargins: { top: 0.75, bottom: 0 }
                    });
                }
                if (volumeMA20Series) volumeMA20Series.applyOptions({ visible: true });
                // Hide delta when showing MA
                if (showDeltaStats) {
                    showDeltaStats = false;
                    document.getElementById('toggleDelta').className = 'toggle-btn';
                    document.getElementById('chartLegend').style.display = 'flex';
                    document.getElementById('version').textContent = 'v157 OFF';

                    // Update layout via CSS class
                    updateLayout();
                    setTimeout(updateLayout, 100);
                }
                updateVolumeMA20();
            } else {
                if (volumeMA20Series) {
                    volumeMA20Series.setData([]);
                    volumeMA20Series.applyOptions({ visible: false });
                }
                // If volume is also off, collapse the scale
                if (!showVolume && volumeSeries) {
                    volumeSeries.priceScale().applyOptions({
                        scaleMargins: { top: 1, bottom: 0 }
                    });
                }
            }

            // Save state to localStorage
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.showVolume = showVolume;
            settings.showMA = showMA;
            settings.showDeltaStats = showDeltaStats;
            localStorage.setItem('chartSettings', JSON.stringify(settings));
        }

        // Make toggle function global so onclick can always find it
        window.toggleDeltaStats = function() {
            try {
                var dw = document.getElementById('deltaWrapper');
                var ch = document.getElementById('chart');
                var btn = document.getElementById('toggleDelta');
                var legend = document.getElementById('chartLegend');
                var ver = document.getElementById('version');

                if (!dw) { alert('ERROR: deltaWrapper not found!'); return; }

                // Check if delta is currently hidden (check display style, not class)
                var isCurrentlyHidden = (dw.style.display === 'none' || dw.style.display === '');

                console.log('DELTA v157: hidden=' + isCurrentlyHidden + ', display=' + dw.style.display);

                if (isCurrentlyHidden) {
                    // SHOW delta - turn off volume and MA first
                    if (showVolume) {
                        showVolume = false;
                        document.getElementById('toggleVol').classList.remove('active');
                        if (volumeSeries) {
                            volumeSeries.setData([]);
                            volumeSeries.applyOptions({ visible: false });
                            volumeSeries.priceScale().applyOptions({
                                scaleMargins: { top: 1, bottom: 0 }
                            });
                        }
                    }
                    if (showMA) {
                        showMA = false;
                        document.getElementById('toggleMA').classList.remove('active');
                        if (volumeMA20Series) {
                            volumeMA20Series.setData([]);
                            volumeMA20Series.applyOptions({ visible: false });
                        }
                    }

                    showDeltaStats = true;
                    userWantsDelta = true;
                    btn.className = 'toggle-btn active';
                    legend.style.display = 'none';
                    ver.textContent = 'v157 ON';

                    // Zoom to last 40 candles when delta is turned on for readable grid
                    if (candleData.length > 0) {
                        var intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                        var lastCandleTime = candleData[candleData.length - 1].time;
                        var barsToShow = Math.min(40, candleData.length);
                        var fromTime = lastCandleTime - (barsToShow * intervalSeconds);
                        chart.timeScale().setVisibleRange({
                            from: fromTime,
                            to: lastCandleTime + intervalSeconds
                        });
                        console.log(`Delta ON: zoomed to last ${barsToShow} candles`);
                    }
                } else {
                    // HIDE delta - chart extends to bottom
                    showDeltaStats = false;
                    userWantsDelta = false;
                    btn.className = 'toggle-btn';
                    legend.style.display = 'flex';
                    ver.textContent = 'v157 OFF';
                }

                // Update layout and resize using helper function
                requestAnimationFrame(() => {
                    updateLayout();
                    if (showDeltaStats) updateDeltaGrid();
                    if (showBigOrders) renderBigOrderCircles();
                });
                setTimeout(() => {
                    updateLayout();
                    if (showDeltaStats) updateDeltaGrid();
                    if (showBigOrders) renderBigOrderCircles();
                }, 50);
                setTimeout(() => {
                    updateLayout();
                    if (showDeltaStats) updateDeltaGrid();
                    if (showBigOrders) renderBigOrderCircles();
                }, 200);

                // Save state to localStorage
                var settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
                settings.showVolume = showVolume;
                settings.showMA = showMA;
                settings.showDeltaStats = showDeltaStats;
                localStorage.setItem('chartSettings', JSON.stringify(settings));
            } catch (e) {
                alert('Toggle error: ' + e.message);
                console.error('Toggle error:', e);
            }
        };

        function toggleBigOrders() {
            showBigOrders = !showBigOrders;
            userWantsBigOrders = showBigOrders;  // Track user preference
            document.getElementById('toggleBigOrders').classList.toggle('active', showBigOrders);

            // Save state to localStorage
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.showBigOrders = showBigOrders;
            localStorage.setItem('chartSettings', JSON.stringify(settings));

            if (showBigOrders) {
                // Zoom to last 25 candles first
                if (candleData.length > 0) {
                    const intervalSeconds = TIMEFRAME_MINUTES[TIMEFRAME] * 60;
                    const lastCandleTime = candleData[candleData.length - 1].time;
                    const fromTime = lastCandleTime - (25 * intervalSeconds);

                    chart.timeScale().setVisibleRange({
                        from: fromTime,
                        to: lastCandleTime + intervalSeconds
                    });
                    console.log(`Zoomed to last 25 candles`);
                }

                // Render after zoom settles
                setTimeout(() => {
                    rebuildChartMarkers();
                }, 300);
            } else {
                // Hide all markers and clear canvas
                candleSeries.setMarkers([]);
                if (bigOrderCtx && bigOrderCanvas) {
                    bigOrderCtx.clearRect(0, 0, bigOrderCanvas.width, bigOrderCanvas.height);
                }
            }

            console.log('Big Orders:', showBigOrders ? 'ON' : 'OFF');
        }

        function toggleAutoScroll() {
            autoScroll = !autoScroll;

            // Save state to localStorage
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.autoScroll = autoScroll;
            localStorage.setItem('chartSettings', JSON.stringify(settings));

            console.log('Auto scroll:', autoScroll ? 'ON' : 'OFF');
        }

        //=============================================================================
        // SETTINGS MODAL
        //=============================================================================
        function openSettings() {
            document.getElementById('settingBigOrderSize').value = CONFIG.bigOrderMinSize;
            document.getElementById('settingBigOrderCandles').value = CONFIG.bigOrderDisplayCandles;
            document.getElementById('settingDeltaTTL').value = CONFIG.deltaTTLHours;
            document.getElementById('settingsModal').classList.add('show');
        }

        function closeSettings() {
            document.getElementById('settingsModal').classList.remove('show');
        }

        async function clearAllData() {
            if (!confirm('Clear all saved delta and big order data from Redis?\n\nThis will delete all persisted data and start fresh.')) {
                return;
            }

            try {
                // Clear local data
                candleDeltaData.clear();
                savedCandles.clear();
                aggregatedBigOrders.clear();
                bigOrderTrades = [];
                seenMBOOrders.clear();
            priceVolumeMap.clear();
                sessionStats.bigOrderCount = 0;
                candleOrderflow.clear();

                // Clear Redis by saving empty data
                const response = await fetch(`${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=${TIMEFRAME}&clear=1`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({})
                });

                console.log('Cleared all delta data');
                closeSettings();
                rebuildChartMarkers();
                updateDeltaGrid();
                alert('All data cleared! Delta will start fresh from new ticks.');
            } catch (e) {
                console.error('Failed to clear data:', e);
                alert('Failed to clear data: ' + e.message);
            }
        }

        function saveSettings() {
            const bigOrderSize = parseInt(document.getElementById('settingBigOrderSize').value) || 20;
            const bigOrderCandles = parseInt(document.getElementById('settingBigOrderCandles').value) || 15;
            const deltaTTL = parseInt(document.getElementById('settingDeltaTTL').value) || 6;

            // Update CONFIG
            CONFIG.bigOrderMinSize = Math.max(1, Math.min(1000, bigOrderSize));
            CONFIG.bigOrderDisplayCandles = Math.max(1, Math.min(100, bigOrderCandles));
            CONFIG.deltaTTLHours = Math.max(1, Math.min(48, deltaTTL));

            // Save to localStorage (merge with existing settings)
            const settings = JSON.parse(localStorage.getItem('chartSettings') || '{}');
            settings.bigOrderMinSize = CONFIG.bigOrderMinSize;
            settings.bigOrderDisplayCandles = CONFIG.bigOrderDisplayCandles;
            settings.deltaTTLHours = CONFIG.deltaTTLHours;
            localStorage.setItem('chartSettings', JSON.stringify(settings));

            console.log(`Settings saved: Big Order Min=${CONFIG.bigOrderMinSize}, Display=${CONFIG.bigOrderDisplayCandles} candles, Delta TTL=${CONFIG.deltaTTLHours}h`);
            closeSettings();

            // Clear existing big orders and let them re-accumulate with new threshold
            seenMBOOrders.clear();
            priceVolumeMap.clear();
            aggregatedBigOrders.clear();
            bigOrderTrades = [];
            sessionStats.bigOrderCount = 0;
            rebuildChartMarkers();
        }

        //=============================================================================
        // INITIALIZATION
        //=============================================================================
        document.addEventListener('DOMContentLoaded', async () => {
            // Load persisted delta data from Redis
            await loadDeltaData();
            clearOldDeltaData();

            console.log('=== INIT v157 ===');
            console.log('showDeltaStats:', showDeltaStats);

            // Show legend if delta is off
            if (!showDeltaStats) {
                document.getElementById('chartLegend').style.display = 'flex';
            }

            // Wait for layout to stabilize
            await new Promise(r => setTimeout(r, 150));

            // Set initial layout before creating chart
            updateLayout();

            // Wait a bit more
            await new Promise(r => setTimeout(r, 50));

            // Create chart
            initChart();

            // Update layout after chart creation
            await new Promise(r => setTimeout(r, 50));
            updateLayout();

            // Window resize handler
            window.addEventListener('resize', updateLayout);

            // ResizeObserver on container to catch any size changes
            new ResizeObserver(() => {
                updateLayout();
            }).observe(document.querySelector('.chart-container'));

            // Timeframe buttons
            document.querySelectorAll('.tf-btn').forEach(btn => {
                btn.addEventListener('click', () => switchTimeframe(btn.dataset.tf));
            });

            // Toggle buttons
            document.getElementById('toggleVol').addEventListener('click', toggleVolume);
            document.getElementById('toggleMA').addEventListener('click', toggleMA);
            // toggleDelta uses inline onclick in HTML
            document.getElementById('toggleBigOrders').addEventListener('click', toggleBigOrders);

            // Set button states from saved settings
            document.getElementById('toggleBigOrders').classList.toggle('active', showBigOrders);
            document.getElementById('toggleVol').classList.toggle('active', showVolume);
            document.getElementById('toggleMA').classList.toggle('active', showMA);
            document.getElementById('toggleDelta').classList.toggle('active', showDeltaStats);

            // Set active timeframe button
            document.querySelectorAll('.tf-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tf === TIMEFRAME);
            });

            // Settings modal
            document.getElementById('settingsBtn').addEventListener('click', openSettings);
            document.getElementById('settingsSave').addEventListener('click', saveSettings);
            document.getElementById('settingsCancel').addEventListener('click', closeSettings);
            document.getElementById('settingsClearData').addEventListener('click', clearAllData);
            document.getElementById('settingsModal').addEventListener('click', (e) => {
                if (e.target.id === 'settingsModal') closeSettings();
            });

            // Connect
            connectWebSocket();

            // Context menu setup
            const contextMenu = document.getElementById('contextMenu');
            const chartEl = document.getElementById('chart');

            // Update context menu checkboxes
            function updateContextMenuChecks() {
                document.getElementById('ctxVolCheck').textContent = showVolume ? '☑' : '☐';
                document.getElementById('ctxMACheck').textContent = showMA ? '☑' : '☐';
                document.getElementById('ctxDeltaCheck').textContent = showDeltaStats ? '☑' : '☐';
                document.getElementById('ctxBigCheck').textContent = showBigOrders ? '☑' : '☐';
                document.getElementById('ctxAutoScrollCheck').textContent = autoScroll ? '☑' : '☐';
            }

            // Show context menu on right-click
            chartEl.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                updateContextMenuChecks();

                // Position menu at cursor
                let x = e.clientX;
                let y = e.clientY;

                // Keep menu in viewport
                const menuWidth = 180;
                const menuHeight = contextMenu.offsetHeight || 400;
                if (x + menuWidth > window.innerWidth) x = window.innerWidth - menuWidth - 10;
                if (y + menuHeight > window.innerHeight) y = Math.max(10, window.innerHeight - menuHeight - 10);

                contextMenu.style.left = x + 'px';
                contextMenu.style.top = y + 'px';
                contextMenu.classList.add('show');
            });

            // Hide context menu when clicking elsewhere
            document.addEventListener('click', (e) => {
                if (!contextMenu.contains(e.target)) {
                    contextMenu.classList.remove('show');
                }
            });

            // Context menu actions
            contextMenu.addEventListener('click', (e) => {
                const item = e.target.closest('.context-menu-item');
                if (!item) return;

                const action = item.dataset.action;
                contextMenu.classList.remove('show');

                switch (action) {
                    case 'fitContent':
                        chart.timeScale().fitContent();
                        // Hide delta if showing
                        if (showDeltaStats) {
                            toggleDeltaStats();
                        }
                        // Show volume if not showing
                        if (!showVolume) {
                            toggleVolume();
                        }
                        updateContextMenuChecks();
                        break;
                    case 'zoomLast25':
                        if (candleData.length > 0) {
                            const startIdx = Math.max(0, candleData.length - 25);
                            chart.timeScale().setVisibleLogicalRange({ from: startIdx, to: candleData.length - 1 });
                        }
                        break;
                    case 'screenshot':
                        takeScreenshot();
                        break;
                    case 'resetChart':
                        // Reset: fit content, show volume, hide delta, hide big orders
                        chart.timeScale().fitContent();
                        // Hide delta if showing
                        if (showDeltaStats) {
                            toggleDeltaStats();
                        }
                        // Show volume if not showing
                        if (!showVolume) {
                            toggleVolume();
                        }
                        // Hide big orders if showing
                        if (showBigOrders) {
                            toggleBigOrders();
                        }
                        updateContextMenuChecks();
                        break;
                    case 'toggleVolume':
                        toggleVolume();
                        updateContextMenuChecks();
                        break;
                    case 'toggleMA':
                        toggleMA();
                        updateContextMenuChecks();
                        break;
                    case 'toggleDelta':
                        toggleDeltaStats();
                        updateContextMenuChecks();
                        break;
                    case 'toggleBigOrders':
                        toggleBigOrders();
                        updateContextMenuChecks();
                        break;
                    case 'toggleAutoScroll':
                        toggleAutoScroll();
                        updateContextMenuChecks();
                        break;
                    case 'settings':
                        openSettings();
                        break;
                    case 'clearData':
                        if (confirm('Clear all delta and big order data?')) {
                            clearAllData();
                        }
                        break;
                }
            });

            // Screenshot function
            function takeScreenshot() {
                try {
                    // Create a canvas from the chart
                    const canvas = chartContainer.querySelector('canvas');
                    if (!canvas) {
                        alert('Unable to capture screenshot');
                        return;
                    }

                    // Create download link
                    const link = document.createElement('a');
                    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
                    link.download = `GC-chart-${TIMEFRAME}-${timestamp}.png`;
                    link.href = canvas.toDataURL('image/png');
                    link.click();
                } catch (err) {
                    console.error('Screenshot error:', err);
                    alert('Failed to capture screenshot');
                }
            }

            // Save delta data AND big orders before page unload
            window.addEventListener('beforeunload', () => {
                // Use sendBeacon for reliable save on page close
                const data = {};

                // Include delta data with individual bigOrderTrades
                candleDeltaData.forEach((value, key) => {
                    if (!value.estimated) {
                        const keyNum = Number(key);
                        const candle = candleData.find(c => c.time === keyNum);
                        // Get individual big order trades for this candle (exact prices)
                        const tradesForCandle = bigOrderTrades.filter(t => Number(t.time) === keyNum);
                        // Only include bigOrderTrades if we have some (don't overwrite with null)
                        const record = {
                            ...value,
                            candle: candle ? { o: candle.open, h: candle.high, l: candle.low, c: candle.close, v: candle.volume } : null
                        };
                        if (tradesForCandle.length > 0) {
                            record.bigOrderTrades = tradesForCandle;
                        }
                        data[key] = record;
                    }
                });

                // Also save big orders that don't have delta data yet
                const candleTimesWithBigOrders = new Set(bigOrderTrades.map(t => Number(t.time)));
                candleTimesWithBigOrders.forEach(candleTime => {
                    const candleTimeKey = String(candleTime);
                    if (!data[candleTimeKey]) {
                        const candle = candleData.find(c => c.time === candleTime);
                        const tradesForCandle = bigOrderTrades.filter(t => Number(t.time) === candleTime);
                        data[candleTimeKey] = {
                            delta: 0, volume: 0, buyVolume: 0, sellVolume: 0,
                            candle: candle ? { o: candle.open, h: candle.high, l: candle.low, c: candle.close, v: candle.volume } : null,
                            bigOrderTrades: tradesForCandle
                        };
                    }
                });

                if (Object.keys(data).length > 0) {
                    console.log(`Saving ${Object.keys(data).length} records on unload (${bigOrderTrades.length} big orders)`);
                    navigator.sendBeacon(
                        `${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=${TIMEFRAME}`,
                        JSON.stringify(data)
                    );
                }

                // ALWAYS save 1m data on unload (for all timeframe aggregation)
                if (TIMEFRAME !== '1m' && oneMinuteDeltaData.size > 0) {
                    const data1m = {};
                    oneMinuteDeltaData.forEach((value, key) => {
                        const keyNum = Number(key);
                        // Include big orders that belong to this 1m bucket
                        const tradesFor1m = bigOrderTrades.filter(t => Number(t.time) === keyNum);
                        data1m[key] = {
                            ...value,
                            bigOrderTrades: tradesFor1m.length > 0 ? tradesFor1m : undefined
                        };
                    });
                    // Also add big orders without delta data
                    bigOrderTrades.forEach(order => {
                        const key = String(order.time);
                        if (!data1m[key]) {
                            data1m[key] = {
                                delta: 0, volume: 0, buyVolume: 0, sellVolume: 0,
                                bigOrderTrades: [order]
                            };
                        }
                    });
                    if (Object.keys(data1m).length > 0) {
                        console.log(`[1m] Saving ${Object.keys(data1m).length} 1m records with big orders on unload`);
                        navigator.sendBeacon(
                            `${DELTA_API_URL}?symbol=${CONFIG.symbol}&timeframe=1m`,
                            JSON.stringify(data1m)
                        );
                    }
                }
            });
        });
    </script>
</body>
</html>
