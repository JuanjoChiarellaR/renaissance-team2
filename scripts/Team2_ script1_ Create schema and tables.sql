/* =========================================================================================
   SCRIPT 1 - CREATE SCHEMA AND TABLES
   Client:   Jim Simons - Renaissance Technologies
   Schema:   renaissance_team2
   Team:     Team 2 - Hult MBA
   Date:     June 2026
 
   Naming conventions used in this schema:
   dim_   = dimension tables. Descriptive data that does not change often.
   fct_   = fact tables. Transactional or event data.
   vw_    = views. Saved queries we reuse in other queries.
   rpt_   = report tables. Pre-calculated results for analysis and dashboards.
   sp_    = stored procedures.
   fn_    = functions.
========================================================================================= */

#DANGER
-- DROP SCHEMA renaissance_team2;
CREATE SCHEMA IF NOT EXISTS renaissance_team2;
USE renaissance_team2;

/* -----------------------------------------------------------------------------------------
   dim_customer
   Stores the client information. So far, we only have one client: Jim Simons.
   We built this table following good data modeling practices even though
   we only have one row, to show a proper relational structure.
----------------------------------------------------------------------------------------- */
#DROP TABLE IF EXISTS dim_customer; #DANGER
CREATE TABLE dim_customer (
	customer_id			INT NOT NULL AUTO_INCREMENT,
    full_name			VARCHAR(100) NOT NULL,
    first_name			VARCHAR(100),
    last_name			VARCHAR(100),
    email				VARCHAR(100),
    customer_location	VARCHAR(100),
    PRIMARY KEY (customer_id)
);  #closing the create table

/* -----------------------------------------------------------------------------------------
   dim_ticker
   Stores descriptive information about each stock in our analysis.
----------------------------------------------------------------------------------------- */
#DROP TABLE IF EXISTS dim_ticker; #DANGER
CREATE TABLE dim_ticker (
    ticker				VARCHAR(10) NOT NULL,
    ticker_name			VARCHAR(100),
    sec_type			VARCHAR(50),
    major_asset_class	VARCHAR(50),
    minor_asset_class	VARCHAR(50),
    PRIMARY KEY (ticker)
);  #closing the create table

/* -----------------------------------------------------------------------------------------
   fct_pricing_daily
   Stores the daily adjusted closing price for each stock.
   This is a fact table because it has one row per stock per day.
----------------------------------------------------------------------------------------- */
#DROP TABLE IF EXISTS fct_pricing_daily; #DANGER
CREATE TABLE fct_pricing_daily (
    ticker  			VARCHAR(10) NOT NULL,
    date				DATE NOT NULL,
    value				DECIMAL(12,6) NOT NULL,
    PRIMARY KEY (ticker, date),
    FOREIGN KEY (ticker) REFERENCES dim_ticker(ticker)
);  #closing the create table

/* -----------------------------------------------------------------------------------------
   fct_holdings
   Stores the stocks that Jim Simons holds in his portfolio.
   Purchase_price is the adjusted closing price on the purchase date.
   Quantity is the number of shares.
----------------------------------------------------------------------------------------- */
#DROP TABLE IF EXISTS fct_holdings; #DANGER
CREATE TABLE fct_holdings (
    customer_id			INT NOT NULL,
    ticker				VARCHAR(10) NOT NULL,
    purchase_date		DATE NOT NULL,
    purchase_price		DECIMAL(12,6) NOT NULL,
    quantity			INT NOT NULL,
    PRIMARY KEY (customer_id, ticker),
    FOREIGN KEY (customer_id) 	REFERENCES dim_customer(customer_id),
    FOREIGN KEY (ticker) 		REFERENCES dim_ticker(ticker)
);  #Closing the create table