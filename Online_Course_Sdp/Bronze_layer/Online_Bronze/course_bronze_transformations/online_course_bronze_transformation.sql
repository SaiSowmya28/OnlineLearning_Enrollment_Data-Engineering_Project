CREATE OR REFRESH STREAMING TABLE course_enrollments_bronze
COMMENT 'Bronze layer: raw ingestion of course_enrollments_raw.csv from the online_enrollment volume'
AS
SELECT
  *,
  _metadata.file_path AS source_file,
  current_timestamp() AS ingested_at
FROM STREAM read_files(
  '/Volumes/online_course/default/online_enrollment',
  format => 'csv',
  header => true,
  rescuedDataColumn => '_rescued_data'
);