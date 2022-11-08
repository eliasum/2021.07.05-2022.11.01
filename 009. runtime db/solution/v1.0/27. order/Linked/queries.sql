/*2022.03.16 17:31 IMM*/

-----------------------------------------------------------------------------------------------------

--тестирование _order(_xpath VARCHAR, _value VARCHAR) 

INSERT INTO order_actual(key, fix, value) VALUES(1, NOW(), '1');

select * from order_actual

SELECT * FROM _order('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage','2');

select * from order_actual

SELECT * FROM _order('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage','22');

select * from order_actual

SELECT * FROM _order('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage','22');

select * from order_archive