-- Week 5.2: Retraining job for both models
-- Retrains bot + minor models on ALL data accumulated so far (the TRAIN split).
-- This is the engine of continuous training - as new edits flow into ml_dataset,
-- re-running this retrains both models on the larger dataset.
-- Uses the same justified feature sets and scoping from Week 4.

-- ============ BOT MODEL ============
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`
OPTIONS(
  model_type='LOGISTIC_REG',      -- same model type as Week 4
  input_label_cols=['bot'],       -- what we predict
  data_split_method='NO_SPLIT'    -- we use our own TRAIN/TEST split, don't let BQML re-split
) AS
SELECT
  bot,                                                    -- label
  edit_size, length_old, comment_length, user_edit_count, -- numbers
  edit_direction,                                         -- category
  is_english, minor,                                      -- flags
  CASE namespace                                          -- group 38 namespace codes into buckets
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL;       -- train on latest accumulated TRAIN rows

-- ============ MINOR MODEL ============
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`
OPTIONS(
  model_type='LOGISTIC_REG',
  input_label_cols=['minor'],
  data_split_method='NO_SPLIT'
) AS
SELECT
  minor,                                                  -- label
  edit_size, length_old, comment_length, user_edit_count, -- numbers
  contributor_type, edit_direction,                      -- categories
  is_english,                                             -- flag
  CASE namespace
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL
  AND contributor_type != 'anonymous';                   -- anon can't mark minor, exclude them