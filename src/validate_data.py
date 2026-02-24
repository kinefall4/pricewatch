import sys
import pandas as pd

INPUT = sys.argv[1] if len(sys.argv) > 1 else "data/prices_demo.csv"
df = pd.read_csv(INPUT)

required = {"date", "item", "price"}
missing = required - set(df.columns)
if missing:
    raise ValueError(f"Missing columns: {missing}")

df["date"] = pd.to_datetime(df["date"], errors="raise")
df["price"] = pd.to_numeric(df["price"], errors="raise")

if (df["price"] <= 0).any():
    raise ValueError("Found non-positive price values")

print(f"Validation OK. Rows={len(df)} Items={df['item'].nunique()}")