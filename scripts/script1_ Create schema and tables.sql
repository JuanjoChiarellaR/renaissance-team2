#DANGER DROP SCHEMA renaissance_team2;
CREATE SCHEMA renaissance_team2;
USE renaissance_team2;

#DROP TABLE IF EXISTS customer_dim; #DANGER
CREATE TABLE customer_dim (
	customer_id			INT NOT NULL AUTO_INCREMENT,
    full_name			VARCHAR(100) NOT NULL,
    first_name			VARCHAR(100),
    last_name			VARCHAR(100),
    email				VARCHAR(100),
    customer_location	VARCHAR(100),
    PRIMARY KEY (customer_id)
);  #closing the create table

#DROP TABLE IF EXISTS ticker_dim; #DANGER
CREATE TABLE ticker_dim (
    ticker				VARCHAR(10) NOT NULL,
    ticker_name			VARCHAR(100),
    sec_type			VARCHAR(50),
    major_asset_class	VARCHAR(50),
    minor_asset_class	VARCHAR(50),
    PRIMARY KEY (ticker)
);  #closing the create table

#DROP TABLE IF EXISTS pricing_daily_adjusted; #DANGER
CREATE TABLE pricing_daily_adjusted (
    ticker				VARCHAR(10) NOT NULL,
    date				DATE NOT NULL,
    value				DECIMAL(12,6) NOT NULL,
    PRIMARY KEY (ticker, date),
    FOREIGN KEY (ticker) REFERENCES ticker_dim(ticker)
);  #closing the create table

#DROP TABLE IF EXISTS holdings_current; #DANGER
CREATE TABLE holdings_current (
    customer_id			INT NOT NULL,
    ticker				VARCHAR(10) NOT NULL,
    purchase_date		DATE NOT NULL,
    purchase_price		DECIMAL(12,6) NOT NULL,
    quantity			INT NOT NULL,
    PRIMARY KEY (customer_id, ticker),
    FOREIGN KEY (customer_id) 	REFERENCES customer_dim(customer_id),
    FOREIGN KEY (ticker) 		REFERENCES ticker_dim(ticker)
);  #closing the create table