/*2022.03.30 17:34 IMM*/

-----------------------------------------------------------------------------------------------------

select * from integer_actual
select * from integer_archive

select * from float_actual
select * from float_archive

TRUNCATE integer_actual RESTART IDENTITY;
TRUNCATE integer_archive RESTART IDENTITY;
TRUNCATE float_actual RESTART IDENTITY;
TRUNCATE float_archive RESTART IDENTITY;

UPDATE integer_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 161);
SELECT * FROM integer_archive WHERE key = 161;

UPDATE integer_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 161) AND key = 161;
SELECT * FROM integer_archive WHERE key = 161;