-- Week 4: Bot Detection Model
-- Trains a logistic regression model to predict bot status
-- using behavioral signals only (excludes contributor_type,
-- which would leak the answer directly)

-- Create/replace the model
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.bot_detection_model`

-- Model configuration
OPTIONS(
  model_type = 'logistic_reg',       -- binary classification model
  input_label_cols = ['bot']         -- column the model learns to predict
)
AS
-- Training data: features + label
SELECT
  edit_size,                  -- bytes changed in edit
  namespace,                  -- page namespace edited
  is_english,                 -- whether edit was on English Wikipedia
  hour_of_day,                -- hour the edit happened
  content_change_category,    -- severity category of the edit
  is_large_edit,              -- whether edit size exceeded 500 bytes
  edit_direction,             -- addition, deletion, or neutral
  minor,                      -- whether edit was flagged as minor
  day_of_week,                -- name of weekday the edit happened
  bot                         -- label: true answer to predict

FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`

-- Filter out incomplete rows
WHERE bot IS NOT NULL
  AND edit_size IS NOT NULL
  AND namespace IS NOT NULL
  AND is_english IS NOT NULL
  AND hour_of_day IS NOT NULL
  AND content_change_category IS NOT NULL
  AND is_large_edit IS NOT NULL
  AND edit_direction IS NOT NULL
  AND minor IS NOT NULL
  AND day_of_week IS NOT NULL;