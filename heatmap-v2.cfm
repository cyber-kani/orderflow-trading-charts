<!--- Heatmap Module - IQFeed Version --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Heatmap - IQFeed v1</title>
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
        .main {
            flex: 1;
            margin-left: 260px;
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
            flex-wrap: wrap;
            gap: 16px;
        }
        .header h2 {
            font-size: 24px;
            font-weight: 600;
            color: #fff;
            line-height: 1;
            margin: 0;
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
            line-height: 1;
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
            padding: 24px;
        }

        /* View Toggle Buttons */
        .view-toggle {
            display: flex;
            gap: 4px;
            background: #1a1a24;
            border-radius: 8px;
            padding: 4px;
        }
        .view-toggle button {
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            background: transparent;
            color: #9ca3af;
        }
        .view-toggle button:hover {
            color: #fff;
        }
        .view-toggle button.active {
            background: #7c3aed;
            color: #fff;
        }

        /* Leverage checkboxes */
        .leverage-options {
            display: flex;
            gap: 12px;
            align-items: center;
        }
        .leverage-option {
            display: flex;
            align-items: center;
            gap: 4px;
            font-size: 12px;
            color: #9ca3af;
            cursor: pointer;
        }
        .leverage-option input {
            cursor: pointer;
            accent-color: #7c3aed;
        }
        .leverage-option.lev-10x { color: #a855f7; }
        .leverage-option.lev-25x { color: #3b82f6; }
        .leverage-option.lev-50x { color: #22c55e; }
        .leverage-option.lev-100x { color: #eab308; }

        /* Heatmap Container */
        .heatmap-container {
            background: #12121a;
            border: 1px solid #1a1a24;
            border-radius: 12px;
            overflow: hidden;
        }
        .heatmap-header {
            padding: 16px 20px;
            border-bottom: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }
        .heatmap-header h3 {
            font-size: 16px;
            font-weight: 600;
            color: #fff;
        }
        .heatmap-controls {
            display: flex;
            gap: 16px;
            align-items: center;
            flex-wrap: wrap;
        }
        .heatmap-controls label {
            font-size: 12px;
            color: #9ca3af;
        }
        .heatmap-controls select {
            background: #1a1a24;
            border: 1px solid #2a2a3d;
            border-radius: 6px;
            color: #fff;
            padding: 6px 12px;
            font-size: 12px;
        }

        /* Canvas container */
        .heatmap-canvas-container {
            position: relative;
            width: 100%;
            height: 700px;
            background: #0d0d14;
        }
        #heatmapCanvas {
            width: 100%;
            height: 100%;
        }

        /* Price axis */
        .price-axis {
            position: absolute;
            right: 0;
            top: 0;
            bottom: 0;
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
        }
        .price-axis .price-label {
            text-align: right;
        }
        .price-axis .current-price {
            color: #f59e0b;
            font-weight: 600;
        }
        .price-axis .liq-long { color: #22c55e; }
        .price-axis .liq-short { color: #ef4444; }

        /* Time axis */
        .time-axis {
            height: 30px;
            background: #12121a;
            border-top: 1px solid #1a1a24;
            display: flex;
            justify-content: space-between;
            padding: 8px 90px 8px 10px;
            font-size: 10px;
            color: #6b7280;
        }

        /* Legend */
        .heatmap-legend {
            padding: 12px 20px;
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
        /* Liquidation colors */
        .legend-color.liq-low { background: #581c87; }
        .legend-color.liq-med { background: #7c3aed; }
        .legend-color.liq-high { background: #eab308; }
        .legend-gradient {
            width: 120px;
            height: 12px;
            border-radius: 2px;
            background: linear-gradient(to right, #3c1450, #00b4c8, #30d8a0, #90ff50, #ffff00);
        }

        /* Stats bar */
        .stats-bar {
            padding: 12px 20px;
            background: #0a0a0f;
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
        .stat-item .stat-value.ask { color: #f97316; }
        .stat-item .stat-value.neutral { color: #fff; }
        .stat-item .stat-value.liq-long { color: #22c55e; }
        .stat-item .stat-value.liq-short { color: #ef4444; }

        @media (max-width: 768px) {
            .main { margin-left: 0; }
            .heatmap-canvas-container { height: 500px; }
        }

        /* Sidebar slide toggle */
        .sidebar {
            transition: transform 0.3s ease;
        }
        .main {
            transition: margin-left 0.3s ease;
        }
        .sidebar-toggle {
            position: fixed;
            left: 270px;
            top: 50%;
            transform: translateY(-50%);
            z-index: 150;
            background: rgba(139, 92, 246, 0.3);
            border: none;
            border-radius: 0 6px 6px 0;
            padding: 16px 8px;
            color: #fff;
            cursor: pointer;
            transition: left 0.3s ease, background 0.2s;
            display: flex;
            align-items: center;
        }
        .sidebar-toggle:hover { background: rgba(139, 92, 246, 0.6); }
        .sidebar-toggle svg { width: 20px; height: 20px; }

        body.fullscreen-heatmap .sidebar {
            transform: translateX(-100%);
        }
        body.fullscreen-heatmap .main {
            margin-left: 0;
        }
        body.fullscreen-heatmap .sidebar-toggle {
            left: 10px;
        }
        body.fullscreen-heatmap .sidebar-overlay {
            display: none;
        }

        /* Loading spinner animation */
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <main class="main" style="margin-left: 0;">
        <header class="header" style="flex-direction: column; align-items: stretch; gap: 12px;">
            <!-- Row 1: Title and View Toggle -->
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div style="display: flex; align-items: center; gap: 16px;">
                    <h2 id="pageTitle">Order Book Heatmap (IQFeed)</h2>
                    <div class="status-indicator">
                        <span class="status-dot" id="statusDot"></span>
                        <span id="statusText">Connecting...</span>
                    </div>
                </div>
                <!-- View Toggle -->
                <div class="view-toggle">
                    <button id="btnOrderBook" class="active" onclick="setViewMode('orderbook')">Order Book</button>
                    <button id="btnLiquidation" onclick="setViewMode('liquidation')">Liquidation Map</button>
                </div>
            </div>

            <!-- Row 2: Filter Options -->
            <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
                <div class="heatmap-controls">
                    <label>Symbol:</label>
                    <select id="symbolSelect" onchange="changeSymbol(this.value)">
                        <optgroup label="Futures (CME)">
                            <option value="GC" selected>GC (Gold Futures)</option>
                            <option value="SI">SI (Silver Futures)</option>
                            <option value="CL">CL (Crude Oil)</option>
                            <option value="ES">ES (S&P 500)</option>
                            <option value="NQ">NQ (Nasdaq 100)</option>
                        </optgroup>
                    </select>
                    <label>Depth:</label>
                    <select id="depthSelect" onchange="setDepth(this.value)">
                        <option value="50">50 levels</option>
                        <option value="100" selected>100 levels</option>
                        <option value="500">500 levels</option>
                        <option value="1000">1000 levels</option>
                    </select>
                    <label>Speed:</label>
                    <select id="speedSelect" onchange="setSpeed(this.value)">
                        <option value="100">Fast (100ms)</option>
                        <option value="250">Medium (250ms)</option>
                        <option value="500" selected>Normal (500ms)</option>
                        <option value="1000">Slow (1s)</option>
                    </select>
                    <span id="rangeContainer" style="display: none;">
                        <label>Range:</label>
                        <select id="rangeSelect" onchange="setLiqRange(this.value)">
                            <option value="1m">1 Month</option>
                            <option value="1w" selected>1 Week</option>
                            <option value="3d">3 Days</option>
                            <option value="24h">24 Hours</option>
                            <option value="12h">12 Hours</option>
                        </select>
                    </span>
                </div>

                <!-- Leverage options (shown in liquidation mode) -->
                <div class="leverage-options" id="leverageOptions" style="display: none;">
                    <label class="leverage-option lev-10x">
                        <input type="checkbox" id="lev10x" checked onchange="updateLiquidationLevels()"> 10x
                    </label>
                    <label class="leverage-option lev-25x">
                        <input type="checkbox" id="lev25x" checked onchange="updateLiquidationLevels()"> 25x
                    </label>
                    <label class="leverage-option lev-50x">
                        <input type="checkbox" id="lev50x" checked onchange="updateLiquidationLevels()"> 50x
                    </label>
                    <label class="leverage-option lev-100x">
                        <input type="checkbox" id="lev100x" checked onchange="updateLiquidationLevels()"> 100x
                    </label>
                </div>
            </div>
        </header>

        <div class="content">
            <div class="heatmap-container">
                <div class="heatmap-header">
                    <h3 id="symbolTitle">GC (Gold Futures) Order Book Heatmap</h3>
                    <div style="font-size: 12px; color: #6b7280;">
                        <span id="timeRange">Last 5 minutes</span>
                    </div>
                </div>

                <div class="heatmap-canvas-container">
                    <!-- Left Intensity Scale Bar (liquidation mode only) -->
                    <div id="intensityScale" style="display: none; position: absolute; left: 0; top: 0; bottom: 0; width: 45px; background: #12121a; border-right: 1px solid #1a1a24; z-index: 20;">
                        <div style="position: absolute; top: 5px; left: 3px; font-size: 9px; color: #9ca3af; font-family: Consolas, monospace; text-transform: uppercase; letter-spacing: 0.5px;">Liq $</div>
                        <div id="intensityMaxLabel" style="position: absolute; top: 18px; left: 3px; font-size: 10px; color: #ffff00; font-family: Consolas, monospace; font-weight: bold;">0M</div>
                        <div style="position: absolute; top: 38px; left: 8px; bottom: 25px; width: 22px; border-radius: 3px; background: linear-gradient(to bottom, #ffff00, #90ff50, #30d8a0, #00b4c8, #3c1450);"></div>
                        <div style="position: absolute; bottom: 5px; left: 3px; font-size: 10px; color: #6b7280; font-family: Consolas, monospace;">0</div>
                    </div>

                    <!-- Left Order Book Scale Bar (orderbook mode only) -->
                    <div id="orderbookScale" style="display: block; position: absolute; left: 0; top: 0; bottom: 0; width: 45px; background: #12121a; border-right: 1px solid #1a1a24; z-index: 20;">
                        <div style="position: absolute; top: 5px; left: 3px; font-size: 9px; color: #9ca3af; font-family: Consolas, monospace; text-transform: uppercase; letter-spacing: 0.5px;">Vol</div>
                        <div id="orderbookMaxLabel" style="position: absolute; top: 18px; left: 3px; font-size: 10px; color: #3b82f6; font-family: Consolas, monospace; font-weight: bold;">0</div>
                        <!-- Ask gradient (top half) -->
                        <div style="position: absolute; top: 38px; left: 8px; height: calc(50% - 50px); width: 22px; border-radius: 3px 3px 0 0; background: linear-gradient(to bottom, #fca5a5, #ef4444, #7f1d1d);"></div>
                        <!-- Bid gradient (bottom half) -->
                        <div style="position: absolute; top: calc(50% - 12px); left: 8px; height: calc(50% - 50px); width: 22px; border-radius: 0 0 3px 3px; background: linear-gradient(to bottom, #14532d, #22c55e, #4ade80);"></div>
                        <!-- Labels -->
                        <div style="position: absolute; top: 38px; right: 3px; font-size: 8px; color: #ef4444;">Ask</div>
                        <div style="position: absolute; bottom: 30px; right: 3px; font-size: 8px; color: #22c55e;">Bid</div>
                        <div style="position: absolute; bottom: 5px; left: 3px; font-size: 10px; color: #6b7280; font-family: Consolas, monospace;">0</div>
                    </div>

                    <!-- Right Liquidation Histogram (liquidation mode only) -->
                    <div id="liqHistogram" style="display: none; position: absolute; right: 80px; top: 0; bottom: 0; width: 120px; background: #0d0d14; border-left: 1px solid #1a1a24; z-index: 20;">
                        <div style="position: absolute; top: 5px; left: 0; right: 0; text-align: center; font-size: 9px; color: #9ca3af; font-family: Consolas, monospace; text-transform: uppercase; letter-spacing: 0.5px; z-index: 25;">Liq Depth</div>
                        <div style="position: absolute; top: 18px; left: 5px; font-size: 8px; color: #00d8c8;">Short</div>
                        <div style="position: absolute; top: 18px; right: 5px; font-size: 8px; color: #ef4444;">Long</div>
                        <canvas id="histogramCanvas" style="width: 100%; height: 100%;"></canvas>
                        <div style="position: absolute; bottom: 2px; left: 5px; font-size: 9px; color: #6b7280;">0</div>
                        <div id="histogramMaxLabel" style="position: absolute; bottom: 2px; right: 5px; font-size: 9px; color: #6b7280;">0M</div>
                    </div>

                    <!-- Right Order Book Histogram (orderbook mode only) -->
                    <div id="orderbookHistogram" style="display: block; position: absolute; right: 80px; top: 0; bottom: 0; width: 120px; background: #0d0d14; border-left: 1px solid #1a1a24; z-index: 20;">
                        <div style="position: absolute; top: 5px; left: 0; right: 0; text-align: center; font-size: 9px; color: #9ca3af; font-family: Consolas, monospace; text-transform: uppercase; letter-spacing: 0.5px; z-index: 25;">Depth</div>
                        <div style="position: absolute; top: 18px; left: 5px; font-size: 8px; color: #22c55e;">Bid</div>
                        <div style="position: absolute; top: 18px; right: 5px; font-size: 8px; color: #ef4444;">Ask</div>
                        <canvas id="orderbookHistCanvas" style="width: 100%; height: 100%;"></canvas>
                        <div style="position: absolute; bottom: 2px; left: 5px; font-size: 9px; color: #6b7280;">0</div>
                        <div id="orderbookHistMaxLabel" style="position: absolute; bottom: 2px; right: 5px; font-size: 9px; color: #6b7280;">0</div>
                    </div>

                    <canvas id="heatmapCanvas" style="position: absolute; left: 0; top: 0;"></canvas>
                    <div class="price-axis" id="priceAxis">
                        <!-- Price labels will be generated -->
                    </div>
                    <!-- Loading indicator -->
                    <div id="loadingIndicator" style="display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; z-index: 50;">
                        <div style="width: 40px; height: 40px; border: 3px solid #2a2a3d; border-top-color: #7c3aed; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 12px;"></div>
                        <div style="color: #9ca3af; font-size: 13px;">Loading liquidation data...</div>
                    </div>
                    <!-- Market closed overlay -->
                    <div id="marketClosedOverlay" style="display: none; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: #0d0d14; z-index: 60; text-align: center; color: #6b7280; padding: 60px 20px;">
                        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;">
                            <svg width="48" height="48" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="margin-bottom: 16px; opacity: 0.5;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <p style="margin: 0;">CME Market Closed</p>
                            <p style="margin: 8px 0 0 0;">Opens Sunday 5:00 PM CT</p>
                            <p style="margin: 8px 0 0 0;">Try BTCUSDT or ETHUSDT for 24/7 crypto data</p>
                        </div>
                    </div>
                    <!-- Hover tooltip -->
                    <div id="heatmapTooltip" style="display: none; position: absolute; background: rgba(0,0,0,0.9); border: 1px solid #7c3aed; border-radius: 6px; padding: 8px 12px; font-size: 12px; font-family: Consolas, monospace; pointer-events: none; z-index: 100;">
                        <div id="tooltipPrice" style="color: #f59e0b; font-weight: 600;"></div>
                        <div id="tooltipInfo" style="color: #9ca3af; margin-top: 4px;"></div>
                    </div>
                    <!-- Crosshair line -->
                    <div id="crosshairY" style="display: none; position: absolute; left: 45px; right: 200px; height: 1px; background: rgba(245, 158, 11, 0.7); pointer-events: none; z-index: 30;">
                        <div id="crosshairPrice" style="position: absolute; right: -75px; top: -8px; background: #f59e0b; color: #000; font-size: 10px; font-weight: bold; padding: 2px 6px; border-radius: 3px; font-family: Consolas, monospace;"></div>
                    </div>
                </div>

                <div class="time-axis" id="timeAxis">
                    <!-- Time labels will be generated -->
                </div>

                <!-- Order Book Stats -->
                <div class="stats-bar" id="orderbookStats">
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
                </div>

                <!-- Liquidation Stats -->
                <div class="stats-bar" id="liquidationStats" style="display: none;">
                    <div class="stat-item">
                        <div class="stat-label">Current Price</div>
                        <div class="stat-value neutral" id="liqCurrentPrice">--</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label">Long Liq Zone</div>
                        <div class="stat-value liq-long" id="liqLongZone">--</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label">Short Liq Zone</div>
                        <div class="stat-value liq-short" id="liqShortZone">--</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label">Total Long Liq</div>
                        <div class="stat-value liq-long" id="totalLongLiq">--</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label">Total Short Liq</div>
                        <div class="stat-value liq-short" id="totalShortLiq">--</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label">Liq Magnet</div>
                        <div class="stat-value neutral" id="liqMagnet">--</div>
                    </div>
                </div>

                <!-- Order Book Legend -->
                <div class="heatmap-legend" id="orderbookLegend">
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
                </div>

                <!-- Liquidation Legend -->
                <div class="heatmap-legend" id="liquidationLegend" style="display: none;">
                    <div class="legend-item">
                        <span style="color: #9ca3af;">Low</span>
                        <div class="legend-gradient"></div>
                        <span style="color: #9ca3af;">High</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #a855f7;"></div>
                        <span>10x Liq</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #3b82f6;"></div>
                        <span>25x Liq</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #22c55e;"></div>
                        <span>50x Liq</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #eab308;"></div>
                        <span>100x Liq</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #22c55e;"></div>
                        <span>Long Liq (below)</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #ef4444;"></div>
                        <span>Short Liq (above)</span>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script>
        // Symbol configuration with provider info
        // Symbol configurations - CME Futures via IQFeed
        var symbolConfig = {
            'GC': { code: 'GC', provider: 'iqfeed', tick: 0.10, decimals: 2, name: 'GC (Gold Futures)' },
            'SI': { code: 'SI', provider: 'iqfeed', tick: 0.005, decimals: 3, name: 'SI (Silver Futures)' },
            'CL': { code: 'CL', provider: 'iqfeed', tick: 0.01, decimals: 2, name: 'CL (Crude Oil)' },
            'ES': { code: 'ES', provider: 'iqfeed', tick: 0.25, decimals: 2, name: 'ES (S&P 500)' },
            'NQ': { code: 'NQ', provider: 'iqfeed', tick: 0.25, decimals: 2, name: 'NQ (Nasdaq 100)' }
        };

        // Configuration
        var currentSymbol = localStorage.getItem('heatmap_iqfeed_symbol') || 'GC';
        var depthLevels = 100;
        var updateSpeed = 500;
        var refreshTimer = null;
        var viewMode = 'orderbook';

        // IQFeed WebSocket
        var iqfeedWs = null;
        var iqfeedConnected = false;
        var marketClosed = false;

        // Heatmap data storage
        var heatmapHistory = []; // Array of snapshots
        var maxHistoryLength = 600; // 5 minutes at 500ms = 600 snapshots
        var priceRange = { min: 0, max: 0, mid: 0 };

        // Liquidation data
        var liquidationHistory = []; // Historical price data for liquidation calc
        var liquidationLevels = {}; // Accumulated liquidation levels
        var currentPrice = 0;
        var priceHistory = []; // Array of {timestamp, price} for candlestick data

        // Leverage configurations
        var leverageConfig = {
            10: { enabled: true, color: '#a855f7', pct: 0.10 },   // 10x = 10% move to liq
            25: { enabled: true, color: '#3b82f6', pct: 0.04 },   // 25x = 4% move
            50: { enabled: true, color: '#22c55e', pct: 0.02 },   // 50x = 2% move
            100: { enabled: true, color: '#eab308', pct: 0.01 }   // 100x = 1% move
        };

        // Canvas
        var canvas, ctx;
        var canvasWidth, canvasHeight;
        var histCanvas, histCtx;
        var obHistCanvas, obHistCtx; // Orderbook histogram
        var maxLiqIntensity = 0;

        // Initialize
        function init() {
            // Restore saved symbol selection
            var select = document.getElementById('symbolSelect');
            var config = symbolConfig[currentSymbol];
            if (config && select) {
                select.value = currentSymbol;
                var displayName = config.name || currentSymbol;
                document.getElementById('symbolTitle').textContent = displayName + ' Order Book Heatmap';
            }

            canvas = document.getElementById('heatmapCanvas');
            ctx = canvas.getContext('2d');

            // Initialize histogram canvas (liquidation)
            histCanvas = document.getElementById('histogramCanvas');
            histCtx = histCanvas.getContext('2d');

            // Initialize orderbook histogram canvas
            obHistCanvas = document.getElementById('orderbookHistCanvas');
            obHistCtx = obHistCanvas.getContext('2d');

            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);
            startFetching();

            // Mouse hover for price tooltip on canvas
            canvas.addEventListener('mousemove', handleMouseMove);
            canvas.addEventListener('mouseout', handleMouseOut);

            // Mouse hover on left scale bars for crosshair
            var heatmapContainer = document.querySelector('.heatmap-canvas-container');
            heatmapContainer.addEventListener('mousemove', handleContainerMouseMove);
            heatmapContainer.addEventListener('mouseleave', handleContainerMouseOut);

            // Connect to IQFeed WebSocket bridge for CME futures
            connectIQFeed();

            // Hide liquidation mode for futures (only available for crypto)
            updateModeAvailability();
        }

        // Connect to IQFeed WebSocket bridge
        function connectIQFeed() {
            // Prevent duplicate connections
            if (iqfeedWs && (iqfeedWs.readyState === WebSocket.CONNECTING || iqfeedWs.readyState === WebSocket.OPEN)) {
                return;
            }

            var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            var wsUrl = protocol + '//' + window.location.host + '/ws/iqfeed';

            iqfeedWs = new WebSocket(wsUrl);

            iqfeedWs.onopen = function() {
                iqfeedConnected = true;
                // Subscribe to current symbol
                var config = symbolConfig[currentSymbol];
                if (config && config.provider === 'iqfeed') {
                    // Wait a tick to ensure WebSocket is fully ready
                    setTimeout(function() {
                        if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                            iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: currentSymbol }));
                        }
                    }, 10);
                    updateStatus('connected', 'Live');
                }
            };

            iqfeedWs.onmessage = function(event) {
                var msg = JSON.parse(event.data);
                if (msg.type === 'orderbook') {
                    // Only process if it matches our current symbol
                    var config = symbolConfig[currentSymbol];
                    if (msg.symbol === currentSymbol && config && config.provider === 'iqfeed') {
                        processIQFeedData(msg.data);
                    }
                } else if (msg.type === 'market_closed') {
                    var config = symbolConfig[currentSymbol];
                    if (config && config.provider === 'iqfeed') {
                        marketClosed = true; // Set flag to prevent reconnection
                        updateStatus('error', 'Market Closed');
                        drawMarketClosedMessage();
                    }
                } else if (msg.type === 'status') {
                    if (msg.connected) {
                        updateStatus('connected', 'Live');
                    } else {
                        updateStatus('connected', 'Demo Mode');
                    }
                }
            };

            iqfeedWs.onerror = function(err) {
                console.error('IQFeed WebSocket error:', err);
                iqfeedConnected = false;
            };

            iqfeedWs.onclose = function() {
                iqfeedConnected = false;
                // Don't reconnect if market is closed (use flag, not DOM text)
                if (!marketClosed) {
                    setTimeout(function() {
                        if (!marketClosed) {
                            connectIQFeed();
                        }
                    }, 3000);
                }
            };
        }

        // Process IQFeed order book data
        function processIQFeedData(data) {
            if (!data.bids || !data.asks) return;

            var config = symbolConfig[currentSymbol];
            var decimals = config ? config.decimals : 2;

            var bids = data.bids || [];
            var asks = data.asks || [];

            if (bids.length === 0 && asks.length === 0) return;

            var bestBid = bids.length > 0 ? bids[0][0] : 0;
            var bestAsk = asks.length > 0 ? asks[0][0] : 0;
            var midPrice = (bestBid + bestAsk) / 2;
            currentPrice = midPrice;

            // Build bid/ask levels
            var bidLevels = {};
            var askLevels = {};
            var totalBidVol = 0, totalAskVol = 0;

            bids.forEach(function(level) {
                var price = level[0];
                var size = level[1];
                bidLevels[price] = size;
                totalBidVol += size;
            });

            asks.forEach(function(level) {
                var price = level[0];
                var size = level[1];
                askLevels[price] = size;
                totalAskVol += size;
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
                totalAskVol: totalAskVol
            };

            // Add to history
            heatmapHistory.push(snapshot);
            if (heatmapHistory.length > maxHistoryLength) {
                heatmapHistory.shift();
            }

            // Update UI
            if (viewMode === 'orderbook') {
                updateStats(snapshot);
                renderHeatmap();
                updatePriceAxis();
                updateTimeAxis();
            }
        }

        // Update mode availability based on symbol provider
        function updateModeAvailability() {
            // IQFeed only supports order book mode (no liquidation data for futures)
            var liqBtn = document.getElementById('btnLiquidation');
            if (liqBtn) {
                liqBtn.style.display = 'none';
            }

            // Always use orderbook mode for futures
            if (viewMode === 'liquidation') {
                setViewMode('orderbook');
            }
        }

        // Handle mouse move on entire container (for left scale hover)
        function handleContainerMouseMove(e) {
            var container = e.currentTarget;
            var rect = container.getBoundingClientRect();
            var y = e.clientY - rect.top;

            // Calculate price from Y position
            var viewMin, viewMax;
            if (viewMode === 'orderbook') {
                if (!priceRange.mid) return;
                var midPrice = priceRange.mid;
                var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
                viewMin = midPrice - halfRange;
                viewMax = midPrice + halfRange;
            } else {
                var allPrices = Object.values(liquidationLevels).map(function(l) { return l.price; });
                if (allPrices.length === 0) return;
                viewMin = Math.min.apply(null, allPrices) * 0.995;
                viewMax = Math.max.apply(null, allPrices) * 1.005;
            }

            var priceSpan = viewMax - viewMin;
            var containerHeight = container.clientHeight;
            var price = viewMax - (y / containerHeight) * priceSpan;

            // Show crosshair
            var crosshair = document.getElementById('crosshairY');
            var crosshairPrice = document.getElementById('crosshairPrice');
            crosshair.style.display = 'block';
            crosshair.style.top = y + 'px';
            crosshairPrice.textContent = price.toFixed(2);
        }

        function handleContainerMouseOut() {
            document.getElementById('crosshairY').style.display = 'none';
        }

        function handleMouseMove(e) {
            var rect = canvas.getBoundingClientRect();
            var x = e.clientX - rect.left;
            var y = e.clientY - rect.top;

            // Calculate price from Y position
            var viewMin, viewMax;
            if (viewMode === 'orderbook') {
                // Center on mid price (same as renderHeatmap)
                var midPrice = priceRange.mid;
                var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
                viewMin = midPrice - halfRange;
                viewMax = midPrice + halfRange;
            } else {
                var allPrices = Object.values(liquidationLevels).map(function(l) { return l.price; });
                if (allPrices.length === 0) return;
                viewMin = Math.min.apply(null, allPrices) * 0.995;
                viewMax = Math.max.apply(null, allPrices) * 1.005;
            }

            var priceSpan = viewMax - viewMin;
            var price = viewMax - (y / canvasHeight) * priceSpan;

            // Show tooltip
            var tooltip = document.getElementById('heatmapTooltip');
            var tooltipPrice = document.getElementById('tooltipPrice');
            var tooltipInfo = document.getElementById('tooltipInfo');
            var crosshair = document.getElementById('crosshairY');

            tooltipPrice.textContent = 'Price: $' + price.toFixed(2);

            // Get additional info based on mode
            if (viewMode === 'orderbook' && heatmapHistory.length > 0) {
                var latest = heatmapHistory[heatmapHistory.length - 1];
                var diff = price - latest.midPrice;
                var pct = (diff / latest.midPrice * 100).toFixed(2);

                // Find volume at this price level
                var bidVol = 0, askVol = 0;
                var cumulativeBid = 0, cumulativeAsk = 0;
                var priceThreshold = (priceRange.max - priceRange.min) / 100;

                Object.keys(latest.bids).forEach(function(p) {
                    var pPrice = parseFloat(p);
                    if (Math.abs(pPrice - price) < priceThreshold) {
                        bidVol += latest.bids[p];
                    }
                    // Cumulative: all bids at or above this price (support)
                    if (pPrice >= price) {
                        cumulativeBid += latest.bids[p];
                    }
                });
                Object.keys(latest.asks).forEach(function(p) {
                    var pPrice = parseFloat(p);
                    if (Math.abs(pPrice - price) < priceThreshold) {
                        askVol += latest.asks[p];
                    }
                    // Cumulative: all asks at or below this price (resistance)
                    if (pPrice <= price) {
                        cumulativeAsk += latest.asks[p];
                    }
                });

                // Calculate wall strength
                var avgVol = (latest.totalBidVol + latest.totalAskVol) / (depthLevels * 2);
                var wallStrength = Math.max(bidVol, askVol) / avgVol;
                var wallLabel = wallStrength > 5 ? '🐋 WHALE WALL' : (wallStrength > 2 ? '⚠️ Strong Wall' : '');

                // Support/Resistance analysis
                var isBidZone = price < latest.midPrice;
                var zoneType = isBidZone ? 'Support' : 'Resistance';
                var zoneStrength = isBidZone ? cumulativeBid : cumulativeAsk;
                var totalVol = latest.totalBidVol + latest.totalAskVol;
                var zonePercent = ((zoneStrength / totalVol) * 100).toFixed(1);

                var volInfo = '';
                if (bidVol > 0) volInfo = '<span style="color:#22c55e">Bid Vol: ' + bidVol.toFixed(3) + '</span>';
                else if (askVol > 0) volInfo = '<span style="color:#ef4444">Ask Vol: ' + askVol.toFixed(3) + '</span>';
                else volInfo = '<span style="color:#6b7280">No orders at level</span>';

                tooltipInfo.innerHTML =
                    '<span style="color:#9ca3af">' + (diff >= 0 ? '+' : '') + pct + '% from mid</span><br>' +
                    volInfo +
                    (wallLabel ? '<br><span style="color:#3b82f6">' + wallLabel + '</span>' : '') +
                    '<br><span style="color:#a855f7">' + zoneType + ': ' + zonePercent + '% depth</span>';

            } else if (viewMode === 'liquidation') {
                var isAbove = price > currentPrice;
                var liqType = isAbove ? 'Short Liq Zone' : 'Long Liq Zone';

                // Find liquidation amount at this price level
                var totalLiqAmount = 0;
                var leveragesAtPrice = [];
                var roundTo = 10; // Default
                if (currentSymbol === 'BTCUSDT') roundTo = 100;
                else if (currentSymbol === 'XAUUSD') roundTo = 5;
                else if (currentSymbol === 'XAGUSD') roundTo = 0.5;
                var roundedPrice = Math.round(price / roundTo) * roundTo;

                // Calculate cascade potential (liqs between current price and this level)
                var cascadeLiq = 0;

                Object.values(liquidationLevels).forEach(function(liq) {
                    if (Math.abs(liq.price - roundedPrice) < roundTo) {
                        totalLiqAmount += liq.intensity;
                        if (leveragesAtPrice.indexOf(liq.leverage + 'x') === -1) {
                            leveragesAtPrice.push(liq.leverage + 'x');
                        }
                    }
                    // Cascade: all liqs between current price and hover price
                    if (isAbove && liq.price > currentPrice && liq.price <= price) {
                        cascadeLiq += liq.intensity;
                    } else if (!isAbove && liq.price < currentPrice && liq.price >= price) {
                        cascadeLiq += liq.intensity;
                    }
                });

                var liqAmountM = (totalLiqAmount * currentPrice / 500000).toFixed(1);
                var cascadeM = (cascadeLiq * currentPrice / 500000).toFixed(1);
                var leverageText = leveragesAtPrice.length > 0 ? leveragesAtPrice.join(', ') : '--';
                var distPct = ((price - currentPrice) / currentPrice * 100).toFixed(2);

                // Magnet strength indicator
                var magnetStrength = '';
                if (parseFloat(liqAmountM) > 20) magnetStrength = '🧲 STRONG MAGNET';
                else if (parseFloat(liqAmountM) > 10) magnetStrength = '🧲 Moderate Pull';

                // Trade signal
                var tradeSignal = '';
                if (isAbove && parseFloat(cascadeM) > 15) {
                    tradeSignal = '<span style="color:#ef4444">⚠️ Short squeeze risk</span>';
                } else if (!isAbove && parseFloat(cascadeM) > 15) {
                    tradeSignal = '<span style="color:#22c55e">⚠️ Long squeeze risk</span>';
                }

                tooltipInfo.innerHTML =
                    '<span style="color:' + (isAbove ? '#ef4444' : '#22c55e') + '">' + liqType + '</span><br>' +
                    'At Level: <span style="color:#fbfd03">' + liqAmountM + 'M</span><br>' +
                    'Cascade to here: <span style="color:#a855f7">' + cascadeM + 'M</span><br>' +
                    'Leverages: ' + leverageText + '<br>' +
                    '<span style="color:#9ca3af">' + (distPct >= 0 ? '+' : '') + distPct + '%</span>' +
                    (magnetStrength ? '<br><span style="color:#eab308">' + magnetStrength + '</span>' : '') +
                    (tradeSignal ? '<br>' + tradeSignal : '');
            }

            // Position tooltip
            tooltip.style.display = 'block';
            tooltip.style.left = (x + 60) + 'px';
            tooltip.style.top = (y - 10) + 'px';

            // Show crosshair with price label
            crosshair.style.display = 'block';
            crosshair.style.top = y + 'px';
            document.getElementById('crosshairPrice').textContent = price.toFixed(2);
        }

        function handleMouseOut() {
            document.getElementById('heatmapTooltip').style.display = 'none';
            // Don't hide crosshair here - let container handler manage it
        }

        function resizeCanvas() {
            var container = canvas.parentElement;
            // Account for price axis (80px right), scale bar (45px left), histogram (120px right)
            var extraLeft = 45; // Both modes have left scale bar
            var extraRight = 200; // Both modes have histogram (80 price axis + 120 histogram)
            canvas.width = container.clientWidth - extraRight - extraLeft;
            canvas.height = container.clientHeight;
            canvasWidth = canvas.width;
            canvasHeight = canvas.height;

            // Position main canvas
            canvas.style.left = extraLeft + 'px';

            // Resize and position histogram canvas
            if (histCanvas && viewMode === 'liquidation') {
                var histContainer = histCanvas.parentElement;
                histCanvas.width = histContainer.clientWidth;
                histCanvas.height = container.clientHeight;
                // Position histogram between main canvas and price axis
                histContainer.style.right = '80px'; // After price axis
            }

            // Check if market is closed - redraw the message
            if (marketClosed) {
                drawMarketClosedMessage();
            } else if (viewMode === 'orderbook') {
                renderHeatmap();
            } else {
                renderLiquidationMap();
            }
        }

        // View mode toggle
        function setViewMode(mode) {
            viewMode = mode;

            // Update buttons
            document.getElementById('btnOrderBook').className = mode === 'orderbook' ? 'active' : '';
            document.getElementById('btnLiquidation').className = mode === 'liquidation' ? 'active' : '';

            // Update page title
            var config = symbolConfig[currentSymbol];
            var displayName = config ? config.name : currentSymbol;
            document.getElementById('pageTitle').textContent =
                mode === 'orderbook' ? 'Order Book Heatmap' : 'Liquidation Heatmap';
            document.getElementById('symbolTitle').textContent =
                displayName + (mode === 'orderbook' ? ' Order Book Heatmap' : ' Liquidation Map');

            // Toggle UI elements
            document.getElementById('leverageOptions').style.display = mode === 'liquidation' ? 'flex' : 'none';
            document.getElementById('rangeContainer').style.display = mode === 'liquidation' ? 'inline' : 'none';
            document.getElementById('orderbookStats').style.display = mode === 'orderbook' ? 'flex' : 'none';
            document.getElementById('liquidationStats').style.display = mode === 'liquidation' ? 'flex' : 'none';
            document.getElementById('orderbookLegend').style.display = mode === 'orderbook' ? 'flex' : 'none';
            document.getElementById('liquidationLegend').style.display = mode === 'liquidation' ? 'flex' : 'none';

            // Toggle intensity scale and histogram based on mode
            document.getElementById('intensityScale').style.display = mode === 'liquidation' ? 'block' : 'none';
            document.getElementById('orderbookScale').style.display = mode === 'orderbook' ? 'block' : 'none';
            document.getElementById('liqHistogram').style.display = mode === 'liquidation' ? 'block' : 'none';
            document.getElementById('orderbookHistogram').style.display = mode === 'orderbook' ? 'block' : 'none';

            // Clear canvas first
            if (ctx) {
                ctx.fillStyle = '#0d0d14';
                ctx.fillRect(0, 0, canvasWidth, canvasHeight);
            }

            if (mode === 'liquidation') {
                fetchHistoricalPrices();
                updateLiquidationTimeAxis();
            } else {
                renderHeatmap();
                updatePriceAxis();
                updateTimeAxis();
            }
        }

        function setLiqRange(range) {
            liqRange = range;
            if (viewMode === 'liquidation') {
                fetchHistoricalPrices();
            }
        }

        function updateLiquidationLevels() {
            leverageConfig[10].enabled = document.getElementById('lev10x').checked;
            leverageConfig[25].enabled = document.getElementById('lev25x').checked;
            leverageConfig[50].enabled = document.getElementById('lev50x').checked;
            leverageConfig[100].enabled = document.getElementById('lev100x').checked;

            if (viewMode === 'liquidation') {
                calculateLiquidationLevels();
                renderLiquidationMap();
            }
        }

        function startFetching() {
            if (refreshTimer) clearInterval(refreshTimer);

            // IQFeed uses WebSocket push, no polling needed
            // Just subscribe to the symbol
            if (iqfeedWs && iqfeedWs.readyState === WebSocket.OPEN) {
                iqfeedWs.send(JSON.stringify({ type: 'subscribe', symbol: currentSymbol }));
                updateStatus('connected', iqfeedConnected ? 'Live' : 'Demo Mode');
            } else {
                updateStatus('', 'Connecting...');
                // Try to reconnect
                connectIQFeed();
            }
        }

        // Fetch historical kline data for liquidation calculations (not used with IQFeed futures)
        function fetchHistoricalPrices() {
            // IQFeed futures don't support liquidation map - this is placeholder
            document.getElementById('loadingIndicator').style.display = 'none';
        }

        function calculateLiquidationLevels() {
            // Liquidation levels not supported for IQFeed futures
            liquidationLevels = {};
        }

        function updateLiquidationStats() {
            if (priceHistory.length === 0) return;

            var price = priceHistory[priceHistory.length - 1].close;
            currentPrice = price;

            document.getElementById('liqCurrentPrice').textContent = price.toFixed(2);

            // Find nearest long liquidation zone (below current price)
            var longLiqs = Object.values(liquidationLevels).filter(function(l) {
                return l.type === 'long' && l.price < price;
            }).sort(function(a, b) { return b.price - a.price; });

            if (longLiqs.length > 0) {
                document.getElementById('liqLongZone').textContent = longLiqs[0].price.toFixed(0);
            }

            // Find nearest short liquidation zone (above current price)
            var shortLiqs = Object.values(liquidationLevels).filter(function(l) {
                return l.type === 'short' && l.price > price;
            }).sort(function(a, b) { return a.price - b.price; });

            if (shortLiqs.length > 0) {
                document.getElementById('liqShortZone').textContent = shortLiqs[0].price.toFixed(0);
            }

            // Calculate total liquidation amounts
            var totalLong = 0, totalShort = 0;
            Object.values(liquidationLevels).forEach(function(l) {
                if (l.type === 'long') totalLong += l.intensity;
                else totalShort += l.intensity;
            });

            document.getElementById('totalLongLiq').textContent = (totalLong / 1000).toFixed(1) + 'K';
            document.getElementById('totalShortLiq').textContent = (totalShort / 1000).toFixed(1) + 'K';

            // Determine magnet direction
            var nearbyLong = longLiqs.slice(0, 3).reduce(function(sum, l) { return sum + l.intensity; }, 0);
            var nearbyShort = shortLiqs.slice(0, 3).reduce(function(sum, l) { return sum + l.intensity; }, 0);

            var magnet = document.getElementById('liqMagnet');
            if (nearbyLong > nearbyShort * 1.5) {
                magnet.textContent = 'DOWN';
                magnet.className = 'stat-value liq-short';
            } else if (nearbyShort > nearbyLong * 1.5) {
                magnet.textContent = 'UP';
                magnet.className = 'stat-value liq-long';
            } else {
                magnet.textContent = 'NEUTRAL';
                magnet.className = 'stat-value neutral';
            }
        }

        function renderLiquidationMap() {
            if (!ctx || priceHistory.length === 0) return;

            // Dark purple background like CoinGlass
            ctx.fillStyle = '#1a0a25';
            ctx.fillRect(0, 0, canvasWidth, canvasHeight);

            // Calculate price range from liquidation levels
            var allPrices = Object.values(liquidationLevels).map(function(l) { return l.price; });
            if (allPrices.length === 0) return;

            var viewMin = Math.min.apply(null, allPrices) * 0.995;
            var viewMax = Math.max.apply(null, allPrices) * 1.005;
            var priceSpan = viewMax - viewMin;

            // Get max intensity for color scaling
            var maxIntensity = Math.max.apply(null, Object.values(liquidationLevels).map(function(l) { return l.intensity; }));

            // Calculate time range
            var minTime = priceHistory[0].timestamp;
            var maxTime = priceHistory[priceHistory.length - 1].timestamp;
            var timeSpan = maxTime - minTime;

            // Group liquidation levels by price for aggregated display
            // Use appropriate rounding based on symbol price scale
            var aggRound = 100; // Default for BTC
            if (currentSymbol === 'ETHUSDT') aggRound = 50;
            else if (currentSymbol === 'XAUUSD') aggRound = 10; // Gold ~$2600
            else if (currentSymbol === 'XAGUSD') aggRound = 1; // Silver ~$30

            var aggregatedLevels = {};
            Object.values(liquidationLevels).forEach(function(liq) {
                var priceKey = Math.round(liq.price / aggRound) * aggRound;
                if (!aggregatedLevels[priceKey]) {
                    aggregatedLevels[priceKey] = { price: priceKey, type: liq.type, totalIntensity: 0, leverages: {} };
                }
                aggregatedLevels[priceKey].totalIntensity += liq.intensity;
                aggregatedLevels[priceKey].leverages[liq.leverage] = (aggregatedLevels[priceKey].leverages[liq.leverage] || 0) + liq.intensity;
            });

            // Draw liquidation levels
            Object.values(liquidationLevels).forEach(function(liq) {
                var y = canvasHeight - ((liq.price - viewMin) / priceSpan) * canvasHeight;
                var intensity = liq.intensity / maxIntensity;

                // Get color based on leverage and intensity
                var color = getLiquidationColor(liq.type, liq.leverage, intensity);

                // Draw each timestamp where this level was created
                liq.timestamps.forEach(function(ts) {
                    var x = ((ts - minTime) / timeSpan) * canvasWidth;
                    var barWidth = canvasWidth / priceHistory.length;
                    var barHeight = Math.max(4, intensity * 20);

                    ctx.fillStyle = color;
                    ctx.fillRect(x, y - barHeight/2, barWidth + 1, barHeight);
                });
            });

            // Draw aggregated liquidation amounts like CoinGlass
            ctx.font = 'bold 11px Consolas';
            ctx.textAlign = 'right';

            // Sort by intensity to draw most significant last (on top)
            var sortedLevels = Object.values(aggregatedLevels).sort(function(a, b) {
                return a.totalIntensity - b.totalIntensity;
            });

            sortedLevels.forEach(function(agg) {
                var y = canvasHeight - ((agg.price - viewMin) / priceSpan) * canvasHeight;
                var intensity = agg.totalIntensity / maxIntensity;

                // Show labels for levels with >15% intensity
                if (intensity > 0.15) {
                    // Calculate estimated USD value (intensity * BTC price * multiplier for realistic amounts)
                    var estimatedM = (agg.totalIntensity * currentPrice / 500000).toFixed(1);

                    // Format: show decimal only if needed
                    var labelText = estimatedM >= 10 ? Math.round(estimatedM) + 'M' : estimatedM + 'M';

                    // Get color based on intensity (CoinGlass style)
                    var labelColor = getLiquidationColor(agg.type, 0, intensity);

                    // Draw label with glow effect for high intensity
                    if (intensity > 0.7) {
                        ctx.shadowColor = '#ffff00';
                        ctx.shadowBlur = 10;
                    } else {
                        ctx.shadowBlur = 0;
                    }

                    // Draw text directly on the chart (CoinGlass style - yellow for high, green for medium, cyan for low)
                    ctx.fillStyle = intensity > 0.7 ? '#ffff00' : (intensity > 0.4 ? '#90ff50' : '#00d8c8');
                    ctx.fillText(labelText, canvasWidth - 10, y + 4);

                    ctx.shadowBlur = 0;
                }
            });

            ctx.textAlign = 'left'; // Reset

            // Draw current price line
            var priceY = canvasHeight - ((currentPrice - viewMin) / priceSpan) * canvasHeight;
            ctx.strokeStyle = '#f59e0b';
            ctx.lineWidth = 2;
            ctx.setLineDash([5, 5]);
            ctx.beginPath();
            ctx.moveTo(0, priceY);
            ctx.lineTo(canvasWidth, priceY);
            ctx.stroke();
            ctx.setLineDash([]);

            // Draw price line label
            ctx.fillStyle = '#f59e0b';
            ctx.font = 'bold 12px Consolas';
            ctx.fillText(currentPrice.toFixed(2), 10, priceY - 5);

            // Draw accumulation zones (high intensity areas)
            drawMagnetZones(viewMin, viewMax, priceSpan, maxIntensity);

            // Render right-side histogram
            renderHistogram(viewMin, viewMax, priceSpan, maxIntensity);

            // Update left intensity scale
            updateIntensityScale(maxIntensity);
        }

        function drawMagnetZones(viewMin, viewMax, priceSpan, maxIntensity) {
            // Find clusters of high liquidation intensity
            var threshold = maxIntensity * 0.6;

            Object.values(liquidationLevels).forEach(function(liq) {
                if (liq.intensity > threshold) {
                    var y = canvasHeight - ((liq.price - viewMin) / priceSpan) * canvasHeight;

                    // Draw glowing effect for magnet zones
                    var gradient = ctx.createRadialGradient(canvasWidth/2, y, 0, canvasWidth/2, y, 50);
                    if (liq.type === 'long') {
                        gradient.addColorStop(0, 'rgba(34, 197, 94, 0.3)');
                        gradient.addColorStop(1, 'rgba(34, 197, 94, 0)');
                    } else {
                        gradient.addColorStop(0, 'rgba(239, 68, 68, 0.3)');
                        gradient.addColorStop(1, 'rgba(239, 68, 68, 0)');
                    }

                    ctx.fillStyle = gradient;
                    ctx.fillRect(0, y - 25, canvasWidth, 50);
                }
            });
        }

        // Render liquidation histogram on right side (like CoinGlass)
        function renderHistogram(viewMin, viewMax, priceSpan, maxIntensity) {
            if (!histCtx) return;

            // Get actual display size
            var container = histCanvas.parentElement;
            var displayWidth = container.clientWidth;
            var displayHeight = container.clientHeight;

            if (displayWidth === 0 || displayHeight === 0) return;

            // Set canvas size accounting for device pixel ratio for sharp rendering
            var dpr = window.devicePixelRatio || 1;
            histCanvas.width = displayWidth * dpr;
            histCanvas.height = displayHeight * dpr;
            histCanvas.style.width = displayWidth + 'px';
            histCanvas.style.height = displayHeight + 'px';

            // Reset transform and apply new scale
            histCtx.setTransform(dpr, 0, 0, dpr, 0, 0);

            var hWidth = displayWidth;
            var hHeight = displayHeight;

            // Clear histogram canvas
            histCtx.fillStyle = '#0d0d14';
            histCtx.fillRect(0, 0, hWidth, hHeight);

            // Aggregate liquidations by price level for histogram
            var priceBins = {};
            var roundTo = 10; // Default
            if (currentSymbol === 'BTCUSDT') roundTo = 100;
            else if (currentSymbol === 'XAUUSD') roundTo = 5; // Gold ~$2600
            else if (currentSymbol === 'XAGUSD') roundTo = 0.5; // Silver ~$30

            Object.values(liquidationLevels).forEach(function(liq) {
                var binPrice = Math.round(liq.price / roundTo) * roundTo;
                if (!priceBins[binPrice]) {
                    priceBins[binPrice] = { long: 0, short: 0 };
                }
                if (liq.type === 'long') {
                    priceBins[binPrice].long += liq.intensity;
                } else {
                    priceBins[binPrice].short += liq.intensity;
                }
            });

            // Find max for scaling
            var maxBinValue = 0;
            Object.values(priceBins).forEach(function(bin) {
                maxBinValue = Math.max(maxBinValue, bin.long, bin.short);
            });

            if (maxBinValue === 0) return;

            // Draw histogram bars - use integer pixels for sharp rendering
            var numBins = Object.keys(priceBins).length;
            var barHeight = Math.max(3, Math.floor(hHeight / numBins * 0.7));
            var centerX = Math.floor(hWidth / 2);

            Object.keys(priceBins).forEach(function(priceStr) {
                var price = parseFloat(priceStr);
                var bin = priceBins[priceStr];

                // Calculate Y position - round to integer
                var y = Math.round(hHeight - ((price - viewMin) / priceSpan) * hHeight);

                // Draw short liquidation bar (above current price - cyan/green pointing LEFT)
                if (bin.short > 0 && price > currentPrice) {
                    var barWidth = Math.round((bin.short / maxBinValue) * (hWidth / 2 - 5));
                    var intensity = bin.short / maxIntensity;
                    histCtx.fillStyle = intensity > 0.6 ? '#00ffdd' : (intensity > 0.3 ? '#00d8c8' : '#00b4c8');
                    histCtx.fillRect(centerX - barWidth, y - Math.floor(barHeight/2), barWidth, barHeight);
                }

                // Draw long liquidation bar (below current price - red/pink pointing RIGHT)
                if (bin.long > 0 && price < currentPrice) {
                    var barWidth = Math.round((bin.long / maxBinValue) * (hWidth / 2 - 5));
                    var intensity = bin.long / maxIntensity;
                    histCtx.fillStyle = intensity > 0.6 ? '#ff4444' : (intensity > 0.3 ? '#ef4444' : '#b91c1c');
                    histCtx.fillRect(centerX, y - Math.floor(barHeight/2), barWidth, barHeight);
                }
            });

            // Draw center line (current price level)
            var currentY = hHeight - ((currentPrice - viewMin) / priceSpan) * hHeight;
            histCtx.strokeStyle = '#f59e0b';
            histCtx.lineWidth = 1;
            histCtx.beginPath();
            histCtx.moveTo(0, currentY);
            histCtx.lineTo(hWidth, currentY);
            histCtx.stroke();

            // Draw vertical center line
            histCtx.strokeStyle = '#333';
            histCtx.beginPath();
            histCtx.moveTo(centerX, 0);
            histCtx.lineTo(centerX, hHeight);
            histCtx.stroke();

            // Update histogram max label
            var maxM = (maxBinValue * currentPrice / 500000).toFixed(1);
            document.getElementById('histogramMaxLabel').textContent = maxM + 'M';
        }

        // Update intensity scale label
        function updateIntensityScale(maxIntensity) {
            var maxM = (maxIntensity * currentPrice / 500000).toFixed(1);
            document.getElementById('intensityMaxLabel').textContent = maxM + 'M';
            maxLiqIntensity = maxIntensity;
        }

        // Update orderbook scale label
        function updateOrderbookScale(maxSize) {
            var label = document.getElementById('orderbookMaxLabel');
            if (label) {
                // Format based on size
                if (maxSize >= 1000) {
                    label.textContent = (maxSize / 1000).toFixed(1) + 'K';
                } else {
                    label.textContent = maxSize.toFixed(1);
                }
            }
        }

        // Render orderbook depth histogram on right side
        function renderOrderbookHistogram() {
            if (!obHistCtx || heatmapHistory.length === 0) return;

            var latest = heatmapHistory[heatmapHistory.length - 1];
            if (!latest) return;

            // Get actual display size
            var container = obHistCanvas.parentElement;
            var displayWidth = container.clientWidth;
            var displayHeight = container.clientHeight;

            if (displayWidth === 0 || displayHeight === 0) return;

            // Set canvas size accounting for device pixel ratio for sharp rendering
            var dpr = window.devicePixelRatio || 1;
            obHistCanvas.width = displayWidth * dpr;
            obHistCanvas.height = displayHeight * dpr;
            obHistCanvas.style.width = displayWidth + 'px';
            obHistCanvas.style.height = displayHeight + 'px';
            obHistCtx.setTransform(dpr, 0, 0, dpr, 0, 0);

            var hWidth = displayWidth;
            var hHeight = displayHeight;

            // Clear canvas
            obHistCtx.fillStyle = '#0d0d14';
            obHistCtx.fillRect(0, 0, hWidth, hHeight);

            // Get price range
            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;
            var priceSpan = viewMax - viewMin;

            if (priceSpan === 0) return;

            // Find max size for scaling
            var maxSize = 0;
            Object.values(latest.bids).forEach(function(s) { maxSize = Math.max(maxSize, s); });
            Object.values(latest.asks).forEach(function(s) { maxSize = Math.max(maxSize, s); });

            if (maxSize === 0) return;

            var centerX = Math.floor(hWidth / 2);
            var barHeight = Math.max(3, Math.floor(hHeight / depthLevels * 0.7));

            // Draw bid bars (green, pointing LEFT from center)
            Object.keys(latest.bids).forEach(function(priceStr) {
                var price = parseFloat(priceStr);
                var size = latest.bids[priceStr];
                var y = Math.round(hHeight - ((price - viewMin) / priceSpan) * hHeight);
                var barWidth = Math.round((size / maxSize) * (hWidth / 2 - 5));

                var intensity = size / maxSize;
                obHistCtx.fillStyle = intensity > 0.6 ? '#4ade80' : (intensity > 0.3 ? '#22c55e' : '#15803d');
                obHistCtx.fillRect(centerX - barWidth, y - Math.floor(barHeight/2), barWidth, barHeight);
            });

            // Draw ask bars (red, pointing RIGHT from center)
            Object.keys(latest.asks).forEach(function(priceStr) {
                var price = parseFloat(priceStr);
                var size = latest.asks[priceStr];
                var y = Math.round(hHeight - ((price - viewMin) / priceSpan) * hHeight);
                var barWidth = Math.round((size / maxSize) * (hWidth / 2 - 5));

                var intensity = size / maxSize;
                obHistCtx.fillStyle = intensity > 0.6 ? '#fca5a5' : (intensity > 0.3 ? '#ef4444' : '#b91c1c');
                obHistCtx.fillRect(centerX, y - Math.floor(barHeight/2), barWidth, barHeight);
            });

            // Draw current price line
            var currentY = Math.round(hHeight - ((midPrice - viewMin) / priceSpan) * hHeight);
            obHistCtx.strokeStyle = '#f59e0b';
            obHistCtx.lineWidth = 1;
            obHistCtx.beginPath();
            obHistCtx.moveTo(0, currentY);
            obHistCtx.lineTo(hWidth, currentY);
            obHistCtx.stroke();

            // Draw vertical center line
            obHistCtx.strokeStyle = '#333';
            obHistCtx.beginPath();
            obHistCtx.moveTo(centerX, 0);
            obHistCtx.lineTo(centerX, hHeight);
            obHistCtx.stroke();

            // Update max label
            var label = document.getElementById('orderbookHistMaxLabel');
            if (label) {
                if (maxSize >= 1000) {
                    label.textContent = (maxSize / 1000).toFixed(1) + 'K';
                } else {
                    label.textContent = maxSize.toFixed(1);
                }
            }
        }

        function getLiquidationColor(type, leverage, intensity) {
            // CoinGlass actual colors: Dark purple bg -> Cyan (low) -> Green (med) -> Yellow (high)
            var r, g, b;

            if (intensity < 0.1) {
                // Very low - dark purple/transparent
                return 'rgba(60, 20, 80, ' + (intensity * 3) + ')';
            } else if (intensity < 0.25) {
                // Low - cyan/teal
                var t = (intensity - 0.1) / 0.15;
                r = Math.floor(0 + t * 20);
                g = Math.floor(180 + t * 30);
                b = Math.floor(200 + t * 20);
            } else if (intensity < 0.45) {
                // Low-medium - cyan to teal-green
                var t = (intensity - 0.25) / 0.2;
                r = Math.floor(20 + t * 30);
                g = Math.floor(210 + t * 30);
                b = Math.floor(220 - t * 80);
            } else if (intensity < 0.65) {
                // Medium - green
                var t = (intensity - 0.45) / 0.2;
                r = Math.floor(50 + t * 100);
                g = Math.floor(240 + t * 15);
                b = Math.floor(140 - t * 80);
            } else if (intensity < 0.85) {
                // Medium-high - green to yellow-green
                var t = (intensity - 0.65) / 0.2;
                r = Math.floor(150 + t * 80);
                g = Math.floor(255);
                b = Math.floor(60 - t * 40);
            } else {
                // High - bright yellow
                var t = (intensity - 0.85) / 0.15;
                r = Math.floor(230 + t * 25);
                g = Math.floor(255);
                b = Math.floor(20 + t * 30);
            }

            return 'rgb(' + r + ',' + g + ',' + b + ')';
        }

        function updateLiquidationPriceAxis() {
            if (priceHistory.length === 0) return;

            var allPrices = Object.values(liquidationLevels).map(function(l) { return l.price; });
            if (allPrices.length === 0) return;

            var viewMin = Math.min.apply(null, allPrices) * 0.995;
            var viewMax = Math.max.apply(null, allPrices) * 1.005;

            var axis = document.getElementById('priceAxis');
            var labels = [];
            var steps = 15;

            for (var i = 0; i <= steps; i++) {
                var price = viewMax - ((viewMax - viewMin) / steps) * i;
                var isCurrent = Math.abs(price - currentPrice) < (viewMax - viewMin) / steps / 2;
                var isLongZone = price < currentPrice;

                var cls = 'price-label';
                if (isCurrent) cls += ' current-price';
                else if (isLongZone) cls += ' liq-long';
                else cls += ' liq-short';

                labels.push('<div class="' + cls + '">' + price.toFixed(0) + '</div>');
            }

            axis.innerHTML = labels.join('');
        }

        function processOrderBook(data) {
            var bids = data.bids || [];
            var asks = data.asks || [];

            if (bids.length === 0 || asks.length === 0) return;

            var bestBid = parseFloat(bids[0][0]);
            var bestAsk = parseFloat(asks[0][0]);
            var midPrice = (bestBid + bestAsk) / 2;
            currentPrice = midPrice;

            // Calculate volume statistics
            var totalBidVol = 0, totalAskVol = 0;
            var bidLevels = {}, askLevels = {};

            bids.forEach(function(level) {
                var price = parseFloat(level[0]);
                var size = parseFloat(level[1]);
                bidLevels[price] = size;
                totalBidVol += size;
            });

            asks.forEach(function(level) {
                var price = parseFloat(level[0]);
                var size = parseFloat(level[1]);
                askLevels[price] = size;
                totalAskVol += size;
            });

            // Update price range
            var allPrices = Object.keys(bidLevels).concat(Object.keys(askLevels)).map(parseFloat);
            priceRange.min = Math.min.apply(null, allPrices);
            priceRange.max = Math.max.apply(null, allPrices);
            priceRange.mid = midPrice;

            // Create snapshot
            var snapshot = {
                timestamp: Date.now(),
                midPrice: midPrice,
                bestBid: bestBid,
                bestAsk: bestAsk,
                bids: bidLevels,
                asks: askLevels,
                totalBidVol: totalBidVol,
                totalAskVol: totalAskVol
            };

            // Add to history
            heatmapHistory.push(snapshot);
            if (heatmapHistory.length > maxHistoryLength) {
                heatmapHistory.shift();
            }

            // Update UI based on view mode
            if (viewMode === 'orderbook') {
                updateStats(snapshot);
                renderHeatmap();
                updatePriceAxis();
                updateTimeAxis();
            }
        }

        function updateStats(snapshot) {
            document.getElementById('bestBid').textContent = snapshot.bestBid.toFixed(2);
            document.getElementById('bestAsk').textContent = snapshot.bestAsk.toFixed(2);
            document.getElementById('spread').textContent = (snapshot.bestAsk - snapshot.bestBid).toFixed(2);
            document.getElementById('totalBidVol').textContent = snapshot.totalBidVol.toFixed(2);
            document.getElementById('totalAskVol').textContent = snapshot.totalAskVol.toFixed(2);

            var imbalance = ((snapshot.totalBidVol - snapshot.totalAskVol) / (snapshot.totalBidVol + snapshot.totalAskVol) * 100).toFixed(1);
            var imbalanceEl = document.getElementById('imbalance');
            imbalanceEl.textContent = imbalance + '%';
            imbalanceEl.className = 'stat-value ' + (imbalance > 0 ? 'bid' : imbalance < 0 ? 'ask' : 'neutral');
        }

        // Show market closed message overlay
        function drawMarketClosedMessage() {
            var overlay = document.getElementById('marketClosedOverlay');
            if (overlay) {
                overlay.style.display = 'block';
            }
        }

        // Hide market closed message overlay
        function hideMarketClosedMessage() {
            var overlay = document.getElementById('marketClosedOverlay');
            if (overlay) {
                overlay.style.display = 'none';
            }
        }

        function renderHeatmap() {
            if (!ctx || heatmapHistory.length === 0) return;

            ctx.fillStyle = '#0d0d14';
            ctx.fillRect(0, 0, canvasWidth, canvasHeight);

            var historyLen = heatmapHistory.length;
            var columnWidth = canvasWidth / Math.min(historyLen, maxHistoryLength);

            // Calculate global max size for color scaling
            var allSizes = [];
            heatmapHistory.forEach(function(snapshot) {
                Object.values(snapshot.bids).forEach(function(s) { allSizes.push(s); });
                Object.values(snapshot.asks).forEach(function(s) { allSizes.push(s); });
            });
            var avgSize = allSizes.reduce(function(a, b) { return a + b; }, 0) / allSizes.length;
            var maxSize = Math.max.apply(null, allSizes);

            // Update orderbook scale label
            updateOrderbookScale(maxSize);

            // Center view on mid price
            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;
            var priceSpan = viewMax - viewMin;

            // Calculate row height based on number of price levels
            var numLevels = depthLevels * 2;
            var rowHeight = Math.max(canvasHeight / numLevels, 2);

            // Render each time column
            heatmapHistory.forEach(function(snapshot, colIndex) {
                var x = colIndex * columnWidth;

                // Draw bid levels
                Object.keys(snapshot.bids).forEach(function(priceStr) {
                    var price = parseFloat(priceStr);
                    var size = snapshot.bids[priceStr];

                    var y = canvasHeight - ((price - viewMin) / priceSpan) * canvasHeight;
                    var intensity = Math.min(size / avgSize, 3) / 3;
                    var color = getBidColor(intensity, size > avgSize * 10);

                    ctx.fillStyle = color;
                    ctx.fillRect(x, y - rowHeight/2, columnWidth + 1, rowHeight);
                });

                // Draw ask levels
                Object.keys(snapshot.asks).forEach(function(priceStr) {
                    var price = parseFloat(priceStr);
                    var size = snapshot.asks[priceStr];

                    var y = canvasHeight - ((price - viewMin) / priceSpan) * canvasHeight;
                    var intensity = Math.min(size / avgSize, 3) / 3;
                    var color = getAskColor(intensity, size > avgSize * 10);

                    ctx.fillStyle = color;
                    ctx.fillRect(x, y - rowHeight/2, columnWidth + 1, rowHeight);
                });

                // Draw mid price line (yellow) - use priceRange.mid for consistent centering
                var midY = canvasHeight - ((priceRange.mid - viewMin) / priceSpan) * canvasHeight;
                ctx.fillStyle = '#f59e0b';
                ctx.fillRect(x, midY - 1, columnWidth + 1, 2);
            });

            // Render orderbook histogram on right side
            renderOrderbookHistogram();
        }

        function getBidColor(intensity, isWhale) {
            if (isWhale) return '#3b82f6';
            if (intensity > 0.7) return '#4ade80';
            if (intensity > 0.3) return '#22c55e';
            return 'rgba(20, 83, 45, ' + (0.3 + intensity * 0.7) + ')';
        }

        function getAskColor(intensity, isWhale) {
            if (isWhale) return '#3b82f6';
            if (intensity > 0.7) return '#fca5a5'; // Light red
            if (intensity > 0.3) return '#ef4444'; // Red
            return 'rgba(127, 29, 29, ' + (0.3 + intensity * 0.7) + ')'; // Dark red
        }

        function updatePriceAxis() {
            if (heatmapHistory.length === 0) return;

            var latest = heatmapHistory[heatmapHistory.length - 1];

            // Center view on mid price (same as renderHeatmap)
            var midPrice = priceRange.mid;
            var halfRange = Math.max(priceRange.max - midPrice, midPrice - priceRange.min);
            var viewMin = midPrice - halfRange;
            var viewMax = midPrice + halfRange;

            var axis = document.getElementById('priceAxis');
            var labels = [];
            var steps = 15;

            for (var i = 0; i <= steps; i++) {
                var price = viewMax - ((viewMax - viewMin) / steps) * i;
                var isMid = Math.abs(price - latest.midPrice) < (viewMax - viewMin) / steps / 2;
                labels.push('<div class="price-label' + (isMid ? ' current-price' : '') + '">' + price.toFixed(2) + '</div>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateTimeAxis() {
            if (heatmapHistory.length < 2) return;

            var axis = document.getElementById('timeAxis');
            var first = heatmapHistory[0].timestamp;
            var last = heatmapHistory[heatmapHistory.length - 1].timestamp;

            var labels = [];
            var steps = 5;

            for (var i = 0; i <= steps; i++) {
                var ts = first + ((last - first) / steps) * i;
                var date = new Date(ts);
                var timeStr = date.toLocaleTimeString();
                labels.push('<span>' + timeStr + '</span>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateLiquidationTimeAxis() {
            if (priceHistory.length < 2) return;

            var axis = document.getElementById('timeAxis');
            var first = priceHistory[0].timestamp;
            var last = priceHistory[priceHistory.length - 1].timestamp;

            var labels = [];
            var steps = 5;

            for (var i = 0; i <= steps; i++) {
                var ts = first + ((last - first) / steps) * i;
                var date = new Date(ts);
                // Show date for longer ranges
                var timeStr = liqRange === '1m' || liqRange === '1w' ?
                    date.toLocaleDateString(undefined, {month: 'short', day: 'numeric'}) :
                    date.toLocaleTimeString();
                labels.push('<span>' + timeStr + '</span>');
            }

            axis.innerHTML = labels.join('');
        }

        function updateStatus(status, text) {
            var dot = document.getElementById('statusDot');
            var textEl = document.getElementById('statusText');
            dot.className = 'status-dot ' + status;
            textEl.textContent = text;
        }

        function changeSymbol(symbol) {
            currentSymbol = symbol;
            marketClosed = false; // Reset market closed flag when changing symbols
            hideMarketClosedMessage(); // Hide the overlay
            // Save symbol selection to localStorage
            localStorage.setItem('heatmap_iqfeed_symbol', symbol);
            heatmapHistory = [];
            liquidationLevels = {};
            priceHistory = [];

            // Update mode availability (liquidation only for crypto)
            updateModeAvailability();

            var config = symbolConfig[symbol];
            var displayName = config ? config.name : symbol;

            if (viewMode === 'orderbook') {
                document.getElementById('symbolTitle').textContent = displayName + ' Order Book Heatmap';
            } else {
                document.getElementById('symbolTitle').textContent = displayName + ' Liquidation Map';
                fetchHistoricalPrices();
            }
            startFetching();
        }

        function setDepth(depth) {
            depthLevels = parseInt(depth);
            startFetching();
        }

        function setSpeed(speed) {
            updateSpeed = parseInt(speed);
            maxHistoryLength = Math.floor(300000 / updateSpeed);
            startFetching();
        }

        // Toggle sidebar for fullscreen heatmap
        function toggleHeatmapSidebar() {
            document.body.classList.toggle('fullscreen-heatmap');
            var isFullscreen = document.body.classList.contains('fullscreen-heatmap');
            // Rotate arrow: right arrow when sidebar hidden, left arrow when shown
            document.getElementById('toggleArrow').style.transform = isFullscreen ? 'rotate(0deg)' : 'rotate(180deg)';
            // Resize canvas after sidebar animation
            setTimeout(resizeCanvas, 350);
        }

        // Start
        init();
    </script>
</body>
</html>
