-- Week 4: Bot Detection Error Investigation
-- Looks at real bots the model incorrectly predicted as human
-- to identify patterns in the model's mistakes

SELECT
  user,                    -- bot account username
  edit_size,                -- bytes changed
  content_change_category,   -- severity category
  comment_length,             -- length of edit summary
  is_large_edit,                -- whether edit was large
  COUNT(*) AS total_misses        -- how many times this user was missed

FROM ML.PREDICT(
  MODEL `fpt-internship-2026.wikimedia_data.bot_detection_model`,
  (
    SELECT *
    FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
    WHERE bot IS NOT NULL
      AND edit_size IS NOT NULL
      AND namespace IS NOT NULL
      AND is_english IS NOT NULL
      AND hour_of_day IS NOT NULL
      AND content_change_category IS NOT NULL
      AND is_large_edit IS NOT NULL
      AND edit_direction IS NOT NULL
      AND minor IS NOT NULL
      AND comment_length IS NOT NULL
  )
)
WHERE bot = TRUE AND predicted_bot = FALSE
GROUP BY user, edit_size, content_change_category, comment_length, is_large_edit
ORDER BY total_misses DESC
LIMIT 15;