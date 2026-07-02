-- ============ BOT DETECTION ============
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`
OPTIONS(
  model_type='LOGISTIC_REG', -- logistic regression
  input_label_cols=['bot'], -- what we predict
  data_split_method='NO_SPLIT' -- we already made our own split, don't let BQML re-split
) AS
SELECT
  bot, -- label
  edit_size, length_old, comment_length, user_edit_count, -- numbers
  edit_direction, -- category
  is_english, minor, -- flags
  CASE namespace -- group the 38 namespace codes into a few buckets
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL; -- training rows only

-- ============ MINOR PREDICTION ============
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`
OPTIONS(
  model_type='LOGISTIC_REG',
  input_label_cols=['minor'],
  data_split_method='NO_SPLIT'
) AS
SELECT
  minor, -- label
  edit_size, length_old, comment_length, user_edit_count, -- numbers
  contributor_type, edit_direction, -- categories
  is_english, -- flag
  CASE namespace
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL
  AND contributor_type != 'anonymous'; -- anon can't mark minor, exclude them