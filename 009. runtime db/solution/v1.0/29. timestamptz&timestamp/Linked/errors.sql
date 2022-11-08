--SELECT * FROM Glossary WHERE communication = 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Voltage'
--SELECT * FROM _communication('Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Voltage', 0.0000);
----
ERROR:  new row for relation "_hyper_1_1_chunk" violates check constraint "constraint_1"
DETAIL:  Failing row contains (121, 2022-03-30 11:22:29.957286+07, 20).
CONTEXT:  SQL statement "UPDATE integer_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 161);"
PL/pgSQL function _communication(character varying,anyelement) line 97 at EXECUTE
SQL-состояние: 23514

--SELECT * FROM integer_archive WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 161) AND key = 161

UPDATE integer_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM integer_archive WHERE key = 161) AND key = 161
----------
ERROR:  new row for relation "_hyper_1_1_chunk" violates check constraint "constraint_1"
DETAIL:  Failing row contains (161, 2022-03-30 11:19:28.126371+07, 0).
SQL-состояние: 23514