#Customer table inserts. Autoincrement define the customer_id, it starts in 1
INSERT INTO renaissance_team2.customer_dim (full_name, first_name,last_name,email,customer_location)
VALUES ('Jim Simons', 'Jim', 'Simons', 'jsimons@renaissance.com', 'Massachusetts');

#Ticker table inserts
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('UTHR', 'United Therapeutics Corporation', 'common_share', 'equity', 'large_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('PLTR', 'Palantir Technologies Inc', 'common_share', 'equity', 'large_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('AAPL', 'Apple Inc', 'common_share', 'equity', 'large_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('KGC',  'Kinross Gold Corp', 'common_share', 'equity', 'mid_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('MU',   'Micron Technology Inc', 'common_share', 'equity', 'large_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('VRSN', 'VeriSign Inc', 'common_share', 'equity', 'large_cap');
INSERT INTO renaissance_team2.ticker_dim (ticker, ticker_name, sec_type, major_asset_class, minor_asset_class)
VALUES ('SPY',  'SPDR S&P 500 ETF Trust', 'etf', 'equity', 'large_cap');

#Ticker table holdings_current (our portfolio)
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'UTHR', '2021-06-01', 177.820007, 5965246);
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'PLTR', '2021-06-01', 23.059999, 44336516);
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'AAPL', '2021-06-01', 121.142166, 6435249);
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'KGC',  '2021-06-01', 7.411746,  105181695);
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'MU',   '2021-06-01', 82.070419, 8876037);
INSERT INTO renaissance_team2.holdings_current (customer_id, ticker, purchase_date, purchase_price, quantity)
VALUES (1, 'VRSN', '2021-06-01', 213.836044, 2988271);

