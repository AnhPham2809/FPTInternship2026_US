import pandas as pd # Table handling
from google.cloud import bigquery # Pull data from BigQuery

PROJECT, DATASET, TABLE = "fpt-internship-2026", "wikimedia_data", "ml_dataset" # Where the data lives
client = bigquery.Client(project=PROJECT) # Connect to BigQuery

NS_MAP = {0:"article", 1:"talk", 2:"user", 3:"user", 4:"project", 5:"project",
          6:"file", 10:"template", 14:"category"} # Same namespace grouping as the stats step

# Surviving features per model (must match 02_feature_stats.py)
MODELS = {
    "bot_detection": {
        "label": "bot", # Predict: is this edit a bot?
        "continuous": ["edit_size", "length_old", "comment_length", "user_edit_count"], # Number features
        "categorical": ["namespace_group", "edit_direction"], # Category features
        "binary": ["is_english", "minor"], # True/false features
        "row_filter": "", # bot model uses all rows
    },
    "minor_prediction": {
        "label": "minor", # Predict: marked minor?
        "continuous": ["edit_size", "length_old", "comment_length", "user_edit_count"], # Number features
        "categorical": ["namespace_group", "contributor_type", "edit_direction"], # Category features
        "binary": ["is_english"], # True/false features
        "row_filter": "AND contributor_type != 'anonymous'", # anon can't mark minor, exclude them
    },
}

def load(cfg):
    feats = cfg["continuous"] + cfg["categorical"] + cfg["binary"] # All features
    real = [("namespace" if c == "namespace_group" else c) for c in feats] # pull raw namespace
    cols = ", ".join(sorted(set(real + [cfg["label"]]))) # columns to SELECT
    q = f"""SELECT {cols} FROM `{PROJECT}.{DATASET}.{TABLE}`
            WHERE split_set='TRAIN' AND length_old IS NOT NULL {cfg['row_filter']}""" # training rows
    df = client.query(q).to_dataframe() # run it
    if "namespace_group" in feats: # build grouped namespace if needed
        df["namespace_group"] = df["namespace"].map(lambda n: NS_MAP.get(int(n), "other") if pd.notna(n) else "other")
    df = df.dropna(subset=[cfg["label"]]) # drop rows with missing answer
    df[cfg["label"]] = df[cfg["label"]].astype(int) # answer as 1/0
    return df

def run(name, cfg):
    print(f"\n{'='*65}\n{name}  (label: {cfg['label']})\n{'='*65}") # header
    df = load(cfg) # get data
    lab = cfg["label"] # short name

    print("\n-- NUMBERS: average value when label=0 vs label=1 --") # continuous split
    print(df.groupby(lab)[cfg["continuous"]].mean().round(1).T.to_string()) # mean per class, features as rows

    print("\n-- FLAGS: how often the flag is True, when label=0 vs label=1 --") # binary split
    print(df.groupby(lab)[cfg["binary"]].mean().round(3).T.to_string()) # rate per class

    for c in cfg["categorical"]: # each category feature
        print(f"\n-- {c}: share that is label=1, per category --") # positive rate per category
        g = df.groupby(c)[lab].agg(["mean", "count"]).round(3) # rate + how many rows
        g.columns = [f"{lab}_rate", "n"] # rename
        print(g.sort_values(f"{lab}_rate", ascending=False).to_string()) # highest rate first

if __name__ == "__main__":
    for n, c in MODELS.items(): # both models
        run(n, c)
    print("\nDone.") # finished