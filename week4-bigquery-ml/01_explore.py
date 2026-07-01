import numpy as np # Math helper
import pandas as pd # Table handling
from google.cloud import bigquery # Pull data from BigQuery

PROJECT, DATASET, TABLE = "fpt-internship-2026", "wikimedia_data", "ml_dataset" # Where the data lives

client = bigquery.Client(project=PROJECT) # Connect to BigQuery

# Every column we might care about for either model (we profile them all before choosing)
COLS = ["bot", "minor", # the two answers we want to predict
        "edit_size", "length_old", "length_new", "hour_of_day", "comment_length", "user_edit_count", # numbers
        "namespace", "contributor_type", "edit_direction", "content_change_category", "day_of_week", # categories
        "is_large_edit", "is_english", "is_vandalism_signal"] # true/false flags

q = f"SELECT {', '.join(COLS)} FROM `{PROJECT}.{DATASET}.{TABLE}` WHERE split_set='TRAIN'" # Training rows only
df = client.query(q).to_dataframe() # Run query, load into a table
print(f"Loaded {len(df)} training rows\n") # How many rows we're profiling

rows = [] # Will hold one summary line per column
for c in COLS: # Go through each column
    s = df[c] # The column itself
    n_null = s.isna().sum() # How many rows are empty/missing
    pct_null = round(100 * n_null / len(df), 2) # Missing as a percentage
    n_unique = s.nunique(dropna=True) # How many different values it has
    if pd.api.types.is_numeric_dtype(s) and n_unique > 10: # If it's a real number column
        detail = f"min={s.min():.0f} median={s.median():.0f} mean={s.mean():.1f} max={s.max():.0f}" # Spread of the numbers
    else: # Otherwise it's a category or true/false
        top = s.value_counts(dropna=True).head(1) # The single most common value
        tv = top.index[0] if len(top) else "NA" # That value
        tshare = round(100 * top.iloc[0] / len(df), 1) if len(top) else 0 # Its share of all rows
        detail = f"top={tv} ({tshare}% of rows)" # Most common value + how dominant it is
    rows.append({"column": c, "pct_null": pct_null, "distinct": n_unique, "detail": detail}) # Save the summary line

profile = pd.DataFrame(rows) # Turn summaries into a table
profile.to_csv("01_data_profile.csv", index=False) # Save it for the slides later
print(profile.to_string(index=False)) # Show it on screen
print("\nSaved: 01_data_profile.csv") # Confirm the file was written