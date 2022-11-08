/*
2021.12.03 14:16 IMM

https://codengineering.ru/q/how-to-search-a-specific-value-in-all-tables-postgresql-8189

вот функция pl/pgsql, которая находит записи, где любой столбец содержит определенное значение. 
Он принимает в качестве аргументов значение для поиска в текстовом формате, массив имен таблиц 
для поиска (по умолчанию для всех таблиц) и массив имен схем (по умолчанию для всех имен схем).

он возвращает структуру таблицы со схемой, имя таблицы, имя столбца и псевдо-столбец ctid 
(недолговечное физическое расположение строки в таблице, см. Колонки)
*/
CREATE OR REPLACE FUNCTION search_columns(
    needle text,
    haystack_tables name[] default '{}',
    haystack_schema name[] default '{}'
)
RETURNS table(schemaname text, tablename text, columnname text, rowctid text)
AS $$
begin
  FOR schemaname,tablename,columnname IN
      SELECT c.table_schema,c.table_name,c.column_name
      FROM information_schema.columns c
      JOIN information_schema.tables t ON
        (t.table_name=c.table_name AND t.table_schema=c.table_schema)
      WHERE (c.table_name=ANY(haystack_tables) OR haystack_tables='{}')
        AND (c.table_schema=ANY(haystack_schema) OR haystack_schema='{}')
        AND t.table_type='BASE TABLE'
  LOOP
    EXECUTE format('SELECT ctid FROM %I.%I WHERE cast(%I as text)=%L',
       schemaname,
       tablename,
       columnname,
       needle
    ) INTO rowctid;
    IF rowctid is not null THEN
      RETURN NEXT;
    END IF;
 END LOOP;
END;
$$ language plpgsql;
/*-------------------------------------------------------------------------------------------------*/
/*Функция, возвращающая значение key записи таблицы table_glossary (входной параметр xpath)*/
CREATE OR REPLACE FUNCTION _Refresh(xpath VARCHAR, _value VARCHAR)
RETURNS INTEGER AS $$
DECLARE 

    _Path VARCHAR; 
	_Id INTEGER;
	
BEGIN
	
	_Path := xpath;
	
        IF (SELECT EXISTS(SELECT 1 from table_glossary WHERE configuration = _Path)) THEN
            RETURN (SELECT key FROM table_glossary WHERE configuration = _Path);
        ELSE
            RETURN NULL;
        END IF;  

END;

$$ LANGUAGE plpgsql;
/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION foo(_path VARCHAR)
RETURNS FLOAT AS $$
DECLARE 

	_Table TEXT;
	_Value FLOAT;
	
BEGIN

        IF (SELECT EXISTS(SELECT 1 from _glossary WHERE configuration = _path)) THEN
			_Table := (SELECT tablename FROM _glossary WHERE configuration = _path);
        ELSE
            _Table := NULL;
        END IF;  
	
		EXECUTE FORMAT('SELECT val FROM %I ORDER BY key DESC LIMIT 1', _Table) INTO _Value;
		RETURN _Value;
		
END;

$$ LANGUAGE plpgsql;