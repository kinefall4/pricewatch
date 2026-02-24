import sys, json
import pandas as pd

INPUT = sys.argv[1] if len(sys.argv) > 1 else "data/prices_demo.csv"
OUT = "site/assets/data/latest.json"

SHOCK_THRESHOLD_PCT = 20.0  # choose 20% to reduce noise

df = pd.read_csv(INPUT)
df["date"] = pd.to_datetime(df["date"])
df["price"] = pd.to_numeric(df["price"])
df = df.sort_values(["item", "date"])

df["pct_change"] = df.groupby("item")["price"].pct_change() * 100

latest_date = df["date"].max()
latest = df[df["date"] == latest_date].copy()

# top movers by absolute % change (ignore NaN)
movers = latest.dropna(subset=["pct_change"]).copy()
movers["abs_change"] = movers["pct_change"].abs()
movers = movers.sort_values("abs_change", ascending=False).head(5)

# shock alerts: abs(% change) >= threshold
shocks = latest.dropna(subset=["pct_change"]).copy()
shocks = shocks[shocks["pct_change"].abs() >= SHOCK_THRESHOLD_PCT].copy()
shocks = shocks.sort_values("pct_change", key=lambda s: s.abs(), ascending=False)

payload = {
    "latest_date": latest_date.strftime("%Y-%m-%d"),
    "shock_threshold_pct": SHOCK_THRESHOLD_PCT,
    "shock_alerts": [
        {
            "item": r.item,
            "pct_change": float(r.pct_change),
            "price": float(r.price),
            "direction": "up" if r.pct_change > 0 else "down"
        }
        for r in shocks.itertuples()
    ],
    "latest_prices": [
        {"item": r.item, "price": float(r.price)}
        for r in latest.itertuples()
    ],
    "top_movers": [
        {"item": r.item, "pct_change": float(r.pct_change), "price": float(r.price)}
        for r in movers.itertuples()
    ],
}

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)

print(f"Wrote {OUT}")