-- Week 4: Backfill user_edit_count
-- Counts total edits per username and updates every row
-- with that user's total edit count in the dataset

UPDATE `fpt-internship-2026.wikimedia_data.recentchange_transformed` AS t
SET user_edit_count = counts.total_edits
FROM (
  SELECT user, COUNT(*) AS total_edits        -- count edits per username
  FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`
  GROUP BY user
) AS counts
WHERE t.user = counts.user;