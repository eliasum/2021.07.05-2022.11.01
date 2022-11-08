INSERT INTO entity_actual(key, fix, entity) VALUES(1, NOW(), '111');
select * from entity_actual;

UPDATE entity_actual SET fix = NOW(), entity = '444' WHERE key = 1;
select * from entity_actual;

SELECT EXISTS(SELECT 1 from entity_actual WHERE key = 1);

INSERT INTO entity_archive(key, fix, entity) VALUES(1, NOW(), '111');
select * from entity_archive;

select * from glossary;

SELECT * FROM _communication('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage',1,'111');

INSERT INTO entity_actual(key, fix, entity) VALUES(1, NOW(), '111');
select * from entity_actual;
SELECT * FROM _refresh('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage') AS (entity TEXT, key INTEGER, fix TIMESTAMP, value INTEGER);

SELECT * FROM _refresh();