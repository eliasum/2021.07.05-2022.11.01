INSERT INTO text_actual(key, fix, value) VALUES(1, NOW(), 'asasasas!!!');



SELECT * FROM _test('asasasas!!!'::TEXT);


SELECT * FROM integer_actual

SELECT * FROM text_actual

SELECT * FROM text_actual WHERE value = 'asasasas!!!'

SELECT * FROM _communication('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage',1);
SELECT * FROM _communication('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045СЕ87'']/Adress/Item[@key=''40'']/Channel/Item[@key=''B'']/Amperage','asasasas!!!'::TEXT);