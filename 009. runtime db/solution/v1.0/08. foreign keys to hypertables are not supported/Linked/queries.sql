CREATE TABLE conditions(
  tstamp timestamptz NOT NULL,
  device VARCHAR(32) NOT NULL,
  temperature FLOAT NOT NULL);

SELECT create_hypertable(
  'conditions', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);

SELECT * FROM conditions;
SELECT * FROM table_Glossary;
SELECT * FROM table_Number;
SELECT * FROM tablename;

INSERT INTO conditions
  SELECT
    tstamp, 'device-' || (random()*30)::INT, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;

select * from generate_series(1,300) number;

CREATE TABLE tablename (
  fieldname1 integer NOT NULL,
  fieldname2 integer NOT NULL);
  
SELECT key, configuration, tstamp
FROM table_Glossary 
INNER JOIN table_Number ON key = key_Number