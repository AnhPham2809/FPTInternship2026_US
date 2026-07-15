-- BOT MODEL 

SELECT 'bot' AS model, *
FROM ML.EVALUATE(
  MODEL `fpt-internship-2026.wikimedia_data.logreg_bot`,
  (
    SELECT
      bot, edit_size, length_old, comment_length, user_edit_count, -- label + numbers
      edit_direction, is_english, minor, -- category + flags
      CASE namespace -- same namespace grouping used in training
        WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
        WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
        WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
      END AS namespace_group
    FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
    WHERE split_set='TEST' AND length_old IS NOT NULL -- held-out rows only
  )
);

-- MINOR MODEL 
FROM ML.EVALUATE(
  MODEL `fpt-internship-2026.wikimedia_data.logreg_minor`,
  (
    SELECT
      minor, edit_size, length_old, comment_length, user_edit_count, -- label + numbers
      contributor_type, edit_direction, is_english, -- categories + flag
      CASE namespace
        WHEN 0 THEN 'article' WHEN 1 THEN 'talk' WHEN 2 THEN 'user' WHEN 3 THEN 'user'
        WHEN 4 THEN 'project' WHEN 5 THEN 'project' WHEN 6 THEN 'file'
        WHEN 10 THEN 'template' WHEN 14 THEN 'category' ELSE 'other'
      END AS namespace_group
    FROM `fpt-internship-2026.wikimedia_data.ml_dataset`
    WHERE split_set='TEST' AND length_old IS NOT NULL
      AND contributor_type != 'anonymous' -- match training scope
  )
);