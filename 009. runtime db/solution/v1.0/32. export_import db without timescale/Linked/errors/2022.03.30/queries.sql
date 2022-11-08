/*2022.03.31 15:23 IMM*/

-----------------------------------------------------------------------------------------------------

select * from integer_actual;
select * from integer_archive;

select * from float_actual;
select * from float_archive;

TRUNCATE integer_actual RESTART IDENTITY;
TRUNCATE integer_archive RESTART IDENTITY;
TRUNCATE float_actual RESTART IDENTITY;
TRUNCATE float_archive RESTART IDENTITY;

--_communication()
--integer, key=1
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage',2);
select * from integer_archive;

SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage',0);
select * from integer_actual;

--integer, key=3
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage',0);
select * from integer_archive;

INSERT INTO integer_archive(key, fix, value) VALUES(1, NOW(), 1.91);
INSERT INTO integer_archive(key, fix, value) VALUES(2, NOW(), 2.91);
INSERT INTO integer_archive(key, fix, value) VALUES(3, NOW(), 3.91);
INSERT INTO integer_archive(key, fix, value) VALUES(4, NOW(), 4.91);

SELECT MAX(fix) FROM integer_archive WHERE key = 1;

SELECT * FROM _synchronizer('start', 'start'); 
select * from synchronization;

TRUNCATE synchronization RESTART IDENTITY;

UPDATE integer_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 1) AND key = 1;
SELECT * FROM integer_archive;

SELECT * FROM integer_archive WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 1) AND key = 1;

