--ошибочный запрос
SELECT * FROM _communication('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Illuminator/Item[@key=''1'']/Amperage', 0);

--проверка наличия записи в таблице glossary
SELECT * FROM glossary where configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Illuminator/Item[@key=''1'']/Amperage';

--проверка ключа (строка 70 функции _communication('XPath',Value))
SELECT EXISTS(SELECT 1 from float_actual WHERE key = 11);

SELECT 1 from glossary WHERE communication = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Illuminator/Item[@key=''1'']/Amperage';
SELECT 1 from glossary WHERE configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Illuminator/Item[@key=''1'']/Amperage';

SELECT * FROM _order('Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Amperage', '22');

SELECT * FROM glossary where configuration = 'Configuration[@key=''_036CE062.ControlWorkstation'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Equipment[@key=''_036CE062'']/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Amperage';