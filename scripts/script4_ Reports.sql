/* =========================================================================================
   SCRIPT 4 - REPORTS
   Client:   Jim Simons - Renaissance Technologies
   Schema:   renaissance_team2
   Team:     Team 2 - Hult MBA
   Date:     June 2026

========================================================================================= */

SELECT * FROM renaissance_team2.rpt_stats ORDER BY period, ticker;
SELECT * FROM renaissance_team2.rpt_portfolio_summary ORDER BY period;
SELECT * FROM renaissance_team2.rpt_stock_detail ORDER BY period, customer_name;