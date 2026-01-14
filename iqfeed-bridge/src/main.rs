//! IQFeed Market Data Bridge - Rust Implementation
//!
//! Connects to IQFeed on Windows and streams data via WebSocket.
//! Uses same message format as Databento bridge for compatibility.

use chrono::{NaiveDateTime, Utc};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{broadcast, Mutex, RwLock};
use tokio_tungstenite::accept_async;
use tokio_tungstenite::tungstenite::Message;
use tracing::{error, info, warn};

// IQFeed Configuration - Windows machine with port proxy
const IQFEED_HOST: &str = "169.197.85.18";
const IQFEED_LEVEL1_PORT: u16 = 15009;  // Level 1 quotes (proxied)
const IQFEED_HISTORY_PORT: u16 = 19100; // Historical data (proxied)
const IQFEED_DEPTH_PORT: u16 = 19200;   // Level 2 market depth (proxied)

// WebSocket server config - same port as Databento dev bridge
const WS_HOST: &str = "0.0.0.0";
const WS_PORT: u16 = 9010;  // IQFeed bridge port

// Symbol mapping: IQFeed symbol -> Display name
fn get_symbol_map() -> HashMap<&'static str, &'static str> {
    let mut m = HashMap::new();
    m.insert("QGC#", "GC");      // E-micro Gold continuous (primary)
    // Uncomment below to add more symbols:
    // m.insert("QSI#", "SI");      // E-micro Silver continuous
    // m.insert("@ES#", "ES");      // E-mini S&P continuous
    // m.insert("@NQ#", "NQ");      // E-mini Nasdaq continuous
    m
}

fn get_display_to_iqfeed() -> HashMap<&'static str, &'static str> {
    let mut m = HashMap::new();
    m.insert("GC", "QGC#");
    // Uncomment below to add more symbols:
    // m.insert("SI", "QSI#");
    // m.insert("ES", "@ES#");
    // m.insert("NQ", "@NQ#");
    m
}

// For historical data, use the same IQFeed symbol as Level 1
fn get_history_symbol(display: &str) -> String {
    let map = get_display_to_iqfeed();
    map.get(display).map(|s| s.to_string()).unwrap_or_else(|| format!("@{}#", display))
}

// Message types - SAME as Databento bridge for compatibility
#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
enum ClientMessage {
    Subscribe { symbol: String },
    GetHistory { symbol: String, timeframe: String, bars: u32 },
    Ping,
}

#[derive(Serialize, Clone, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
enum ServerMessage {
    HistoricalCandles {
        symbol: String,
        timeframe: String,
        candles: Vec<Candle>,
        count: usize,
    },
    Candle {
        symbol: String,
        timeframe: String,
        data: Candle,
        timestamp: String,
    },
    Tick {
        symbol: String,
        price: f64,
        size: u32,
        bid: f64,
        ask: f64,
        timestamp: String,
    },
    Orderbook {
        symbol: String,
        data: OrderBookData,
        timestamp: String,
    },
    Status {
        connected: bool,
        symbols: Vec<String>,
        message: String,
    },
    Pong,
}

#[derive(Serialize, Deserialize, Clone, Debug, Default)]
struct OrderBookData {
    bids: Vec<[f64; 2]>,  // [price, size]
    asks: Vec<[f64; 2]>,  // [price, size]
    best_bid: f64,
    best_ask: f64,
    spread: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    cached: Option<bool>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
struct Candle {
    time: i64,  // milliseconds
    open: f64,
    high: f64,
    low: f64,
    close: f64,
    volume: u64,
}

// Live candle being built
#[derive(Clone, Debug)]
struct LiveCandle {
    time: i64,
    open: f64,
    high: f64,
    low: f64,
    close: f64,
    volume: u64,
}

impl LiveCandle {
    fn new(time: i64, price: f64, size: u64) -> Self {
        Self {
            time,
            open: price,
            high: price,
            low: price,
            close: price,
            volume: size,
        }
    }

    fn update(&mut self, price: f64, size: u64) {
        self.high = self.high.max(price);
        self.low = self.low.min(price);
        self.close = price;
        self.volume += size;
    }

    fn to_candle(&self) -> Candle {
        Candle {
            time: self.time,
            open: self.open,
            high: self.high,
            low: self.low,
            close: self.close,
            volume: self.volume,
        }
    }
}

struct AppState {
    broadcast_tx: broadcast::Sender<ServerMessage>,
    live_candles: RwLock<HashMap<(String, String), LiveCandle>>,
    order_books: RwLock<HashMap<String, OrderBookData>>,
    connected: RwLock<bool>,
}

impl AppState {
    fn new() -> Self {
        let (tx, _) = broadcast::channel(1000);
        Self {
            broadcast_tx: tx,
            live_candles: RwLock::new(HashMap::new()),
            order_books: RwLock::new(HashMap::new()),
            connected: RwLock::new(false),
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("info")
        .with_writer(std::io::stderr)
        .init();

    info!("==================================================");
    info!("IQFeed Market Data Bridge (Rust) Starting");
    info!("IQFeed host: {}:{}", IQFEED_HOST, IQFEED_LEVEL1_PORT);
    info!("WebSocket: ws://{}:{}", WS_HOST, WS_PORT);
    info!("==================================================");

    let state = Arc::new(AppState::new());

    // Start Level 1 connection to IQFeed
    let state_clone = state.clone();
    tokio::spawn(async move {
        loop {
            match run_iqfeed_client(state_clone.clone()).await {
                Ok(_) => info!("IQFeed client exited normally"),
                Err(e) => error!("IQFeed client error: {}", e),
            }
            *state_clone.connected.write().await = false;
            warn!("IQFeed disconnected, reconnecting in 5s...");
            tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
        }
    });

    // Level 2 / Market Depth - Re-enabled for MBO big orders
    let state_clone = state.clone();
    tokio::spawn(async move {
        loop {
            match run_level2_client(state_clone.clone()).await {
                Ok(_) => info!("IQFeed Level 2 client exited normally"),
                Err(e) => error!("IQFeed Level 2 client error: {}", e),
            }
            warn!("IQFeed Level 2 disconnected, reconnecting in 5s...");
            tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
        }
    });

    // Start WebSocket server
    let listener = TcpListener::bind(format!("{}:{}", WS_HOST, WS_PORT))
        .await
        .expect("Failed to bind WebSocket server");

    info!("WebSocket server listening on ws://{}:{}", WS_HOST, WS_PORT);

    while let Ok((stream, addr)) = listener.accept().await {
        info!("Client connected from {}", addr);
        let state_clone = state.clone();
        tokio::spawn(handle_websocket(stream, state_clone, addr));
    }
}

async fn run_iqfeed_client(state: Arc<AppState>) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let addr = format!("{}:{}", IQFEED_HOST, IQFEED_LEVEL1_PORT);
    info!("Connecting to IQFeed Level 1 at {}", addr);

    let stream = TcpStream::connect(&addr).await?;
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Set protocol
    writer.write_all(b"S,SET PROTOCOL,6.2\r\n").await?;
    info!("Connected to IQFeed Level 1");

    *state.connected.write().await = true;

    // Broadcast connected status
    let _ = state.broadcast_tx.send(ServerMessage::Status {
        connected: true,
        symbols: vec!["GC".to_string(), "SI".to_string(), "ES".to_string(), "NQ".to_string()],
        message: "Connected to IQFeed".to_string(),
    });

    // Subscribe to symbols
    let display_to_iqfeed = get_display_to_iqfeed();
    for (_display, iqfeed) in &display_to_iqfeed {
        writer.write_all(format!("w{}\r\n", iqfeed).as_bytes()).await?;
        info!("Subscribed to {}", iqfeed);
    }

    let symbol_map = get_symbol_map();
    let mut line = String::new();

    loop {
        line.clear();
        let n = reader.read_line(&mut line).await?;
        if n == 0 {
            return Err("Connection closed".into());
        }

        let line_trimmed = line.trim();
        if line_trimmed.is_empty() {
            continue;
        }

        // Log first few messages of each type for debugging
        static MSG_COUNTS: std::sync::LazyLock<std::sync::Mutex<std::collections::HashMap<String, u32>>> =
            std::sync::LazyLock::new(|| std::sync::Mutex::new(std::collections::HashMap::new()));

        let msg_type = line_trimmed.chars().next().unwrap_or('?').to_string();
        {
            let mut counts = MSG_COUNTS.lock().unwrap();
            let count = counts.entry(msg_type.clone()).or_insert(0);
            *count += 1;
            if *count <= 3 {
                info!("Level1 raw (type {}): {}", msg_type, &line_trimmed[..std::cmp::min(100, line_trimmed.len())]);
            }
        }

        // Parse Level 1 update
        // Format: Q,SYMBOL,LAST,LAST_SIZE,LAST_TIME,MARKET_CENTER,VOLUME,BID,BID_SIZE,ASK,ASK_SIZE,OPEN,HIGH,LOW,CLOSE,...
        let parts: Vec<&str> = line_trimmed.split(',').collect();
        if parts.len() < 10 || parts[0] != "Q" {
            continue;
        }

        let iqfeed_symbol = parts[1];
        let display_symbol = match symbol_map.get(iqfeed_symbol) {
            Some(s) => *s,
            None => continue,
        };

        let last_price: f64 = match parts[2].parse() {
            Ok(p) if p > 0.0 => p,
            _ => continue,
        };

        // Q message format: Q,SYMBOL,LAST,SIZE,TIME,MKT_CTR,VOLUME,BID,BID_SIZE,ASK,ASK_SIZE,...
        let size: u32 = parts[3].parse().unwrap_or(1);
        let last_trade_time = parts[4];
        let bid: f64 = parts.get(7).and_then(|s| s.parse().ok()).unwrap_or(0.0);
        let ask: f64 = parts.get(9).and_then(|s| s.parse().ok()).unwrap_or(0.0);

        // Track last trade time to detect actual new trades
        // Q messages are sent on any quote change (bid/ask), not just trades
        static LAST_TRADE_TIMES: std::sync::LazyLock<std::sync::Mutex<std::collections::HashMap<String, String>>> =
            std::sync::LazyLock::new(|| std::sync::Mutex::new(std::collections::HashMap::new()));

        let is_new_trade = {
            let mut times = LAST_TRADE_TIMES.lock().unwrap();
            let prev = times.get(iqfeed_symbol).cloned();
            if prev.as_deref() != Some(last_trade_time) {
                times.insert(iqfeed_symbol.to_string(), last_trade_time.to_string());
                true
            } else {
                false
            }
        };

        // Only count as trade if the trade time changed
        if !is_new_trade {
            continue;  // Skip quote-only updates
        }

        let now = Utc::now();

        // Broadcast tick with bid/ask for delta classification
        let tick_msg = ServerMessage::Tick {
            symbol: display_symbol.to_string(),
            price: last_price,
            size,
            bid,
            ask,
            timestamp: now.to_rfc3339(),
        };

        // Log tick broadcasts for debugging
        static TICK_COUNT: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
        let tick_num = TICK_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        if tick_num < 5 || tick_num % 100 == 0 {
            info!("Broadcasting tick #{}: {} @ {} size {} bid={} ask={}", tick_num + 1, display_symbol, last_price, size, bid, ask);
        }

        let _ = state.broadcast_tx.send(tick_msg);

        // Update live candles for common timeframes
        let trade_time_ms = now.timestamp_millis();

        for tf in &["1m", "5m", "15m", "1h"] {
            let tf_ms: i64 = match *tf {
                "1m" => 60_000,
                "5m" => 300_000,
                "15m" => 900_000,
                "1h" => 3_600_000,
                _ => 60_000,
            };

            let candle_time = (trade_time_ms / tf_ms) * tf_ms;
            let key = (display_symbol.to_string(), tf.to_string());

            let mut candles = state.live_candles.write().await;

            if let Some(candle) = candles.get_mut(&key) {
                if candle.time == candle_time {
                    // Update existing candle
                    candle.update(last_price, size as u64);
                } else {
                    // New candle period - broadcast completed candle
                    let completed = ServerMessage::Candle {
                        symbol: display_symbol.to_string(),
                        timeframe: tf.to_string(),
                        data: candle.to_candle(),
                        timestamp: now.to_rfc3339(),
                    };
                    let _ = state.broadcast_tx.send(completed);

                    // Start new candle
                    *candle = LiveCandle::new(candle_time, last_price, size as u64);
                }
            } else {
                // First trade for this symbol/timeframe
                candles.insert(key.clone(), LiveCandle::new(candle_time, last_price, size as u64));
            }

            // Broadcast live candle update
            if let Some(candle) = candles.get(&key) {
                let msg = ServerMessage::Candle {
                    symbol: display_symbol.to_string(),
                    timeframe: tf.to_string(),
                    data: candle.to_candle(),
                    timestamp: now.to_rfc3339(),
                };
                let _ = state.broadcast_tx.send(msg);
            }
        }
    }
}

async fn handle_websocket(stream: TcpStream, state: Arc<AppState>, addr: std::net::SocketAddr) {
    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            error!("WebSocket handshake failed: {}", e);
            return;
        }
    };

    let (ws_sender, mut ws_receiver) = ws_stream.split();
    let ws_sender = Arc::new(Mutex::new(ws_sender));
    let mut broadcast_rx = state.broadcast_tx.subscribe();

    // Send initial status
    {
        let connected = *state.connected.read().await;
        let status = ServerMessage::Status {
            connected,
            symbols: vec!["GC".to_string(), "SI".to_string(), "ES".to_string(), "NQ".to_string()],
            message: if connected { "Connected to IQFeed".to_string() } else { "Connecting to IQFeed...".to_string() },
        };
        if let Ok(json) = serde_json::to_string(&status) {
            let mut sender = ws_sender.lock().await;
            let _ = sender.send(Message::Text(json)).await;
        }
    }

    // Spawn task to forward broadcasts
    let ws_sender_clone = ws_sender.clone();
    let forward_task = tokio::spawn(async move {
        while let Ok(msg) = broadcast_rx.recv().await {
            if let Ok(json) = serde_json::to_string(&msg) {
                let mut sender = ws_sender_clone.lock().await;
                if sender.send(Message::Text(json)).await.is_err() {
                    break;
                }
            }
        }
    });

    // Handle incoming messages
    while let Some(msg) = ws_receiver.next().await {
        match msg {
            Ok(Message::Text(text)) => {
                if let Ok(client_msg) = serde_json::from_str::<ClientMessage>(&text) {
                    handle_client_message(&state, &ws_sender, client_msg).await;
                }
            }
            Ok(Message::Close(_)) => break,
            Err(e) => {
                error!("WebSocket error: {}", e);
                break;
            }
            _ => {}
        }
    }

    forward_task.abort();
    info!("Client disconnected: {}", addr);
}

async fn handle_client_message(
    _state: &Arc<AppState>,
    ws_sender: &Arc<Mutex<futures_util::stream::SplitSink<
        tokio_tungstenite::WebSocketStream<TcpStream>,
        Message,
    >>>,
    msg: ClientMessage,
) {
    match msg {
        ClientMessage::Ping => {
            let response = serde_json::to_string(&ServerMessage::Pong).unwrap();
            let mut sender = ws_sender.lock().await;
            let _ = sender.send(Message::Text(response)).await;
        }
        ClientMessage::Subscribe { symbol } => {
            info!("Client subscribed to {}", symbol);
        }
        ClientMessage::GetHistory { symbol, timeframe, bars } => {
            info!("Client requested history: {} {} {} bars", symbol, timeframe, bars);

            // Fetch from IQFeed History port
            let candles = fetch_historical_candles(&symbol, &timeframe, bars).await;
            let count = candles.len();

            let response = ServerMessage::HistoricalCandles {
                symbol,
                timeframe,
                candles,
                count,
            };

            if let Ok(json) = serde_json::to_string(&response) {
                info!("Sending {} historical candles", count);
                let mut sender = ws_sender.lock().await;
                let _ = sender.send(Message::Text(json)).await;
            }
        }
    }
}

async fn fetch_historical_candles(symbol: &str, timeframe: &str, bars: u32) -> Vec<Candle> {
    // Use history-specific symbol format
    let iqfeed_symbol = get_history_symbol(symbol);

    // Map timeframe to IQFeed interval (seconds)
    let interval: u32 = match timeframe {
        "1m" => 60,
        "5m" => 300,
        "15m" => 900,
        "1h" => 3600,
        "4h" => 14400,
        "1d" => 86400,
        _ => 60,
    };

    let addr = format!("{}:{}", IQFEED_HOST, IQFEED_HISTORY_PORT);

    info!("Connecting to IQFeed History at {}", addr);
    let stream = match TcpStream::connect(&addr).await {
        Ok(s) => {
            info!("Connected to IQFeed History");
            s
        },
        Err(e) => {
            error!("Failed to connect to IQFeed History: {}", e);
            return Vec::new();
        }
    };

    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Wait a bit for connection to stabilize
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

    // Read any initial message from IQFeed
    let mut buf = String::new();
    if let Ok(Ok(_)) = tokio::time::timeout(
        tokio::time::Duration::from_millis(500),
        reader.read_line(&mut buf)
    ).await {
        info!("History initial: {}", buf.trim());
    }

    // Set protocol
    if let Err(e) = writer.write_all(b"S,SET PROTOCOL,6.2\r\n").await {
        error!("Failed to set protocol: {}", e);
        return Vec::new();
    }
    let _ = writer.flush().await;

    // Wait for protocol response
    buf.clear();
    if let Ok(Ok(_)) = tokio::time::timeout(
        tokio::time::Duration::from_millis(500),
        reader.read_line(&mut buf)
    ).await {
        info!("History protocol response: {}", buf.trim());
    }

    // Request: HIX,SYMBOL,INTERVAL,BARS,DATAPOINTS_PER_SEND,DIRECTION
    // Direction: 1 = oldest to newest
    let request = format!("HIX,{},{},{},,1\r\n", &iqfeed_symbol, interval, bars);
    info!("Sending history request: {} (symbol: {})", request.trim(), &iqfeed_symbol);

    if let Err(e) = writer.write_all(request.as_bytes()).await {
        error!("Failed to send history request: {}", e);
        return Vec::new();
    }
    let _ = writer.flush().await;
    info!("History request sent, waiting for data...");

    let mut candles = Vec::new();
    let mut line = String::new();

    let mut line_count = 0;
    loop {
        line.clear();
        match tokio::time::timeout(
            tokio::time::Duration::from_secs(30),
            reader.read_line(&mut line)
        ).await {
            Ok(Ok(0)) => {
                info!("History: connection closed after {} lines", line_count);
                break;
            }
            Err(_) => {
                info!("History: timeout after {} lines", line_count);
                break;
            }
            Ok(Err(e)) => {
                error!("History: read error: {}", e);
                break;
            }
            Ok(Ok(_)) => {
                line_count += 1;
            }
        }

        let line_trimmed = line.trim();

        // Log first few lines for debugging
        if candles.len() < 3 {
            info!("History line: {}", line_trimmed);
        }

        if line_trimmed.contains("!ENDMSG!") {
            info!("End of history data");
            break;
        }

        if line_trimmed.contains(",E,") || line_trimmed.starts_with("E,") {
            error!("History error: {}", line_trimmed);
            break;
        }

        if line_trimmed.is_empty() || line_trimmed.starts_with("S,") {
            continue;
        }

        // Parse candle: RequestID,LH,TIMESTAMP,HIGH,LOW,OPEN,CLOSE,CumulativeVolume,PeriodVolume,NumTrades
        // Format: 1,LH,2026-01-12 10:11:00,4627.6,4625.7,4626.4,4626.4,177511,185,0,
        // Index:  0  1  2                  3      4      5      6      7      8   9
        let parts: Vec<&str> = line_trimmed.split(',').collect();
        if parts.len() >= 9 && parts[1] == "LH" {
            // Parse timestamp: "YYYY-MM-DD HH:MM:SS" (index 2)
            // IQFeed timestamps are in Eastern Time (EST/EDT)
            // EST = UTC-5, EDT = UTC-4
            // We add 5 hours (EST offset) to convert to UTC
            // This may be off by 1 hour during DST but is close enough for candle matching
            if let Ok(dt) = NaiveDateTime::parse_from_str(parts[2], "%Y-%m-%d %H:%M:%S") {
                let est_offset_seconds: i64 = 5 * 60 * 60; // 5 hours in seconds
                let timestamp_ms = (dt.and_utc().timestamp() + est_offset_seconds) * 1000;

                if let (Ok(high), Ok(low), Ok(open), Ok(close)) = (
                    parts[3].parse::<f64>(),
                    parts[4].parse::<f64>(),
                    parts[5].parse::<f64>(),
                    parts[6].parse::<f64>(),
                ) {
                    // Use index 8 for period volume (not index 7 which is cumulative)
                    let volume: u64 = parts[8].parse().unwrap_or(0);

                    candles.push(Candle {
                        time: timestamp_ms,
                        open,
                        high,
                        low,
                        close,
                        volume,
                    });
                }
            }
        }
    }

    info!("Retrieved {} historical candles for {} {}", candles.len(), symbol, timeframe);
    candles
}

/// Level 2 / Market Depth client - connects to IQFeed depth port
async fn run_level2_client(state: Arc<AppState>) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let addr = format!("{}:{}", IQFEED_HOST, IQFEED_DEPTH_PORT);
    info!("Connecting to IQFeed Level 2 (Market Depth) at {}", addr);

    let stream = TcpStream::connect(&addr).await?;
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Set protocol
    writer.write_all(b"S,SET PROTOCOL,6.2\r\n").await?;
    writer.flush().await?;
    info!("Connected to IQFeed Level 2");

    // Wait for protocol response
    tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;

    // Subscribe to market depth for our symbols
    // IQFeed Level 2 uses "WOR,SYMBOL" command for Watch Order Book
    let display_to_iqfeed = get_display_to_iqfeed();
    for (_display, iqfeed) in &display_to_iqfeed {
        // Watch Order command for Level 2 depth
        let cmd = format!("WOR,{}\r\n", iqfeed);
        writer.write_all(cmd.as_bytes()).await?;
        writer.flush().await?;
        info!("Level 2: Sent WOR for {}", iqfeed);
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }

    let symbol_map = get_symbol_map();
    let mut line = String::new();

    // Maintain order book state per symbol
    let mut order_books: HashMap<String, OrderBookState> = HashMap::new();

    loop {
        line.clear();
        let n = reader.read_line(&mut line).await?;
        if n == 0 {
            return Err("Level 2 connection closed".into());
        }

        let line_trimmed = line.trim();
        if line_trimmed.is_empty() {
            continue;
        }

        // Parse Level 2 messages
        // Format varies by message type:
        // Z,Symbol,MessageType,... - Market Depth messages
        let parts: Vec<&str> = line_trimmed.split(',').collect();
        if parts.is_empty() {
            continue;
        }

        match parts[0] {
            // Order-based depth updates from WOR command
            // Format: 6,SYMBOL,ORDER_ID,,SIDE,PRICE,SIZE,...
            "3" | "4" | "5" | "6" => {
                // 3 = Add order, 4 = Update order, 5 = Delete order, 6 = Summary
                if parts.len() >= 7 {
                    let iqfeed_symbol = parts[1];
                    let display_symbol = match symbol_map.get(iqfeed_symbol) {
                        Some(s) => *s,
                        None => continue,
                    };

                    let side = parts[4];  // "B" = bid, "A" = ask (index 4 after WOR format)
                    let price: f64 = match parts[5].parse() {
                        Ok(p) => p,
                        Err(_) => continue,
                    };
                    let size: u32 = parts[6].parse().unwrap_or(0);
                    let msg_type = parts[0];

                    let book = order_books
                        .entry(display_symbol.to_string())
                        .or_insert_with(OrderBookState::new);

                    // Debug: log first few parsed orders
                    static DEBUG_COUNT: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
                    let count = DEBUG_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                    if count < 20 {
                        info!("L2 Parse: side={} price={} size={} -> {}",
                            side, price, size, if side == "B" { "BID" } else { "ASK" });
                    }

                    match msg_type {
                        "3" | "4" | "6" => {
                            // Add, update, or snapshot order
                            // B = Bid (buy orders), A = Ask (sell orders)
                            if side == "B" {
                                book.update_bid(price, size);
                            } else if side == "A" {
                                book.update_ask(price, size);
                            }
                        }
                        "5" => {
                            // Delete order
                            if side == "B" {
                                book.remove_bid(price);
                            } else if side == "A" {
                                book.remove_ask(price);
                            }
                        }
                        _ => {}
                    }

                    // Broadcast updated order book
                    let order_book_data = book.to_order_book_data();

                    // Store in app state
                    {
                        let mut books = state.order_books.write().await;
                        books.insert(display_symbol.to_string(), order_book_data.clone());
                    }

                    let msg = ServerMessage::Orderbook {
                        symbol: display_symbol.to_string(),
                        data: order_book_data,
                        timestamp: Utc::now().to_rfc3339(),
                    };
                    let _ = state.broadcast_tx.send(msg);
                }
            }
            // Price-level based depth (alternative format) - SKIP
            // Z messages interfere with proper MBO orderbook
            "Z" => {
                // Skip Z messages entirely
            }
            "S" => {
                // System message
                info!("Level 2 system: {}", line_trimmed);
            }
            "E" => {
                // Error
                warn!("Level 2 error: {}", line_trimmed);
            }
            _ => {
                // Log unknown messages for debugging
                if !line_trimmed.starts_with("T,") {  // Skip timestamp messages
                    info!("Level 2 msg: {}", line_trimmed);
                }
            }
        }
    }
}

/// Internal state for building order book
struct OrderBookState {
    bids: HashMap<i64, u32>,  // price (as int cents) -> size
    asks: HashMap<i64, u32>,
}

impl OrderBookState {
    fn new() -> Self {
        Self {
            bids: HashMap::new(),
            asks: HashMap::new(),
        }
    }

    fn price_to_key(price: f64) -> i64 {
        (price * 100.0).round() as i64  // Store as cents
    }

    fn key_to_price(key: i64) -> f64 {
        key as f64 / 100.0
    }

    fn update_bid(&mut self, price: f64, size: u32) {
        let key = Self::price_to_key(price);
        if size > 0 {
            // Aggregate sizes at each price level
            *self.bids.entry(key).or_insert(0) += size;
        } else {
            self.bids.remove(&key);
        }
    }

    fn update_ask(&mut self, price: f64, size: u32) {
        let key = Self::price_to_key(price);
        if size > 0 {
            // Aggregate sizes at each price level
            *self.asks.entry(key).or_insert(0) += size;
        } else {
            self.asks.remove(&key);
        }
    }

    fn remove_bid(&mut self, price: f64) {
        let key = Self::price_to_key(price);
        self.bids.remove(&key);
    }

    fn remove_ask(&mut self, price: f64) {
        let key = Self::price_to_key(price);
        self.asks.remove(&key);
    }

    fn to_order_book_data(&self) -> OrderBookData {
        // Sort bids descending (highest first)
        let mut bids: Vec<[f64; 2]> = self.bids
            .iter()
            .map(|(&k, &v)| [Self::key_to_price(k), v as f64])
            .collect();
        bids.sort_by(|a, b| b[0].partial_cmp(&a[0]).unwrap());

        // Sort asks ascending (lowest first)
        let mut asks: Vec<[f64; 2]> = self.asks
            .iter()
            .map(|(&k, &v)| [Self::key_to_price(k), v as f64])
            .collect();
        asks.sort_by(|a, b| a[0].partial_cmp(&b[0]).unwrap());

        // Limit to top 10 levels each side
        bids.truncate(10);
        asks.truncate(10);

        let best_bid = bids.first().map(|b| b[0]).unwrap_or(0.0);
        let best_ask = asks.first().map(|a| a[0]).unwrap_or(0.0);
        let spread = if best_bid > 0.0 && best_ask > 0.0 {
            best_ask - best_bid
        } else {
            0.0
        };

        OrderBookData {
            bids,
            asks,
            best_bid,
            best_ask,
            spread,
            cached: None,
        }
    }
}
