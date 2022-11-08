select * from glossary order by key;

select * from glossary where configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage';

--order_actual
SELECT * FROM _set_order('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Elegaz/Item[@key=''1'']/Command/Item[@key=''on'']/Voltage','<Entity/>');
select * from order_actual order by key;

--_set_value
SELECT * FROM _set_value('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage','<Entity/>');
select * from value_actual order by key;

SELECT * FROM tem


