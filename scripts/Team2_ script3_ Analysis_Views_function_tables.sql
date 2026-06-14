/* =========================================================================================
   SCRIPT 3 - PORTFOLIO ANALYSIS
   Client:   Jim Simons - Renaissance Technologies
   Schema:   renaissance_team2
   Team:     Team 2 - Hult MBA
   Date:     June 2026

   In this script we build all the analysis on top of the data we loaded in scripts 1 and 2.
   We calculate return, risk and Sharpe Ratio for each stock in Jim Simons portfolio
   and we compare the current portfolio weights against the optimal weights.
   We also compare the portfolio against SPY as a market benchmark.
   We do this analysis across 6 time periods: 1YR, 2YR, 3YR, 4YR, 5YR and ALL.

   What we create in this script:
   1. vw_last_price         -- view: most recent price per stock
   2. fct_daily_ror         -- table: daily returns pre-calculated for performance
   3. fn_period_start_date  -- function: returns start date for each time period
   4. rpt_stats             -- table: return, risk and Sharpe per stock per period
   5. rpt_portfolio_summary -- table: overall portfolio metrics per period
   6. rpt_stock_detail      -- table: full stock detail per period with weights
========================================================================================= */

USE renaissance_team2;


/* -----------------------------------------------------------------------------------------
   STEP 1: vw_last_price

   We created this view to get the most recent price for each stock.
   We use a view and not a function because we need one row per stock.
   A function in MySQL can only return one single value.
   last_date is the MAX date we have in fct_pricing_daily, not today.
----------------------------------------------------------------------------------------- */
DROP VIEW IF EXISTS renaissance_team2.vw_last_price;

CREATE VIEW renaissance_team2.vw_last_price AS
SELECT
    p.ticker,
    p.date  AS last_date,  -- last date we have price data for this stock
    p.value AS last_price  -- adjusted closing price on that date
FROM renaissance_team2.fct_pricing_daily p
INNER JOIN (
    SELECT ticker, MAX(date) AS max_date
    FROM renaissance_team2.fct_pricing_daily
    GROUP BY ticker
) max_dates
    ON p.ticker = max_dates.ticker
    AND p.date  = max_dates.max_date;


/* -----------------------------------------------------------------------------------------
   STEP 2: fct_daily_ror

   We store the daily returns in a physical table for performance.
   Formula: ror = (today price / yesterday price) - 1
   We use LAG to get yesterday price for each stock.
   The first row per stock always has NULL for ror because there is no previous row.
   We add two indexes to make the period queries faster.
----------------------------------------------------------------------------------------- */
DROP TABLE IF EXISTS renaissance_team2.fct_daily_ror;

CREATE TABLE renaissance_team2.fct_daily_ror (
    ticker  VARCHAR(10)    NOT NULL,
    date    DATE           NOT NULL,
    value   DECIMAL(12,6)  NOT NULL,
    p0      DECIMAL(12,6),           -- previous day price from LAG
    ror     DECIMAL(18,10),          -- daily return, NULL on first row per stock
    PRIMARY KEY (ticker, date)
);

INSERT INTO renaissance_team2.fct_daily_ror (ticker, date, value, p0, ror)
SELECT
    a.ticker,
    a.date,
    a.value,
    LAG(a.value, 1) OVER(PARTITION BY a.ticker ORDER BY a.date ASC) AS p0,
    (a.value / LAG(a.value, 1) OVER(PARTITION BY a.ticker ORDER BY a.date ASC)) - 1 AS ror
FROM renaissance_team2.fct_pricing_daily a
WHERE a.ticker IN ('UTHR', 'PLTR', 'AAPL', 'KGC', 'MU', 'VRSN', 'SPY')
  AND a.date >= '2021-06-01';

-- indexes to speed up the WHERE date >= and GROUP BY ticker queries
CREATE INDEX idx_daily_ror_date        ON renaissance_team2.fct_daily_ror(date);
CREATE INDEX idx_daily_ror_ticker_date ON renaissance_team2.fct_daily_ror(ticker, date);


/* -----------------------------------------------------------------------------------------
   STEP 3: fn_period_start_date

   We created this function so we do not hardcode dates in our queries.
   It receives a period name like '1YR' and returns the correct start date.
   We calculate from MAX date in fct_pricing_daily, not from today.
   For ALL we return NULL because we want all data with no date filter.
----------------------------------------------------------------------------------------- */
DROP FUNCTION IF EXISTS renaissance_team2.fn_period_start_date;

DELIMITER $$
CREATE FUNCTION renaissance_team2.fn_period_start_date(p_period VARCHAR(10))
RETURNS DATE
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_max_date DATE;
    SELECT MAX(date) INTO v_max_date
    FROM renaissance_team2.fct_pricing_daily;

    RETURN CASE p_period
        WHEN '1YR' THEN DATE_SUB(v_max_date, INTERVAL 1 YEAR)
        WHEN '2YR' THEN DATE_SUB(v_max_date, INTERVAL 2 YEAR)
        WHEN '3YR' THEN DATE_SUB(v_max_date, INTERVAL 3 YEAR)
        WHEN '4YR' THEN DATE_SUB(v_max_date, INTERVAL 4 YEAR)
        WHEN '5YR' THEN DATE_SUB(v_max_date, INTERVAL 5 YEAR)
        WHEN 'ALL' THEN NULL
        ELSE NULL
    END;
END$$
DELIMITER ;


/* -----------------------------------------------------------------------------------------
   STEP 4: rpt_stats

   This table stores return, risk and Sharpe Ratio for each stock per period.
   We fill it with direct INSERT queries, one per period.
   executed_at tells us when these results were last calculated.
----------------------------------------------------------------------------------------- */
DROP TABLE IF EXISTS renaissance_team2.rpt_stats;
CREATE TABLE renaissance_team2.rpt_stats (
    period       VARCHAR(10)    NOT NULL,
    ticker       VARCHAR(10)    NOT NULL,
    expected_ror DECIMAL(18,10),
    risk         DECIMAL(18,10),
    sharpe_ratio DECIMAL(18,10),
    executed_at  DATETIME       NOT NULL,
    PRIMARY KEY (period, ticker)
);

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT '1YR', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE date >= renaissance_team2.fn_period_start_date('1YR') AND ror IS NOT NULL
GROUP BY ticker;

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT '2YR', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE date >= renaissance_team2.fn_period_start_date('2YR') AND ror IS NOT NULL
GROUP BY ticker;

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT '3YR', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE date >= renaissance_team2.fn_period_start_date('3YR') AND ror IS NOT NULL
GROUP BY ticker;

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT '4YR', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE date >= renaissance_team2.fn_period_start_date('4YR') AND ror IS NOT NULL
GROUP BY ticker;

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT '5YR', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE date >= renaissance_team2.fn_period_start_date('5YR') AND ror IS NOT NULL
GROUP BY ticker;

INSERT INTO renaissance_team2.rpt_stats (period, ticker, expected_ror, risk, sharpe_ratio, executed_at)
SELECT 'ALL', ticker, AVG(ror), STD(ror), AVG(ror) / STD(ror), NOW()
FROM renaissance_team2.fct_daily_ror
WHERE ror IS NOT NULL
GROUP BY ticker;


/* -----------------------------------------------------------------------------------------
   STEP 5: rpt_portfolio_summary

   This table stores the overall portfolio metrics for Jim Simons per period.
   Weight = (current price x quantity) / total portfolio value today.
   We use vw_last_price to get the current price (MAX date in fct_pricing_daily).
   as_of_date tells us which price date was used for the weights.
----------------------------------------------------------------------------------------- */
DROP TABLE IF EXISTS renaissance_team2.rpt_portfolio_summary;
CREATE TABLE renaissance_team2.rpt_portfolio_summary (
    period                  VARCHAR(10)    NOT NULL,
    full_name               VARCHAR(100),
    num_tickers             INT,
    portfolio_expected_ror  DECIMAL(18,10),
    portfolio_risk          DECIMAL(18,10),
    portfolio_sharpe        DECIMAL(18,10),
    as_of_date              DATE,
    executed_at             DATETIME       NOT NULL,
    PRIMARY KEY (period, full_name)
);

INSERT INTO renaissance_team2.rpt_portfolio_summary
    (period, full_name, num_tickers, portfolio_expected_ror, portfolio_risk, portfolio_sharpe, as_of_date, executed_at)
SELECT
    t.period,
    t.full_name,
    COUNT(DISTINCT t.ticker)        AS num_tickers,
    SUM(t.expected_ror * t.weight)  AS portfolio_expected_ror,
    SUM(t.risk * t.weight)          AS portfolio_risk,
    SUM(t.sharpe_ratio * t.weight)  AS portfolio_sharpe,
    t.as_of_date,
    NOW()
FROM (
    SELECT
        s.period,
        c.full_name,
        s.ticker,
        s.expected_ror,
        s.risk,
        s.sharpe_ratio,
        (lp.last_price * h.quantity) /
            SUM(lp.last_price * h.quantity) OVER(PARTITION BY s.period) AS weight,
        lp.last_date AS as_of_date
    FROM renaissance_team2.rpt_stats s
    JOIN renaissance_team2.fct_holdings h   ON s.ticker = h.ticker
    JOIN renaissance_team2.dim_customer c   ON h.customer_id = c.customer_id
    JOIN renaissance_team2.vw_last_price lp ON s.ticker = lp.ticker
    WHERE s.ticker != 'SPY'
) t
GROUP BY t.period, t.full_name, t.as_of_date;


/* -----------------------------------------------------------------------------------------
   STEP 6: rpt_stock_detail

   This table has the full detail per stock per period.
   We use it to feed the dashboard.

   current_weight: (current price x quantity) / total portfolio value.
   optimal_weight: sharpe of this stock / sum of sharpes of all stocks in this period.
   PARTITION BY s.period keeps each period independent so weights are correct.
   SPY is added at the end as benchmark with NULL for portfolio-specific columns.
----------------------------------------------------------------------------------------- */
DROP TABLE IF EXISTS renaissance_team2.rpt_stock_detail;
CREATE TABLE renaissance_team2.rpt_stock_detail (
    period              VARCHAR(10)     NOT NULL,
    customer_name       VARCHAR(100)    NOT NULL,
    ticker              VARCHAR(10)     NOT NULL,
    ticker_name         VARCHAR(100),
    purchase_date       DATE,
    as_of_date          DATE,
    purchase_price      DECIMAL(12,6),
    current_price       DECIMAL(12,6),
    variation_pct       DECIMAL(10,2),
    expected_ror_pct    DECIMAL(12,4),
    risk_pct            DECIMAL(12,4),
    sharpe_ratio        DECIMAL(12,4),
    current_weight_pct  DECIMAL(10,2),
    optimal_weight_pct  DECIMAL(10,2),
    executed_at         DATETIME        NOT NULL,
    PRIMARY KEY (period, customer_name, ticker)
);

-- portfolio stocks
INSERT INTO renaissance_team2.rpt_stock_detail
    (period, customer_name, ticker, ticker_name, purchase_date, as_of_date,
     purchase_price, current_price, variation_pct, expected_ror_pct, risk_pct,
     sharpe_ratio, current_weight_pct, optimal_weight_pct, executed_at)
SELECT
    s.period,
    c.full_name                                                                   AS customer_name,
    h.ticker,
    td.ticker_name,
    h.purchase_date,
    lp.last_date                                                                  AS as_of_date,
    h.purchase_price,
    lp.last_price                                                                 AS current_price,
    ROUND(((lp.last_price - h.purchase_price) / h.purchase_price) * 100, 2)     AS variation_pct,
    ROUND(s.expected_ror * 100, 4)                                               AS expected_ror_pct,
    ROUND(s.risk * 100, 4)                                                       AS risk_pct,
    ROUND(s.sharpe_ratio, 4)                                                     AS sharpe_ratio,
    ROUND((lp.last_price * h.quantity) /
          SUM(lp.last_price * h.quantity) OVER(PARTITION BY s.period) * 100, 2) AS current_weight_pct,
    ROUND(s.sharpe_ratio /
          SUM(s.sharpe_ratio) OVER(PARTITION BY s.period) * 100, 2)              AS optimal_weight_pct,
    NOW()
FROM renaissance_team2.rpt_stats s
JOIN renaissance_team2.fct_holdings h   ON s.ticker = h.ticker
JOIN renaissance_team2.dim_customer c   ON h.customer_id = c.customer_id
JOIN renaissance_team2.dim_ticker td    ON s.ticker = td.ticker
JOIN renaissance_team2.vw_last_price lp ON s.ticker = lp.ticker
WHERE s.ticker != 'SPY';

-- SPY benchmark rows
INSERT INTO renaissance_team2.rpt_stock_detail
    (period, customer_name, ticker, ticker_name, purchase_date, as_of_date,
     purchase_price, current_price, variation_pct, expected_ror_pct, risk_pct,
     sharpe_ratio, current_weight_pct, optimal_weight_pct, executed_at)
SELECT
    s.period,
    'Benchmark'                    AS customer_name,
    s.ticker,
    td.ticker_name,
    NULL                           AS purchase_date,
    lp.last_date                   AS as_of_date,
    NULL                           AS purchase_price,
    lp.last_price                  AS current_price,
    NULL                           AS variation_pct,
    ROUND(s.expected_ror * 100, 4) AS expected_ror_pct,
    ROUND(s.risk * 100, 4)         AS risk_pct,
    ROUND(s.sharpe_ratio, 4)       AS sharpe_ratio,
    NULL                           AS current_weight_pct,
    NULL                           AS optimal_weight_pct,
    NOW()
FROM renaissance_team2.rpt_stats s
JOIN renaissance_team2.dim_ticker td    ON s.ticker = td.ticker
JOIN renaissance_team2.vw_last_price lp ON s.ticker = lp.ticker
WHERE s.ticker = 'SPY';


/* =========================================================================================
   VALIDATION
   We run these queries to check the results are correct.
========================================================================================= */

-- should be 7 stocks x 6 periods = 42 rows
SELECT period, COUNT(*) AS num_stocks
FROM renaissance_team2.rpt_stats
GROUP BY period ORDER BY period;

-- should be 6 rows, one per period
SELECT * FROM renaissance_team2.rpt_portfolio_summary ORDER BY period;

-- should be 7 stocks x 6 periods = 42 rows
SELECT period, customer_name, COUNT(*) AS num_stocks
FROM renaissance_team2.rpt_stock_detail
GROUP BY period, customer_name
ORDER BY period, customer_name;

-- weights should add up to 100% for each period
SELECT period,
       ROUND(SUM(current_weight_pct), 2) AS total_current_weight,
       ROUND(SUM(optimal_weight_pct), 2) AS total_optimal_weight
FROM renaissance_team2.rpt_stock_detail
WHERE customer_name != 'Benchmark'
GROUP BY period ORDER BY period;