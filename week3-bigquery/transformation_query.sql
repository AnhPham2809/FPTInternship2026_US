-- Week 3: Transformation Query
-- Reads from recentchange_landing, computes 7 derived columns,
-- and inserts enriched records into recentchange_transformed

INSERT INTO `fpt-internship-2026.wikimedia_data.recentchange_transformed`
(
  id, title, user, bot, wiki, namespace, meta_dt,
  length_old, length_new, comment, minor,
  edit_size, edit_direction, is_large_edit,
  contributor_type, is_vandalism_signal, hour_of_day,
  content_change_category, is_english
)
SELECT
  id,
  title,
  user,
  bot,
  wiki,
  namespace,
  meta_dt,
  length_old,
  length_new,
  comment,
  minor,

  -- edit_size: how much content changed in bytes
  (length_new - length_old) AS edit_size,

  -- edit_direction: classify the nature of the edit
  CASE
    WHEN (length_new - length_old) > 0 THEN 'addition'
    WHEN (length_new - length_old) < 0 THEN 'deletion'
    ELSE 'neutral'
  END AS edit_direction,

  -- is_large_edit: flag edits over 500 bytes of change
  ABS(length_new - length_old) > 500 AS is_large_edit,

-- contributor_type: classify who made the edit
  -- Detects both legacy IPv4 addresses and newer Wikipedia temporary
  -- anonymous account format (~YEAR-XXXXX-XX)
  CASE
    WHEN bot = TRUE THEN 'bot'
    WHEN REGEXP_CONTAINS(user, r'^\d+\.\d+\.\d+\.\d+$') THEN 'anonymous'
    WHEN REGEXP_CONTAINS(user, r'^~\d{4}-\d+-\d+$') THEN 'anonymous'
    ELSE 'registered'
  END AS contributor_type,

  -- is_vandalism_signal: anonymous user making a large deletion
  (REGEXP_CONTAINS(user, r'^\d+\.\d+\.\d+\.\d+$')
    OR REGEXP_CONTAINS(user, r'^~\d{4}-\d+-\d+$'))
    AND (length_new - length_old) < -500 AS is_vandalism_signal,
  
  -- hour_of_day: extract hour from timestamp for time pattern analysis
  EXTRACT(HOUR FROM meta_dt) AS hour_of_day,

  -- content_change_category: severity classification of the edit
  CASE
    WHEN ABS(length_new - length_old) < 50 THEN 'minor'
    WHEN ABS(length_new - length_old) < 500 THEN 'moderate'
    WHEN ABS(length_new - length_old) < 2000 THEN 'major'
    ELSE 'massive'
  END AS content_change_category,

  -- is_english: flag edits made on English Wikipedia specifically
  (wiki = 'enwiki') AS is_english

FROM `fpt-internship-2026.wikimedia_data.recentchange_landing` AS landing
WHERE landing.id NOT IN (
  SELECT id FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
);