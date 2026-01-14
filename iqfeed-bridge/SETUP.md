# IQFeed Bridge Setup Guide

## Overview

Rust-based IQFeed market data bridge that connects to IQFeed on Windows and streams data via WebSocket. Uses same message format as Databento bridge for compatibility.

## Architecture

```
Windows (IQFeed)                    Linux (Bridge)
┌─────────────────┐                ┌─────────────────┐
│ IQFeed Client   │                │ Rust Bridge     │
│                 │    TCP/IP      │                 │
│ Level 1: 5009  ─┼───────────────►│ Port 5055 (WS)  │
│ Level 2: 9200  ─┼───────────────►│                 │
│ History: 9100  ─┼───────────────►│                 │
│ Admin:   9300   │                │                 │
└─────────────────┘                └─────────────────┘
```

## Windows Setup

### IQFeed Ports (bind to 127.0.0.1 only)
- **5009** - Level 1 (quotes, ticks)
- **9100** - Lookup/History
- **9200** - Level 2 (market depth/DOM)
- **9300** - Admin
- **9400** - Derivative

### Port Proxy (expose ports externally)

IQFeed binds to 127.0.0.1 only. Use netsh to expose externally:

```cmd
# Run as Administrator
netsh interface portproxy add v4tov4 listenport=15009 listenaddress=0.0.0.0 connectport=5009 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=19100 listenaddress=0.0.0.0 connectport=9100 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=19200 listenaddress=0.0.0.0 connectport=9200 connectaddress=127.0.0.1
```

Verify:
```cmd
netsh interface portproxy show all
```

### Firewall Rules

```cmd
netsh advfirewall firewall add rule name="IQFeed Level1" dir=in action=allow protocol=tcp localport=15009
netsh advfirewall firewall add rule name="IQFeed History" dir=in action=allow protocol=tcp localport=19100
netsh advfirewall firewall add rule name="IQFeed Level2" dir=in action=allow protocol=tcp localport=19200
```

### IQFeed Credentials

1. Account Number: 2633438
2. UserID: 525501
3. Password: (from DTN account portal)
4. Product ID: (register at https://www.iqfeed.net/dev/main.cfm)

### Registry Settings

Check settings:
```cmd
reg query "HKEY_CURRENT_USER\SOFTWARE\DTN\IQFeed\Startup"
```

Set Product ID:
```cmd
reg add "HKEY_CURRENT_USER\SOFTWARE\DTN\IQFeed\Startup" /v Product /t REG_SZ /d "YOUR_PRODUCT_ID" /f
reg add "HKEY_CURRENT_USER\SOFTWARE\DTN\IQFeed\Startup" /v Login /t REG_SZ /d "525501" /f
```

### Check IQFeed Status

```powershell
$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 9300)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.WriteLine("S,STATS")
$writer.Flush()
Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) { $reader.ReadLine() }
$client.Close()
```

Should show "Connected" (not "Not Connected").

### Verify Ports Listening

```cmd
netstat -an | findstr "5009 9100 9200 9300"
```

Expected output:
```
TCP    127.0.0.1:5009    LISTENING
TCP    127.0.0.1:9100    LISTENING  <-- This was missing!
TCP    127.0.0.1:9200    LISTENING
TCP    127.0.0.1:9300    LISTENING
```

## Linux Setup

### Configuration

File: `/var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed-bridge/src/main.rs`

```rust
const IQFEED_HOST: &str = "169.197.85.18";  // Windows IP
const IQFEED_LEVEL1_PORT: u16 = 15009;       // Proxied Level 1
const IQFEED_HISTORY_PORT: u16 = 19100;      // Proxied History
const IQFEED_DEPTH_PORT: u16 = 19200;        // Proxied Level 2
const WS_PORT: u16 = 5055;                    // WebSocket server
```

### Symbols Configured

- GC (Gold)
- SI (Silver)
- ES (E-mini S&P)
- NQ (E-mini Nasdaq)

### Build

```bash
cd /var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed-bridge
cargo build --release
```

### Systemd Service

File: `/etc/systemd/system/iqfeed-bridge.service`

```ini
[Unit]
Description=IQFeed Market Data Bridge (Rust)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed-bridge
ExecStart=/var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed-bridge/target/release/iqfeed-bridge
Restart=always
RestartSec=5
Environment=RUST_LOG=info
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Service Commands

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable iqfeed-bridge
sudo systemctl start iqfeed-bridge

# Check status
sudo systemctl status iqfeed-bridge

# View logs
sudo journalctl -u iqfeed-bridge -f

# Restart
sudo systemctl restart iqfeed-bridge
```

## WebSocket API

### Connect

```javascript
const ws = new WebSocket('ws://localhost:5055');
```

### Message Types (same as Databento bridge)

**Subscribe:**
```json
{"type": "subscribe", "symbol": "GC"}
```

**Get History:**
```json
{"type": "get_history", "symbol": "GC", "timeframe": "1m", "bars": 500}
```

**Ping:**
```json
{"type": "ping"}
```

### Server Messages

**Tick:**
```json
{"type": "tick", "symbol": "GC", "price": 2650.5, "size": 1, "timestamp": "..."}
```

**Candle:**
```json
{"type": "candle", "symbol": "GC", "timeframe": "1m", "data": {...}, "timestamp": "..."}
```

**Orderbook:**
```json
{"type": "orderbook", "symbol": "GC", "data": {"bids": [...], "asks": [...], "best_bid": 2650.4, "best_ask": 2650.6, "spread": 0.2}, "timestamp": "..."}
```

**Historical Candles:**
```json
{"type": "historical_candles", "symbol": "GC", "timeframe": "1m", "candles": [...], "count": 500}
```

## IQFeed Symbol Format

- `@GC#` - Gold continuous front month
- `@SI#` - Silver continuous
- `@ES#` - E-mini S&P continuous
- `@NQ#` - E-mini Nasdaq continuous

## Troubleshooting

### Port 9100 (History) Not Listening

This happens when IQFeed is "Not Connected" to DTN servers.

1. Check connection status via Admin port (see above)
2. Verify credentials and Product ID
3. Contact DTN support if needed

### "Not Connected" Status

IQFeed isn't authenticated. Check:
- Product ID is registered at iqfeed.net/dev
- Login credentials are correct
- Subscription is active

### Connection Reset by Peer

Usually means the port isn't listening on Windows side. Check:
```cmd
netstat -an | findstr "9100"
```

### Level 2 "SERVER DISCONNECTED"

Normal when markets are closed (weekends). CME Globex opens Sunday 5pm CT.

## Market Hours

CME Globex (GC, SI, ES, NQ):
- Opens: Sunday 5:00 PM CT
- Closes: Friday 4:00 PM CT
- Daily maintenance: 4:00 PM - 5:00 PM CT

## Files

- `/var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed-bridge/` - Bridge source
- `/etc/systemd/system/iqfeed-bridge.service` - Systemd service
- `/var/www/sites/clitools.app/wwwroot/orderflowtest/iqfeed_bridge.py` - Old Python bridge (not used)

## Dependencies

Cargo.toml:
```toml
tokio = { version = "1", features = ["full"] }
tokio-tungstenite = "0.21"
futures-util = "0.3"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
chrono = "0.4"
```
