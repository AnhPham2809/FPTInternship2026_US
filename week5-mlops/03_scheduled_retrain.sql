-- Week 5.3: Scheduled retraining pipeline
-- The full continuous-training chain, run on a schedule.
-- Each cycle: bring in new data, refresh counts, re-split, retrain both models.
-- Scheduling this = the model stays current automatically as edits stream in.

-- STEP 1: Transform new landing rows into transformed (only rows not already there)
INSERT INTO `fpt-internship-2026.wikimedia_data.recentchange_transformed`
(
  id, title, user, bot, wiki, namespace, meta_dt,
  length_old, length_new, comment, minor,
  edit_size, edit_direction, is_large_edit,
  contributor_type, is_vandalism_signal, hour_of_day,
  content_change_category, is_english, is_high_value_contributor, day_of_week,
  comment_length
)
SELECT
  id, title, user, bot, wiki, namespace, meta_dt,
  length_old, length_new, comment, minor,
  (length_new - length_old) AS edit_size,
  CASE
    WHEN (length_new - length_old) > 0 THEN 'addition'
    WHEN (length_new - length_old) < 0 THEN 'deletion'
    ELSE 'neutral'
  END AS edit_direction,
  ABS(length_new - length_old) > 500 AS is_large_edit,
  CASE
    WHEN bot = TRUE THEN 'bot'
    WHEN REGEXP_CONTAINS(user, r'^\d+\.\d+\.\d+\.\d+$') THEN 'anonymous'
    WHEN REGEXP_CONTAINS(user, r'^~\d{4}-\d+-\d+$') THEN 'anonymous'
    ELSE 'registered'
  END AS contributor_type,
  (REGEXP_CONTAINS(user, r'^\d+\.\d+\.\d+\.\d+$')
    OR REGEXP_CONTAINS(user, r'^~\d{4}-\d+-\d+$'))
    AND (length_new - length_old) < -500 AS is_vandalism_signal,
  EXTRACT(HOUR FROM meta_dt) AS hour_of_day,
  CASE
    WHEN ABS(length_new - length_old) < 50 THEN 'minor'
    WHEN ABS(length_new - length_old) < 500 THEN 'moderate'
    WHEN ABS(length_new - length_old) < 2000 THEN 'major'
    ELSE 'massive'
  END AS content_change_category,
  (wiki = 'enwiki') AS is_english,
  (
    CASE
      WHEN bot = TRUE THEN 'bot'
      WHEN REGEXP_CONTAINS(user, r'^\d+\.\d+\.\d+\.\d+$') THEN 'anonymous'
      WHEN REGEXP_CONTAINS(user, r'^~\d{4}-\d+-\d+$') THEN 'anonymous'
      ELSE 'registered'
    END = 'registered'
  )
  AND (length_new - length_old) > 0
  AND ABS(length_new - length_old) > 500
  AS is_high_value_contributor,
  FORMAT_TIMESTAMP('%A', meta_dt) AS day_of_week,
  LENGTH(comment) AS comment_length
FROM `fpt-internship-2026.wikimedia_data.recentchange_landing` AS landing
WHERE landing.id NOT IN (
  SELECT id FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
);



UPDATE `fpt-internship-2026.wikimedia_data.recentchange_transformed` AS t
SET user_edit_count = counts.total_edits
FROM (
  SELECT user, COUNT(*) AS total_edits        -- count edits per username
  FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
  GROUP BY user
) AS counts
WHERE t.user = counts.user;                    -- update every row, not just null ones

-- STEP 2: Rebuild ml_dataset with the split (hashed on id, so old rows keep their assignment)
CREATE OR REPLACE TABLE `fpt-internship-2026.wikimedia_data.ml_dataset` AS
SELECT
  *,
  CASE
    WHEN MOD(ABS(FARM_FINGERPRINT(CAST(id AS STRING))), 10) < 8 THEN 'TRAIN'
    ELSE 'TEST'
  END AS split_set
FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`;

-- STEP 3: Retrain BOT model on the fresh data
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`
OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['bot'], data_split_method='NO_SPLIT') AS
SELECT
  bot, edit_size, length_old, comment_length, user_edit_count,
  edit_direction, is_english, minor,
  CASE namespace
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL;

-- STEP 4: Retrain MINOR model on the fresh data
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`
OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['minor'], data_split_method='NO_SPLIT') AS
SELECT
  minor, edit_size, length_old, comment_length, user_edit_count,
  contributor_type, edit_direction, is_english,
  CASE namespace
    WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
    WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
    WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
  END AS namespace_group
FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
WHERE split_set='TRAIN' AND length_old IS NOT NULL
  AND contributor_type != 'anonymous';