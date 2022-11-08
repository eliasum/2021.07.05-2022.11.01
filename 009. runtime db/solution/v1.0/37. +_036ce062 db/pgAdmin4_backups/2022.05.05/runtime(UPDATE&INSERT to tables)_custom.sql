PGDMP     9    1    
            z            runtime    9.6.24    9.6.24 e    
           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            
           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            
           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            
           1262    93802    runtime    DATABASE     �   CREATE DATABASE runtime WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Russian_Russia.1251' LC_CTYPE = 'Russian_Russia.1251';
    DROP DATABASE runtime;
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            
           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                  postgres    false    4                        3079    93803    timescaledb 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;
    DROP EXTENSION timescaledb;
                  false    4            
           0    0    EXTENSION timescaledb    COMMENT     i   COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';
                       false    2                        3079    12387    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            
           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1            �           1255    94464     _communication(text, anyelement)    FUNCTION        CREATE FUNCTION public._communication(xpath text, valuenew anyelement) RETURNS void
    LANGUAGE plpgsql
    AS $$

	--Сбор информации с оборудования в БД

	--Использование функции:
	--SELECT * FROM _communication(XPath,Value);

DECLARE 

	--переменные для:
	_TableName VARCHAR(30);			--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table VARCHAR(30);				--имени актуальной таблицы  
	_HyperTable VARCHAR(30);		--имени соответствующей гипер таблицы
	_ValueOld FLOAT;				--последнего значения 3-го поля val из гипертаблицы
	_DateOld DATE;					--даты последнего значения 2-го поля fix из гипертаблицы
	_Delta FLOAT;					--получения разницы в % между старым и новым значениями val гипертаблицы  
	_Key INTEGER;					--значения ключа таблицы glossary  
	_Existence BOOLEAN;				--признак существования в таблице _Table записи с ключом _Key
	_MaxFixArchive TIMESTAMP;		--последний фикс гипертаблицы по ключу _Key
	_MaxFixSynchro TIMESTAMP;		--последний фикс таблицы synchronization
	
BEGIN
		
									--получение имён актуальной и гипертаблицы
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	ELSE
		_Key := NULL;
	END IF;  	
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE communication = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table 		:= _TableName || '_actual';
	ELSE
		_Table 		:= NULL;
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 
					
	--Приведение типа valueNew к INTEGER, если valueNew из таблицы integer_archive 
	IF(_TableName = 'integer') THEN
	valueNew := valueNew::INTEGER;
	END IF; 

									--заполнение актуальной таблицы
	--Проверка существования в актуальной таблице _Table записи с ключом _Key 
	EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from %I WHERE key = %s)', _Table, _Key) INTO _Existence;

	IF (_Existence) THEN
		EXECUTE FORMAT('UPDATE %I SET fix = NOW(), value = %s WHERE key = %s;', _Table, valueNew, _Key);
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _Table, _Key, valueNew);
	END IF; 
	
									--заполнение гипертаблицы при синхронизации
	--Вычислить последние фиксы в гипертаблице и таблице synchronization
	EXECUTE FORMAT('SELECT MAX(fix) FROM %I;', _HyperTable) INTO _MaxFixArchive;
	
	IF (_MaxFixArchive IS NULL) THEN
		_MaxFixArchive := '-infinity'::timestamp;
	END IF;
	
	SELECT INTO _MaxFixSynchro (SELECT MAX(fix) FROM synchronization);	
	
	IF (_MaxFixSynchro IS NULL) THEN
		_MaxFixSynchro := '-infinity'::timestamp;
	END IF;

	--Если после синхронизации не было записи в гипертаблицу, то сделать 2 записи в гипертаблице
	IF(_MaxFixSynchro > _MaxFixArchive) THEN
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
	ELSE
	END IF;	

									--заполнение гипертаблицы после синхронизации
	--Получение старого значения value из гипертаблицы
	EXECUTE FORMAT('SELECT value FROM %I WHERE key = %s ORDER BY fix DESC LIMIT 1;', _HyperTable, _Key) INTO _ValueOld;
	
	--Получение старого значения date из гипертаблицы
	EXECUTE FORMAT('SELECT fix::date FROM %I WHERE key = %s ORDER BY fix DESC LIMIT 1;', _HyperTable, _Key) INTO _DateOld;

	--Если старого значения в гипертаблице нет
	IF(_ValueOld IS NULL) THEN
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
	ELSE
		--Приведение типа _ValueOld к INTEGER, если _ValueOld из таблицы integer_archive 
		IF(_TableName = 'integer') THEN
		_ValueOld := _ValueOld::INTEGER;
		END IF; 
		
		--Получение разницы в % между старым и новым значениями:
		--Если старое значение не равно 0
		IF(_ValueOld <> 0) THEN
			_Delta := ABS(_ValueOld - valueNew) * 100 / _ValueOld;
		ELSE
			--Если новое значение не равно 0
			IF(valueNew <> 0) THEN
				_Delta := ABS(_ValueOld - valueNew) * 100 / valueNew;
			ELSE
				_Delta := NULL;
			END IF;
		END IF;	
		
		--Если старое и новое значения различаются	
		IF(_Delta IS NOT NULL AND _Delta <> 0) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
		ELSE
			--Если старая и новая даты совпадают	
			IF(_DateOld = CURRENT_DATE) THEN
				EXECUTE FORMAT('UPDATE %I SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM %I WHERE key = %s) AND key = %s;', _HyperTable, _HyperTable, _Key, _Key);
			ELSE
				EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
				EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
			END IF;	
		END IF;	
	END IF;
	
END;

$$;
 F   DROP FUNCTION public._communication(xpath text, valuenew anyelement);
       public       postgres    false    1    4            �           1255    94422    _order()    FUNCTION       CREATE FUNCTION public._order() RETURNS TABLE(_xpath text, fix timestamp without time zone, _value text)
    LANGUAGE plpgsql
    AS $$

	--Функция, возвращающая видоизменённую таблицу order_actual

	--Использование функции:
	--SELECT * FROM _order();
	
BEGIN

	--создание временной таблицы и запись в неё запроса
	CREATE TEMPORARY TABLE tempo ON COMMIT DROP AS 
	SELECT glossary.communication, order_actual.fix, order_actual.value
	FROM order_actual  
	INNER JOIN glossary ON order_actual.key = glossary.key;
	
	--очистить таблицу order_actual
	TRUNCATE order_actual RESTART IDENTITY;

	RETURN QUERY SELECT * FROM tempo;

END;

$$;
    DROP FUNCTION public._order();
       public       postgres    false    1    4            �           1255    94421    _order(text, text)    FUNCTION     �  CREATE FUNCTION public._order(_xpath text, _value text) RETURNS void
    LANGUAGE plpgsql
    AS $$

	--Функция заполнения таблиц order_actual и order_archive

	--Использование функции:
	--SELECT * FROM _order(XPath,Value);

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary  
	_Existence BOOLEAN;		--признак существования в таблице order_actual записи с ключом _Key
	
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = _xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE communication = _xpath);
	ELSE
		_Key := NULL;
	END IF;  	
	
	--Проверка существования в таблице order_actual записи с ключом _Key 
	SELECT INTO _Existence (SELECT EXISTS(SELECT 1 from order_actual WHERE key = _Key));

	IF (_Existence) THEN
		UPDATE order_actual SET fix = NOW(), value = _value WHERE key = _Key;
	ELSE
		INSERT INTO order_actual(key, fix, value) VALUES(_Key, NOW(), _value);
	END IF;  

	--вставить новую запись в таблицу order_archive
	INSERT INTO order_archive(key, fix, value) VALUES(_Key, NOW(), _value);

END;

$$;
 7   DROP FUNCTION public._order(_xpath text, _value text);
       public       postgres    false    4    1            �           1255    94417 
   _refresh()    FUNCTION     �  CREATE FUNCTION public._refresh() RETURNS TABLE(configuration text, fix timestamp without time zone, value_float double precision, value_integer integer)
    LANGUAGE plpgsql
    AS $$

	--Обновление активной информации в ПО из БД, возврат записей из всех активных таблиц

	--Использование функции:
	--SELECT * FROM _refresh();

DECLARE 
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.configuration AS config, float_actual.fix AS fix, float_actual.value AS value_float, NULL AS value_integer
	FROM glossary AS g
	INNER JOIN float_actual ON g.key = float_actual.key 
	UNION
	SELECT g.configuration AS config, integer_actual.fix AS fix, NULL AS value_float, integer_actual.value AS value_integer
	FROM glossary AS g
	INNER JOIN integer_actual ON g.key = integer_actual.key;
	');			
	
END;

$$;
 !   DROP FUNCTION public._refresh();
       public       postgres    false    1    4            �           1255    94416    _refresh(text)    FUNCTION     �  CREATE FUNCTION public._refresh(xpath text) RETURNS record
    LANGUAGE plpgsql
    AS $$

	--Обновление активной информации в ПО из БД, возврат одной записи из актуальной таблицы

	--Использование функции:
	--SELECT * FROM _refresh(XPath) AS (key INTEGER, fix TIMESTAMP, value FLOAT); - возврат записи из float_actual
	--SELECT * FROM _refresh(XPath) AS (key INTEGER, fix TIMESTAMP, value INTEGER); - возврат записи из integer_actual

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary
	_TableName VARCHAR(30);	--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table VARCHAR(30);		--имени актуальной таблицы  
	
	ret RECORD;				--возвращаемая запись
		
BEGIN
		
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := NULL;
	END IF;  
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table := _TableName || '_actual';
	ELSE
		_Table := NULL;
	END IF;  

	--Получение одной записи из актуальной таблицы
	IF (_Table IS NOT NULL) THEN
		EXECUTE FORMAT('
		SELECT %I.key, %I.fix, %I.value
		FROM %I 
		INNER JOIN glossary ON %I.key = %s
		', _Table, _Table, _Table
		 , _Table
		 , _Table, _Key) INTO ret;
	END IF;  
	
	--Возврат записи
	RETURN ret;
	
END;

$$;
 +   DROP FUNCTION public._refresh(xpath text);
       public       postgres    false    4    1            �           1255    94419 E   _refreshold(timestamp without time zone, timestamp without time zone)    FUNCTION     �  CREATE FUNCTION public._refreshold(st timestamp without time zone, fin timestamp without time zone) RETURNS TABLE(_key integer, configuration text, fix timestamp without time zone, value_float double precision, value_integer integer)
    LANGUAGE plpgsql
    AS $$

	--Обновление архивной информации в ПО из БД, возврат записей из всех гипертаблиц от st до fin
	
	--Использование функции:
	--SELECT * FROM _refreshold(St, Fin);

DECLARE 
		
BEGIN

	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.key AS key, g.configuration AS config, float_archive.fix AS fix, float_archive.value AS value_float, NULL AS value_integer
	FROM glossary AS g
	INNER JOIN float_archive ON g.key = float_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	UNION
	SELECT g.key AS key, configuration AS config, integer_archive.fix AS fix, NULL AS value_float, integer_archive.value AS value_integer
	FROM glossary AS g
	INNER JOIN integer_archive ON g.key = integer_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	ORDER BY key;
	', st, fin, st, fin);
	
END;

$$;
 c   DROP FUNCTION public._refreshold(st timestamp without time zone, fin timestamp without time zone);
       public       postgres    false    1    4            �           1255    94418 K   _refreshold(text, timestamp without time zone, timestamp without time zone)    FUNCTION     �  CREATE FUNCTION public._refreshold(xpath text, st timestamp without time zone, fin timestamp without time zone) RETURNS TABLE(_key integer, fix timestamp without time zone, _value double precision)
    LANGUAGE plpgsql
    AS $$

	--Обновление архивной информации в ПО из БД, возврат записей из гипертаблицы от st до fin
	
	--Использование функции:
	--SELECT * FROM _refreshold(XPath, St, Fin);

DECLARE 

	--переменные для:
	_Key INTEGER;				--значения ключа таблицы glossary
	_TableName VARCHAR(30);		--значения 4-го поля таблицы glossary, формирующего _HyperTable    
	_HyperTable VARCHAR(30);	--имени гипертаблицы  
		
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := NULL;
	END IF;  
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN 
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 

	RETURN QUERY EXECUTE FORMAT('	
	SELECT %I.key, %I.fix, %I.value
	FROM %I 
	INNER JOIN glossary ON %I.key = %s
	WHERE %I.fix BETWEEN ''%s'' AND ''%s'';
	', _HyperTable, _HyperTable, _HyperTable,
	_HyperTable,
	_HyperTable, _Key,
	_HyperTable, st, fin);

END;

$$;
 o   DROP FUNCTION public._refreshold(xpath text, st timestamp without time zone, fin timestamp without time zone);
       public       postgres    false    1    4            �           1255    94420    _synchronizer(text, text)    FUNCTION     n  CREATE FUNCTION public._synchronizer(_xpath text, _status text) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$

	--Функция заполнения таблицы синхронизации synchronization table

	--Использование функции:
	--SELECT * FROM _communication(XPath,Status);
	
BEGIN
		
	INSERT INTO synchronization (xpath, fix, status) VALUES (_xpath, NOW(), _status);
	
	--очистить таблицы integer_actual и float_actual
	TRUNCATE integer_actual RESTART IDENTITY;
	TRUNCATE float_actual RESTART IDENTITY;
	
	RETURN NOW();

END;

$$;
 ?   DROP FUNCTION public._synchronizer(_xpath text, _status text);
       public       postgres    false    1    4            �           1255    94348    before_insert_in_glossary()    FUNCTION     �  CREATE FUNCTION public.before_insert_in_glossary() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 

	--переменные для:
	_TableName VARCHAR(30);		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table VARCHAR(30);			--имени актуальной таблицы  
	_HyperTable VARCHAR(30);	--имени соответствующей гипертаблицы

BEGIN
	--NEW.tablename - значение поля tablename таблицы glossary, 
	--которое будет вставлено в новую запись glossary
	_TableName := NEW.tablename;
	
	_Table 		 := _TableName  || '_actual';
	_HyperTable  := _TableName	|| '_archive';
				
	--Создание актуальной и гипертаблицы, если они не существуют, 
	--исходя из значения поля tablename таблицы glossary	
	
	EXECUTE FORMAT('
	CREATE TABLE IF NOT EXISTS %I(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));

	SELECT create_hypertable(
	''%I'', ''fix'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));',
	_HyperTable, 	
	_TableName,
	
	_HyperTable,	
	
	_Table,			
	_TableName);	
	
	RETURN NEW; 
	
END;

$$;
 2   DROP FUNCTION public.before_insert_in_glossary();
       public       postgres    false    1    4            �            1259    94378    integer_archive    TABLE     �   CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);
 #   DROP TABLE public.integer_archive;
       public         postgres    false    4            �            1259    94439    _hyper_1_2_chunk    TABLE     �   CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);
 3   DROP TABLE _timescaledb_internal._hyper_1_2_chunk;
       _timescaledb_internal         postgres    false    2    238            �            1259    94454    _hyper_1_3_chunk    TABLE     �   CREATE TABLE _timescaledb_internal._hyper_1_3_chunk (
    CONSTRAINT constraint_3 CHECK (((fix >= '2022-05-05 00:00:00'::timestamp without time zone) AND (fix < '2022-05-06 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);
 3   DROP TABLE _timescaledb_internal._hyper_1_3_chunk;
       _timescaledb_internal         postgres    false    238    2            �            1259    94396    float_archive    TABLE     �   CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);
 !   DROP TABLE public.float_archive;
       public         postgres    false    4            �            1259    94429    _hyper_2_1_chunk    TABLE     �   CREATE TABLE _timescaledb_internal._hyper_2_1_chunk (
    CONSTRAINT constraint_1 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);
 3   DROP TABLE _timescaledb_internal._hyper_2_1_chunk;
       _timescaledb_internal         postgres    false    2    240            �            1259    94466    _hyper_2_4_chunk    TABLE     �   CREATE TABLE _timescaledb_internal._hyper_2_4_chunk (
    CONSTRAINT constraint_4 CHECK (((fix >= '2022-05-05 00:00:00'::timestamp without time zone) AND (fix < '2022-05-06 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);
 3   DROP TABLE _timescaledb_internal._hyper_2_4_chunk;
       _timescaledb_internal         postgres    false    2    240            �            1259    94406    float_actual    TABLE     �   CREATE TABLE public.float_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);
     DROP TABLE public.float_actual;
       public         postgres    false    4            �            1259    94337    glossary    TABLE     �   CREATE TABLE public.glossary (
    key integer NOT NULL,
    communication text NOT NULL,
    configuration text,
    tablename character varying(30) NOT NULL
);
    DROP TABLE public.glossary;
       public         postgres    false    4            
           0    0    TABLE glossary    COMMENT     i   COMMENT ON TABLE public.glossary IS 'Словарь для индефикации переменных';
            public       postgres    false    234            
           0    0    COLUMN glossary.key    COMMENT     �   COMMENT ON COLUMN public.glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';
            public       postgres    false    234            
           0    0    COLUMN glossary.communication    COMMENT     �   COMMENT ON COLUMN public.glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
            public       postgres    false    234            
           0    0    COLUMN glossary.configuration    COMMENT     �   COMMENT ON COLUMN public.glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
            public       postgres    false    234            
           0    0    COLUMN glossary.tablename    COMMENT     �   COMMENT ON COLUMN public.glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';
            public       postgres    false    234            �            1259    94335    glossary_key_seq    SEQUENCE     y   CREATE SEQUENCE public.glossary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.glossary_key_seq;
       public       postgres    false    4    234            
           0    0    glossary_key_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.glossary_key_seq OWNED BY public.glossary.key;
            public       postgres    false    233            �            1259    94388    integer_actual    TABLE     �   CREATE TABLE public.integer_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);
 "   DROP TABLE public.integer_actual;
       public         postgres    false    4            �            1259    94356    order_actual    TABLE     �   CREATE TABLE public.order_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);
     DROP TABLE public.order_actual;
       public         postgres    false    4            �            1259    94367    order_archive    TABLE     �   CREATE TABLE public.order_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);
 !   DROP TABLE public.order_archive;
       public         postgres    false    4            �            1259    94350    synchronization    TABLE     �   CREATE TABLE public.synchronization (
    xpath text NOT NULL,
    fix timestamp without time zone NOT NULL,
    status text NOT NULL
);
 #   DROP TABLE public.synchronization;
       public         postgres    false    4            g	           2604    94340    glossary key    DEFAULT     l   ALTER TABLE ONLY public.glossary ALTER COLUMN key SET DEFAULT nextval('public.glossary_key_seq'::regclass);
 ;   ALTER TABLE public.glossary ALTER COLUMN key DROP DEFAULT;
       public       postgres    false    234    233    234            P	          0    94249    cache_inval_bgw_job 
   TABLE DATA               9   COPY _timescaledb_cache.cache_inval_bgw_job  FROM stdin;
    _timescaledb_cache       postgres    false    222   m�       O	          0    94252    cache_inval_extension 
   TABLE DATA               ;   COPY _timescaledb_cache.cache_inval_extension  FROM stdin;
    _timescaledb_cache       postgres    false    223   ��       N	          0    94246    cache_inval_hypertable 
   TABLE DATA               <   COPY _timescaledb_cache.cache_inval_hypertable  FROM stdin;
    _timescaledb_cache       postgres    false    221   ��       5	          0    93820 
   hypertable 
   TABLE DATA               �   COPY _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compressed, compressed_hypertable_id) FROM stdin;
    _timescaledb_catalog       postgres    false    193   Ķ       <	          0    93894    chunk 
   TABLE DATA               w   COPY _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped) FROM stdin;
    _timescaledb_catalog       postgres    false    201   ?�       8	          0    93859 	   dimension 
   TABLE DATA               �   COPY _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, integer_now_func_schema, integer_now_func) FROM stdin;
    _timescaledb_catalog       postgres    false    197   ��       :	          0    93878    dimension_slice 
   TABLE DATA               a   COPY _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) FROM stdin;
    _timescaledb_catalog       postgres    false    199   ��       >	          0    93915    chunk_constraint 
   TABLE DATA               �   COPY _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) FROM stdin;
    _timescaledb_catalog       postgres    false    202   >�       
           0    0    chunk_constraint_name    SEQUENCE SET     Q   SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 4, true);
            _timescaledb_catalog       postgres    false    203            
           0    0    chunk_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 4, true);
            _timescaledb_catalog       postgres    false    200            @	          0    93933    chunk_index 
   TABLE DATA               o   COPY _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) FROM stdin;
    _timescaledb_catalog       postgres    false    204   ø       L	          0    94118    compression_chunk_size 
   TABLE DATA               �   COPY _timescaledb_catalog.compression_chunk_size (chunk_id, compressed_chunk_id, uncompressed_heap_size, uncompressed_toast_size, uncompressed_index_size, compressed_heap_size, compressed_toast_size, compressed_index_size) FROM stdin;
    _timescaledb_catalog       postgres    false    219   2�       B	          0    93951    bgw_job 
   TABLE DATA               �   COPY _timescaledb_config.bgw_job (id, application_name, job_type, schedule_interval, max_runtime, max_retries, retry_period) FROM stdin;
    _timescaledb_config       postgres    false    206   O�       F	          0    94030    continuous_agg 
   TABLE DATA               %  COPY _timescaledb_catalog.continuous_agg (mat_hypertable_id, raw_hypertable_id, user_view_schema, user_view_name, partial_view_schema, partial_view_name, bucket_width, job_id, refresh_lag, direct_view_schema, direct_view_name, max_interval_per_job, ignore_invalidation_older_than) FROM stdin;
    _timescaledb_catalog       postgres    false    212   l�       H	          0    94068 #   continuous_aggs_completed_threshold 
   TABLE DATA               j   COPY _timescaledb_catalog.continuous_aggs_completed_threshold (materialization_id, watermark) FROM stdin;
    _timescaledb_catalog       postgres    false    214   ��       I	          0    94078 +   continuous_aggs_hypertable_invalidation_log 
   TABLE DATA               �   COPY _timescaledb_catalog.continuous_aggs_hypertable_invalidation_log (hypertable_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
    _timescaledb_catalog       postgres    false    215   ��       G	          0    94058 &   continuous_aggs_invalidation_threshold 
   TABLE DATA               h   COPY _timescaledb_catalog.continuous_aggs_invalidation_threshold (hypertable_id, watermark) FROM stdin;
    _timescaledb_catalog       postgres    false    213   ù       J	          0    94082 0   continuous_aggs_materialization_invalidation_log 
   TABLE DATA               �   COPY _timescaledb_catalog.continuous_aggs_materialization_invalidation_log (materialization_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
    _timescaledb_catalog       postgres    false    216   �       
           0    0    dimension_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 2, true);
            _timescaledb_catalog       postgres    false    196             
           0    0    dimension_slice_id_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 4, true);
            _timescaledb_catalog       postgres    false    198            K	          0    94099    hypertable_compression 
   TABLE DATA               �   COPY _timescaledb_catalog.hypertable_compression (hypertable_id, attname, compression_algorithm_id, segmentby_column_index, orderby_column_index, orderby_asc, orderby_nullsfirst) FROM stdin;
    _timescaledb_catalog       postgres    false    218   ��       !
           0    0    hypertable_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 2, true);
            _timescaledb_catalog       postgres    false    192            E	          0    94022    metadata 
   TABLE DATA               R   COPY _timescaledb_catalog.metadata (key, value, include_in_telemetry) FROM stdin;
    _timescaledb_catalog       postgres    false    211   �       7	          0    93844 
   tablespace 
   TABLE DATA               V   COPY _timescaledb_catalog.tablespace (id, hypertable_id, tablespace_name) FROM stdin;
    _timescaledb_catalog       postgres    false    195   `�       "
           0    0    bgw_job_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1000, false);
            _timescaledb_config       postgres    false    205            M	          0    94133    bgw_policy_compress_chunks 
   TABLE DATA               d   COPY _timescaledb_config.bgw_policy_compress_chunks (job_id, hypertable_id, older_than) FROM stdin;
    _timescaledb_config       postgres    false    220   }�       D	          0    93986    bgw_policy_drop_chunks 
   TABLE DATA               �   COPY _timescaledb_config.bgw_policy_drop_chunks (job_id, hypertable_id, older_than, cascade, cascade_to_materializations) FROM stdin;
    _timescaledb_config       postgres    false    209   ��       C	          0    93969    bgw_policy_reorder 
   TABLE DATA               g   COPY _timescaledb_config.bgw_policy_reorder (job_id, hypertable_id, hypertable_index_name) FROM stdin;
    _timescaledb_config       postgres    false    208   ��       
          0    94439    _hyper_1_2_chunk 
   TABLE DATA               J   COPY _timescaledb_internal._hyper_1_2_chunk (key, fix, value) FROM stdin;
    _timescaledb_internal       postgres    false    243   Ժ       
          0    94454    _hyper_1_3_chunk 
   TABLE DATA               J   COPY _timescaledb_internal._hyper_1_3_chunk (key, fix, value) FROM stdin;
    _timescaledb_internal       postgres    false    244   ��       

          0    94429    _hyper_2_1_chunk 
   TABLE DATA               J   COPY _timescaledb_internal._hyper_2_1_chunk (key, fix, value) FROM stdin;
    _timescaledb_internal       postgres    false    242   O�       
          0    94466    _hyper_2_4_chunk 
   TABLE DATA               J   COPY _timescaledb_internal._hyper_2_4_chunk (key, fix, value) FROM stdin;
    _timescaledb_internal       postgres    false    245   ��       	
          0    94406    float_actual 
   TABLE DATA               7   COPY public.float_actual (key, fix, value) FROM stdin;
    public       postgres    false    241   �       
          0    94396    float_archive 
   TABLE DATA               8   COPY public.float_archive (key, fix, value) FROM stdin;
    public       postgres    false    240   ��       
          0    94337    glossary 
   TABLE DATA               P   COPY public.glossary (key, communication, configuration, tablename) FROM stdin;
    public       postgres    false    234   ��       #
           0    0    glossary_key_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.glossary_key_seq', 240, true);
            public       postgres    false    233            
          0    94388    integer_actual 
   TABLE DATA               9   COPY public.integer_actual (key, fix, value) FROM stdin;
    public       postgres    false    239   ��       
          0    94378    integer_archive 
   TABLE DATA               :   COPY public.integer_archive (key, fix, value) FROM stdin;
    public       postgres    false    238   ��       
          0    94356    order_actual 
   TABLE DATA               7   COPY public.order_actual (key, fix, value) FROM stdin;
    public       postgres    false    236   ��       
          0    94367    order_archive 
   TABLE DATA               8   COPY public.order_archive (key, fix, value) FROM stdin;
    public       postgres    false    237   ��       
          0    94350    synchronization 
   TABLE DATA               =   COPY public.synchronization (xpath, fix, status) FROM stdin;
    public       postgres    false    235   �       m	           2606    94347 #   glossary glossary_communication_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_communication_key UNIQUE (communication);
 M   ALTER TABLE ONLY public.glossary DROP CONSTRAINT glossary_communication_key;
       public         postgres    false    234    234            o	           2606    94345    glossary glossary_key 
   CONSTRAINT     T   ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);
 ?   ALTER TABLE ONLY public.glossary DROP CONSTRAINT glossary_key;
       public         postgres    false    234    234            s	           1259    94448 (   _hyper_1_2_chunk_integer_archive_fix_idx    INDEX     x   CREATE INDEX _hyper_1_2_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (fix DESC);
 K   DROP INDEX _timescaledb_internal._hyper_1_2_chunk_integer_archive_fix_idx;
       _timescaledb_internal         postgres    false    243            t	           1259    94463 (   _hyper_1_3_chunk_integer_archive_fix_idx    INDEX     x   CREATE INDEX _hyper_1_3_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree (fix DESC);
 K   DROP INDEX _timescaledb_internal._hyper_1_3_chunk_integer_archive_fix_idx;
       _timescaledb_internal         postgres    false    244            r	           1259    94438 &   _hyper_2_1_chunk_float_archive_fix_idx    INDEX     v   CREATE INDEX _hyper_2_1_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (fix DESC);
 I   DROP INDEX _timescaledb_internal._hyper_2_1_chunk_float_archive_fix_idx;
       _timescaledb_internal         postgres    false    242            u	           1259    94475 &   _hyper_2_4_chunk_float_archive_fix_idx    INDEX     v   CREATE INDEX _hyper_2_4_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (fix DESC);
 I   DROP INDEX _timescaledb_internal._hyper_2_4_chunk_float_archive_fix_idx;
       _timescaledb_internal         postgres    false    245            q	           1259    94405    float_archive_fix_idx    INDEX     S   CREATE INDEX float_archive_fix_idx ON public.float_archive USING btree (fix DESC);
 )   DROP INDEX public.float_archive_fix_idx;
       public         postgres    false    240            p	           1259    94387    integer_archive_fix_idx    INDEX     W   CREATE INDEX integer_archive_fix_idx ON public.integer_archive USING btree (fix DESC);
 +   DROP INDEX public.integer_archive_fix_idx;
       public         postgres    false    238            �	           2620    94349 *   glossary existence_check_or_creation_table    TRIGGER     �   CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();
 C   DROP TRIGGER existence_check_or_creation_table ON public.glossary;
       public       postgres    false    384    234            �	           2620    94404    float_archive ts_insert_blocker    TRIGGER     �   CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.float_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();
 8   DROP TRIGGER ts_insert_blocker ON public.float_archive;
       public       postgres    false    2    2    240            �	           2620    94386 !   integer_archive ts_insert_blocker    TRIGGER     �   CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.integer_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();
 :   DROP TRIGGER ts_insert_blocker ON public.integer_archive;
       public       postgres    false    2    2    238            |	           2606    94433 +   _hyper_2_1_chunk 1_1_float_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk
    ADD CONSTRAINT "1_1_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);
 f   ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk DROP CONSTRAINT "1_1_float_archive_key_fkey";
       _timescaledb_internal       postgres    false    234    242    2415            }	           2606    94443 -   _hyper_1_2_chunk 2_2_integer_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);
 h   ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk DROP CONSTRAINT "2_2_integer_archive_key_fkey";
       _timescaledb_internal       postgres    false    2415    243    234            ~	           2606    94458 -   _hyper_1_3_chunk 3_3_integer_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk
    ADD CONSTRAINT "3_3_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);
 h   ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk DROP CONSTRAINT "3_3_integer_archive_key_fkey";
       _timescaledb_internal       postgres    false    2415    234    244            	           2606    94470 +   _hyper_2_4_chunk 4_4_float_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk
    ADD CONSTRAINT "4_4_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);
 f   ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk DROP CONSTRAINT "4_4_float_archive_key_fkey";
       _timescaledb_internal       postgres    false    234    245    2415            {	           2606    94409 "   float_actual float_actual_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.float_actual
    ADD CONSTRAINT float_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 L   ALTER TABLE ONLY public.float_actual DROP CONSTRAINT float_actual_key_fkey;
       public       postgres    false    234    241    2415            z	           2606    94399 $   float_archive float_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.float_archive
    ADD CONSTRAINT float_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 N   ALTER TABLE ONLY public.float_archive DROP CONSTRAINT float_archive_key_fkey;
       public       postgres    false    240    2415    234            y	           2606    94391 &   integer_actual integer_actual_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.integer_actual
    ADD CONSTRAINT integer_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 P   ALTER TABLE ONLY public.integer_actual DROP CONSTRAINT integer_actual_key_fkey;
       public       postgres    false    234    239    2415            x	           2606    94381 (   integer_archive integer_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.integer_archive
    ADD CONSTRAINT integer_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 R   ALTER TABLE ONLY public.integer_archive DROP CONSTRAINT integer_archive_key_fkey;
       public       postgres    false    238    234    2415            v	           2606    94362 "   order_actual order_actual_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.order_actual
    ADD CONSTRAINT order_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 L   ALTER TABLE ONLY public.order_actual DROP CONSTRAINT order_actual_key_fkey;
       public       postgres    false    234    2415    236            w	           2606    94373 $   order_archive order_archive_key_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.order_archive
    ADD CONSTRAINT order_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);
 N   ALTER TABLE ONLY public.order_archive DROP CONSTRAINT order_archive_key_fkey;
       public       postgres    false    234    237    2415            P	      x������ � �      O	      x������ � �      N	      x������ � �      5	   k   x���A
�0 ϛ����²nW\��$��7"�q�����AC�Y&IH�}���";��g�C�H
�[�,�?Ac.JY�}��)j�п��~�������[�2�� -�Q�      <	   T   x�3�4�/��M-NN�IMI���+I-�K��Ϩ,H-�7�7�O�(�����L�2�4į��I�1a����M��Y}� 7B9      8	   B   x�3�4�Lˬ�,��M-.I�-P(�,��/-Q �(T��r�p��A����@D��8�(3 F��� ��%�      :	   9   x�3�4�44354401���%B���U�PU�(��-M��L�6�W���� �u�      >	   u   x���A
�@����a�IrOPxej���t(x{�݀��Ϳx���0n��j^�Ƅ�*$&N�-7�:��Qx/ONg�y����Ry.�V�;�� �9.���9��<�����ED^��m-      @	   _   x�3�Ϩ,H-�7�7�O�(�ˎO��O,�O,J��,K�Oˬ��L��4��*�e3�hĀ̼��t����8d����m�	�+&dy%F��� ��e5      L	      x������ � �      B	      x������ � �      F	      x������ � �      H	      x������ � �      I	      x������ � �      G	      x������ � �      J	      x������ � �      K	      x������ � �      E	   6   x�K�(�/*IM�/-�L�4�]0a"��Mu-�M���-�8K�b���� �3      7	      x������ � �      M	      x������ � �      D	      x������ � �      C	      x������ � �      
     x��[ە$;
��i�:p��slY��X��g���N�R�E�pc���y��֟.���^c�?�0x<��>���Ǟ�������|�g�ϩ�����_�?�U�^��g���@�s���9����#�Cv�g<�C"���C5�$��0��n���W<T#�#���j,��SOQc�����lGlA�,�bI��Kዥ��k,�Ϡ@0��-��E�X��,�X2�)i=���f�� �9��}Fh޷H�F��t�R���SW �<tM�?�t0�.�����F@g�Ϙ�C���IÓ��/�G�`2�KQcُ�@��X��^�9�������;�|z����(�t�G{��laVz��9NxX��\����2�¬zf ��2}j�`�35��������3j4�7����_�����C��`�k�!j,��j,���=j,������凤����[�������3f\�HF������N��3k(Ӵ��f���;��{Н�D��I�Y ��|=L���Ϫ���hAR��׊X�@��~�m>��{.עiU`rF�����<^v�~V�%5[?���t7lz6@22�ƀ�r��`��tE���+*4
��ջBSW�9�~� dN�D�+4Y�/�����C�]��;����_sh�Z��;/t�2:5�����s������0�q�L~j$�b�b��v�ď ϩ�rg�[��3{�o8y\������3tA�eۉ�
K��>J�B�5��ij��j@��m������n�u���ʿ����A��v�0�4�����-�u�P6`�d�� �`s�G���|�J.��� ��B�5U]"h�bJ� ��t��|�`�pZ�((�%N*)��ī-2VU�"�O�lI���������T�"N�1������n�k���)Jb�8�ft�\E���FzV�^��Tr#�E$
"GmD�Jv�5�G�� ?Z�6� m7W�N@�v41�zK�����Hm�=�LaI�fw@�֊xeKjT;k���DI�ڌ��:
D�A�8*��Z���fD%S5�]ݷ�J�f�簐�� �Mo�dK�)͎Z���Ճ�lI�äw�K*T3�sY	��߫))ӛ��&5�k�&jπ4mv7�5y��v�
V��i�%o�l���8�>�qPɜxy�8Tr'E�9��u��i�"*�'��VT�ʻ���J���� �:n��r��A)�}D}F%���*{!���ȉZkɡ4�8����5�3J#�ޒEIR��7S�(KО[�kK���� ]P[�8'�xTâwI��i�i0�����T�)�GFW�ME'B�Qu�[��`Sgg7� ��N�=G���+��� 6����SoaI��SF4� T���v�%��o�de�[r*�%TV@ �ZG��[�*ɒ�nЪ9�u̒Yi$��.���lQ[)(%��dWV�zգi'�&]��+	���L���`�A��g+@�
+���ٴ�
X����ʺ����DW԰���VԨ�0$�z\,�4��P2�WCZM�*�Z�qɯ��>k���ֳ$��K�5z �I*�������mX}%z�U�gF�Ы�UB�5�ӕ��Ѐy�;1�W3�T��W�$|ي��]A�_.�UW�g�V���� W�s�jJve)�gy�%��L�V��5S�-�C��������&���]ue$���O�,n����*coY)f%�R��2p�[�u^��%��Y��Օ�J�gk�z5ZV���r-�j�%��D��r�P����{�ZO��"�}�<�z/S��[W��%��^iy��"�ZJ��_��l�1G�|[;��7!H���/FP����2�@�>��	{_p	���Z }i�l�H��l�$��p�>��Q�>G2�T{���6Н��%{$�LK��!�R�%���j�<h�xQ�'����e#վg�����55��T�� ٞ=�1!ٞ{�'Д
�uP���8-�j�iu3R���!�^"`n��O�x��@�Oa�<�~�ﲽ ў��o�T�P����FTPȵ�hO�cX�����4��U}��}�i�ݑ҈4��"�A�}\��h>Qv��d�${�Q*�4@��>mb�Ē�%�h��.5��^\��D�(�m0D̘�O��)�`2'�ɎD���I�;��A���)��$�㮣a(�o	J��%�*�M��=�����$@�_=����$�;��N%C�������Z��4��y@�_!�e�6S�c.���NA�@�)d�;o	���8y��S+��p����OZ.��)��}j]��;H:L��`��foZv�f��kɞ���UK���X�?@��#���+���� �>�Ҵ"/�J6��3���4C��V���%��3^�����a �[�����>�A���>����}�vZ_��)Y<9I�j�^?����V��O"� ���e$�h�a����.(�C3Hݞ�������"9@��=c]���'���ܼ���M�T�X����k-���D�O��需mOL��6����k�ހ�Q���L�����;�:P���kƢ���9/�y���f�w�ڭ�u�U33@�F6�:�W�6L_�#����4Լ��@���)%?��g���Az�j��SJ�d�!>o�Y��� ���5MM7�wx�V�m ��E�}t���J�������}hC��"���Ȃ<q��U{��z@��)���/f�2�Fm���=��=
�KC����9+�	U���@�7M�mq�^�(F���3;��%����gd�iy��j���"� ����x�P#f����"��p�lo��7@����h-ۿE��MK"%J�VV
`��|�,��hd#q%�R������{�F^�@�5 t�9W"�T��Ɏ�u�;�Q2��{H�6��S�{�c�Fʽh��� ��UǀV�K�y�H�����o�ҽ$��"������}���{+�XP�P�-׸�/ ܛZ�����=/d����N u�	��͒aYu��h@�ׯ)�!ٞ�� ��-{�������}�/���m$�d{�)�+���D��~�x�@���{�K# X';T(���e^�@��9��@��Μ�z5-zL�{����ʽZk���R�M��SLnp��}q�{y[<��pO?�|-��/��1�
(O�'��I����Q��5YaO ��c�MF�P��v��e ݛd�MҽM�`?�t�+(3V��K�.w@ �&^�1�^�?���7ʮj���[�1q�toA@�A����Ӯ�_�jfD�1%��9xc��_�G�Cۚ�S���,�������bs�Q}�6��������~=��?�2�T      
   H   x�mɻ�0�:�����GN<��A
*��a0���E4��5&�<������Le�:�����v?*"/�6�      

      x��\[�%)
��3��@�R�c����A0��T��ʵ2<�"��l#�	��T��������I�ԁe��p��	�3��g��L*O�O��L���S����-������T�[���O����(Oo��_��y�����|�s���������)�6�S�9���������Ɂ�z�i�S�վ�t� і�6Ⱦ�h�f`�d�R�-UhE�f�-f�&~rdõ���8;�}#BZ��t�=�5�V������9}��"�"�97s���"4��?�� �hӃ��T�"/\khd��fH����rfp<H���ž�I�(���|�B��߸e;q}F>�xhE����q{�a��c ���E��L8w�ά��^���o\hmM	hĹ�=�p�h�A1�V���CA`�˙�ӱ:-��EQ�{O�_��s-h�'����%`A�Q}+�Xo�9lB�.�jvKO="ͧ�Vl����re�q�O���-W�ؑ���8~�(��E�����#�ߢu��o��f��ź�x���&yfP�2�2gu
?��'y��5Dɲ���pxn^����N����l�ڸ�w���a���+UߞtZ� J�����۳d���t��o�����ϐS}�=%�&�� �
�b�8�74ߺE<��ޞ��[�N�v���7����Ik8e�4ߺU��ي��7ߺU�K'4'3 �Kb���/� ߺC��
{Z��r����[wJm���Gǧ�֝��h+����[wxl��cڄ�}�&��x�ݳ(����h��[&�s�g����k��~�O�-J۱�Ю3�����E�����ə�6M÷h����߈t�W̥�m�>��.Z�d4� \�&������]�h���ÿ��K�@6�~����8�ƭ��w�ψt�f���tJ*JF��eh�������FA��}�Q�V_y�\�g]�v95q����oݮ��Wx��u�2��F�� �j:"e����qфm���`�F� �3X��+;��Lϊ�]��^��n��u�E�3(?��T4����h_��3<�+�%G9"*��U�ק�H�y�kV_��O�	���A��eN�!i�X B��3Se;�4 E��fY����͝FxF��|�>���Y�F���\��뛹��W�7#\���1��R�SQ��v�mg��E@�JN(mm�#`$VcLz�`�ʷs���7d��="L��~:���Gc�]��b��;p�M3:a�_tF��G���BH�]nCzmC�����V�T�n���~�oN�.c���fQ*����(�3�R~J-���h�9��?W�s�1��e�0F%Z�J}��a�c�|X�H�9��c�; �4v�};·+n��w��tnb����.OD?,{C���*���	�^�ߪEI�W	�Ҩȉ,�������s@!��ߠ�m�:����^��\�W�(���9�
��� ��� �����!��D*��Gce�bW�ߦl�5�*�
Z�pѣ��V$ܩ �:.��	C���J-
���4M��RJ n'��$Ų����D	�6X��P.�DA�*�H�����^��Sh��`=<���Fd��c.Z�t�#.���g����k��6&���9ݸ�A��8�4�J�r��;\ֈ@j�w��]��s��؇]~�޾���y�gC�f���ι��Q�>�� ���z�\5�ss�щ{��b�P�?�Cg�b/�"�(���h�v�k�Z�"ONkn������E/�NE�-����;�J�x�~
��p~׷m��-5:���o϶�~�B�e��w<�?���vLs^]�w�B�(7�]Z��O�8.����+�2�f���d�ʐЙ��ܷ���SP@S���*�+��U��}��It�~j
^����ķ'F��-�g6͝�W��a�!~J��0w��ș%b��^���~�b�y�i��iK�-ȟ��B��K���J�r��xv�B��j�hj+"��V���D��{Y& ���f��6�����5��������Je��m���YoQ�Kq�{���
b�;V�BO��O�#���V_�f�p�Ɠ�w��\J���F���ZV���"7pY��ŏ�@��tI�-3tr�.�y^�p��$I�}^ \F�F�XKnH���l;"mh@�Te������9���'�_iD@�IV��/C:B@���"���Δ(����s��;�`ӳ��FA���=�#�A@�4��ͨ)f�~R�2��. ��nr��Ev"�Ё��qPE�'�9).��.�ҋ��M�D��{�+89q��	���\R�K1�\�:pI��}w����9��Rxw��%up�;�a-X	�:+K�q/�my�_8v�F`\%:��� r�K����O���SP<P��g\��㠀mB�ɮ#���%ـ�o����2�lܳ�TB��N��c���mY(35���P@��Gz$���ت�f5R�H3J�L�����T^��=F:Y��5u�?[[,]��l��Հ4� ���M�"��t���^VB�lFGkg�n��
��5X��DZ��8��<Ŷaс��մ�S���,6k���2�������pf�H�yܖ�d�����[hߥ�5���.63YIaUnM8q؄wDbӆ:�H
��%�+�E^�giU���U;VT �|���&�F��2w9~2>3R�V9��4�h3�k.���������\#*	�*�&�Z�4P�f�V}n0U����G��*��ȗ*hh��a�= 􈬜/n�
�-�[��H��T��i��؂W*Pł���Z9R�*�X���E%,�+�'xˑ,v��,?+���e�
�����K'fށ.�iӜ�Бv�a��*Ha�B	��g��� A�sg���C)lj�r|=�I���{���,�hc���D���!|~�WTd���W=�,V�h��|(��V�l��1M�@;U�>�^k �����SMHa7k�Y ��1�cxV ���i��Jr#��.~���晠�1��Z��Ӟ�V��P��A$�U��IV���,r�k��A��P�9��B!�6�YD9"�+��,V��_��P�����;JXӐ�ngދ}�yn����9n-�v6�5�L�)���_W��0}�.���c�h�{���:�zW� ��&��e�Y�hΘ���'��ᛐ�5���z`�B���R`��X�(\��/.��je�����si��U�UZ�3���\�T�,�ʑ�uw�%:z�1�H����R���F�d����A_C��&��+J�KP��F���^`[�k�� =��+�'Y+��2�F$k���me�nO����jK=�J־�Dߥ�#�����fg�Ɂ��.KF _�ZF�J���p/+�t\�ZߞM/����T����[���.�ePm���R�P��"'�{��W�¾���V�Rs�z���պ�(t���PУg��٩�U��Qm�N�h=d��t��5�u�D�w5�B�޴\��1���f�[\�Z�x�s�:��}���7�B֢}������ѻ�N��kW9��]��(Яꭄj:���������N�_E�����W�b�f3.�5 }�^9��>G�զ��/!]�� ������>?Z�y! ~T�����0P�r�J
�"]���)����P�:��O�����J�=W5�E�
��+��U�ڸ:
��:�u�z��5��|u�}�*����Q#Ь�mhj�_���җ� ���h7#ww�xo�g�}�x�Y�r:H{:��.q���:� ��H8��i��_���Sϝ���:U֦��ɐ9�N�/_Hęw�	t�Y��W�s�V��ʖC�4��_E�ifhV�`\�lk��Mg�U�[�r:���-�x!Ҳ�\�_���]8�rƾ��ݭ�AÿkY˸X�H�:��iμ��K����U��CT0b?���Z�+��I_���8���@�
�+�	.���F���"}�*nLs�߁z�V�[F�W��U=�&澤�de($�Z|RV�jlY��/e�|�Ovz�DhY� e  ��7<��k�@��&;�� ����C+���9�(���?�X��Uz��q7L?c����I�}�������>�E�oc�y*��Z/�� ����P=62��ϫHc�bk����+����f�&
t�I<����J�J���h��/��~�����w���q?��A���hS�PӪy�П͓��U��X�ñW�[��^@Ǽ�ֵ���T��^�	�R"G�)��75��ҏi
���S�:�5_ ���rb��,\7�}=,_�K�ԩh`_Rv�Un�X����j2�>E`(ᙙ�+c��9g��\P�`.���*]�:"ݯJW���FH�t�O�1j1B2_���6Шd�P${����b+h_��^K/�>V�_[��x�K��aEn�q��
�T�W�ė�¾#�DPH`q�V�h��K`�n	$����A.�f�i��#���`��p"��������%��R�? Yj {��z����ϡ�I��o�ؓ�rA��aӼž#�{�i���.[�4� �rA�~\��A��I{ae�;}y+��	����.��^7`���<S���De7�Q��?����W�7#NM�:���E����������{�=��>���bl�      
   ;   x�3�4202�50"C+#C+#K=CN=#K4�e����\�������=... �{      	
   w	  x��ZY�'����Ab�Z��uDj��P��{��Ǩ�P*�����+�_<�����ߙb곎�W)q����C��'���~-8��_Zl%��Q�����)q���1<#�����>k��&߳��)�|�'r�q$Y�6"��Cz&��n�Z lv9�N�9�c���Y�K�7-��.Wql�N&7�MN�4�gPI�h�	�NWF,�L��X�T'��eF�}�k2F��t�X���A��53�B��1F��fo�_~ w��JVA��d���XG`�!/�ǈtEi��䴽��Y�L��m{�gYi�Rlw���u]TBv�?B���_��]��c�,�:����^;~b��(2=�+b����)�{��ත*����q��^�10`��h;Ț��`�J�瞱��3��˕r��q���P[̗/�P0�u���r"q�=�q^�	ŉĶV��:�N����5�Қ�_0���l-[����C��}q�m˔R3L�W�n]�g�د�_Bu�rl�J$�w�N��K$.�/��ݼɘq6�F:���-)���:Ѻk�殻�T�t���$9�P{����;x����)��#�k��0�se�����=sh��>���a�;���Ѐ����?V�1]�ʑ0�oR׀�w��N�;���"zhN�l��(�y�t�1�5�N=ϱ�
̡9��rw���E;c�%DJ��ێ���A��i�c<��?rn��1���j]�ݪ;�x�=*8t�[)s�����`�,���QpRn^٧|
j��Օ�uB��UwP�o�i�0"�wAv��Q�!BE����y5#b����%��4f�j�P���eW�CLt�� :7��#�!���c6�e pY�r���}�p"q�{��W5�FY>�j�оHf��D>1��7iÄ�0H)Z	d:<h�1u=!�Ƨ�r/s��p�	+�61���᦭Ԫ��e�	r$�[�O�e!|l�ʺ�4��쀃r.�`JJ7��3-�+�$��S��C0W��%;��t>�ا�r�cQ�9��r@]��IO��U^�FifH�ɵ��xK˥Kā�)���;Q��W���L%�#��D�8��g���C��>��]໩��(>��*d�A�GZI:�g�<A�t8e�|r��S���a�!�+�b!�yb��<��}�Q^!=@�4B�D��r89���b�u�4T�V�Q�J�p�ˈrtG&jcEW�g���D��C^��O�&��L�!V9e��v��
8���5�P��q�+����sA��Nɲ�"�;�g�����n�D�,��~3"���х�$��ɨ�E">�k���Ũ-ݯ���h,�ʑ�ЎL���O����J�c���L(e)1m�������{Y��l����v�rW�����
���i�o���*G��1�Y�2�z#)�;p^0R���t$�Hi�om�ڑ�U:�.�D�ַ��� �f�R�%>���!�o��*C2c��;�_���� A`K���b��,�.���T�$"�ܝ5� �m�L�y� G�m�H
A��	��ɮ�!���qJރ�O>�Q�|�v��>��.օ�OVY��w�}j�GBf]�66�Nb+cG��:���a/� �G*T.h!�����;a�m1��T��5;�S,z�`��9�OY�Av��iّS..!.��?m��aR��q(�E9�H��Ke�[�ڵ�#�����>lԆ�/ON�AqHflo���(�\97�R3AyH2K�'�Zo������W���V>����*�E!Yv�'*���ѡ*��S>z�e�P#<�y�*>�T���֍�-U"-�����&A�H�vނƧ��4�Ul�l��Fھ���i�T�4��Y�1��$��1�~�%(IRܭ��6/��TZڲ�GL���ֵt���r�݋
"��Ӌ�ݗ<��GZ�x�m���Z�XB�H����Pm��[2��n]�2�����)\�\l�,o��Q�"�YwL�AhK�V��~^5#��s7N�2�f$\�ߧ8SjF�Ȗ�KÓ��\S�jᴽ��U@��U1{�΀:Q�i��I]��e�N����n���D�>(�%�N�?��&_�Dg`hg�Z�#�3ԆX�M�m��P���m76;3Ԇ�a�����)�HC���e/h����JC���P~���yEf��~Iv�@8m�����-�d��Rt�}΋Kg��լ&�P(�q.�H5��M$a9���]�ӡ�#����y�WUO��|>��a�8$<j�5}6=;B�~�VD&��#���j���B�����uU�f[j"I��	�A�j���o_�!Yw����G껀Ș˩u]�sIJ��ᵣ������oA8e���Q��~����[�RG{���LRx
�]�̸�A|�P��ߔ~3��]�w�Ih�b�_��0A      
      x������ � �      
   �  x����n#u��5yvt�~�i$��Y�MK�2��2���A��x$�=�U�ܹ�ս�[��⯎Z�����\�?ܽy:��w����~������k����P>y���?�^�����o_�z�;�_����;��?\w�;��=�/����x~s�?>��\.{y�Ӿk맿}�>�w��.�o��?����|y՗���O�{���^���;�>��������)�ty����w�����������=������{���?�������~|<��u�G�ſ������O��a9���WO���?��v9_���v��?����|S���Z��zkw�����t3]3��lkp�����ߍ>v�}�n�x��Ɛi`�e�1����P���^k�5䞆
��4�`]�q �0_c�1��4�5C�mvG�
����1�����Ӡ�P9,�ꑥ�/���A�!pe��ya$F�G�<15dZ1yc$56Fo��<29�$	UI����ye4jH=� B�I���@���;�@�9`�X坱�tZ0����;��A�!pe��yg$vF����35dZ�3Vyg$5vFo���39�d	��3�;��4��hԐz���3�;#΁8c�wF#�Ls����wƎ�R��<���(yg4:�9�6{ ��ΈC�8c+�F�V�匭�3�;�7�;���h�{�%t��Hr���8�;�QC�q�g��Hj�8⌭�3d�挝�3�ܗ�.@���t��hts\l�@�I����q�N��2���O3�;#�!�3zs ���;��C�q@���;#�!�3:{@� �F���A�;#�!�3��3v��h�i�3���8p_
� ����U��b�+���;#� �3�<���;�QC�Up9c/�����PB/�F��Y� �$��������35�x!��Έs`���3d�挃�3�ܗ�.������hts\l�@�I����q�A��2���yg$5vFo�yg4r�=�Fyg$9vFgh�Ѩ!�8�3yg$5vF�q�A�� 2�s�Q�'�KA`� �jFyg4:�9�6{ ��ΈC�8�(�F�V�匣�3�;�7@	��39�d	��3�;��4��hԐz���3�;#΁8�(�F ��9�$�3���0{�i5��3�W�=�wF�A`g�!x�q�wF��L��r�I�I��ћ��I��r���Y�I����yg4jH=�B�I���@�q�wF#�Ls��qVw��p_
� �o�B��V1����fԥ��XI	j�թ��!�.��qV�F�C`kt� <aV�F����D�4��Ȃ̍�"�>�{��C�}�����r��"���8Z�F���7�©)��5���4��h�t\!l7A^I	����Q��ȳ��C�ep�ci�ݑ���A W(�<<A$�EI���Yyy4z�=�`B�I��A�4��h$�j�=y{�\���@���z��=%W�M��GRBd{�)���ۣ�C�e��c��G�Cd{��h��ۣD򁀶P����E����G�����&����q���=	��j�U�[.NQW����z��=%W�M��GRBd{�)���ۣ�C�e��c��G�Cd{��h��ۣD򁀶���#	"�=:��!o�F��M��#�!�=� �=Vy{4H5	�[y{�8E]��CN�1h���(!��B�n��=�"�#N�e���==�Z�=���Hz�l�� -���h�| �-t��H��l��"�@�ۣ�C��g��Hz�l�8f���=	��j���=�\���@�!��t��h�t\!l7A�I	�����N��R-��;y{$=D�Go�:y{4�H>�zy{$AD�Ggp ����!�@�	y{$=D�G��N��RM��^�.NQW`��zzy{4J:��� o������Sp�c/o�F���g���=�"ۣ7D��=A$h��=� "ۣ�8��h��{ �ل�=�"�#��c/o�F�&��� o�#��+0z�i=��=%W�M��GRBd{�)��q��G��T���A�I�����A�� ���Q�I���Yy{4z�=�lB�I����q��G#�T�@�q��ǉ�S��<��Q�����+��&��#)!�=�\�8�ۣ�C�e���(o��������(o�F���$o�$����,��==�|6!o�������`�8�ۣ�@�I��8�����)�
�rZ��$o�F	A���v�푔�q
.{�����!�2��q��G�Cd{��ha��G#��ma��GDd{tB��r>���G�Cd{�A0{����H �$P{����6\�����[���8�ۣUB�1����u{d%�G���gu{�zH�>{������A Z����
"�@ [���=� ۣ�8��h��{ �ل�=��#	���n�V�&��cm���pq���CN�1���=%W�M��GRBd{�)x�6��h��j\�Xy{$=D�Go�j#o�F��c��GDd{tB��r>���G�Cd{�A{���=	��j�E�+��+P=��"o�F	A���v�푔�q
.{,��h��j|�X�����A Z(��h�| �-Ty{$AD�Ggp ����!�@�	y{$=D�G��"o�F�&��c��ǖ�S�h=��*o�F	A���v�푔�q
.{���h��j|�X�����A Z���h�| �-���H��l��"�@�ۣ�C��g��Hz�l�8f�U��RM��V�;.NQW���zZy{4J:��� o������Sp�c+o�F���g���=�"ۣ7D��=A$h��=� "ۣ�8��h��{ �ل�=�"�#��c+o�F�&���7�����v_       
   �  x�}�ۍ;D��(��"��X��ؤz�E��7�D�Uj��U�O�t�����W�O�{���hi����_�t������G�ܠ?�V6����HMv菇0n��RD���Ǣi~L�ǋY�$���Yd$���	������J|AJT�8�IP<{�]����x�Z�f�SFQS��T�f,�MYE9L��Zp�M�N{�����g뾆Ԣ	Pn��j���� ���VZBt.?�)��ǁi-�#��h�'7��@�8Od �9ϸ����F4N��O��4[}��s�c<0�M�R<E�G٦s��=��,��� [$��a�[��\z��s�p�-p�$2���
/7��\�48̶�ݑ�Mϱ1��4��$����G�22��X���ӓ�G��o(8�ɡe$q9v/��|����$�L"��D�LX���'8�9��:�"iA�ܒ8�$����Y�zBSqPS�	!�&�9����8�#~[�,�����J:�DY��o�_I:��\�����eq��j����T��ZI��r��i%I�&�f,�#�a���$�ś�β9��Ɂֲ����������@����^&a�3"�v3���M�%��,�G�8e3�������q�=A���Y������1����+J.6I`zL�3S?�F]�0�X��8q�IBӻ��&IŜ��><4wT�:1�'��&��ʉ�ZRQE�(�ĸ�'z���l?��
j�U}GE���5���"���7��H�>oNs$��(b')�ފ��C�%r��P"����<B�̃H�"��f��D����C5z�A����)5L��X=�F���I^ݔ��MɊ�$�(�c�$T��5��Ԟ`�8�F��Cd��F`�.�*# �z�,QF�-.&QF�{W���H�S���F8J�7Ȩ4�w&Z���߼�[�������"�h���M��:��[��������jj�ёȣ��&T ᰎ�^��<��6�HG�"D5���>~LKDRs�,�~ZS*��>�A�I"�B�Y��D'��[4T�J�����$�Jg��O��n�;{��U�1J�Vz[�y�h���d,T,�;I=g�mj���/�}��R�&��R��IT4l;I"�^�!��:�PIe]��{�PI�0�y�G�QM�5�q������݆Je�p\�+��گ�DW��lP}�^�v*��u�1����Z�k��V�}����D\�|�d��Z3�" ���a�;�Q�����6_y;��/���1�$��Ù�p�1��Y��`ϫN$QY���*��j�g|Ht։^�Th�P���S�P��޷�&��O�����~�%W�	�.�=Vs�Z�y�*��Y1 ���)H��8�/5��PH<L,�յ��e���"2_�Y��w즺��ug�Dxu�-��5��3��Tx��H&����+@�Ty�����Ʃ��d��TX$�5.�����;yLx�����B��.	��
Z��A/'�U���6o��Dz�'p��A�W��~ߍ4�^+�l��:�3��j/T
T��k��#�5�^�{�������8��|����T{!��WJ���y|��^(��N�J�W�]Q�5�,�x�j���k/5WU\�|_M����o�k�#!$`���M4Q_�W[i�aj���i�X��A�V���W#�N�,�+�2�$T�S��J�W�8����Չ'a@��Xi�y���#y$�_����Ӎџ2��B����?��ro�_�bK�Z�~J)��?�4      
      x������ � �      
      x������ � �      
      x������ � �      
      x������ � �     