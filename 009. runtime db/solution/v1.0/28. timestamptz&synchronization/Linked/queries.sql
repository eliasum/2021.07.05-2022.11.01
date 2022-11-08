/*2022.03.18 17:59 IMM*/

-----------------------------------------------------------------------------------------------------

select * from integer_actual
select * from integer_archive

select * from float_actual
select * from float_archive

INSERT INTO integer_archive(key, fix, value) VALUES(1, NOW(), '1');
INSERT INTO integer_archive(key, fix, value) VALUES(2, NOW(), '2');
INSERT INTO integer_archive(key, fix, value) VALUES(3, NOW(), '3');
INSERT INTO integer_archive(key, fix, value) VALUES(4, NOW(), '4');

select * from integer_archive;

select * from integer_archive where fix = (SELECT MAX(fix) FROM integer_archive);

SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage', 0.0000);

INSERT INTO synchronization (xpath, fix, status) VALUES ('1', NOW()::TIMESTAMP WITH TIME ZONE, '1');

select * from synchronization;
