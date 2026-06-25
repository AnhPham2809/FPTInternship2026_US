-- Week 4: Refresh user_edit_count
-- Recalculates and updates user_edit_count for any rows
-- missing it (run this after every transformation_query.sql run)

UPDATE `fpt-internship-2026.wikimedia_data.recentchange_transformed` AS t
SET user_edit_count = counts.total_edits
FROM (
  SELECT user, COUNT(*) AS total_edits        -- count edits per username
  FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
  GROUP BY user
) AS counts
WHERE t.user = counts.user
  AND t.user_edit_count IS NULL;