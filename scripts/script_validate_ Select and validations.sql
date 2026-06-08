#Select - visualization
select count(customer_id) num_customers from renaissance_team2.customer_dim;
select count(ticker) num_tickers from renaissance_team2.ticker_dim;
select count(ticker) num_tickers_portfolio from renaissance_team2.holdings_current;
select count(ticker) num_historical_data from renaissance_team2.pricing_daily_adjusted;

#Customer portfolio - visualization
select
	c.full_name as customer_name,
    c.customer_location as customer_location,
    h.ticker,
    t.ticker_name,
    h.purchase_date,
    h.purchase_price,
    h.quantity,
    t.sec_type,
    t.major_asset_class,
    t.minor_asset_class
from renaissance_team2.holdings_current h
left join renaissance_team2.customer_dim c
	on h.customer_id = c.customer_id
left join renaissance_team2.ticker_dim t
	on h.ticker = t.ticker;