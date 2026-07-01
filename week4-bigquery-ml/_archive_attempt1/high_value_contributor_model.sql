-- Week 4: High-Value Contributor Model
-- Trains a logistic regression model to predict whether a
-- human edit qualifies as a high-value contribution.
-- Excludes edit_size, content_change_category, edit_direction,
-- and is_large_edit since the label was directly computed from
-- these fields - including them would leak the answer.

-- Create/replace the model
CREATE OR REPLACE MODEL `fpt-internship-2026.wikimedia_data.high_value_contributor_model`

-- Model configuration
OPTIONS(
  model_type = 'logistic_reg',                    -- binary classification model
  input_label_cols = ['is_high_value_contributor'] -- column the model learns to predict
)
AS
-- Training data: features + label
SELECT
  namespace,
  is_english,
  hour_of_day,
  comment_length,
  user_edit_count,
  minor,
  is_high_value_contributor

FROM `fpt-internship-2026.wikimedia_data.recentchange_transformed`

WHERE contributor_type != 'bot'
  AND is_high_value_contributor IS NOT NULL
  AND namespace IS NOT NULL
  AND is_english IS NOT NULL
  AND hour_of_day IS NOT NULL
  AND comment_length IS NOT NULL
  AND user_edit_count IS NOT NULL
  AND minor IS NOT NULL;