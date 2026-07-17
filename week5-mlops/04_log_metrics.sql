-- Week 5.7: Log weights, performance, and data volume after each retrain.
-- Run this right after the models retrain. One shared timestamp ties the rows together.

-- LOG BOT MODEL WEIGHTS (numeric features only)
INSERT INTO `fpt-internship-2026.wikimedia_data.metrics_model_weights`
  (retrain_timestamp, model_name, feature_name, coefficient)
SELECT
  CURRENT_TIMESTAMP() AS retrain_timestamp,
  'bot' AS model_name,
  processed_input AS feature_name,
  weight AS coefficient
FROM ML.WEIGHTS(MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`)
WHERE weight IS NOT NULL;                 -- numeric features + intercept (skip nested categoricals)

-- LOG MINOR MODEL WEIGHTS (numeric features only) 
INSERT INTO `fpt-internship-2026.wikimedia_data.metrics_model_weights`
  (retrain_timestamp, model_name, feature_name, coefficient)
SELECT
  CURRENT_TIMESTAMP() AS retrain_timestamp,
  'minor' AS model_name,
  processed_input AS feature_name,
  weight AS coefficient
FROM ML.WEIGHTS(MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`)
WHERE weight IS NOT NULL;

--  LOG BOT MODEL PERFORMANCE (on TEST split) 
INSERT INTO `fpt-internship-2026.wikimedia_data.metrics_performance`
  (retrain_timestamp, model_name, accuracy, precision, recall, auc)
SELECT
  CURRENT_TIMESTAMP(), 'bot',
  accuracy, precision, recall, roc_auc
FROM ML.EVALUATE(
  MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`,
  (
    SELECT
      bot, edit_size, length_old, comment_length, user_edit_count,
      edit_direction, is_english, minor,
      CASE namespace
        WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
        WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
        WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
      END AS namespace_group
    FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
    WHERE split_set='TEST' AND length_old IS NOT NULL
  )
);

-- LOG MINOR MODEL PERFORMANCE (on TEST split)
INSERT INTO `fpt-internship-2026.wikimedia_data.metrics_performance`
  (retrain_timestamp, model_name, accuracy, precision, recall, auc)
SELECT
  CURRENT_TIMESTAMP(), 'minor',
  accuracy, precision, recall, roc_auc
FROM ML.EVALUATE(
  MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`,
  (
    SELECT
      minor, edit_size, length_old, comment_length, user_edit_count,
      contributor_type, edit_direction, is_english,
      CASE namespace
        WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
        WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
        WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
      END AS namespace_group
    FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
    WHERE split_set='TEST' AND length_old IS NOT NULL
      AND contributor_type != 'anonymous'
  )
);

-- LOG DAILY DATA VOLUME 
-- Count edits per day from transformed, refreshed each run.
-- Delete-then-insert so re-runs update counts instead of duplicating.
DELETE FROM `fpt-internship-2026.wikimedia_data.metrics_data_volume` WHERE TRUE;

INSERT INTO `fpt-internship-2026.wikimedia_data.metrics_data_volume`
  (date, record_count, ingested_at)
SELECT
  DATE(meta_dt) AS date,
  COUNT(*) AS record_count,
  CURRENT_TIMESTAMP() AS ingested_at
FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
GROUP BY DATE(meta_dt)
ORDER BY date;