select * from glossary order by key;

select * from glossary where configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage';

--Configuration 1
SELECT * FROM _update('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage','<Entity/>');

--Communication 2
SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage','<Entity/>');

select * from entity_actual order by key;

--new Configuration 104
SELECT * FROM _update('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate'']/Amperage','<Entity/>');  

--Communication 104
SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage','<Entity><Entity1 order="1!" /></Entity>');

SELECT xpath_exists('*/@order', entity) FROM entity_actual WHERE key = 104;

--Communication 2
SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage','<Entity/>');

--Communication 103
SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage','<Entity/>');

UPDATE entity_actual SET fix = NOW(), entity = '<Entity/>' WHERE key = 103;
select * from entity_actual order by key;

SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage','<Entity><Entity1 /></Entity>');
select * from entity_actual order by key;

SELECT xpath_exists('*/@order', entity) FROM entity_actual WHERE key = 103;

SELECT xpath_exists('*/@order', '<Entity/>')

--Communication 333
SELECT xpath('//@order', entity) FROM entity_actual WHERE key = 333;

SELECT * FROM _update('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''B'']/Voltage','<Entity><Entity1 /></Entity>');
select * from entity_actual order by key;

SELECT * FROM (SELECT xpath('//@order', entity) FROM entity_actual) foo WHERE foo::TEXT <> '0';


