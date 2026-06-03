import pandas as pd
import os

tickers = ['UTHR', 'PLTR', 'AAPL', 'KGC', 'MU', 'VRSN', 'SPY']
csv_folder = '/Users/juanjo/Documents/Estudios/0 Hult MBA 2025/M3 Data Management & SQL - DAT 5486/Team Assessment/CSV/'

output = open('pricing_inserts.sql', 'w')

for ticker in tickers:
    filepath = os.path.join(csv_folder, f'{ticker}.csv')
    print(f"Reading: {filepath}")
    
    if not os.path.exists(filepath):
        print(f"ERROR: File not found - {filepath}")
        continue
        
    df = pd.read_csv(filepath)
    df = df[['Date', 'Adj Close']].dropna()
    print(f"{ticker}: {len(df)} rows found")
    
    for _, row in df.iterrows():
        date = row['Date']
        value = round(row['Adj Close'], 6)
        sql = f"INSERT INTO renaissance_team2.pricing_daily_adjusted (ticker, date, value) VALUES ('{ticker}', '{date}', {value:.6f});\n"
        output.write(sql)

output.close()
print("Done - pricing_inserts.sql generated")