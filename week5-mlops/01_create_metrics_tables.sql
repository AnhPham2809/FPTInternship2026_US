-- Week 5.1: Metrics-logging schema
-- Three tables that store history over time, so the dashboard can chart it.
-- Nothing can be visualized until there's somewhere to log it - this is the foundation.

-- Table 1: how many records come in per day (the "is the pipeline alive?" metric)
CREATE TABLE IF NOT EXISTS `fpt-internship-2026.wikimedia_data.metrics_data_volume` (
  date DATE,               -- the day being counted
  record_count INT64,      -- how many edits landed that day
  ingested_at TIMESTAMP    -- when this count row was written
);

-- Table 2: model weights over time (how each coefficient shifts with each retrain)
CREATE TABLE IF NOT EXISTS `fpt-internship-2026.wikimedia_data.metrics_model_weights` (
  retrain_timestamp TIMESTAMP,  -- which retrain this snapshot is from
  model_name STRING,            -- 'bot' or 'minor'
  feature_name STRING,          -- e.g. 'user_edit_count'
  coefficient FLOAT64           -- the weight value at this retrain
);

-- Table 3: prediction performance over time (accuracy/precision/recall per retrain)
CREATE TABLE IF NOT EXISTS `fpt-internship-2026.wikimedia_data.metrics_performance` (
  retrain_timestamp TIMESTAMP,  -- which retrain these metrics are from
  model_name STRING,            -- 'bot' or 'minor'
  accuracy FLOAT64,             -- % correct (misleading for minor - keep but note)
  precision FLOAT64,            -- of what it flagged, how much was right
  recall FLOAT64,               -- of the real ones, how many it caught
  auc FLOAT64                   -- ranking quality (the fair headline metric)
);