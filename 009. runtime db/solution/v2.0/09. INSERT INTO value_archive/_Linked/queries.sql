SELECT EXISTS(SELECT 1 from glossary WHERE communication = 'Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage');

SELECT key FROM glossary WHERE communication = 'Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage';

INSERT INTO value_archive(key, fix, entity) VALUES(1, NOW(), '<Entity/>');
select * from value_archive order by key;

--_set_value
SELECT * FROM _set_value('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage','<Entity/>');

select * from value_actual order by key;

select * from value_archive order by key;