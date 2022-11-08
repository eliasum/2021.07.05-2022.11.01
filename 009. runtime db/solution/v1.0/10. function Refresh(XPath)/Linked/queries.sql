/*2021.12.03 14:16 IMM*/

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

select * from search_columns('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage');

select * from search_columns('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage','{table_glossary}');

/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION Refresh_(xpath VARCHAR, value_ VARCHAR)
RETURNS INT AS $$
DECLARE 
    DEBUG_ENABLED INT;  
	
BEGIN
	
	DEBUG_ENABLED := 0;
	
        IF DEBUG_ENABLED > 0  THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;  

END;

$$ LANGUAGE plpgsql;

select * from Refresh_('111','111');
/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION return_int() RETURNS int AS
$$
BEGIN
  RETURN 1;
END
$$ LANGUAGE plpgsql;

SELECT * FROM return_int();
/*-------------------------------------------------------------------------------------------------*/
select exists(select 'ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage' from table_glossary);
select exists(select '111' from table_glossary);

select * from _Refresh('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage');
select * from _Refresh('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage');
select * from _Refresh('111');
select * from NumberActual;

SELECT EXISTS
(SELECT 1 
FROM table_glossary 
WHERE configuration = 'ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage') AS "exists"

SELECT EXISTS
(SELECT 1 
FROM table_glossary 
WHERE configuration = '111') AS "exists"

SELECT val FROM NumberActual ORDER BY NumberActKey DESC LIMIT 1
SELECT val FROM NumberActual ORDER BY NumberActKey DESC

CREATE TABLE aaaaa(a1 INTEGER, a2 text, a3 DOUBLE PRECISION);

SELECT pga.attname
FROM pg_catalog.pg_attribute AS pga, pg_catalog.pg_class AS pgc 
WHERE pga.attrelid=pgc.oid AND pgc.relname='aaaaa';