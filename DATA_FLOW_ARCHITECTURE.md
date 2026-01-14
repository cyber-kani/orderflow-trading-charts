# Order Flow Test - Data Flow Architecture

## Overview

This document describes how historical and live data flow through the system.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA SOURCE                                        │
│                    Databento WebSocket Server                                │
│                   wss://clitools.app/ws/databento                            │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      REDIS SYNC SERVICE (Python)                            │
│                      redis_sync_service.py                                   │
│  ┌─────────────┐    ┌──────────────────┐    ┌─────────────────────────────┐ │
│  │ WebSocket   │───▶│ Process & Merge  │───▶│ Store to Upstash Redis      │ │
│  │ Listener    │    │ Historical+Live  │    │ - chart:{sym}:{tf}:1year    │ │
│  └─────────────┘    │ Enforce Continuity│   │ - live:{sym}:{tf}:current   │ │
│                     └──────────────────┘    │ - live:{sym}:{tf}:buffer    │ │
│                                             └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
┌───────────────────────────────┐ ┌────────────────────────────────────────────┐
│     chart-today.cfm           │ │         chart-1year.cfm                    │
│     LIVE CHART                │ │         HISTORICAL CHART                   │
│                               │ │                                            │
│  ┌─────────────────────────┐  │ │  ┌──────────────────────────────────────┐  │
│  │ Direct WebSocket        │  │ │  │ Redis REST API Polling               │  │
│  │ - Receives ticks        │  │ │  │ - Loads chart:{sym}:{tf}:1year       │  │
│  │ - Receives candles      │  │ │  │ - Polls live:{sym}:{tf}:current      │  │
│  │ - Real-time updates     │  │ │  │ - Every 5 seconds                    │  │
│  └─────────────────────────┘  │ │  └──────────────────────────────────────┘  │
└───────────────────────────────┘ └────────────────────────────────────────────┘
```

---

## How Historical Data is Loaded

### 1. Backend Sync Service (redis_sync_service.py)

**Request Historical Data:**
```python
# Sends to WebSocket server
{
    "type": "get_history",
    "symbol": "GC",
    "timeframe": "1m",
    "bars": 100000
}
```

**Bars Requested per Timeframe:**
| Timeframe | Bars Requested | Approximate Duration |
|-----------|----------------|---------------------|
| 1m        | 100,000        | ~70 days            |
| 5m        | 50,000         | ~350 days           |
| 15m       | 35,000         | ~365 days           |
| 1h        | 8,760          | ~1 year             |
| 4h        | 2,200          | ~1 year             |
| 1d        | 365            | 1 year              |

**Processing Steps:**
1. Receives `historical_candles` message from WebSocket
2. Filters to last 365 days only
3. Deduplicates by timestamp (uses Map)
4. Validates OHLC values
5. Stores in `self.historical_data[symbol][timeframe]`

### 2. Frontend - chart-today.cfm (Live Chart)

**Direct WebSocket Request:**
```javascript
ws.send(JSON.stringify({
    type: 'get_history',
    symbol: SYMBOL,
    timeframe: TIMEFRAME,
    bars: 500
}));
```

**Processing in handleHistoricalCandles():**
1. Converts time from milliseconds to seconds
2. Floors to timeframe boundary
3. Clamps excessive wicks (max 10 points from body)
4. Deduplicates and merges by timestamp
5. Enforces continuity: `open = previous.close`
6. Sets data on chart via `candleSeries.setData()`

### 3. Frontend - chart-1year.cfm (Historical Chart)

**Redis REST API:**
```javascript
const key = `chart:${symbol}:${timeframe}:1year`;
const response = await fetch(`${UPSTASH_URL}/get/${key}`, {
    headers: { 'Authorization': `Bearer ${UPSTASH_TOKEN}` }
});
```

**No WebSocket Connection** - relies entirely on cached Redis data.

---

## How Live Data is Received

### 1. Backend Sync Service

**Receives Live Candle:**
```python
# Message from WebSocket
{
    "type": "candle",
    "symbol": "GC",
    "timeframe": "1m",
    "data": {
        "time": 1704067200000,  # milliseconds
        "open": 2030.5,
        "high": 2031.2,
        "low": 2030.1,
        "close": 2031.0,
        "volume": 15000
    }
}
```

**Processing:**
1. Converts timestamp from ms to seconds
2. Updates or appends to `self.live_buffer[symbol][timeframe]`
3. Maintains rolling buffer of 500 candles
4. Stores to Redis immediately:
   - `live:{symbol}:{timeframe}:current` (TTL: 2 minutes)
   - `live:{symbol}:{timeframe}:buffer` (TTL: 10 minutes)

**Merging with Historical:**
1. Historical candles stored first
2. Live candles overwrite historical (same timestamp)
3. Continuity enforced: each `open = previous.close`
4. Stored to `chart:{symbol}:{timeframe}:1year` (TTL: 24 hours)

### 2. Frontend - chart-today.cfm (Live Chart)

**Receives Candle Updates:**
```javascript
case 'candle':
    if (msg.symbol === SYMBOL && msg.timeframe === TIMEFRAME) {
        handleLiveCandle(msg.data);
    }
    break;
```

**handleLiveCandle() Processing:**
1. Rejects if close price moves >15 points from last known
2. Clamps wicks to max 10 points from body
3. Finds existing candle or creates new one
4. Enforces continuity: `open = previous.close`
5. Updates chart via `candleSeries.update()`

**Receives Tick Updates:**
```javascript
case 'tick':
    if (msg.symbol === SYMBOL) {
        handleTick(msg.price, msg.size);
    }
    break;
```

**handleTick() Processing:**
1. Rejects if price moves >15 points from last close
2. Updates current candle's close price
3. Extends high/low (clamped to max 10 from body)
4. Creates new candle if timeframe boundary crossed
5. Updates chart via `candleSeries.update()`

### 3. Frontend - chart-1year.cfm (Historical Chart)

**Polling Interval:** Every 5 seconds

```javascript
pollTimer = setInterval(async () => {
    // Check live candle
    const liveKey = `live:${symbol}:${timeframe}`;  // BUG: Missing `:current`
    const liveCandle = await getFromRedis(liveKey);

    // Update chart if found
    if (liveCandle) {
        candleSeries.update(newCandle);
    }
}, 5000);
```

---

## Data Validation Rules

### Candle Validation (chart-today.cfm)

| Validation | Threshold | Action |
|------------|-----------|--------|
| Close price movement | >15 points | Reject entire candle |
| Wick length | >10 points from body | Clamp to limit |
| OHLC validity | high >= all, low <= all | Enforce |

### Tick Validation

| Validation | Threshold | Action |
|------------|-----------|--------|
| Price movement | >15 points from last close | Reject tick |
| Wick extension | >10 points from body | Clamp to limit |

### Continuity Enforcement

- Each candle's `open` is set to previous candle's `close`
- Gap tolerance: Up to 10 hours before breaking continuity
- Applies in both backend (sync service) and frontend (chart-today.cfm)

---

## Redis Cache Keys

| Key Pattern | Content | TTL |
|-------------|---------|-----|
| `chart:{symbol}:{tf}:1year` | Full merged OHLC data | 24 hours |
| `live:{symbol}:{tf}:current` | Current live candle | 2 minutes |
| `live:{symbol}:{tf}:buffer` | Last 500 live candles | 10 minutes |

---

## Known Issues / Bugs

### 1. Sync Service Only Syncs GC 1m

**File:** `redis_sync_service.py:40-41`
```python
SYMBOLS = ["GC"]  # Focus on Gold only for now
TIMEFRAMES = ["1m"]  # Focus on 1-minute only for now
```

**Impact:** Redis cache is only populated for GC 1-minute data. Other symbols (SI, CL, ES, NQ) and other timeframes (5m, 15m, 1h, 4h, 1d) will have no data in Redis.

### 2. chart-1year.cfm Wrong Redis Key

**File:** `chart-1year.cfm:303-305`
```javascript
function getLiveKey(symbol, tf) {
    return `live:${symbol}:${tf}`;  // Missing `:current`
}
```

**Should be:**
```javascript
return `live:${symbol}:${tf}:current`;
```

**Impact:** Live polling in chart-1year.cfm never finds data because it queries the wrong key.

### 3. chart-1year.cfm Timeframes Not Synced

**File:** `chart-1year.cfm:235-237`
```javascript
<button data-tf="1h" class="active">1H</button>
<button data-tf="4h">4H</button>
<button data-tf="1d">1D</button>
```

But sync service only syncs `1m`. These timeframes will show "No data in Redis".

### 4. API Token Exposed in Frontend

**Files:** `chart-1year.cfm:278`, `redis_sync_service.py:33`

The Upstash Redis token is hardcoded in the frontend JavaScript, visible to anyone viewing page source. This is a security risk.

**Recommendation:** Use a backend API proxy that adds the token server-side.

### 5. No Aggregation for Higher Timeframes

The sync service does not aggregate 1-minute candles into higher timeframes. If you want 1h data, you need to either:
1. Request it directly from the WebSocket server
2. Add aggregation logic to the sync service

---

## Sync Intervals Summary

| Operation | Interval | Purpose |
|-----------|----------|---------|
| Full historical sync | 3600s (1 hour) | Refresh historical data |
| Redis periodic sync | 30s | Ensure all data in cache |
| Live candle update | 1s (per message) | Push to Redis immediately |
| Frontend polling (1year) | 5000ms | Check for live updates |
| WebSocket heartbeat | 60s ping / 120s timeout | Connection health |

---

## Data Flow Summary

### chart-today.cfm (Live Trading View)
1. Opens WebSocket to `wss://clitools.app/ws/databento`
2. Requests 500 historical bars
3. Receives `historical_candles` message
4. Continuously receives `candle` and `tick` messages
5. Validates and processes data client-side
6. Updates chart in real-time

### chart-1year.cfm (Historical Analysis View)
1. Fetches from Redis: `chart:{symbol}:{tf}:1year`
2. Displays cached historical data
3. Polls every 5 seconds for updates
4. No direct WebSocket connection
5. Relies entirely on sync service to populate cache

### redis_sync_service.py (Backend Worker)
1. Connects to WebSocket server
2. Requests historical data for configured symbols/timeframes
3. Receives live candle updates
4. Merges historical + live data
5. Enforces candle continuity
6. Stores to Upstash Redis
7. Runs continuously as systemd service
