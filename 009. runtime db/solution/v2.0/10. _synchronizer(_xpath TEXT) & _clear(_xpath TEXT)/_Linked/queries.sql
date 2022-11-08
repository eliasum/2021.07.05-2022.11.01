--2022.09.23 11:46 IMM

SELECT key FROM glossary WHERE communication = 'Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage';

SELECT key FROM glossary WHERE configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage';

--проверка новых и измененных функций

--_set_order
SELECT * FROM _set_order('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage','<Entity/>');

select * from order_actual order by key;

select * from order_archive order by key;

--_set_value
SELECT * FROM _set_value('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage','<Entity/>');

select * from value_actual order by key;

select * from value_archive order by key;

--_synchronizer(_xpath TEXT) 
SELECT * FROM _synchronizer('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage');

select * from value_archive order by key;

select * from order_archive order by key;

select * from value_actual order by key;

select * from order_actual order by key;

--_clear(xpath TEXT)
SELECT * FROM _set_order('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage','<Entity/>');

select * from order_actual order by key;

select * from order_archive order by key;

SELECT * FROM _clear('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage');

select * from order_actual order by key;

select * from order_archive order by key;