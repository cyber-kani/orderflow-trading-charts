-- ============================================
-- OrderFlowTest Database Schema
-- Delta Data and Big Orders Storage
-- Database: orderflow_signals (MSSQL)
-- ============================================

-- ============================================
-- TABLE: delta_data
-- Stores delta statistics per candle per timeframe
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'delta_data')
BEGIN
    CREATE TABLE delta_data (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        symbol VARCHAR(20) NOT NULL,                    -- GC, SI, CL, ES, NQ
        timeframe VARCHAR(10) NOT NULL,                 -- 1m, 5m, 15m, 1h, 4h, 1d
        candle_time BIGINT NOT NULL,                    -- Unix timestamp (seconds) of candle start

        -- Delta statistics
        delta INT NOT NULL DEFAULT 0,                   -- Net delta (buyVolume - sellVolume)
        max_delta INT NOT NULL DEFAULT 0,               -- Highest delta reached in candle
        min_delta INT NOT NULL DEFAULT 0,               -- Lowest delta reached in candle

        -- Volume breakdown
        volume INT NOT NULL DEFAULT 0,                  -- Total volume
        buy_volume INT NOT NULL DEFAULT 0,              -- Total buy volume
        sell_volume INT NOT NULL DEFAULT 0,             -- Total sell volume

        -- OHLC snapshot at delta calculation
        candle_open DECIMAL(18,4) NULL,
        candle_high DECIMAL(18,4) NULL,
        candle_low DECIMAL(18,4) NULL,
        candle_close DECIMAL(18,4) NULL,

        -- Metadata
        is_estimated BIT NOT NULL DEFAULT 0,            -- True if aggregated from smaller timeframe
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),

        -- Unique constraint: one record per symbol/timeframe/candle
        CONSTRAINT UQ_delta_data_candle UNIQUE (symbol, timeframe, candle_time)
    );

    -- Indexes for common queries
    CREATE INDEX IX_delta_data_symbol_tf ON delta_data (symbol, timeframe);
    CREATE INDEX IX_delta_data_candle_time ON delta_data (candle_time DESC);
    CREATE INDEX IX_delta_data_lookup ON delta_data (symbol, timeframe, candle_time DESC);
END
GO

-- ============================================
-- TABLE: big_orders
-- Stores individual big order events
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'big_orders')
BEGIN
    CREATE TABLE big_orders (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        symbol VARCHAR(20) NOT NULL,                    -- GC, SI, CL, ES, NQ
        timeframe VARCHAR(10) NOT NULL,                 -- Timeframe when detected
        candle_time BIGINT NOT NULL,                    -- Unix timestamp of candle containing order

        -- Order details
        price DECIMAL(18,4) NOT NULL,                   -- Price level where order occurred
        size INT NOT NULL,                              -- Cumulative size at price level
        side VARCHAR(4) NOT NULL,                       -- 'BUY' or 'SELL'

        -- Metadata
        detected_at DATETIME2 NOT NULL DEFAULT GETDATE(),

        -- Index for deduplication (prevent duplicate entries)
        CONSTRAINT UQ_big_orders_unique UNIQUE (symbol, timeframe, candle_time, price, side)
    );

    -- Indexes for common queries
    CREATE INDEX IX_big_orders_symbol_tf ON big_orders (symbol, timeframe);
    CREATE INDEX IX_big_orders_candle_time ON big_orders (candle_time DESC);
    CREATE INDEX IX_big_orders_lookup ON big_orders (symbol, timeframe, candle_time DESC);
    CREATE INDEX IX_big_orders_price ON big_orders (symbol, price);
END
GO

-- ============================================
-- TABLE: delta_aggregates
-- Pre-computed aggregates for faster dashboard queries
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'delta_aggregates')
BEGIN
    CREATE TABLE delta_aggregates (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        symbol VARCHAR(20) NOT NULL,
        timeframe VARCHAR(10) NOT NULL,
        period_type VARCHAR(20) NOT NULL,               -- 'hourly', 'daily', 'weekly'
        period_start BIGINT NOT NULL,                   -- Unix timestamp of period start

        -- Aggregated stats
        total_delta INT NOT NULL DEFAULT 0,             -- Sum of deltas in period
        total_volume INT NOT NULL DEFAULT 0,            -- Sum of volume in period
        total_buy_volume INT NOT NULL DEFAULT 0,
        total_sell_volume INT NOT NULL DEFAULT 0,
        max_delta INT NOT NULL DEFAULT 0,               -- Max delta seen in period
        min_delta INT NOT NULL DEFAULT 0,               -- Min delta seen in period
        candle_count INT NOT NULL DEFAULT 0,            -- Number of candles in period

        -- Big order counts
        big_buy_count INT NOT NULL DEFAULT 0,
        big_sell_count INT NOT NULL DEFAULT 0,
        big_buy_volume INT NOT NULL DEFAULT 0,
        big_sell_volume INT NOT NULL DEFAULT 0,

        -- Metadata
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),

        CONSTRAINT UQ_delta_aggregates UNIQUE (symbol, timeframe, period_type, period_start)
    );

    CREATE INDEX IX_delta_aggregates_lookup ON delta_aggregates (symbol, timeframe, period_type, period_start DESC);
END
GO

-- ============================================
-- STORED PROCEDURE: usp_upsert_delta_data
-- Insert or update delta data for a candle
-- ============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_upsert_delta_data')
    DROP PROCEDURE usp_upsert_delta_data
GO

CREATE PROCEDURE usp_upsert_delta_data
    @symbol VARCHAR(20),
    @timeframe VARCHAR(10),
    @candle_time BIGINT,
    @delta INT,
    @max_delta INT,
    @min_delta INT,
    @volume INT,
    @buy_volume INT,
    @sell_volume INT,
    @candle_open DECIMAL(18,4) = NULL,
    @candle_high DECIMAL(18,4) = NULL,
    @candle_low DECIMAL(18,4) = NULL,
    @candle_close DECIMAL(18,4) = NULL,
    @is_estimated BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    MERGE delta_data AS target
    USING (SELECT @symbol AS symbol, @timeframe AS timeframe, @candle_time AS candle_time) AS source
    ON (target.symbol = source.symbol AND target.timeframe = source.timeframe AND target.candle_time = source.candle_time)
    WHEN MATCHED THEN
        UPDATE SET
            delta = @delta,
            max_delta = @max_delta,
            min_delta = @min_delta,
            volume = @volume,
            buy_volume = @buy_volume,
            sell_volume = @sell_volume,
            candle_open = ISNULL(@candle_open, target.candle_open),
            candle_high = ISNULL(@candle_high, target.candle_high),
            candle_low = ISNULL(@candle_low, target.candle_low),
            candle_close = ISNULL(@candle_close, target.candle_close),
            is_estimated = @is_estimated,
            updated_at = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (symbol, timeframe, candle_time, delta, max_delta, min_delta, volume, buy_volume, sell_volume,
                candle_open, candle_high, candle_low, candle_close, is_estimated, created_at, updated_at)
        VALUES (@symbol, @timeframe, @candle_time, @delta, @max_delta, @min_delta, @volume, @buy_volume, @sell_volume,
                @candle_open, @candle_high, @candle_low, @candle_close, @is_estimated, GETDATE(), GETDATE());
END
GO

-- ============================================
-- STORED PROCEDURE: usp_upsert_big_order
-- Insert big order (ignore if exists)
-- ============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_upsert_big_order')
    DROP PROCEDURE usp_upsert_big_order
GO

CREATE PROCEDURE usp_upsert_big_order
    @symbol VARCHAR(20),
    @timeframe VARCHAR(10),
    @candle_time BIGINT,
    @price DECIMAL(18,4),
    @size INT,
    @side VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert only if not exists (prevent duplicates)
    IF NOT EXISTS (
        SELECT 1 FROM big_orders
        WHERE symbol = @symbol AND timeframe = @timeframe AND candle_time = @candle_time
          AND price = @price AND side = @side
    )
    BEGIN
        INSERT INTO big_orders (symbol, timeframe, candle_time, price, size, side, detected_at)
        VALUES (@symbol, @timeframe, @candle_time, @price, @size, @side, GETDATE());
    END
    ELSE
    BEGIN
        -- Update size if order already exists and new size is larger
        UPDATE big_orders
        SET size = @size
        WHERE symbol = @symbol AND timeframe = @timeframe AND candle_time = @candle_time
          AND price = @price AND side = @side AND size < @size;
    END
END
GO

-- ============================================
-- STORED PROCEDURE: usp_get_delta_data
-- Get delta data for a symbol/timeframe with optional time range
-- ============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_get_delta_data')
    DROP PROCEDURE usp_get_delta_data
GO

CREATE PROCEDURE usp_get_delta_data
    @symbol VARCHAR(20),
    @timeframe VARCHAR(10),
    @start_time BIGINT = NULL,
    @end_time BIGINT = NULL,
    @limit INT = 1000
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@limit)
        candle_time,
        delta,
        max_delta AS maxDelta,
        min_delta AS minDelta,
        volume,
        buy_volume AS buyVolume,
        sell_volume AS sellVolume,
        candle_open,
        candle_high,
        candle_low,
        candle_close,
        is_estimated AS estimated
    FROM delta_data
    WHERE symbol = @symbol
      AND timeframe = @timeframe
      AND (@start_time IS NULL OR candle_time >= @start_time)
      AND (@end_time IS NULL OR candle_time <= @end_time)
    ORDER BY candle_time DESC;
END
GO

-- ============================================
-- STORED PROCEDURE: usp_get_big_orders
-- Get big orders for a symbol/timeframe with optional time range
-- ============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_get_big_orders')
    DROP PROCEDURE usp_get_big_orders
GO

CREATE PROCEDURE usp_get_big_orders
    @symbol VARCHAR(20),
    @timeframe VARCHAR(10),
    @start_time BIGINT = NULL,
    @end_time BIGINT = NULL,
    @limit INT = 500
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@limit)
        candle_time AS time,
        price,
        size,
        side
    FROM big_orders
    WHERE symbol = @symbol
      AND timeframe = @timeframe
      AND (@start_time IS NULL OR candle_time >= @start_time)
      AND (@end_time IS NULL OR candle_time <= @end_time)
    ORDER BY candle_time DESC;
END
GO

-- ============================================
-- STORED PROCEDURE: usp_cleanup_old_data
-- Remove data older than specified days
-- ============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_cleanup_old_data')
    DROP PROCEDURE usp_cleanup_old_data
GO

CREATE PROCEDURE usp_cleanup_old_data
    @days_to_keep INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cutoff_time BIGINT;
    SET @cutoff_time = DATEDIFF(SECOND, '1970-01-01', DATEADD(DAY, -@days_to_keep, GETDATE()));

    -- Delete old delta data
    DELETE FROM delta_data WHERE candle_time < @cutoff_time;

    -- Delete old big orders
    DELETE FROM big_orders WHERE candle_time < @cutoff_time;

    -- Return counts
    SELECT @@ROWCOUNT AS deleted_count;
END
GO

PRINT 'Schema created successfully!';
