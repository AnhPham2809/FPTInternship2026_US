-- Week 4: False Positive Investigation
-- Looks at real humans the model incorrectly predicted as bots
-- to identify patterns in this direction of error

SELECT
  user,
  edit_size,
  content_change_category,
  comment_length,
  user_edit_count,
  COUNT(*) AS total_misses

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
      AND user_edit_count IS NOT NULL
  )
)
WHERE bot = FALSE AND predicted_bot = TRUE
GROUP BY user, edit_size, content_change_category, comment_length, user_edit_count
ORDER BY total_misses DESC
LIMIT 15;