"""Clean data.csv (fitness log): missing values, bad formats, outliers, new columns."""
import pandas as pd

df = pd.read_csv("data.csv")
print("Raw shape:", df.shape)

# ---- 1. Fix formats -------------------------------------------------------
# Dates have stray quotes ('2020/12/01') and one row is 20201226 (no separators).
df["Date"] = df["Date"].astype("string").str.strip("'")
df["Date"] = pd.to_datetime(df["Date"], format="mixed", errors="coerce")

# ---- 2. Duplicates --------------------------------------------------------
df = df.drop_duplicates().reset_index(drop=True)          # row 12 repeated row 11

# ---- 3. Missing values ----------------------------------------------------
# Date: the log is one row per day, so a gap is filled from its neighbours.
df["Date"] = df["Date"].fillna(df["Date"].shift(1) + pd.Timedelta(days=1))
# Calories: fill with the median of sessions of the same Duration.
df["Calories"] = df["Calories"].fillna(df.groupby("Duration")["Calories"].transform("median"))

# ---- 4. Wrong values ------------------------------------------------------
# Duration 450 min is a typo (calories match a ~45-60 min session): use the median.
df.loc[df["Duration"] > 240, "Duration"] = df["Duration"].median()
# Pulse can't exceed Maxpulse (row: Pulse 130, Maxpulse 101): drop impossible rows.
df = df[df["Pulse"] <= df["Maxpulse"]]

# ---- 5. New columns -------------------------------------------------------
df["Weekday"] = df["Date"].dt.day_name()
df["Cal_per_min"] = (df["Calories"] / df["Duration"]).round(2)
df["Intensity"] = pd.cut(df["Maxpulse"], bins=[0, 120, 135, 300],
                         labels=["Low", "Medium", "High"])

# ---- 6. Save + report -----------------------------------------------------
df = df.reset_index(drop=True)
df.to_csv("data_cleaned.csv", index=False)
print("Clean shape:", df.shape)
print("Missing values left:", int(df.isna().sum().sum()))
print(df.head())
