
SELECT * FROM _communication('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage
',1,'1');

INSERT INTO glossary (communication, configuration, tablename, entity) VALUES('1', '2', 'integer', '4');

select * from GLOSSARY;

select * from _communication('1', 2, '5');

UPDATE glossary SET entity = '6' WHERE key = 341;

select * from integer_actual; 7 2022-07-28 17:28:56.03538 75

--integer
SELECT * FROM _refresh('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage') AS (entity TEXT, key INTEGER, fix TIMESTAMP, value INTEGER);

SELECT * FROM _chart('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage') AS (key INTEGER, fix TIMESTAMP, value INTEGER);  