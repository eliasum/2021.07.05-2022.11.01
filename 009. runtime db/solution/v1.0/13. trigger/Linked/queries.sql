/*2022.01.14 11:07 IMM*/

DROP TABLE table_glossary;

DROP TABLE table_number;
DROP TABLE table_float;
DROP TABLE table_decimal;
DROP TABLE table_string;

DROP TABLE number_actual;
DROP TABLE float_actual;
DROP TABLE decimal_actual;
DROP TABLE string_actual;
/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION before_insert_in_glossary()
  RETURNS TRIGGER AS
$$
DECLARE 

	_Table TEXT;  

BEGIN
	
	CASE 
		  WHEN NEW.tablename = 'number_actual' 	THEN NEW.tablename := '111';
		  WHEN NEW.tablename = 'float_actual' 	THEN NEW.tablename := '222';
		  WHEN NEW.tablename = 'decimal_actual'	THEN NEW.tablename := '333';
		  WHEN NEW.tablename = 'string_actual' 	THEN NEW.tablename := '444';
	END CASE;
	
	RETURN NEW;
	
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER existence_check_creation_table 
  BEFORE INSERT
  ON table_glossary
  FOR EACH ROW
  EXECUTE PROCEDURE before_insert_in_glossary();
/*-------------------------------------------------------------------------------------------------*/
CREATE TABLE table_glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);

INSERT INTO table_glossary (configuration, communication, allowance, tablename) VALUES 
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float_actual');
select * from table_glossary;

select * from number_actual;