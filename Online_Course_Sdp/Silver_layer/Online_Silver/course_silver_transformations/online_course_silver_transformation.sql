-- Validation + dedup layer: keep one row per enrollment_id (first occurrence), flag it valid or rejected
CREATE TEMPORARY VIEW enrollments_validated
COMMENT 'Deduped bronze enrollments; rejection_reason is NULL for valid rows, _row_num > 1 marks duplicate rows'
AS
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY enrollment_id ORDER BY ingested_at) AS _row_num,
  CASE
    WHEN enrollment_id IS NULL OR trim(enrollment_id) = '' THEN 'missing enrollment_id'
    WHEN learner_id IS NULL OR trim(learner_id) = '' THEN 'missing learner_id'
    WHEN course_id IS NULL OR trim(course_id) = '' THEN 'missing course_id'
    WHEN trim(learner_email) IS NULL OR trim(learner_email) NOT LIKE '%_@_%._%' THEN 'invalid learner_email'
    WHEN enrollment_date IS NULL THEN 'missing enrollment_date'
    WHEN progress_pct IS NULL THEN 'missing progress_pct'
    WHEN progress_pct < 0 OR progress_pct > 100 THEN 'progress_pct outside 0-100'
    WHEN price_paid IS NULL THEN 'missing price_paid'
    WHEN round(price_paid, 2) <> round(list_price - discount_amount, 2) THEN 'price_paid does not equal list_price - discount_amount'
    ELSE NULL
  END AS rejection_reason
FROM online_course.default.course_enrollments_bronze;

-- Silver layer: cleaned, deduplicated enrollments (valid first occurrences) with derived learner_status
CREATE OR REFRESH MATERIALIZED VIEW course_enrollments_clean
COMMENT 'Silver layer: cleaned, deduplicated course enrollments with learner status'
AS
SELECT
  trim(enrollment_id) AS enrollment_id,
  trim(learner_id) AS learner_id,
  lower(trim(learner_email)) AS learner_email,
  coalesce(nullif(trim(learner_city), ''), 'Unknown') AS learner_city,
  trim(age_group) AS age_group,
  trim(course_id) AS course_id,
  trim(course_name) AS course_name,
  initcap(lower(trim(category))) AS category,
  trim(course_level) AS course_level,
  trim(instructor_name) AS instructor_name,
  enrollment_date,
  initcap(lower(trim(enrollment_channel))) AS enrollment_channel,
  cast(list_price AS decimal(10, 2)) AS list_price,
  cast(discount_amount AS decimal(10, 2)) AS discount_amount,
  cast(price_paid AS decimal(10, 2)) AS price_paid,
  upper(trim(payment_method)) AS payment_method,
  progress_pct,
  round(hours_watched, 1) AS hours_watched,
  course_rating,
  upper(trim(certificate_issued)) AS certificate_issued,
  CASE
    WHEN progress_pct >= 100 THEN 'Completed'
    WHEN progress_pct >= 1 THEN 'In Progress'
    ELSE 'Not Started'
  END AS learner_status,
  source_file,
  ingested_at
FROM enrollments_validated
WHERE rejection_reason IS NULL
  AND _row_num = 1;

-- Quarantine: bad enrollments kept separately with the rejection reason
CREATE OR REFRESH MATERIALIZED VIEW course_enrollments_quarantine
COMMENT 'Rejected enrollments that failed silver validation rules (first occurrence per enrollment_id)'
AS
SELECT
  *,
  current_timestamp() AS rejected_at
FROM enrollments_validated
WHERE rejection_reason IS NOT NULL
  AND _row_num = 1;