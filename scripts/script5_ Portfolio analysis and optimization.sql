/* -----------------------------------------------------------------------------------------
	PORTFOLIO ANALYSIS AND OPTIMIZATION
    
    Client:	Jim Simons (Renaissance)
    Schema:	renaissance_team2
    Date:	June 2026
   ----------------------------------------------------------------------------------------- */

#Create view from our historical data
CREATE OR REPLACE VIEW renaissance_team2.renaissance_dailyror AS(
SELECT
a.*,
LAG(a.value,1) OVER(PARTITION BY a.ticker ORDER BY a.date ASC) as p0,
(a.value / LAG(a.value,1) OVER(PARTITION BY a.ticker ORDER BY a.date ASC)) - 1 as ror
FROM renaissance_team2.pricing_daily_adjusted a
WHERE a.ticker in ('UTHR','PLTR','AAPL','KGC','MU','VRSN','SPY')
	and a.date >='2021-06-01');

#calculate the stats per ticker
SELECT 
    ticker,
    AVG(ror) as expected_ror,
    STD(ror) as risk,
    AVG(ror) / STD(ror) as sharpe_ratio
FROM renaissance_team2.renaissance_dailyror
GROUP BY ticker
ORDER BY sharpe_ratio DESC;

#calculate the stats for the whole portfolio
SELECT
	t.full_name,
    COUNT(distinct t.ticker) num_tickers,
    SUM(t.expected_ror * t.weight) as portfolio_expected_ror,
    SUM(t.risk * t.weight) as portfolio_risk,
    SUM(t.sharpe_ratio * t.weight) as portfolio_sharpe
FROM (
    SELECT
		c.full_name,
        r.ticker,
        AVG(r.ror) as expected_ror,
        STD(r.ror) as risk,
        AVG(r.ror) / STD(r.ror) as sharpe_ratio,
        (h.purchase_price * h.quantity) / SUM(h.purchase_price * h.quantity) OVER() as weight
    FROM renaissance_team2.renaissance_dailyror r
    JOIN renaissance_team2.holdings_current h
		ON r.ticker = h.ticker
    JOIN renaissance_team2.customer_dim c
		ON h.customer_id = c.customer_id
    GROUP BY
		c.full_name,
		r.ticker,
        h.purchase_price,
        h.quantity
) t
GROUP BY
	t.full_name
;

#calculate the portafolio optimization
SELECT
    c.full_name as customer_name,
    h.ticker,
    td.ticker_name,
    h.purchase_date,
    last_price.last_date as as_of_date,
    h.purchase_price as purchase_price,
    last_price.value as current_price,
    ROUND(((last_price.value - h.purchase_price) / h.purchase_price) * 100, 2) as variation_pct,
    ROUND(stats.expected_ror * 100, 4) as expected_ror_pct,
    ROUND(stats.risk * 100, 4) as risk_pct,
    ROUND(stats.sharpe_ratio, 4) as sharpe_ratio,
    ROUND(stats.current_weight * 100, 2) as current_weight_pct,
    ROUND(stats.sharpe_ratio / SUM(stats.sharpe_ratio) OVER() * 100, 2) as optimal_weight_pct
FROM renaissance_team2.holdings_current h
JOIN renaissance_team2.customer_dim c 
    ON h.customer_id = c.customer_id
JOIN renaissance_team2.ticker_dim td 
    ON h.ticker = td.ticker
JOIN (
    SELECT ticker, MAX(date) as last_date, value
    FROM renaissance_team2.pricing_daily_adjusted
    WHERE (ticker, date) IN (
        SELECT ticker, MAX(date)
        FROM renaissance_team2.pricing_daily_adjusted
        GROUP BY ticker
    )
    GROUP BY ticker, value
) last_price 
    ON h.ticker = last_price.ticker
JOIN (
    SELECT 
        r.ticker,
        AVG(r.ror) as expected_ror,
        STD(r.ror) as risk,
        AVG(r.ror) / STD(r.ror) as sharpe_ratio,
        (last_p.value * hh.quantity) / SUM(last_p.value * hh.quantity) OVER() as current_weight
    FROM renaissance_team2.renaissance_dailyror r
    JOIN renaissance_team2.holdings_current hh 
        ON r.ticker = hh.ticker
    JOIN (
        SELECT ticker, value
        FROM renaissance_team2.pricing_daily_adjusted
        WHERE (ticker, date) IN (
            SELECT ticker, MAX(date)
            FROM renaissance_team2.pricing_daily_adjusted
            GROUP BY ticker
        )
    ) last_p 
        ON hh.ticker = last_p.ticker
    GROUP BY r.ticker, hh.quantity, last_p.value
) stats 
    ON h.ticker = stats.ticker

UNION ALL

SELECT
    'Benchmark' as customer_name,
    p.ticker,
    td.ticker_name,
    NULL as purchase_date,
    last_price.last_date as as_of_date,
    NULL as purchase_price,
    last_price.value as current_price,
    NULL as variation_pct,
    ROUND(AVG(r.ror) * 100, 4) as expected_ror_pct,
    ROUND(STD(r.ror) * 100, 4) as risk_pct,
    ROUND(AVG(r.ror) / STD(r.ror), 4) as sharpe_ratio,
    NULL as current_weight_pct,
    NULL as optimal_weight_pct
FROM renaissance_team2.renaissance_dailyror r
JOIN renaissance_team2.ticker_dim td 
    ON r.ticker = td.ticker
JOIN (
    SELECT ticker, MAX(date) as last_date, value
    FROM renaissance_team2.pricing_daily_adjusted
    WHERE (ticker, date) IN (
        SELECT ticker, MAX(date)
        FROM renaissance_team2.pricing_daily_adjusted
        GROUP BY ticker
    )
    GROUP BY ticker, value
) last_price 
    ON r.ticker = last_price.ticker
JOIN renaissance_team2.pricing_daily_adjusted p 
    ON r.ticker = p.ticker
WHERE r.ticker = 'SPY'
GROUP BY p.ticker, td.ticker_name, last_price.last_date, last_price.value

ORDER BY customer_name, current_weight_pct DESC;