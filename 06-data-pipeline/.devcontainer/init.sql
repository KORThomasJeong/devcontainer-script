-- 데이터 파이프라인용 기본 스키마
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

COMMENT ON SCHEMA raw     IS '원시 데이터 (ETL 수집)';
COMMENT ON SCHEMA staging IS '정제 데이터 (변환 중간)';
COMMENT ON SCHEMA mart    IS '분석용 최종 테이블';
