/*2022.03.01 16:24 IMM*/

-----------------------------------------------------------------------------------------------------

--тестирование _communication

	select * from integer_actual order by key;
	select * from integer_archive order by key;
	select * from float_actual order by key;
	select * from float_archive order by key;

	TRUNCATE integer_actual RESTART IDENTITY;
	TRUNCATE integer_archive RESTART IDENTITY;
	TRUNCATE float_actual RESTART IDENTITY;
	TRUNCATE float_archive RESTART IDENTITY;

	insert into integer_actual(key, fix, value) 
	values (1, Now(), 111);
	select * from integer_actual order by key;

SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);

SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value', 0.7845);
select * from integer_archive order by key;

-----------------------------------------------------------------------------------------------------

--тестирование _refresh(xpath VARCHAR)

select * from float_actual order by key;
select * from integer_actual order by key;

SELECT * FROM _refresh('Configuration/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value') AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue INTEGER, unit VARCHAR, formatt VARCHAR);

SELECT * FROM float_actual WHERE float_actual.key = 1;

select * from glossary;

SELECT float_actual.key, float_actual.fix, float_actual.value, glossary.unit, glossary.formatt 
FROM float_actual 
INNER JOIN glossary ON float_actual.key = glossary.key

INSERT INTO float_actual(key, fix, value)
VALUES (1, Now(), 111);
SELECT * FROM float_actual;

SELECT integer_actual.key, integer_actual.fix, integer_actual.value, glossary.unit, glossary.formatt 
FROM integer_actual 
INNER JOIN glossary ON integer_actual.key = glossary.key

INSERT INTO integer_actual(key, fix, value)
VALUES (1, Now(), 111);
SELECT * FROM float_actual;
-----------------------------------------------------------------------------------------------------

--тестирование _refresh()

SELECT * FROM _refresh();
-----------------------------------------------------------------------------------------------------

--тестирование _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)

SELECT * FROM float_archive;
SELECT * FROM integer_archive;

INSERT INTO float_archive(key, fix, value)
VALUES (1, Now(), 111);
SELECT * FROM float_archive;

INSERT INTO integer_archive(key, fix, value)
VALUES (1, Now(), 111);
SELECT * FROM integer_archive;

SELECT * FROM _refreshold('Configuration/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value','2022-03-01 11:57:05.844831+07','2022-03-03 12:02:05.844831+07');


	SELECT integer_archive.key, integer_archive.fix, integer_archive.value, glossary.unit, glossary.formatt 
	FROM integer_archive 
	INNER JOIN glossary ON integer_archive.key = glossary.key
	WHERE integer_archive.fix BETWEEN '2022-03-01 11:57:05.844831+07' AND '2022-03-03 12:02:05.844831+07'

	
SELECT * FROM _refreshold('2022-03-01 11:57:05.844831+07','2022-03-03 12:02:05.844831+07');
