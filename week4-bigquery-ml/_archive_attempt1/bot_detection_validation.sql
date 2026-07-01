-- Week 4: Bot Detection Validation
-- Compares model predictions against the real bot flag
-- to check agreement rate and investigate disagreements

-- Overall agreement rate between prediction and actual
SELECT
  bot AS actual_bot,                -- real bot flag from Wikimedia
  predicted_bot,                    -- model's predicted bot flag
  COUNT(*) AS total                 -- count per combination

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
GROUP BY actual_bot, predicted_bot
ORDER BY actual_bot, predicted_bot;