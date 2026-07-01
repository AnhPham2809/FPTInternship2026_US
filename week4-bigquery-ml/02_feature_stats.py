import numpy as np # Math helper for arrays
import pandas as pd # Table/dataframe handling
import statsmodels.api as sm # Gives us p-values (BigQuery ML can't)
from statsmodels.stats.outliers_influence import variance_inflation_factor # VIF = redundancy check
from google.cloud import bigquery # Pull data from BigQuery

PROJECT, DATASET, TABLE = "fpt-internship-2026", "wikimedia_data", "ml_dataset" # Where the data lives

client = bigquery.Client(project=PROJECT) # Connect to BigQuery using ADC credentials

# Turn the 38 namespace codes into a few readable groups (avoids 37 one-hot columns)
NS_MAP = {0:"article", 1:"talk", 2:"user", 3:"user", 4:"project", 5:"project",
          6:"file", 10:"template", 14:"category"} # Common Wikipedia namespaces; rest become "other"

# Settings per model. Edit-size BINS (is_large_edit, content_change_category) dropped:
# they're just binned edit_size (redundant), and caused perfect separation in the minor model.
MODELS = {
    "bot_detection": {
        "label": "bot", # Predict: is this edit made by a bot?
        "continuous":  ["edit_size", "length_old", "comment_length", "user_edit_count"], # Number columns
        "categorical": ["namespace_group", "edit_direction"], # Category columns
        "binary":      ["is_english", "minor"], # True/false columns
        "row_filter":  "", # bot model uses all rows
        # contributor_type + is_high_value_contributor left out: built from `bot`, would leak the answer
    },
    "minor_prediction": {
        "label": "minor", # Predict: did the editor mark this edit as minor?
        "continuous":  ["edit_size", "length_old", "comment_length", "user_edit_count"], # Number columns
        "categorical": ["namespace_group", "contributor_type", "edit_direction"], # Category columns
        "binary":      ["is_english"], # True/false columns
        "row_filter":  "AND contributor_type != 'anonymous'", # anon users CAN'T mark minor - excluding them removes perfect separation
        # dropped standalone `bot`: identical to contributor_type_bot (VIF was infinite)
    },
}

def load_train(cfg):
    feats = cfg["continuous"] + cfg["categorical"] + cfg["binary"] # All feature columns for this model
    real = [("namespace" if c == "namespace_group" else c) for c in feats] # namespace_group is derived, pull raw namespace
    cols = ", ".join(sorted(set(real + [cfg["label"]]))) # Real columns to actually SELECT
    q = f"""SELECT {cols} FROM `{PROJECT}.{DATASET}.{TABLE}`
            WHERE split_set='TRAIN' AND length_old IS NOT NULL AND length_new IS NOT NULL {cfg.get('row_filter','')}""" # Training rows, skip missing lengths, apply any per-model filter
    df = client.query(q).to_dataframe() # Run query, return as a table
    if "namespace_group" in feats: # If this model wants the grouped namespace
        df["namespace_group"] = df["namespace"].map(lambda n: NS_MAP.get(int(n), "other") if pd.notna(n) else "other") # Build it
    return df # Hand back the data

def build_design(df, cfg):
    df = df.dropna(subset=[cfg["label"]]) # Drop rows where the answer is missing - can't learn from unknown
    y = df[cfg["label"]].astype(int) # The answer column, turned into 1/0
    cont = df[cfg["continuous"]].astype(float).fillna(0) # Number columns; missing comment/edit-count counts as 0
    cont = (cont - cont.mean()) / cont.std(ddof=0).replace(0, 1) # Scale to mean 0 spread 1 so coefficients compare fairly
    parts = [cont] # Start building the feature table
    if cfg["categorical"]: # If there are category columns
        parts.append(pd.get_dummies(df[cfg["categorical"]].astype(str), drop_first=True)) # Turn each category into its own 0/1 column
    parts.append(df[cfg["binary"]].fillna(False).astype(int)) # True/false columns as 0/1, missing counts as false
    X = pd.concat(parts, axis=1).astype(float) # Glue all feature columns together
    X = sm.add_constant(X) # Add intercept column (standard for this model)
    return X, y # Hand back features and answer

def fit_logit(X, y):
    try:
        return sm.Logit(y, X).fit(disp=False, maxiter=300) # Normal training, hide progress spam
    except Exception as e:
        print(f"  [warn] normal fit failed ({e}); using regularized fit instead.") # A feature predicted too perfectly
        return sm.Logit(y, X).fit_regularized(disp=False, maxiter=300) # Steadier fallback training

def run(name, cfg):
    print(f"\n{'='*60}\n{name}  (predicting: {cfg['label']})\n{'='*60}") # Header for this model
    df = load_train(cfg) # Get the training data
    X, y = build_design(df, cfg) # Shape it into features + answer
    m = fit_logit(X, y) # Train the model

    stats = pd.DataFrame({"feature": X.columns,
                          "coefficient": np.asarray(m.params), # How strong + which direction
                          "p_value": np.asarray(m.pvalues)}) # Is the effect real or noise
    stats["significant_5pct"] = stats["p_value"] < 0.05 # Below 0.05 = counts as real
    stats = stats.reindex(stats["coefficient"].abs().sort_values(ascending=False).index) # Strongest features first

    Xv = X.drop(columns="const") # VIF doesn't apply to the intercept, drop it
    vif = pd.DataFrame({"feature": Xv.columns,
        "VIF": [variance_inflation_factor(Xv.values, i) for i in range(Xv.shape[1])] # Redundancy score per feature
        }).sort_values("VIF", ascending=False) # Most redundant first

    stats.to_csv(f"{name}_feature_stats.csv", index=False) # Save coefficients + p-values
    vif.to_csv(f"{name}_vif.csv", index=False) # Save redundancy scores

    print(f"pseudo-R2: {m.prsquared:.4f}  rows: {len(y)}  positive_rate: {y.mean():.4f}") # Quick model summary
    print("\n-- coefficients & p-values --") # Section label
    print(stats.to_string(index=False)) # Show the stats table
    print("\n-- VIF (above 5 = redundant, above 10 = seriously redundant) --") # Section label
    print(vif.to_string(index=False)) # Show the VIF table

if __name__ == "__main__": # Prevent running on import
    for n, c in MODELS.items(): # Loop over both models
        run(n, c) # Do the full run
    print("\nDone. Wrote CSV files: *_feature_stats.csv and *_vif.csv") # Final message