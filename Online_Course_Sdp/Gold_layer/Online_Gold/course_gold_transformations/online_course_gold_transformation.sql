-- Gold: completion rate over all valid (silver) enrollments
CREATE OR REFRESH MATERIALIZED VIEW enrollment_completion_metrics
COMMENT 'Gold: completion_rate_pct = Completed enrollments x 100 / all enrollments'
AS
SELECT
  COUNT(*) AS total_enrollments,
  SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) AS completed_enrollments,
  ROUND(SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate_pct
FROM online_course.default.course_enrollments_clean;

-- Gold: unique learners based on cleaned emails
CREATE OR REFRESH MATERIALIZED VIEW unique_learners
COMMENT 'Gold: COUNT(DISTINCT learner_email) on cleaned emails from silver'
AS
SELECT
  COUNT(DISTINCT learner_email) AS unique_learners
FROM online_course.default.course_enrollments_clean;

-- BR-01: monthly enrollment trends
CREATE OR REFRESH MATERIALIZED VIEW enrollment_monthly_trends
COMMENT 'BR-01: enrollments, unique learners, revenue, discount, completions, hours watched per month'
AS
SELECT
  date_format(enrollment_date, 'yyyy-MM') AS enrollment_month,
  COUNT(*) AS enrollments,
  COUNT(DISTINCT learner_email) AS unique_learners,
  SUM(price_paid) AS revenue,
  SUM(discount_amount) AS total_discount,
  SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) AS completions,
  ROUND(SUM(hours_watched), 1) AS total_hours_watched
FROM online_course.default.course_enrollments_clean
GROUP BY ALL
ORDER BY enrollment_month;

-- BR-02: category performance
CREATE OR REFRESH MATERIALIZED VIEW category_performance
COMMENT 'BR-02: enrollments, revenue, learner status counts, completion rate per category'
AS
SELECT
  category,
  COUNT(*) AS enrollments,
  SUM(price_paid) AS revenue,
  SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
  SUM(CASE WHEN learner_status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress,
  SUM(CASE WHEN learner_status = 'Not Started' THEN 1 ELSE 0 END) AS not_started,
  ROUND(SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate_pct
FROM online_course.default.course_enrollments_clean
GROUP BY ALL;

-- BR-03: course performance
CREATE OR REFRESH MATERIALIZED VIEW course_performance
COMMENT 'BR-03: enrollments, revenue, completion rate, average rating, hours watched per course'
AS
SELECT
  course_id,
  course_name,
  COUNT(*) AS enrollments,
  SUM(price_paid) AS revenue,
  ROUND(SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate_pct,
  ROUND(AVG(course_rating), 2) AS avg_course_rating,
  ROUND(SUM(hours_watched), 1) AS total_hours_watched
FROM online_course.default.course_enrollments_clean
GROUP BY ALL;

-- BR-04: channel performance
CREATE OR REFRESH MATERIALIZED VIEW channel_performance
COMMENT 'BR-04: enrollments, revenue, completion rate per enrollment channel'
AS
SELECT
  enrollment_channel,
  COUNT(*) AS enrollments,
  SUM(price_paid) AS revenue,
  ROUND(SUM(CASE WHEN learner_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate_pct
FROM online_course.default.course_enrollments_clean
GROUP BY ALL;

-- BR-05: data quality summary
CREATE OR REFRESH MATERIALIZED VIEW data_quality_summary
COMMENT 'BR-05: rows affected per data quality problem'
AS
SELECT 'rejected: ' || rejection_reason AS problem, COUNT(*) AS rows_affected
FROM online_course.default.course_enrollments_quarantine
GROUP BY ALL
UNION ALL
SELECT 'duplicate enrollment_id rows removed (kept first occurrence)' AS problem,
  COUNT(*) - COUNT(DISTINCT enrollment_id) AS rows_affected
FROM online_course.default.course_enrollments_bronze
UNION ALL
SELECT 'learners double-counted before email cleaning' AS problem,
  COUNT(DISTINCT learner_email) - COUNT(DISTINCT lower(trim(learner_email))) AS rows_affected
FROM online_course.default.course_enrollments_bronze;

-- BR-06: reconciliation check
CREATE OR REFRESH MATERIALIZED VIEW reconciliation_check
COMMENT 'BR-06: proves bronze rows = clean + quarantined + duplicates removed'
AS
SELECT
  (SELECT COUNT(*) FROM online_course.default.course_enrollments_bronze) AS bronze_rows,
  (SELECT COUNT(*) FROM online_course.default.course_enrollments_clean) AS clean_rows,
  (SELECT COUNT(*) FROM online_course.default.course_enrollments_quarantine) AS quarantined_rows,
  (SELECT COUNT(*) - COUNT(DISTINCT enrollment_id) FROM online_course.default.course_enrollments_bronze) AS duplicate_rows_removed,
  CASE
    WHEN (SELECT COUNT(*) FROM online_course.default.course_enrollments_clean)
       + (SELECT COUNT(*) FROM online_course.default.course_enrollments_quarantine)
       + (SELECT COUNT(*) - COUNT(DISTINCT enrollment_id) FROM online_course.default.course_enrollments_bronze)
     = (SELECT COUNT(*) FROM online_course.default.course_enrollments_bronze)
    THEN 'PASS'
    ELSE 'FAIL'
  END AS status;