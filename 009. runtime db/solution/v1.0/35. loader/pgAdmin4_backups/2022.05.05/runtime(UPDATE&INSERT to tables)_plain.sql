--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.24
-- Dumped by pg_dump version 9.6.24

-- Started on 2022-05-05 10:55:15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 93803)
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- TOC entry 2581 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';


--
-- TOC entry 1 (class 3079 OID 12387)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2582 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 392 (class 1255 OID 94464)
-- Name: _communication(text, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._communication(xpath text, valuenew anyelement) RETURNS void
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


ALTER FUNCTION public._communication(xpath text, valuenew anyelement) OWNER TO postgres;

--
-- TOC entry 391 (class 1255 OID 94422)
-- Name: _order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._order() RETURNS TABLE(_xpath text, fix timestamp without time zone, _value text)
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


ALTER FUNCTION public._order() OWNER TO postgres;

--
-- TOC entry 390 (class 1255 OID 94421)
-- Name: _order(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._order(_xpath text, _value text) RETURNS void
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


ALTER FUNCTION public._order(_xpath text, _value text) OWNER TO postgres;

--
-- TOC entry 386 (class 1255 OID 94417)
-- Name: _refresh(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._refresh() RETURNS TABLE(configuration text, fix timestamp without time zone, value_float double precision, value_integer integer)
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


ALTER FUNCTION public._refresh() OWNER TO postgres;

--
-- TOC entry 385 (class 1255 OID 94416)
-- Name: _refresh(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._refresh(xpath text) RETURNS record
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


ALTER FUNCTION public._refresh(xpath text) OWNER TO postgres;

--
-- TOC entry 388 (class 1255 OID 94419)
-- Name: _refreshold(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._refreshold(st timestamp without time zone, fin timestamp without time zone) RETURNS TABLE(_key integer, configuration text, fix timestamp without time zone, value_float double precision, value_integer integer)
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


ALTER FUNCTION public._refreshold(st timestamp without time zone, fin timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 387 (class 1255 OID 94418)
-- Name: _refreshold(text, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._refreshold(xpath text, st timestamp without time zone, fin timestamp without time zone) RETURNS TABLE(_key integer, fix timestamp without time zone, _value double precision)
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


ALTER FUNCTION public._refreshold(xpath text, st timestamp without time zone, fin timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 389 (class 1255 OID 94420)
-- Name: _synchronizer(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._synchronizer(_xpath text, _status text) RETURNS timestamp without time zone
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


ALTER FUNCTION public._synchronizer(_xpath text, _status text) OWNER TO postgres;

--
-- TOC entry 384 (class 1255 OID 94348)
-- Name: before_insert_in_glossary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.before_insert_in_glossary() RETURNS trigger
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


ALTER FUNCTION public.before_insert_in_glossary() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 238 (class 1259 OID 94378)
-- Name: integer_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_archive OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 94439)
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);


ALTER TABLE _timescaledb_internal._hyper_1_2_chunk OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 94454)
-- Name: _hyper_1_3_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_3_chunk (
    CONSTRAINT constraint_3 CHECK (((fix >= '2022-05-05 00:00:00'::timestamp without time zone) AND (fix < '2022-05-06 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);


ALTER TABLE _timescaledb_internal._hyper_1_3_chunk OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 94396)
-- Name: float_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_archive OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 94429)
-- Name: _hyper_2_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_2_1_chunk (
    CONSTRAINT constraint_1 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);


ALTER TABLE _timescaledb_internal._hyper_2_1_chunk OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 94466)
-- Name: _hyper_2_4_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_2_4_chunk (
    CONSTRAINT constraint_4 CHECK (((fix >= '2022-05-05 00:00:00'::timestamp without time zone) AND (fix < '2022-05-06 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);


ALTER TABLE _timescaledb_internal._hyper_2_4_chunk OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 94406)
-- Name: float_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_actual OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 94337)
-- Name: glossary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.glossary (
    key integer NOT NULL,
    communication text NOT NULL,
    configuration text,
    tablename character varying(30) NOT NULL
);


ALTER TABLE public.glossary OWNER TO postgres;

--
-- TOC entry 2583 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE glossary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.glossary IS 'Словарь для индефикации переменных';


--
-- TOC entry 2584 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';


--
-- TOC entry 2585 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.communication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';


--
-- TOC entry 2586 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.configuration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';


--
-- TOC entry 2587 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.tablename; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';


--
-- TOC entry 233 (class 1259 OID 94335)
-- Name: glossary_key_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.glossary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.glossary_key_seq OWNER TO postgres;

--
-- TOC entry 2588 (class 0 OID 0)
-- Dependencies: 233
-- Name: glossary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.glossary_key_seq OWNED BY public.glossary.key;


--
-- TOC entry 239 (class 1259 OID 94388)
-- Name: integer_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_actual OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 94356)
-- Name: order_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_actual OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 94367)
-- Name: order_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_archive OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 94350)
-- Name: synchronization; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synchronization (
    xpath text NOT NULL,
    fix timestamp without time zone NOT NULL,
    status text NOT NULL
);


ALTER TABLE public.synchronization OWNER TO postgres;

--
-- TOC entry 2407 (class 2604 OID 94340)
-- Name: glossary key; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary ALTER COLUMN key SET DEFAULT nextval('public.glossary_key_seq'::regclass);


--
-- TOC entry 2384 (class 0 OID 94249)
-- Dependencies: 222
-- Data for Name: cache_inval_bgw_job; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_bgw_job  FROM stdin;
\.


--
-- TOC entry 2383 (class 0 OID 94252)
-- Dependencies: 223
-- Data for Name: cache_inval_extension; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_extension  FROM stdin;
\.


--
-- TOC entry 2382 (class 0 OID 94246)
-- Dependencies: 221
-- Data for Name: cache_inval_hypertable; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_hypertable  FROM stdin;
\.


--
-- TOC entry 2357 (class 0 OID 93820)
-- Dependencies: 193
-- Data for Name: hypertable; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compressed, compressed_hypertable_id) FROM stdin;
1	public	integer_archive	_timescaledb_internal	_hyper_1	1	_timescaledb_internal	calculate_chunk_interval	0	f	\N
2	public	float_archive	_timescaledb_internal	_hyper_2	1	_timescaledb_internal	calculate_chunk_interval	0	f	\N
\.


--
-- TOC entry 2364 (class 0 OID 93894)
-- Dependencies: 201
-- Data for Name: chunk; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped) FROM stdin;
1	2	_timescaledb_internal	_hyper_2_1_chunk	\N	f
2	1	_timescaledb_internal	_hyper_1_2_chunk	\N	f
3	1	_timescaledb_internal	_hyper_1_3_chunk	\N	f
4	2	_timescaledb_internal	_hyper_2_4_chunk	\N	f
\.


--
-- TOC entry 2360 (class 0 OID 93859)
-- Dependencies: 197
-- Data for Name: dimension; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, integer_now_func_schema, integer_now_func) FROM stdin;
1	1	fix	timestamp without time zone	t	\N	\N	\N	86400000000	\N	\N
2	2	fix	timestamp without time zone	t	\N	\N	\N	86400000000	\N	\N
\.


--
-- TOC entry 2362 (class 0 OID 93878)
-- Dependencies: 199
-- Data for Name: dimension_slice; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) FROM stdin;
1	2	1651104000000000	1651190400000000
2	1	1651104000000000	1651190400000000
3	1	1651708800000000	1651795200000000
4	2	1651708800000000	1651795200000000
\.


--
-- TOC entry 2366 (class 0 OID 93915)
-- Dependencies: 202
-- Data for Name: chunk_constraint; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) FROM stdin;
1	1	constraint_1	\N
1	\N	1_1_float_archive_key_fkey	float_archive_key_fkey
2	2	constraint_2	\N
2	\N	2_2_integer_archive_key_fkey	integer_archive_key_fkey
3	3	constraint_3	\N
3	\N	3_3_integer_archive_key_fkey	integer_archive_key_fkey
4	4	constraint_4	\N
4	\N	4_4_float_archive_key_fkey	float_archive_key_fkey
\.


--
-- TOC entry 2589 (class 0 OID 0)
-- Dependencies: 203
-- Name: chunk_constraint_name; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 4, true);


--
-- TOC entry 2590 (class 0 OID 0)
-- Dependencies: 200
-- Name: chunk_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 4, true);


--
-- TOC entry 2368 (class 0 OID 93933)
-- Dependencies: 204
-- Data for Name: chunk_index; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) FROM stdin;
1	_hyper_2_1_chunk_float_archive_fix_idx	2	float_archive_fix_idx
2	_hyper_1_2_chunk_integer_archive_fix_idx	1	integer_archive_fix_idx
3	_hyper_1_3_chunk_integer_archive_fix_idx	1	integer_archive_fix_idx
4	_hyper_2_4_chunk_float_archive_fix_idx	2	float_archive_fix_idx
\.


--
-- TOC entry 2380 (class 0 OID 94118)
-- Dependencies: 219
-- Data for Name: compression_chunk_size; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.compression_chunk_size (chunk_id, compressed_chunk_id, uncompressed_heap_size, uncompressed_toast_size, uncompressed_index_size, compressed_heap_size, compressed_toast_size, compressed_index_size) FROM stdin;
\.


--
-- TOC entry 2370 (class 0 OID 93951)
-- Dependencies: 206
-- Data for Name: bgw_job; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_job (id, application_name, job_type, schedule_interval, max_runtime, max_retries, retry_period) FROM stdin;
\.


--
-- TOC entry 2374 (class 0 OID 94030)
-- Dependencies: 212
-- Data for Name: continuous_agg; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_agg (mat_hypertable_id, raw_hypertable_id, user_view_schema, user_view_name, partial_view_schema, partial_view_name, bucket_width, job_id, refresh_lag, direct_view_schema, direct_view_name, max_interval_per_job, ignore_invalidation_older_than) FROM stdin;
\.


--
-- TOC entry 2376 (class 0 OID 94068)
-- Dependencies: 214
-- Data for Name: continuous_aggs_completed_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_completed_threshold (materialization_id, watermark) FROM stdin;
\.


--
-- TOC entry 2377 (class 0 OID 94078)
-- Dependencies: 215
-- Data for Name: continuous_aggs_hypertable_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_hypertable_invalidation_log (hypertable_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- TOC entry 2375 (class 0 OID 94058)
-- Dependencies: 213
-- Data for Name: continuous_aggs_invalidation_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_invalidation_threshold (hypertable_id, watermark) FROM stdin;
\.


--
-- TOC entry 2378 (class 0 OID 94082)
-- Dependencies: 216
-- Data for Name: continuous_aggs_materialization_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_materialization_invalidation_log (materialization_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- TOC entry 2591 (class 0 OID 0)
-- Dependencies: 196
-- Name: dimension_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 2, true);


--
-- TOC entry 2592 (class 0 OID 0)
-- Dependencies: 198
-- Name: dimension_slice_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 4, true);


--
-- TOC entry 2379 (class 0 OID 94099)
-- Dependencies: 218
-- Data for Name: hypertable_compression; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.hypertable_compression (hypertable_id, attname, compression_algorithm_id, segmentby_column_index, orderby_column_index, orderby_asc, orderby_nullsfirst) FROM stdin;
\.


--
-- TOC entry 2593 (class 0 OID 0)
-- Dependencies: 192
-- Name: hypertable_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 2, true);


--
-- TOC entry 2373 (class 0 OID 94022)
-- Dependencies: 211
-- Data for Name: metadata; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.metadata (key, value, include_in_telemetry) FROM stdin;
exported_uuid	00000000-0000-4000-bc51-8753b3800200	t
\.


--
-- TOC entry 2359 (class 0 OID 93844)
-- Dependencies: 195
-- Data for Name: tablespace; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.tablespace (id, hypertable_id, tablespace_name) FROM stdin;
\.


--
-- TOC entry 2594 (class 0 OID 0)
-- Dependencies: 205
-- Name: bgw_job_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_config; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1000, false);


--
-- TOC entry 2381 (class 0 OID 94133)
-- Dependencies: 220
-- Data for Name: bgw_policy_compress_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_compress_chunks (job_id, hypertable_id, older_than) FROM stdin;
\.


--
-- TOC entry 2372 (class 0 OID 93986)
-- Dependencies: 209
-- Data for Name: bgw_policy_drop_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_drop_chunks (job_id, hypertable_id, older_than, cascade, cascade_to_materializations) FROM stdin;
\.


--
-- TOC entry 2371 (class 0 OID 93969)
-- Dependencies: 208
-- Data for Name: bgw_policy_reorder; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_reorder (job_id, hypertable_id, hypertable_index_name) FROM stdin;
\.


--
-- TOC entry 2571 (class 0 OID 94439)
-- Dependencies: 243
-- Data for Name: _hyper_1_2_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_2_chunk (key, fix, value) FROM stdin;
1	2022-04-28 17:43:31.087583	2
2	2022-04-28 17:43:31.086583	89
3	2022-04-28 17:43:31.089583	68
4	2022-04-28 17:43:31.098583	57
5	2022-04-28 17:43:31.109583	84
6	2022-04-28 17:43:31.086583	85
7	2022-04-28 17:43:31.137583	145
8	2022-04-28 17:43:31.090583	138
9	2022-04-28 17:43:31.200583	39
10	2022-04-28 17:43:31.174583	81
11	2022-04-28 17:43:31.206583	99
12	2022-04-28 17:43:31.218583	20
13	2022-04-28 17:43:31.139583	77
14	2022-04-28 17:43:31.088583	110
15	2022-04-28 17:43:31.149583	11
16	2022-04-28 17:43:31.250583	132
17	2022-04-28 17:43:31.312583	27
18	2022-04-28 17:43:31.218583	24
19	2022-04-28 17:43:31.093583	48
20	2022-04-28 17:43:31.114583	16
21	2022-04-28 17:43:31.326583	30
22	2022-04-28 17:43:31.118583	10
23	2022-04-28 17:43:31.189583	42
24	2022-04-28 17:43:31.338583	123
25	2022-04-28 17:43:31.224583	117
26	2022-04-28 17:43:31.282583	140
27	2022-04-28 17:43:31.155583	139
28	2022-04-28 17:43:31.214583	34
29	2022-04-28 17:43:31.190583	40
30	2022-04-28 17:43:31.224583	110
31	2022-04-28 17:43:31.291583	94
32	2022-04-28 17:43:31.138583	54
33	2022-04-28 17:43:31.470583	19
34	2022-04-28 17:43:31.414583	64
35	2022-04-28 17:43:31.319583	132
36	2022-04-28 17:43:31.542583	92
37	2022-04-28 17:43:31.222583	79
38	2022-04-28 17:43:31.492583	91
39	2022-04-28 17:43:31.425583	110
40	2022-04-28 17:43:31.554583	4
41	2022-04-28 17:43:31.525583	26
42	2022-04-28 17:43:31.368583	72
43	2022-04-28 17:43:31.418583	111
44	2022-04-28 17:43:31.602583	144
45	2022-04-28 17:43:31.659583	48
46	2022-04-28 17:43:31.718583	109
47	2022-04-28 17:43:31.121583	40
48	2022-04-28 17:43:31.554583	28
49	2022-04-28 17:43:31.221583	101
50	2022-04-28 17:43:31.274583	27
51	2022-04-28 17:43:31.584583	48
52	2022-04-28 17:43:31.386583	63
53	2022-04-28 17:43:31.763583	134
54	2022-04-28 17:43:31.668583	84
55	2022-04-28 17:43:31.294583	96
56	2022-04-28 17:43:31.578583	63
57	2022-04-28 17:43:31.473583	43
58	2022-04-28 17:43:31.886583	40
59	2022-04-28 17:43:31.310583	88
60	2022-04-28 17:43:31.794583	15
61	2022-04-28 17:43:31.440583	94
62	2022-04-28 17:43:31.570583	19
63	2022-04-28 17:43:31.956583	28
64	2022-04-28 17:43:31.650583	141
65	2022-04-28 17:43:31.919583	80
66	2022-04-28 17:43:31.602583	134
67	2022-04-28 17:43:31.610583	94
68	2022-04-28 17:43:31.482583	65
69	2022-04-28 17:43:31.833583	144
70	2022-04-28 17:43:31.704583	87
71	2022-04-28 17:43:31.216583	32
72	2022-04-28 17:43:31.866583	35
73	2022-04-28 17:43:31.877583	79
74	2022-04-28 17:43:31.444583	106
75	2022-04-28 17:43:31.449583	57
76	2022-04-28 17:43:32.138583	75
77	2022-04-28 17:43:31.998583	18
78	2022-04-28 17:43:32.010583	2
79	2022-04-28 17:43:31.943583	41
80	2022-04-28 17:43:31.714583	101
81	2022-04-28 17:43:31.479583	110
82	2022-04-28 17:43:31.894583	100
83	2022-04-28 17:43:31.323583	100
84	2022-04-28 17:43:32.166583	117
85	2022-04-28 17:43:32.179583	81
86	2022-04-28 17:43:31.762583	34
87	2022-04-28 17:43:32.292583	38
88	2022-04-28 17:43:31.250583	20
89	2022-04-28 17:43:32.231583	45
90	2022-04-28 17:43:31.704583	58
91	2022-04-28 17:43:32.257583	130
92	2022-04-28 17:43:31.994583	72
93	2022-04-28 17:43:31.911583	2
94	2022-04-28 17:43:31.262583	64
95	2022-04-28 17:43:32.214583	54
96	2022-04-28 17:43:32.034583	73
97	2022-04-28 17:43:31.850583	134
98	2022-04-28 17:43:31.564583	42
99	2022-04-28 17:43:31.866583	12
100	2022-04-28 17:43:31.274583	5
101	2022-04-28 17:43:32.084583	72
102	2022-04-28 17:43:32.298583	106
103	2022-04-28 17:43:32.413583	107
104	2022-04-28 17:43:31.906583	86
105	2022-04-28 17:43:31.284583	104
106	2022-04-28 17:43:31.392583	70
107	2022-04-28 17:43:32.465583	15
108	2022-04-28 17:43:32.370583	61
109	2022-04-28 17:43:31.292583	30
110	2022-04-28 17:43:31.404583	21
111	2022-04-28 17:43:32.073583	65
112	2022-04-28 17:43:31.186583	81
113	2022-04-28 17:43:32.543583	145
114	2022-04-28 17:43:32.328583	10
115	2022-04-28 17:43:32.684583	113
116	2022-04-28 17:43:32.118583	119
117	2022-04-28 17:43:31.542583	56
118	2022-04-28 17:43:32.372583	58
119	2022-04-28 17:43:31.312583	141
120	2022-04-28 17:43:32.154583	124
121	2022-04-28 17:43:32.042583	71
122	2022-04-28 17:43:31.806583	14
123	2022-04-28 17:43:31.566583	28
124	2022-04-28 17:43:32.190583	59
125	2022-04-28 17:43:31.449583	128
126	2022-04-28 17:43:31.578583	47
127	2022-04-28 17:43:32.852583	139
128	2022-04-28 17:43:31.970583	33
129	2022-04-28 17:43:32.106583	38
130	2022-04-28 17:43:32.634583	131
131	2022-04-28 17:43:31.205583	68
132	2022-04-28 17:43:32.262583	42
133	2022-04-28 17:43:31.473583	45
134	2022-04-28 17:43:31.744583	72
135	2022-04-28 17:43:31.884583	61
136	2022-04-28 17:43:31.890583	14
137	2022-04-28 17:43:32.307583	38
138	2022-04-28 17:43:32.454583	19
139	2022-04-28 17:43:31.352583	133
140	2022-04-28 17:43:31.774583	103
141	2022-04-28 17:43:31.920583	49
142	2022-04-28 17:43:33.062583	13
143	2022-04-28 17:43:32.218583	44
144	2022-04-28 17:43:32.802583	39
145	2022-04-28 17:43:33.104583	76
146	2022-04-28 17:43:32.972583	121
147	2022-04-28 17:43:31.515583	102
148	2022-04-28 17:43:32.850583	4
149	2022-04-28 17:43:32.862583	16
150	2022-04-28 17:43:33.174583	137
151	2022-04-28 17:43:33.037583	20
152	2022-04-28 17:43:31.378583	103
153	2022-04-28 17:43:32.298583	20
154	2022-04-28 17:43:32.768583	105
155	2022-04-28 17:43:31.849583	44
156	2022-04-28 17:43:31.542583	83
157	2022-04-28 17:43:33.272583	19
158	2022-04-28 17:43:32.338583	98
159	2022-04-28 17:43:32.346583	80
160	2022-04-28 17:43:32.834583	117
161	2022-04-28 17:43:32.201583	1
162	2022-04-28 17:43:32.370583	123
163	2022-04-28 17:43:32.378583	73
164	2022-04-28 17:43:33.370583	132
165	2022-04-28 17:43:32.229583	94
166	2022-04-28 17:43:31.904583	140
167	2022-04-28 17:43:33.245583	54
168	2022-04-28 17:43:33.090583	35
169	2022-04-28 17:43:31.919583	36
170	2022-04-28 17:43:32.434583	62
171	2022-04-28 17:43:32.613583	19
172	2022-04-28 17:43:33.482583	97
173	2022-04-28 17:43:32.112583	50
174	2022-04-28 17:43:33.336583	3
175	2022-04-28 17:43:31.599583	27
176	2022-04-28 17:43:32.482583	45
177	2022-04-28 17:43:32.136583	28
178	2022-04-28 17:43:32.498583	134
179	2022-04-28 17:43:32.685583	30
180	2022-04-28 17:43:31.794583	9
181	2022-04-28 17:43:31.798583	118
182	2022-04-28 17:43:31.984583	96
183	2022-04-28 17:43:31.440583	30
184	2022-04-28 17:43:32.914583	85
185	2022-04-28 17:43:32.184583	43
186	2022-04-28 17:43:32.190583	42
187	2022-04-28 17:43:31.261583	45
188	2022-04-28 17:43:31.826583	50
189	2022-04-28 17:43:31.452583	127
190	2022-04-28 17:43:32.594583	26
191	2022-04-28 17:43:32.793583	137
192	2022-04-28 17:43:33.186583	34
193	2022-04-28 17:43:31.653583	140
194	2022-04-28 17:43:32.820583	108
195	2022-04-28 17:43:33.609583	125
196	2022-04-28 17:43:33.034583	15
197	2022-04-28 17:43:31.468583	70
198	2022-04-28 17:43:31.866583	113
199	2022-04-28 17:43:33.462583	45
200	2022-04-28 17:43:33.074583	25
201	2022-04-28 17:43:33.084583	44
202	2022-04-28 17:43:33.094583	128
203	2022-04-28 17:43:33.510583	32
204	2022-04-28 17:43:32.094583	12
205	2022-04-28 17:43:33.944583	22
206	2022-04-28 17:43:33.752583	106
207	2022-04-28 17:43:33.351583	5
208	2022-04-28 17:43:32.530583	36
209	2022-04-28 17:43:31.492583	14
210	2022-04-28 17:43:32.754583	10
211	2022-04-28 17:43:32.973583	132
212	2022-04-28 17:43:33.194583	70
213	2022-04-28 17:43:33.204583	42
214	2022-04-28 17:43:31.930583	80
215	2022-04-28 17:43:31.504583	65
216	2022-04-28 17:43:32.802583	107
217	2022-04-28 17:43:31.942583	47
218	2022-04-28 17:43:32.600583	47
219	2022-04-28 17:43:32.169583	124
220	2022-04-28 17:43:32.614583	135
221	2022-04-28 17:43:33.284583	75
222	2022-04-28 17:43:33.516583	108
223	2022-04-28 17:43:34.196583	133
224	2022-04-28 17:43:32.418583	4
225	2022-04-28 17:43:31.524583	2
226	2022-04-28 17:43:33.334583	105
227	2022-04-28 17:43:33.798583	85
228	2022-04-28 17:43:32.898583	115
229	2022-04-28 17:43:33.135583	30
230	2022-04-28 17:43:31.994583	76
231	2022-04-28 17:43:34.308583	108
232	2022-04-28 17:43:31.306583	77
233	2022-04-28 17:43:33.171583	24
234	2022-04-28 17:43:32.946583	58
235	2022-04-28 17:43:32.954583	19
236	2022-04-28 17:43:34.378583	33
237	2022-04-28 17:43:33.444583	85
238	2022-04-28 17:43:32.502583	16
239	2022-04-28 17:43:31.791583	140
240	2022-04-28 17:43:32.994583	108
1	2022-04-28 17:43:31.087583	32
2	2022-04-28 17:43:31.090583	9
3	2022-04-28 17:43:31.107583	117
4	2022-04-28 17:43:31.126583	95
5	2022-04-28 17:43:31.129583	101
6	2022-04-28 17:43:31.140583	11
7	2022-04-28 17:43:31.137583	131
8	2022-04-28 17:43:31.186583	137
9	2022-04-28 17:43:31.146583	37
10	2022-04-28 17:43:31.104583	119
11	2022-04-28 17:43:31.151583	143
12	2022-04-28 17:43:31.158583	133
13	2022-04-28 17:43:31.100583	71
14	2022-04-28 17:43:31.102583	33
15	2022-04-28 17:43:31.134583	66
16	2022-04-28 17:43:31.234583	93
17	2022-04-28 17:43:31.244583	72
18	2022-04-28 17:43:31.236583	112
19	2022-04-28 17:43:31.150583	139
20	2022-04-28 17:43:31.314583	119
21	2022-04-28 17:43:31.158583	124
22	2022-04-28 17:43:31.272583	125
23	2022-04-28 17:43:31.235583	132
24	2022-04-28 17:43:31.290583	112
25	2022-04-28 17:43:31.299583	65
26	2022-04-28 17:43:31.308583	129
27	2022-04-28 17:43:31.398583	100
28	2022-04-28 17:43:31.214583	133
29	2022-04-28 17:43:31.393583	86
30	2022-04-28 17:43:31.134583	38
31	2022-04-28 17:43:31.415583	104
32	2022-04-28 17:43:31.298583	47
33	2022-04-28 17:43:31.140583	13
34	2022-04-28 17:43:31.278583	21
35	2022-04-28 17:43:31.249583	27
36	2022-04-28 17:43:31.434583	80
37	2022-04-28 17:43:31.333583	44
38	2022-04-28 17:43:31.416583	82
39	2022-04-28 17:43:31.308583	91
40	2022-04-28 17:43:31.394583	18
41	2022-04-28 17:43:31.607583	43
42	2022-04-28 17:43:31.452583	111
43	2022-04-28 17:43:31.590583	112
44	2022-04-28 17:43:31.602583	3
45	2022-04-28 17:43:31.209583	103
46	2022-04-28 17:43:31.166583	94
47	2022-04-28 17:43:31.685583	78
48	2022-04-28 17:43:31.170583	74
49	2022-04-28 17:43:31.417583	46
50	2022-04-28 17:43:31.674583	47
51	2022-04-28 17:43:31.482583	67
52	2022-04-28 17:43:31.490583	66
53	2022-04-28 17:43:31.657583	9
54	2022-04-28 17:43:31.452583	80
55	2022-04-28 17:43:31.184583	111
56	2022-04-28 17:43:31.578583	18
57	2022-04-28 17:43:31.188583	132
58	2022-04-28 17:43:31.422583	66
59	2022-04-28 17:43:31.251583	100
60	2022-04-28 17:43:31.494583	40
61	2022-04-28 17:43:31.379583	53
62	2022-04-28 17:43:31.942583	84
63	2022-04-28 17:43:31.263583	11
64	2022-04-28 17:43:31.650583	134
65	2022-04-28 17:43:31.334583	14
66	2022-04-28 17:43:31.272583	8
67	2022-04-28 17:43:31.878583	29
68	2022-04-28 17:43:31.686583	64
69	2022-04-28 17:43:31.902583	21
70	2022-04-28 17:43:31.214583	117
71	2022-04-28 17:43:31.500583	36
72	2022-04-28 17:43:32.010583	60
73	2022-04-28 17:43:31.293583	134
74	2022-04-28 17:43:31.740583	4
75	2022-04-28 17:43:31.374583	91
76	2022-04-28 17:43:31.530583	106
77	2022-04-28 17:43:31.998583	81
78	2022-04-28 17:43:31.152583	27
79	2022-04-28 17:43:31.706583	132
80	2022-04-28 17:43:31.474583	97
81	2022-04-28 17:43:31.641583	75
82	2022-04-28 17:43:31.566583	145
83	2022-04-28 17:43:31.821583	75
84	2022-04-28 17:43:31.494583	129
85	2022-04-28 17:43:31.584583	134
86	2022-04-28 17:43:31.934583	144
87	2022-04-28 17:43:31.944583	97
88	2022-04-28 17:43:32.218583	10
89	2022-04-28 17:43:31.697583	83
90	2022-04-28 17:43:31.704583	34
91	2022-04-28 17:43:31.802583	88
92	2022-04-28 17:43:32.086583	87
93	2022-04-28 17:43:32.097583	64
94	2022-04-28 17:43:31.450583	36
95	2022-04-28 17:43:31.359583	59
96	2022-04-28 17:43:32.418583	131
97	2022-04-28 17:43:32.238583	54
98	2022-04-28 17:43:31.662583	120
99	2022-04-28 17:43:32.361583	135
100	2022-04-28 17:43:32.274583	92
101	2022-04-28 17:43:31.983583	99
102	2022-04-28 17:43:32.094583	38
103	2022-04-28 17:43:32.516583	57
104	2022-04-28 17:43:31.282583	27
105	2022-04-28 17:43:32.019583	140
106	2022-04-28 17:43:32.240583	134
107	2022-04-28 17:43:31.823583	13
108	2022-04-28 17:43:31.398583	121
109	2022-04-28 17:43:32.273583	106
110	2022-04-28 17:43:31.624583	26
111	2022-04-28 17:43:31.629583	12
112	2022-04-28 17:43:32.306583	135
113	2022-04-28 17:43:32.656583	109
114	2022-04-28 17:43:31.416583	43
115	2022-04-28 17:43:31.649583	16
116	2022-04-28 17:43:31.422583	75
117	2022-04-28 17:43:32.361583	117
118	2022-04-28 17:43:32.136583	120
119	2022-04-28 17:43:32.621583	72
120	2022-04-28 17:43:32.154583	49
121	2022-04-28 17:43:31.800583	5
122	2022-04-28 17:43:32.172583	32
123	2022-04-28 17:43:32.304583	5
124	2022-04-28 17:43:31.942583	109
125	2022-04-28 17:43:31.574583	79
126	2022-04-28 17:43:31.326583	27
127	2022-04-28 17:43:32.344583	92
128	2022-04-28 17:43:31.714583	78
129	2022-04-28 17:43:32.880583	111
130	2022-04-28 17:43:31.724583	35
131	2022-04-28 17:43:31.598583	114
132	2022-04-28 17:43:32.790583	77
133	2022-04-28 17:43:32.670583	33
134	2022-04-28 17:43:31.476583	98
135	2022-04-28 17:43:32.019583	50
136	2022-04-28 17:43:32.842583	40
137	2022-04-28 17:43:31.485583	138
138	2022-04-28 17:43:32.730583	42
139	2022-04-28 17:43:32.047583	73
140	2022-04-28 17:43:31.774583	138
141	2022-04-28 17:43:31.779583	62
142	2022-04-28 17:43:31.358583	111
143	2022-04-28 17:43:31.360583	141
144	2022-04-28 17:43:32.946583	20
145	2022-04-28 17:43:32.234583	14
146	2022-04-28 17:43:32.826583	23
147	2022-04-28 17:43:31.662583	57
148	2022-04-28 17:43:31.518583	84
149	2022-04-28 17:43:31.521583	15
150	2022-04-28 17:43:31.974583	65
151	2022-04-28 17:43:33.037583	111
152	2022-04-28 17:43:31.834583	126
153	2022-04-28 17:43:32.451583	115
154	2022-04-28 17:43:31.382583	101
155	2022-04-28 17:43:32.934583	6
156	2022-04-28 17:43:31.386583	68
157	2022-04-28 17:43:32.330583	48
158	2022-04-28 17:43:33.128583	116
159	2022-04-28 17:43:32.664583	18
160	2022-04-28 17:43:32.354583	123
161	2022-04-28 17:43:32.040583	5
162	2022-04-28 17:43:31.722583	55
163	2022-04-28 17:43:32.378583	111
164	2022-04-28 17:43:31.402583	105
165	2022-04-28 17:43:33.054583	35
166	2022-04-28 17:43:31.572583	53
167	2022-04-28 17:43:31.575583	119
168	2022-04-28 17:43:31.410583	81
169	2022-04-28 17:43:31.581583	34
170	2022-04-28 17:43:31.584583	37
171	2022-04-28 17:43:33.297583	26
172	2022-04-28 17:43:31.934583	66
173	2022-04-28 17:43:31.247583	58
174	2022-04-28 17:43:32.814583	129
175	2022-04-28 17:43:32.299583	46
176	2022-04-28 17:43:33.362583	5
177	2022-04-28 17:43:32.667583	81
178	2022-04-28 17:43:31.430583	123
179	2022-04-28 17:43:32.685583	132
180	2022-04-28 17:43:32.154583	125
181	2022-04-28 17:43:33.065583	52
182	2022-04-28 17:43:33.258583	86
183	2022-04-28 17:43:33.453583	105
184	2022-04-28 17:43:32.178583	99
185	2022-04-28 17:43:31.814583	53
186	2022-04-28 17:43:32.934583	69
187	2022-04-28 17:43:33.692583	36
188	2022-04-28 17:43:33.706583	27
189	2022-04-28 17:43:33.153583	107
190	2022-04-28 17:43:32.214583	14
191	2022-04-28 17:43:31.647583	25
192	2022-04-28 17:43:32.034583	77
193	2022-04-28 17:43:32.232583	17
194	2022-04-28 17:43:33.208583	81
195	2022-04-28 17:43:33.219583	36
196	2022-04-28 17:43:33.818583	34
197	2022-04-28 17:43:33.438583	41
198	2022-04-28 17:43:32.658583	80
199	2022-04-28 17:43:32.069583	105
200	2022-04-28 17:43:32.674583	43
201	2022-04-28 17:43:31.476583	142
202	2022-04-28 17:43:33.094583	17
203	2022-04-28 17:43:33.104583	60
204	2022-04-28 17:43:31.482583	54
205	2022-04-28 17:43:32.919583	132
206	2022-04-28 17:43:31.692583	122
207	2022-04-28 17:43:32.730583	44
208	2022-04-28 17:43:33.362583	84
209	2022-04-28 17:43:31.492583	48
210	2022-04-28 17:43:31.914583	114
211	2022-04-28 17:43:34.028583	118
212	2022-04-28 17:43:34.042583	2
213	2022-04-28 17:43:32.352583	64
214	2022-04-28 17:43:33.000583	102
215	2022-04-28 17:43:33.439583	59
216	2022-04-28 17:43:33.882583	144
217	2022-04-28 17:43:31.942583	12
218	2022-04-28 17:43:31.510583	20
219	2022-04-28 17:43:32.826583	22
220	2022-04-28 17:43:33.934583	138
221	2022-04-28 17:43:31.516583	57
222	2022-04-28 17:43:34.182583	119
223	2022-04-28 17:43:31.743583	22
224	2022-04-28 17:43:33.314583	80
225	2022-04-28 17:43:32.874583	136
226	2022-04-28 17:43:32.656583	144
227	2022-04-28 17:43:32.890583	112
228	2022-04-28 17:43:32.214583	32
229	2022-04-28 17:43:31.303583	93
230	2022-04-28 17:43:33.604583	33
231	2022-04-28 17:43:33.615583	52
232	2022-04-28 17:43:33.394583	30
233	2022-04-28 17:43:31.540583	21
234	2022-04-28 17:43:33.414583	69
235	2022-04-28 17:43:32.014583	91
236	2022-04-28 17:43:31.546583	139
237	2022-04-28 17:43:32.733583	42
238	2022-04-28 17:43:33.692583	85
239	2022-04-28 17:43:34.181583	21
240	2022-04-28 17:43:34.194583	35
1	2022-04-28 17:54:18.500623	0
7	2022-04-28 17:54:18.500623	0
9	2022-04-28 17:54:18.500623	0
1	2022-04-28 17:54:31.447703	0
7	2022-04-28 17:54:31.447703	0
9	2022-04-28 17:54:31.447703	0
\.


--
-- TOC entry 2572 (class 0 OID 94454)
-- Dependencies: 244
-- Data for Name: _hyper_1_3_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_3_chunk (key, fix, value) FROM stdin;
5	2022-05-05 10:03:33.481401	0
5	2022-05-05 10:03:33.491401	0
1	2022-05-05 10:18:55.177089	0
1	2022-05-05 10:20:40.051217	0
\.


--
-- TOC entry 2570 (class 0 OID 94429)
-- Dependencies: 242
-- Data for Name: _hyper_2_1_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_2_1_chunk (key, fix, value) FROM stdin;
1	2022-04-28 17:43:31.084583	139.88
2	2022-04-28 17:43:31.102583	142.31
3	2022-04-28 17:43:31.098583	104.63
4	2022-04-28 17:43:31.098583	7.8300000000000001
5	2022-04-28 17:43:31.124583	119.87
6	2022-04-28 17:43:31.152583	102.36
7	2022-04-28 17:43:31.151583	84.769999999999996
8	2022-04-28 17:43:31.138583	144.11000000000001
9	2022-04-28 17:43:31.182583	135.69999999999999
10	2022-04-28 17:43:31.184583	96.519999999999996
11	2022-04-28 17:43:31.129583	113.78
12	2022-04-28 17:43:31.170583	143.59
13	2022-04-28 17:43:31.152583	20.870000000000001
14	2022-04-28 17:43:31.144583	144.37
15	2022-04-28 17:43:31.224583	114.51000000000001
16	2022-04-28 17:43:31.138583	8.6999999999999993
17	2022-04-28 17:43:31.159583	5.6500000000000004
18	2022-04-28 17:43:31.200583	34.619999999999997
19	2022-04-28 17:43:31.207583	1.9099999999999999
20	2022-04-28 17:43:31.254583	7.1600000000000001
21	2022-04-28 17:43:31.263583	67.230000000000004
22	2022-04-28 17:43:31.162583	133.63999999999999
23	2022-04-28 17:43:31.097583	64.310000000000002
24	2022-04-28 17:43:31.170583	38.32
25	2022-04-28 17:43:31.374583	33.450000000000003
26	2022-04-28 17:43:31.204583	30.870000000000001
27	2022-04-28 17:43:31.452583	105.81999999999999
28	2022-04-28 17:43:31.158583	132.36000000000001
29	2022-04-28 17:43:31.277583	139.74000000000001
30	2022-04-28 17:43:31.374583	55.920000000000002
31	2022-04-28 17:43:31.291583	55.259999999999998
32	2022-04-28 17:43:31.266583	125.26000000000001
33	2022-04-28 17:43:31.371583	119.62
34	2022-04-28 17:43:31.312583	108.52
35	2022-04-28 17:43:31.179583	37.630000000000003
36	2022-04-28 17:43:31.398583	118.42
37	2022-04-28 17:43:31.296583	99.019999999999996
38	2022-04-28 17:43:31.150583	121.51000000000001
39	2022-04-28 17:43:31.386583	85.200000000000003
40	2022-04-28 17:43:31.634583	130.56999999999999
41	2022-04-28 17:43:31.607583	144.63
42	2022-04-28 17:43:31.242583	61.700000000000003
43	2022-04-28 17:43:31.418583	7.1699999999999999
44	2022-04-28 17:43:31.162583	78.840000000000003
45	2022-04-28 17:43:31.659583	72.659999999999997
46	2022-04-28 17:43:31.580583	66.299999999999997
47	2022-04-28 17:43:31.356583	27.16
48	2022-04-28 17:43:31.506583	28.789999999999999
49	2022-04-28 17:43:31.172583	55.32
50	2022-04-28 17:43:31.374583	29.710000000000001
51	2022-04-28 17:43:31.125583	71.090000000000003
52	2022-04-28 17:43:31.178583	78.010000000000005
53	2022-04-28 17:43:31.604583	68.519999999999996
54	2022-04-28 17:43:31.722583	45.619999999999997
55	2022-04-28 17:43:31.569583	48.649999999999999
56	2022-04-28 17:43:31.410583	127.75
57	2022-04-28 17:43:31.872583	108.76000000000001
58	2022-04-28 17:43:31.480583	68.950000000000003
59	2022-04-28 17:43:31.251583	142.86000000000001
60	2022-04-28 17:43:31.434583	78.299999999999997
61	2022-04-28 17:43:31.745583	130.77000000000001
62	2022-04-28 17:43:31.880583	98.989999999999995
63	2022-04-28 17:43:31.578583	19.539999999999999
64	2022-04-28 17:43:31.522583	29.109999999999999
65	2022-04-28 17:43:31.269583	131.44999999999999
66	2022-04-28 17:43:31.800583	25.649999999999999
67	2022-04-28 17:43:31.342583	112.33
68	2022-04-28 17:43:31.958583	62.079999999999998
69	2022-04-28 17:43:31.971583	98.489999999999995
70	2022-04-28 17:43:31.844583	6.8099999999999996
71	2022-04-28 17:43:31.358583	110.33
72	2022-04-28 17:43:32.010583	78.739999999999995
73	2022-04-28 17:43:31.293583	129.96000000000001
74	2022-04-28 17:43:31.592583	89.849999999999994
75	2022-04-28 17:43:31.899583	16.539999999999999
76	2022-04-28 17:43:31.226583	11.699999999999999
77	2022-04-28 17:43:31.151583	117.64
78	2022-04-28 17:43:31.620583	15.84
79	2022-04-28 17:43:31.785583	59.579999999999998
80	2022-04-28 17:43:31.234583	75.840000000000003
81	2022-04-28 17:43:31.155583	93.260000000000005
82	2022-04-28 17:43:31.402583	106.03
83	2022-04-28 17:43:31.738583	29.379999999999999
84	2022-04-28 17:43:31.914583	33.140000000000001
85	2022-04-28 17:43:32.094583	8.4499999999999993
86	2022-04-28 17:43:31.848583	72.170000000000002
87	2022-04-28 17:43:31.422583	46.759999999999998
88	2022-04-28 17:43:31.514583	145.22999999999999
89	2022-04-28 17:43:32.320583	50.159999999999997
90	2022-04-28 17:43:31.794583	85.989999999999995
91	2022-04-28 17:43:31.984583	121.86
92	2022-04-28 17:43:31.810583	144.77000000000001
93	2022-04-28 17:43:32.283583	103.02
94	2022-04-28 17:43:31.356583	63.520000000000003
95	2022-04-28 17:43:31.644583	115.89
96	2022-04-28 17:43:32.226583	74.25
97	2022-04-28 17:43:31.947583	38.259999999999998
98	2022-04-28 17:43:31.270583	83.430000000000007
99	2022-04-28 17:43:31.866583	27.23
100	2022-04-28 17:43:32.474583	136.00999999999999
101	2022-04-28 17:43:31.579583	35.460000000000001
102	2022-04-28 17:43:32.196583	95.950000000000003
103	2022-04-28 17:43:31.898583	77.849999999999994
104	2022-04-28 17:43:32.426583	102.76000000000001
105	2022-04-28 17:43:31.914583	64.939999999999998
106	2022-04-28 17:43:31.392583	39.799999999999997
107	2022-04-28 17:43:32.358583	67.969999999999999
108	2022-04-28 17:43:32.370583	26.850000000000001
109	2022-04-28 17:43:31.401583	31.440000000000001
110	2022-04-28 17:43:32.394583	122.81
111	2022-04-28 17:43:31.296583	30.850000000000001
112	2022-04-28 17:43:32.530583	8.9100000000000001
113	2022-04-28 17:43:31.526583	8.6400000000000006
114	2022-04-28 17:43:32.556583	138.28
115	2022-04-28 17:43:31.649583	110.06999999999999
116	2022-04-28 17:43:31.886583	118.04000000000001
117	2022-04-28 17:43:31.776583	89.480000000000004
118	2022-04-28 17:43:31.782583	63.25
119	2022-04-28 17:43:31.312583	120.66
120	2022-04-28 17:43:31.914583	51.350000000000001
121	2022-04-28 17:43:32.526583	65.269999999999996
122	2022-04-28 17:43:32.782583	129.12
123	2022-04-28 17:43:32.304583	80.090000000000003
124	2022-04-28 17:43:32.314583	24.329999999999998
125	2022-04-28 17:43:31.949583	123.15000000000001
126	2022-04-28 17:43:31.956583	50.450000000000003
127	2022-04-28 17:43:31.836583	22
128	2022-04-28 17:43:32.738583	8.3900000000000006
129	2022-04-28 17:43:31.848583	103.90000000000001
130	2022-04-28 17:43:31.984583	72.780000000000001
131	2022-04-28 17:43:32.384583	132.90000000000001
132	2022-04-28 17:43:31.998583	105.95999999999999
133	2022-04-28 17:43:32.936583	44.420000000000002
134	2022-04-28 17:43:32.816583	36.5
135	2022-04-28 17:43:31.479583	61.649999999999999
136	2022-04-28 17:43:31.482583	47.890000000000001
137	2022-04-28 17:43:32.581583	73.260000000000005
138	2022-04-28 17:43:31.212583	87.980000000000004
139	2022-04-28 17:43:31.769583	1.8700000000000001
140	2022-04-28 17:43:31.914583	100.37
141	2022-04-28 17:43:31.920583	103.31
142	2022-04-28 17:43:32.210583	65.510000000000005
143	2022-04-28 17:43:31.932583	16.539999999999999
144	2022-04-28 17:43:32.082583	31.120000000000001
145	2022-04-28 17:43:32.669583	42.020000000000003
146	2022-04-28 17:43:31.366583	52.920000000000002
147	2022-04-28 17:43:32.103583	138.34
148	2022-04-28 17:43:32.554583	134.96000000000001
149	2022-04-28 17:43:31.372583	33.43
150	2022-04-28 17:43:33.024583	56.770000000000003
151	2022-04-28 17:43:32.584583	59.530000000000001
152	2022-04-28 17:43:31.378583	143.59999999999999
153	2022-04-28 17:43:32.757583	14.77
154	2022-04-28 17:43:32.460583	121.28
155	2022-04-28 17:43:31.539583	42.560000000000002
156	2022-04-28 17:43:32.946583	50.390000000000001
157	2022-04-28 17:43:32.016583	107.02
158	2022-04-28 17:43:31.390583	138.80000000000001
159	2022-04-28 17:43:32.028583	140.47999999999999
160	2022-04-28 17:43:32.034583	129.18000000000001
161	2022-04-28 17:43:33.006583	103.33
162	2022-04-28 17:43:32.370583	123.31
163	2022-04-28 17:43:32.052583	109.01000000000001
164	2022-04-28 17:43:33.206583	118.02
165	2022-04-28 17:43:33.054583	11.869999999999999
166	2022-04-28 17:43:32.568583	5.7999999999999998
167	2022-04-28 17:43:31.575583	142.84999999999999
168	2022-04-28 17:43:31.410583	144.97
169	2022-04-28 17:43:32.764583	81.329999999999998
170	2022-04-28 17:43:32.774583	36.289999999999999
171	2022-04-28 17:43:32.442583	94.129999999999995
172	2022-04-28 17:43:31.418583	64.159999999999997
173	2022-04-28 17:43:32.458583	108.38
174	2022-04-28 17:43:31.248583	98.159999999999997
175	2022-04-28 17:43:33.174583	106.47
176	2022-04-28 17:43:32.658583	10.699999999999999
177	2022-04-28 17:43:33.198583	1.99
178	2022-04-28 17:43:32.676583	134.21000000000001
179	2022-04-28 17:43:33.401583	27.59
180	2022-04-28 17:43:32.874583	144.12
181	2022-04-28 17:43:31.798583	112.09999999999999
182	2022-04-28 17:43:31.256583	11.06
183	2022-04-28 17:43:33.087583	111.12
184	2022-04-28 17:43:31.810583	53.329999999999998
185	2022-04-28 17:43:32.924583	15.210000000000001
186	2022-04-28 17:43:32.004583	118.55
187	2022-04-28 17:43:32.009583	22.239999999999998
188	2022-04-28 17:43:32.202583	26.780000000000001
189	2022-04-28 17:43:32.964583	13.4
190	2022-04-28 17:43:32.214583	86.409999999999997
191	2022-04-28 17:43:33.175583	36.450000000000003
192	2022-04-28 17:43:33.762583	13.42
193	2022-04-28 17:43:32.618583	73.870000000000005
194	2022-04-28 17:43:31.850583	16.48
195	2022-04-28 17:43:32.439583	20.510000000000002
196	2022-04-28 17:43:31.662583	72.590000000000003
197	2022-04-28 17:43:33.635583	104.29000000000001
198	2022-04-28 17:43:31.470583	110.34
199	2022-04-28 17:43:32.865583	144.88999999999999
200	2022-04-28 17:43:33.274583	105.87
201	2022-04-28 17:43:32.682583	95.310000000000002
202	2022-04-28 17:43:33.902583	110.72
203	2022-04-28 17:43:32.495583	108.44
204	2022-04-28 17:43:33.522583	100.42
205	2022-04-28 17:43:33.124583	56.850000000000001
206	2022-04-28 17:43:32.104583	116.34
207	2022-04-28 17:43:33.558583	10.17
208	2022-04-28 17:43:32.114583	135.59999999999999
209	2022-04-28 17:43:33.582583	135.74000000000001
210	2022-04-28 17:43:32.754583	31.890000000000001
211	2022-04-28 17:43:32.973583	19.079999999999998
212	2022-04-28 17:43:34.042583	79.560000000000002
213	2022-04-28 17:43:34.056583	113.8
214	2022-04-28 17:43:33.856583	79.680000000000007
215	2022-04-28 17:43:31.504583	88.280000000000001
216	2022-04-28 17:43:32.802583	94.379999999999995
217	2022-04-28 17:43:32.376583	92.349999999999994
218	2022-04-28 17:43:31.510583	12.84
219	2022-04-28 17:43:31.950583	29.140000000000001
220	2022-04-28 17:43:33.054583	112.47
221	2022-04-28 17:43:33.284583	74.620000000000005
222	2022-04-28 17:43:32.628583	6.0199999999999996
223	2022-04-28 17:43:33.750583	46.659999999999997
224	2022-04-28 17:43:33.314583	122.34
225	2022-04-28 17:43:32.649583	20.530000000000001
226	2022-04-28 17:43:34.238583	101.13
227	2022-04-28 17:43:32.663583	74.269999999999996
228	2022-04-28 17:43:31.758583	57.380000000000003
229	2022-04-28 17:43:33.593583	66.299999999999997
230	2022-04-28 17:43:33.604583	98.180000000000007
231	2022-04-28 17:43:33.846583	38.950000000000003
232	2022-04-28 17:43:33.162583	6.9800000000000004
233	2022-04-28 17:43:33.870583	92.459999999999994
234	2022-04-28 17:43:32.712583	28.920000000000002
235	2022-04-28 17:43:34.364583	26.780000000000001
236	2022-04-28 17:43:33.434583	90.870000000000005
237	2022-04-28 17:43:32.259583	113.70999999999999
238	2022-04-28 17:43:32.978583	9.2400000000000002
239	2022-04-28 17:43:33.464583	132.22
240	2022-04-28 17:43:33.474583	97.450000000000003
1	2022-04-28 17:43:31.077583	11.460000000000001
2	2022-04-28 17:43:31.078583	137.47999999999999
3	2022-04-28 17:43:31.104583	124.8
4	2022-04-28 17:43:31.090583	124.87
5	2022-04-28 17:43:31.109583	100.34
6	2022-04-28 17:43:31.110583	116.2
7	2022-04-28 17:43:31.123583	139.28
8	2022-04-28 17:43:31.186583	64.069999999999993
9	2022-04-28 17:43:31.191583	62
10	2022-04-28 17:43:31.114583	33.109999999999999
11	2022-04-28 17:43:31.217583	70.170000000000002
12	2022-04-28 17:43:31.218583	41.539999999999999
13	2022-04-28 17:43:31.165583	47.229999999999997
14	2022-04-28 17:43:31.158583	96.909999999999997
15	2022-04-28 17:43:31.284583	16.43
16	2022-04-28 17:43:31.250583	116.75
17	2022-04-28 17:43:31.261583	16.920000000000002
18	2022-04-28 17:43:31.236583	110.95
19	2022-04-28 17:43:31.150583	96.819999999999993
20	2022-04-28 17:43:31.194583	142.13999999999999
21	2022-04-28 17:43:31.221583	84.219999999999999
22	2022-04-28 17:43:31.316583	44.020000000000003
23	2022-04-28 17:43:31.350583	128.81
24	2022-04-28 17:43:31.170583	50.890000000000001
25	2022-04-28 17:43:31.374583	12.58
26	2022-04-28 17:43:31.152583	35.880000000000003
27	2022-04-28 17:43:31.371583	68.650000000000006
28	2022-04-28 17:43:31.410583	92.299999999999997
29	2022-04-28 17:43:31.190583	117.59
30	2022-04-28 17:43:31.314583	50.719999999999999
31	2022-04-28 17:43:31.291583	78.75
32	2022-04-28 17:43:31.490583	53.899999999999999
33	2022-04-28 17:43:31.536583	83.150000000000006
34	2022-04-28 17:43:31.142583	45.609999999999999
35	2022-04-28 17:43:31.284583	26.879999999999999
36	2022-04-28 17:43:31.254583	35.390000000000001
37	2022-04-28 17:43:31.148583	32.960000000000001
38	2022-04-28 17:43:31.530583	45.229999999999997
39	2022-04-28 17:43:31.503583	81.739999999999995
40	2022-04-28 17:43:31.354583	82.739999999999995
41	2022-04-28 17:43:31.197583	7.8399999999999999
42	2022-04-28 17:43:31.578583	132.81
43	2022-04-28 17:43:31.676583	71.400000000000006
44	2022-04-28 17:43:31.162583	43.649999999999999
45	2022-04-28 17:43:31.299583	135.31
46	2022-04-28 17:43:31.442583	54.130000000000003
47	2022-04-28 17:43:31.215583	6.0800000000000001
48	2022-04-28 17:43:31.458583	129.94
49	2022-04-28 17:43:31.613583	52.460000000000001
50	2022-04-28 17:43:31.374583	35.630000000000003
51	2022-04-28 17:43:31.686583	130.5
52	2022-04-28 17:43:31.802583	96.769999999999996
53	2022-04-28 17:43:31.710583	133.53999999999999
54	2022-04-28 17:43:31.290583	71.930000000000007
55	2022-04-28 17:43:31.624583	70.540000000000006
56	2022-04-28 17:43:31.802583	95.870000000000005
57	2022-04-28 17:43:31.416583	135.09999999999999
58	2022-04-28 17:43:31.306583	61.880000000000003
59	2022-04-28 17:43:31.723583	138.58000000000001
60	2022-04-28 17:43:31.494583	69.430000000000007
61	2022-04-28 17:43:31.501583	108.01000000000001
62	2022-04-28 17:43:31.942583	68.260000000000005
63	2022-04-28 17:43:31.704583	130.13
64	2022-04-28 17:43:31.202583	2.75
65	2022-04-28 17:43:31.789583	130.50999999999999
66	2022-04-28 17:43:31.668583	59.119999999999997
67	2022-04-28 17:43:31.342583	34.899999999999999
68	2022-04-28 17:43:31.822583	32.520000000000003
69	2022-04-28 17:43:31.212583	24.260000000000002
70	2022-04-28 17:43:31.214583	5.8700000000000001
71	2022-04-28 17:43:31.429583	87.700000000000003
72	2022-04-28 17:43:31.722583	122.52
73	2022-04-28 17:43:31.220583	129.38
74	2022-04-28 17:43:31.222583	35.789999999999999
75	2022-04-28 17:43:31.974583	14.19
76	2022-04-28 17:43:31.378583	110.29000000000001
77	2022-04-28 17:43:32.152583	125.66
78	2022-04-28 17:43:31.932583	16.899999999999999
79	2022-04-28 17:43:32.101583	70.959999999999994
80	2022-04-28 17:43:31.234583	134.22999999999999
81	2022-04-28 17:43:32.046583	27.93
82	2022-04-28 17:43:31.976583	113.72
83	2022-04-28 17:43:32.153583	69.370000000000005
84	2022-04-28 17:43:31.662583	15.800000000000001
85	2022-04-28 17:43:31.414583	2.96
86	2022-04-28 17:43:31.504583	81.239999999999995
87	2022-04-28 17:43:32.118583	56.399999999999999
88	2022-04-28 17:43:31.426583	127.72
89	2022-04-28 17:43:31.341583	21.940000000000001
90	2022-04-28 17:43:31.704583	108.28
91	2022-04-28 17:43:32.257583	120.61
92	2022-04-28 17:43:31.442583	90.480000000000004
93	2022-04-28 17:43:32.097583	122.11
94	2022-04-28 17:43:31.732583	52.890000000000001
95	2022-04-28 17:43:31.739583	88.700000000000003
96	2022-04-28 17:43:31.554583	89.560000000000002
97	2022-04-28 17:43:31.365583	26.120000000000001
98	2022-04-28 17:43:31.466583	16.43
99	2022-04-28 17:43:32.262583	121.73
100	2022-04-28 17:43:32.474583	85.219999999999999
101	2022-04-28 17:43:31.781583	135.40000000000001
102	2022-04-28 17:43:31.278583	115.42
103	2022-04-28 17:43:32.207583	90.980000000000004
104	2022-04-28 17:43:32.426583	81.560000000000002
105	2022-04-28 17:43:32.124583	128.52000000000001
106	2022-04-28 17:43:32.558583	111.88
107	2022-04-28 17:43:31.288583	42.729999999999997
108	2022-04-28 17:43:31.290583	4.2999999999999998
109	2022-04-28 17:43:32.600583	24.559999999999999
110	2022-04-28 17:43:31.294583	7.9400000000000004
111	2022-04-28 17:43:31.185583	12.19
112	2022-04-28 17:43:32.082583	88.579999999999998
113	2022-04-28 17:43:32.204583	103.7
114	2022-04-28 17:43:31.872583	99.879999999999995
115	2022-04-28 17:43:31.534583	12.279999999999999
116	2022-04-28 17:43:31.306583	42.729999999999997
117	2022-04-28 17:43:31.542583	120.34999999999999
118	2022-04-28 17:43:31.664583	135.43000000000001
119	2022-04-28 17:43:32.502583	60.859999999999999
120	2022-04-28 17:43:32.514583	15.09
121	2022-04-28 17:43:32.768583	131.49000000000001
122	2022-04-28 17:43:32.294583	86.159999999999997
123	2022-04-28 17:43:32.181583	78.730000000000004
124	2022-04-28 17:43:32.066583	122.41
125	2022-04-28 17:43:31.449583	24.43
126	2022-04-28 17:43:31.452583	95.870000000000005
127	2022-04-28 17:43:32.471583	132.31
128	2022-04-28 17:43:32.226583	55.740000000000002
129	2022-04-28 17:43:31.719583	61.840000000000003
130	2022-04-28 17:43:31.334583	9.1199999999999992
131	2022-04-28 17:43:31.598583	32.170000000000002
132	2022-04-28 17:43:31.866583	88.310000000000002
133	2022-04-28 17:43:32.670583	101.59999999999999
134	2022-04-28 17:43:32.280583	36.939999999999998
135	2022-04-28 17:43:32.964583	19.870000000000001
136	2022-04-28 17:43:31.618583	82.700000000000003
137	2022-04-28 17:43:31.759583	140.34
138	2022-04-28 17:43:31.488583	16.73
139	2022-04-28 17:43:31.908583	6.8499999999999996
140	2022-04-28 17:43:33.034583	25.52
141	2022-04-28 17:43:31.497583	85.579999999999998
142	2022-04-28 17:43:32.352583	6.8899999999999997
143	2022-04-28 17:43:33.076583	59.189999999999998
144	2022-04-28 17:43:32.226583	41.280000000000001
145	2022-04-28 17:43:31.799583	132.38
146	2022-04-28 17:43:32.388583	56.130000000000003
147	2022-04-28 17:43:31.956583	116.3
148	2022-04-28 17:43:32.998583	105.65000000000001
149	2022-04-28 17:43:32.266583	11.77
150	2022-04-28 17:43:32.724583	134.66
151	2022-04-28 17:43:33.188583	43.100000000000001
152	2022-04-28 17:43:32.898583	142.84
153	2022-04-28 17:43:33.216583	82.079999999999998
154	2022-04-28 17:43:31.998583	117.86
155	2022-04-28 17:43:32.934583	68.040000000000006
156	2022-04-28 17:43:33.258583	39.170000000000002
157	2022-04-28 17:43:32.173583	133.43000000000001
158	2022-04-28 17:43:33.128583	89.299999999999997
159	2022-04-28 17:43:32.664583	46.990000000000002
160	2022-04-28 17:43:32.674583	62.030000000000001
161	2022-04-28 17:43:31.718583	44.780000000000001
162	2022-04-28 17:43:33.342583	14.140000000000001
163	2022-04-28 17:43:32.378583	122.11
164	2022-04-28 17:43:31.730583	74.739999999999995
165	2022-04-28 17:43:31.404583	56.359999999999999
166	2022-04-28 17:43:32.568583	48.119999999999997
167	2022-04-28 17:43:31.909583	9.5600000000000005
168	2022-04-28 17:43:31.746583	128.31999999999999
169	2022-04-28 17:43:32.933583	86.230000000000004
170	2022-04-28 17:43:31.584583	57.32
171	2022-04-28 17:43:31.416583	102.7
172	2022-04-28 17:43:32.278583	115.31
173	2022-04-28 17:43:33.323583	53.880000000000003
174	2022-04-28 17:43:33.510583	60.390000000000001
175	2022-04-28 17:43:33.349583	42.789999999999999
176	2022-04-28 17:43:31.426583	34.259999999999998
177	2022-04-28 17:43:32.313583	50.68
178	2022-04-28 17:43:33.032583	95.659999999999997
179	2022-04-28 17:43:31.969583	109.52
180	2022-04-28 17:43:32.514583	15.99
181	2022-04-28 17:43:31.979583	122
182	2022-04-28 17:43:33.076583	61.700000000000003
183	2022-04-28 17:43:33.453583	95.5
184	2022-04-28 17:43:33.650583	55.840000000000003
185	2022-04-28 17:43:32.924583	1.27
186	2022-04-28 17:43:33.492583	8.7699999999999996
187	2022-04-28 17:43:31.822583	39.350000000000001
188	2022-04-28 17:43:32.202583	70.239999999999995
189	2022-04-28 17:43:33.342583	30.18
190	2022-04-28 17:43:31.644583	20.710000000000001
191	2022-04-28 17:43:33.557583	120.40000000000001
192	2022-04-28 17:43:32.802583	113.22
193	2022-04-28 17:43:32.039583	48.990000000000002
194	2022-04-28 17:43:33.596583	135.37
195	2022-04-28 17:43:32.049583	81.310000000000002
196	2022-04-28 17:43:32.838583	144.30000000000001
197	2022-04-28 17:43:31.665583	144.69999999999999
198	2022-04-28 17:43:31.470583	32.369999999999997
199	2022-04-28 17:43:33.860583	9.2799999999999994
200	2022-04-28 17:43:33.674583	41.030000000000001
201	2022-04-28 17:43:32.280583	82.670000000000002
202	2022-04-28 17:43:33.094583	133.21000000000001
203	2022-04-28 17:43:32.495583	5.5199999999999996
204	2022-04-28 17:43:31.278583	23.510000000000002
205	2022-04-28 17:43:33.944583	39.25
206	2022-04-28 17:43:33.546583	15.210000000000001
207	2022-04-28 17:43:32.937583	51.189999999999998
208	2022-04-28 17:43:31.906583	72.799999999999997
209	2022-04-28 17:43:31.910583	140.53
210	2022-04-28 17:43:31.704583	83.579999999999998
211	2022-04-28 17:43:33.395583	9.6600000000000001
212	2022-04-28 17:43:31.498583	22.91
213	2022-04-28 17:43:32.565583	127.22
214	2022-04-28 17:43:34.070583	33.5
215	2022-04-28 17:43:31.934583	23.079999999999998
216	2022-04-28 17:43:32.802583	112.29000000000001
217	2022-04-28 17:43:32.159583	128.47999999999999
218	2022-04-28 17:43:33.472583	48.700000000000003
219	2022-04-28 17:43:31.731583	98.939999999999998
220	2022-04-28 17:43:32.394583	40.189999999999998
221	2022-04-28 17:43:32.179583	109.51000000000001
222	2022-04-28 17:43:34.182583	8.5899999999999999
223	2022-04-28 17:43:33.527583	71.370000000000005
224	2022-04-28 17:43:32.418583	110.92
225	2022-04-28 17:43:33.774583	83.219999999999999
226	2022-04-28 17:43:34.238583	144.44
227	2022-04-28 17:43:34.252583	46.920000000000002
228	2022-04-28 17:43:32.898583	46.960000000000001
229	2022-04-28 17:43:32.906583	81.030000000000001
230	2022-04-28 17:43:32.914583	80.090000000000003
231	2022-04-28 17:43:31.536583	114.45
232	2022-04-28 17:43:34.322583	119.93000000000001
233	2022-04-28 17:43:33.637583	9.5700000000000003
234	2022-04-28 17:43:33.882583	103.43000000000001
235	2022-04-28 17:43:33.189583	127.81999999999999
236	2022-04-28 17:43:32.490583	82.799999999999997
237	2022-04-28 17:43:33.207583	123.56
238	2022-04-28 17:43:32.026583	144.87
239	2022-04-28 17:43:31.791583	3.04
240	2022-04-28 17:43:32.754583	135.22
2	2022-04-28 17:54:18.500623	0.29999999999999999
8	2022-04-28 17:54:18.500623	0.29999999999999999
10	2022-04-28 17:54:18.500623	0.46000000000000002
2	2022-04-28 17:54:31.447703	0.29999999999999999
8	2022-04-28 17:54:31.447703	0.29999999999999999
10	2022-04-28 17:54:31.447703	0.46000000000000002
\.


--
-- TOC entry 2573 (class 0 OID 94466)
-- Dependencies: 245
-- Data for Name: _hyper_2_4_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_2_4_chunk (key, fix, value) FROM stdin;
2	2022-05-05 10:21:29.41808	0.29999999999999999
2	2022-05-05 10:21:57.037718	0.29999999999999999
\.


--
-- TOC entry 2569 (class 0 OID 94406)
-- Dependencies: 241
-- Data for Name: float_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_actual (key, fix, value) FROM stdin;
1	2022-04-28 17:43:31.079583	44.979999999999997
3	2022-04-28 17:43:31.092583	5.5999999999999996
4	2022-04-28 17:43:31.122583	46.640000000000001
5	2022-04-28 17:43:31.124583	102.19
6	2022-04-28 17:43:31.134583	29.109999999999999
7	2022-04-28 17:43:31.165583	139.40000000000001
9	2022-04-28 17:43:31.173583	70.030000000000001
11	2022-04-28 17:43:31.129583	80.409999999999997
12	2022-04-28 17:43:31.170583	8.9700000000000006
13	2022-04-28 17:43:31.139583	33
14	2022-04-28 17:43:31.172583	124.45
15	2022-04-28 17:43:31.104583	2.71
16	2022-04-28 17:43:31.170583	129.66
17	2022-04-28 17:43:31.108583	140.30000000000001
18	2022-04-28 17:43:31.272583	48.460000000000001
19	2022-04-28 17:43:31.283583	7.04
20	2022-04-28 17:43:31.174583	87.780000000000001
21	2022-04-28 17:43:31.221583	90.010000000000005
22	2022-04-28 17:43:31.118583	132.41999999999999
23	2022-04-28 17:43:31.212583	76.709999999999994
24	2022-04-28 17:43:31.410583	33.719999999999999
25	2022-04-28 17:43:31.124583	101.58
26	2022-04-28 17:43:31.204583	88.159999999999997
27	2022-04-28 17:43:31.209583	33.979999999999997
28	2022-04-28 17:43:31.438583	107.29000000000001
29	2022-04-28 17:43:31.422583	10.699999999999999
30	2022-04-28 17:43:31.254583	19.489999999999998
31	2022-04-28 17:43:31.353583	140.38999999999999
32	2022-04-28 17:43:31.202583	101.38
33	2022-04-28 17:43:31.272583	113.81
34	2022-04-28 17:43:31.176583	132.38999999999999
35	2022-04-28 17:43:31.214583	41.5
36	2022-04-28 17:43:31.254583	100.78
37	2022-04-28 17:43:31.222583	132.97999999999999
38	2022-04-28 17:43:31.150583	101.59999999999999
39	2022-04-28 17:43:31.386583	87.689999999999998
40	2022-04-28 17:43:31.474583	109.54000000000001
41	2022-04-28 17:43:31.238583	35.689999999999998
42	2022-04-28 17:43:31.578583	56.369999999999997
43	2022-04-28 17:43:31.504583	110.17
44	2022-04-28 17:43:31.470583	115.95999999999999
45	2022-04-28 17:43:31.164583	1.8899999999999999
46	2022-04-28 17:43:31.442583	94.900000000000006
47	2022-04-28 17:43:31.544583	21.859999999999999
48	2022-04-28 17:43:31.170583	68.159999999999997
49	2022-04-28 17:43:31.368583	54.479999999999997
50	2022-04-28 17:43:31.524583	84.730000000000004
51	2022-04-28 17:43:31.380583	11.279999999999999
52	2022-04-28 17:43:31.126583	112.93000000000001
53	2022-04-28 17:43:31.392583	89.969999999999999
54	2022-04-28 17:43:31.398583	60.079999999999998
55	2022-04-28 17:43:31.239583	30.690000000000001
56	2022-04-28 17:43:31.354583	29.09
57	2022-04-28 17:43:31.416583	94.909999999999997
58	2022-04-28 17:43:31.828583	48.259999999999998
59	2022-04-28 17:43:31.251583	124.20999999999999
60	2022-04-28 17:43:31.914583	85.590000000000003
61	2022-04-28 17:43:31.318583	55.109999999999999
62	2022-04-28 17:43:31.818583	31.960000000000001
63	2022-04-28 17:43:31.767583	95.069999999999993
64	2022-04-28 17:43:31.202583	10.470000000000001
65	2022-04-28 17:43:31.919583	87.180000000000007
66	2022-04-28 17:43:31.404583	17.84
67	2022-04-28 17:43:31.208583	17.600000000000001
68	2022-04-28 17:43:31.482583	25.82
69	2022-04-28 17:43:31.350583	4.8700000000000001
70	2022-04-28 17:43:32.054583	13.890000000000001
71	2022-04-28 17:43:31.500583	24.289999999999999
72	2022-04-28 17:43:31.722583	125.09
73	2022-04-28 17:43:31.877583	50.380000000000003
74	2022-04-28 17:43:31.444583	143.72
75	2022-04-28 17:43:31.449583	103.33
76	2022-04-28 17:43:31.454583	77.109999999999999
77	2022-04-28 17:43:31.536583	142.97999999999999
78	2022-04-28 17:43:31.542583	142.43000000000001
79	2022-04-28 17:43:31.390583	115.68000000000001
80	2022-04-28 17:43:31.234583	108.43000000000001
81	2022-04-28 17:43:31.803583	49.020000000000003
82	2022-04-28 17:43:31.730583	83.349999999999994
83	2022-04-28 17:43:32.153583	20.77
84	2022-04-28 17:43:31.326583	38.549999999999997
85	2022-04-28 17:43:31.499583	104.34999999999999
86	2022-04-28 17:43:31.246583	21.379999999999999
87	2022-04-28 17:43:32.205583	131.41
88	2022-04-28 17:43:31.426583	8.8000000000000007
89	2022-04-28 17:43:32.053583	143.43000000000001
90	2022-04-28 17:43:31.704583	59.439999999999998
91	2022-04-28 17:43:31.620583	10.34
92	2022-04-28 17:43:32.178583	25.82
93	2022-04-28 17:43:31.539583	115.06
94	2022-04-28 17:43:32.108583	8.0500000000000007
95	2022-04-28 17:43:32.119583	61.469999999999999
96	2022-04-28 17:43:32.418583	64.269999999999996
97	2022-04-28 17:43:32.432583	36.329999999999998
98	2022-04-28 17:43:31.858583	5.3099999999999996
99	2022-04-28 17:43:31.965583	9.8499999999999996
100	2022-04-28 17:43:32.474583	90.280000000000001
101	2022-04-28 17:43:31.478583	3.8500000000000001
102	2022-04-28 17:43:32.196583	79.25
103	2022-04-28 17:43:32.001583	24.18
104	2022-04-28 17:43:32.114583	69.670000000000002
105	2022-04-28 17:43:32.229583	46.479999999999997
106	2022-04-28 17:43:31.498583	35.369999999999997
107	2022-04-28 17:43:31.716583	91.450000000000003
108	2022-04-28 17:43:31.722583	73.349999999999994
109	2022-04-28 17:43:31.946583	52.869999999999997
110	2022-04-28 17:43:31.624583	15.35
111	2022-04-28 17:43:31.740583	17.789999999999999
112	2022-04-28 17:43:31.970583	121.43000000000001
113	2022-04-28 17:43:32.317583	95.939999999999998
114	2022-04-28 17:43:31.416583	90.890000000000001
115	2022-04-28 17:43:31.764583	29.579999999999998
116	2022-04-28 17:43:31.886583	99.819999999999993
117	2022-04-28 17:43:31.191583	122.52
118	2022-04-28 17:43:31.546583	52.469999999999999
119	2022-04-28 17:43:31.788583	39.530000000000001
120	2022-04-28 17:43:32.154583	21.09
121	2022-04-28 17:43:31.437583	38.990000000000002
122	2022-04-28 17:43:31.684583	63.609999999999999
123	2022-04-28 17:43:31.566583	103.56
124	2022-04-28 17:43:31.446583	54.43
125	2022-04-28 17:43:32.699583	4.6200000000000001
126	2022-04-28 17:43:32.082583	40.490000000000002
127	2022-04-28 17:43:32.598583	127.09999999999999
128	2022-04-28 17:43:31.586583	10.390000000000001
129	2022-04-28 17:43:32.106583	131.28
130	2022-04-28 17:43:32.504583	139.08000000000001
131	2022-04-28 17:43:31.205583	6.7800000000000002
132	2022-04-28 17:43:31.338583	82.140000000000001
133	2022-04-28 17:43:32.803583	80.700000000000003
134	2022-04-28 17:43:31.610583	72.25
135	2022-04-28 17:43:31.884583	3.29
136	2022-04-28 17:43:31.482583	38.479999999999997
137	2022-04-28 17:43:32.718583	20.629999999999999
138	2022-04-28 17:43:33.006583	20.890000000000001
139	2022-04-28 17:43:32.742583	12.619999999999999
140	2022-04-28 17:43:32.474583	9.6300000000000008
141	2022-04-28 17:43:32.202583	112.95999999999999
142	2022-04-28 17:43:32.636583	52.450000000000003
143	2022-04-28 17:43:32.504583	22.719999999999999
144	2022-04-28 17:43:32.946583	21.649999999999999
145	2022-04-28 17:43:32.379583	24.5
146	2022-04-28 17:43:32.826583	62.369999999999997
147	2022-04-28 17:43:32.250583	87.75
148	2022-04-28 17:43:31.518583	14.26
149	2022-04-28 17:43:31.521583	106.08
150	2022-04-28 17:43:32.274583	92.140000000000001
151	2022-04-28 17:43:32.282583	89.140000000000001
152	2022-04-28 17:43:33.202583	125.06
153	2022-04-28 17:43:32.910583	36.590000000000003
154	2022-04-28 17:43:32.152583	95.269999999999996
155	2022-04-28 17:43:33.089583	13.16
156	2022-04-28 17:43:31.698583	62.780000000000001
157	2022-04-28 17:43:31.859583	104.19
158	2022-04-28 17:43:32.022583	35.710000000000001
159	2022-04-28 17:43:31.869583	107.92
160	2022-04-28 17:43:33.154583	108.31999999999999
161	2022-04-28 17:43:32.684583	12.73
162	2022-04-28 17:43:33.180583	35.689999999999998
163	2022-04-28 17:43:31.563583	109.23
164	2022-04-28 17:43:32.878583	30.190000000000001
165	2022-04-28 17:43:31.239583	127.81999999999999
166	2022-04-28 17:43:33.398583	15.380000000000001
167	2022-04-28 17:43:32.410583	4.2199999999999998
168	2022-04-28 17:43:32.586583	137.31999999999999
169	2022-04-28 17:43:33.102583	129.38
170	2022-04-28 17:43:32.434583	65.689999999999998
171	2022-04-28 17:43:32.784583	36.420000000000002
172	2022-04-28 17:43:31.762583	78.959999999999994
173	2022-04-28 17:43:33.323583	62.060000000000002
174	2022-04-28 17:43:31.596583	113.41
175	2022-04-28 17:43:31.774583	128.59999999999999
176	2022-04-28 17:43:33.186583	62.600000000000001
177	2022-04-28 17:43:33.198583	116.15000000000001
178	2022-04-28 17:43:33.566583	60.079999999999998
179	2022-04-28 17:43:33.043583	106.31999999999999
180	2022-04-28 17:43:32.874583	15.69
181	2022-04-28 17:43:32.522583	40.130000000000003
182	2022-04-28 17:43:32.894583	4.9699999999999998
183	2022-04-28 17:43:31.623583	21.309999999999999
184	2022-04-28 17:43:33.466583	34.340000000000003
185	2022-04-28 17:43:31.629583	67.209999999999994
186	2022-04-28 17:43:32.376583	58.979999999999997
187	2022-04-28 17:43:31.822583	61.939999999999998
188	2022-04-28 17:43:31.450583	60.359999999999999
189	2022-04-28 17:43:33.342583	48.950000000000003
190	2022-04-28 17:43:32.024583	108.28
191	2022-04-28 17:43:32.793583	143.49000000000001
192	2022-04-28 17:43:31.266583	19.609999999999999
193	2022-04-28 17:43:31.460583	79.670000000000002
194	2022-04-28 17:43:31.850583	108.02
195	2022-04-28 17:43:31.464583	24.510000000000002
196	2022-04-28 17:43:31.858583	12.41
197	2022-04-28 17:43:31.862583	59.609999999999999
198	2022-04-28 17:43:33.846583	60.030000000000001
199	2022-04-28 17:43:32.865583	31.66
200	2022-04-28 17:43:32.474583	114.26000000000001
201	2022-04-28 17:43:32.682583	137.24000000000001
202	2022-04-28 17:43:33.094583	107.91
203	2022-04-28 17:43:32.495583	58.82
204	2022-04-28 17:43:31.890583	64.280000000000001
205	2022-04-28 17:43:33.329583	82.780000000000001
206	2022-04-28 17:43:32.928583	60.060000000000002
207	2022-04-28 17:43:32.523583	138.34
208	2022-04-28 17:43:32.738583	72.219999999999999
209	2022-04-28 17:43:32.119583	75.219999999999999
210	2022-04-28 17:43:34.014583	83.120000000000005
211	2022-04-28 17:43:33.817583	22.48
212	2022-04-28 17:43:31.922583	142.86000000000001
213	2022-04-28 17:43:32.139583	52.350000000000001
214	2022-04-28 17:43:31.930583	120.77
215	2022-04-28 17:43:32.579583	95.890000000000001
216	2022-04-28 17:43:33.666583	92.209999999999994
217	2022-04-28 17:43:33.895583	77.75
218	2022-04-28 17:43:31.946583	92.299999999999997
219	2022-04-28 17:43:32.388583	39.060000000000002
220	2022-04-28 17:43:33.274583	98.969999999999999
221	2022-04-28 17:43:32.400583	116.78
222	2022-04-28 17:43:31.296583	70.200000000000003
223	2022-04-28 17:43:33.081583	116.02
224	2022-04-28 17:43:33.314583	36.329999999999998
225	2022-04-28 17:43:33.999583	69.650000000000006
226	2022-04-28 17:43:31.752583	14.140000000000001
227	2022-04-28 17:43:32.209583	124.95
228	2022-04-28 17:43:34.038583	56.850000000000001
229	2022-04-28 17:43:33.593583	95.090000000000003
230	2022-04-28 17:43:32.914583	15.130000000000001
231	2022-04-28 17:43:31.998583	53.340000000000003
232	2022-04-28 17:43:34.322583	12.1
233	2022-04-28 17:43:33.637583	135.91
234	2022-04-28 17:43:32.946583	128.44999999999999
235	2022-04-28 17:43:33.659583	129.87
236	2022-04-28 17:43:31.782583	1.8799999999999999
237	2022-04-28 17:43:33.918583	40.109999999999999
238	2022-04-28 17:43:32.026583	15.380000000000001
239	2022-04-28 17:43:31.791583	103.06
240	2022-04-28 17:43:32.514583	67
8	2022-04-28 17:54:31.447703	0.29999999999999999
10	2022-04-28 17:54:31.447703	0.46000000000000002
2	2022-05-05 10:21:57.037718	0.29999999999999999
\.


--
-- TOC entry 2568 (class 0 OID 94396)
-- Dependencies: 240
-- Data for Name: float_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_archive (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2562 (class 0 OID 94337)
-- Dependencies: 234
-- Data for Name: glossary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.glossary (key, communication, configuration, tablename) FROM stdin;
2	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='photocathode']/Amperage	float
1	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='photocathode']/Voltage	integer
8	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate1']/Amperage	float
7	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate1']/Voltage	integer
4	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate12']/Amperage	float
3	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate12']/Voltage	integer
10	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate2']/Amperage	float
9	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='microchannelplate2']/Voltage	integer
6	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='anode']/Amperage	float
5	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='01']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='1']/Supply/Item[@key='anode']/Voltage	integer
12	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='photocathode']/Amperage	float
11	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='photocathode']/Voltage	integer
18	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate1']/Amperage	float
17	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate1']/Voltage	integer
14	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate12']/Amperage	float
13	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate12']/Voltage	integer
20	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate2']/Amperage	float
19	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='microchannelplate2']/Voltage	integer
16	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='anode']/Amperage	float
15	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='02']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='2']/Supply/Item[@key='anode']/Voltage	integer
22	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='photocathode']/Amperage	float
21	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='photocathode']/Voltage	integer
28	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate1']/Amperage	float
27	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate1']/Voltage	integer
24	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate12']/Amperage	float
23	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate12']/Voltage	integer
30	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate2']/Amperage	float
29	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='microchannelplate2']/Voltage	integer
26	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='anode']/Amperage	float
25	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='03']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='3']/Supply/Item[@key='anode']/Voltage	integer
32	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='photocathode']/Amperage	float
31	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='photocathode']/Voltage	integer
38	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate1']/Amperage	float
37	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate1']/Voltage	integer
34	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate12']/Amperage	float
33	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate12']/Voltage	integer
40	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate2']/Amperage	float
39	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='microchannelplate2']/Voltage	integer
36	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='anode']/Amperage	float
35	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='04']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='4']/Supply/Item[@key='anode']/Voltage	integer
42	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='photocathode']/Amperage	float
41	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='photocathode']/Voltage	integer
48	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate1']/Amperage	float
47	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate1']/Voltage	integer
44	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate12']/Amperage	float
43	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate12']/Voltage	integer
50	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate2']/Amperage	float
49	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='microchannelplate2']/Voltage	integer
46	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='anode']/Amperage	float
45	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='05']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='5']/Supply/Item[@key='anode']/Voltage	integer
52	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='photocathode']/Amperage	float
51	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='photocathode']/Voltage	integer
58	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate1']/Amperage	float
57	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate1']/Voltage	integer
54	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate12']/Amperage	float
53	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate12']/Voltage	integer
60	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate2']/Amperage	float
59	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='microchannelplate2']/Voltage	integer
56	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='anode']/Amperage	float
55	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='06']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='6']/Supply/Item[@key='anode']/Voltage	integer
62	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='photocathode']/Amperage	float
61	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='photocathode']/Voltage	integer
68	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate1']/Amperage	float
67	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate1']/Voltage	integer
64	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate12']/Amperage	float
63	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate12']/Voltage	integer
70	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate2']/Amperage	float
69	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='microchannelplate2']/Voltage	integer
66	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='anode']/Amperage	float
65	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='07']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='7']/Supply/Item[@key='anode']/Voltage	integer
72	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='photocathode']/Amperage	float
71	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='photocathode']/Voltage	integer
78	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate1']/Amperage	float
77	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate1']/Voltage	integer
74	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate12']/Amperage	float
73	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate12']/Voltage	integer
80	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate2']/Amperage	float
79	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='microchannelplate2']/Voltage	integer
76	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='anode']/Amperage	float
75	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='08']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='8']/Supply/Item[@key='anode']/Voltage	integer
82	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='photocathode']/Amperage	float
81	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='photocathode']/Voltage	integer
88	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate1']/Amperage	float
87	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate1']/Voltage	integer
84	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate12']/Amperage	float
83	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate12']/Voltage	integer
90	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate2']/Amperage	float
89	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='microchannelplate2']/Voltage	integer
86	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='anode']/Amperage	float
85	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='09']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='9']/Supply/Item[@key='anode']/Voltage	integer
92	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='photocathode']/Amperage	float
91	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='photocathode']/Voltage	integer
98	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate1']/Amperage	float
97	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate1']/Voltage	integer
94	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate12']/Amperage	float
93	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate12']/Voltage	integer
100	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate2']/Amperage	float
99	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='microchannelplate2']/Voltage	integer
96	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='anode']/Amperage	float
95	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='10']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='10']/Supply/Item[@key='anode']/Voltage	integer
102	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='photocathode']/Amperage	float
101	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='photocathode']/Voltage	integer
108	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate1']/Amperage	float
107	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate1']/Voltage	integer
104	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate12']/Amperage	float
103	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate12']/Voltage	integer
110	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate2']/Amperage	float
109	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='microchannelplate2']/Voltage	integer
106	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='anode']/Amperage	float
105	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='11']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='11']/Supply/Item[@key='anode']/Voltage	integer
112	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='photocathode']/Amperage	float
111	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='photocathode']/Voltage	integer
118	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate1']/Amperage	float
117	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate1']/Voltage	integer
114	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate12']/Amperage	float
113	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate12']/Voltage	integer
120	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate2']/Amperage	float
119	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='microchannelplate2']/Voltage	integer
116	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='anode']/Amperage	float
115	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='12']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='12']/Supply/Item[@key='anode']/Voltage	integer
122	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='photocathode']/Amperage	float
121	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='photocathode']/Voltage	integer
128	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate1']/Amperage	float
127	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate1']/Voltage	integer
124	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate12']/Amperage	float
123	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate12']/Voltage	integer
130	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate2']/Amperage	float
129	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='microchannelplate2']/Voltage	integer
126	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='anode']/Amperage	float
125	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='13']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='13']/Supply/Item[@key='anode']/Voltage	integer
132	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='photocathode']/Amperage	float
131	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='photocathode']/Voltage	integer
138	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate1']/Amperage	float
137	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate1']/Voltage	integer
134	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate12']/Amperage	float
133	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate12']/Voltage	integer
140	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate2']/Amperage	float
139	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='microchannelplate2']/Voltage	integer
136	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='anode']/Amperage	float
135	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='14']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='14']/Supply/Item[@key='anode']/Voltage	integer
142	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='photocathode']/Amperage	float
141	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='photocathode']/Voltage	integer
148	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate1']/Amperage	float
147	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate1']/Voltage	integer
144	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate12']/Amperage	float
143	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate12']/Voltage	integer
150	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate2']/Amperage	float
149	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='microchannelplate2']/Voltage	integer
146	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='anode']/Amperage	float
145	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='15']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='15']/Supply/Item[@key='anode']/Voltage	integer
152	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='photocathode']/Amperage	float
151	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='photocathode']/Voltage	integer
158	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate1']/Amperage	float
157	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate1']/Voltage	integer
154	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate12']/Amperage	float
153	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate12']/Voltage	integer
160	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate2']/Amperage	float
159	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='microchannelplate2']/Voltage	integer
156	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='anode']/Amperage	float
155	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='16']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='16']/Supply/Item[@key='anode']/Voltage	integer
162	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='photocathode']/Amperage	float
161	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='photocathode']/Voltage	integer
168	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate1']/Amperage	float
167	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate1']/Voltage	integer
164	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate12']/Amperage	float
163	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate12']/Voltage	integer
170	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate2']/Amperage	float
169	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='microchannelplate2']/Voltage	integer
166	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='anode']/Amperage	float
165	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='17']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='17']/Supply/Item[@key='anode']/Voltage	integer
172	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='photocathode']/Amperage	float
171	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='photocathode']/Voltage	integer
178	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate1']/Amperage	float
177	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate1']/Voltage	integer
174	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate12']/Amperage	float
173	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate12']/Voltage	integer
180	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate2']/Amperage	float
179	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='microchannelplate2']/Voltage	integer
176	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='anode']/Amperage	float
175	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='18']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='18']/Supply/Item[@key='anode']/Voltage	integer
182	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='photocathode']/Amperage	float
181	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='photocathode']/Voltage	integer
188	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate1']/Amperage	float
187	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate1']/Voltage	integer
184	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate12']/Amperage	float
183	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate12']/Voltage	integer
190	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate2']/Amperage	float
189	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='microchannelplate2']/Voltage	integer
186	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='anode']/Amperage	float
185	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='19']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='19']/Supply/Item[@key='anode']/Voltage	integer
192	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='photocathode']/Amperage	float
191	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='photocathode']/Voltage	integer
198	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate1']/Amperage	float
197	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate1']/Voltage	integer
194	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate12']/Amperage	float
193	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate12']/Voltage	integer
200	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate2']/Amperage	float
199	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='microchannelplate2']/Voltage	integer
196	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='anode']/Amperage	float
195	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='20']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='20']/Supply/Item[@key='anode']/Voltage	integer
202	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='photocathode']/Amperage	float
201	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='photocathode']/Voltage	integer
208	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate1']/Amperage	float
207	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate1']/Voltage	integer
204	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate12']/Amperage	float
203	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate12']/Voltage	integer
210	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate2']/Amperage	float
209	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='microchannelplate2']/Voltage	integer
206	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='anode']/Amperage	float
205	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='21']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='21']/Supply/Item[@key='anode']/Voltage	integer
212	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='photocathode']/Amperage	float
211	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='photocathode']/Voltage	integer
218	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate1']/Amperage	float
217	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate1']/Voltage	integer
214	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate12']/Amperage	float
213	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate12']/Voltage	integer
220	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate2']/Amperage	float
219	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='microchannelplate2']/Voltage	integer
216	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='anode']/Amperage	float
215	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='22']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='22']/Supply/Item[@key='anode']/Voltage	integer
222	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='photocathode']/Amperage	float
221	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='photocathode']/Voltage	integer
228	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate1']/Amperage	float
227	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate1']/Voltage	integer
224	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate12']/Amperage	float
223	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate12']/Voltage	integer
230	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate2']/Amperage	float
229	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='microchannelplate2']/Voltage	integer
226	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='anode']/Amperage	float
225	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='23']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='23']/Supply/Item[@key='anode']/Voltage	integer
232	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='1']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='photocathode']/Amperage	float
231	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='1']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='photocathode']/Voltage	integer
238	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='2']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate1']/Amperage	float
237	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='2']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate1']/Voltage	integer
234	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='3']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate12']/Amperage	float
233	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='3']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate12']/Voltage	integer
240	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='4']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate2']/Amperage	float
239	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='4']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='microchannelplate2']/Voltage	integer
236	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='5']/Amperage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='anode']/Amperage	float
235	Configuration[@key='_036CE061.Communicator']/Scale/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Communication/Item[@key='serialport']/Modbus/Item[@key='COM2']/Board/Item[@key='_045СЕ108']/Adress/Item[@key='24']/Channel/Item[@key='5']/Voltage	Configuration[@key='_036CE061.ControlWorkstation']/Communication/Item[@key='database']/Postgres/Item[@key='localhost:5432:_036CE061.Runtime']/Equipment/Scale/Slot/Item[@key='24']/Supply/Item[@key='anode']/Voltage	integer
\.


--
-- TOC entry 2595 (class 0 OID 0)
-- Dependencies: 233
-- Name: glossary_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.glossary_key_seq', 240, true);


--
-- TOC entry 2567 (class 0 OID 94388)
-- Dependencies: 239
-- Data for Name: integer_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_actual (key, fix, value) FROM stdin;
2	2022-04-28 17:43:31.088583	92
3	2022-04-28 17:43:31.086583	77
4	2022-04-28 17:43:31.122583	145
6	2022-04-28 17:43:31.146583	83
8	2022-04-28 17:43:31.106583	78
10	2022-04-28 17:43:31.124583	98
11	2022-04-28 17:43:31.184583	101
12	2022-04-28 17:43:31.110583	132
13	2022-04-28 17:43:31.126583	60
14	2022-04-28 17:43:31.158583	14
15	2022-04-28 17:43:31.104583	78
16	2022-04-28 17:43:31.138583	72
17	2022-04-28 17:43:31.125583	83
18	2022-04-28 17:43:31.110583	131
19	2022-04-28 17:43:31.188583	48
20	2022-04-28 17:43:31.274583	33
21	2022-04-28 17:43:31.158583	115
22	2022-04-28 17:43:31.206583	22
23	2022-04-28 17:43:31.120583	117
24	2022-04-28 17:43:31.218583	117
25	2022-04-28 17:43:31.324583	104
26	2022-04-28 17:43:31.178583	141
27	2022-04-28 17:43:31.344583	110
28	2022-04-28 17:43:31.186583	114
29	2022-04-28 17:43:31.103583	77
30	2022-04-28 17:43:31.284583	113
31	2022-04-28 17:43:31.167583	109
32	2022-04-28 17:43:31.490583	120
33	2022-04-28 17:43:31.206583	50
34	2022-04-28 17:43:31.312583	89
35	2022-04-28 17:43:31.459583	42
36	2022-04-28 17:43:31.218583	69
37	2022-04-28 17:43:31.370583	14
38	2022-04-28 17:43:31.340583	133
39	2022-04-28 17:43:31.308583	5
40	2022-04-28 17:43:31.554583	57
41	2022-04-28 17:43:31.115583	85
42	2022-04-28 17:43:31.368583	52
43	2022-04-28 17:43:31.332583	36
44	2022-04-28 17:43:31.558583	55
45	2022-04-28 17:43:31.344583	43
46	2022-04-28 17:43:31.672583	120
47	2022-04-28 17:43:31.685583	127
48	2022-04-28 17:43:31.170583	70
49	2022-04-28 17:43:31.711583	78
50	2022-04-28 17:43:31.724583	104
51	2022-04-28 17:43:31.380583	113
52	2022-04-28 17:43:31.178583	56
53	2022-04-28 17:43:31.498583	107
54	2022-04-28 17:43:31.506583	91
55	2022-04-28 17:43:31.349583	47
56	2022-04-28 17:43:31.466583	143
57	2022-04-28 17:43:31.644583	8
58	2022-04-28 17:43:31.712583	82
59	2022-04-28 17:43:31.369583	84
60	2022-04-28 17:43:31.554583	143
61	2022-04-28 17:43:31.623583	10
62	2022-04-28 17:43:31.384583	65
63	2022-04-28 17:43:31.452583	54
64	2022-04-28 17:43:31.650583	90
65	2022-04-28 17:43:31.139583	141
66	2022-04-28 17:43:31.206583	117
67	2022-04-28 17:43:31.275583	23
68	2022-04-28 17:43:31.210583	36
69	2022-04-28 17:43:31.626583	7
70	2022-04-28 17:43:31.914583	88
71	2022-04-28 17:43:31.855583	24
72	2022-04-28 17:43:31.218583	5
73	2022-04-28 17:43:31.950583	132
74	2022-04-28 17:43:31.296583	123
75	2022-04-28 17:43:31.299583	76
76	2022-04-28 17:43:31.302583	43
77	2022-04-28 17:43:31.228583	136
78	2022-04-28 17:43:31.308583	45
79	2022-04-28 17:43:31.706583	91
80	2022-04-28 17:43:32.194583	25
81	2022-04-28 17:43:31.317583	126
82	2022-04-28 17:43:31.812583	50
83	2022-04-28 17:43:31.489583	93
84	2022-04-28 17:43:32.166583	76
85	2022-04-28 17:43:31.244583	75
86	2022-04-28 17:43:31.246583	41
87	2022-04-28 17:43:32.031583	130
88	2022-04-28 17:43:31.426583	59
89	2022-04-28 17:43:32.320583	36
90	2022-04-28 17:43:31.884583	71
91	2022-04-28 17:43:31.438583	107
92	2022-04-28 17:43:31.810583	72
93	2022-04-28 17:43:32.190583	111
94	2022-04-28 17:43:32.108583	27
95	2022-04-28 17:43:32.404583	105
96	2022-04-28 17:43:32.130583	129
97	2022-04-28 17:43:31.268583	97
98	2022-04-28 17:43:31.760583	130
99	2022-04-28 17:43:31.866583	106
100	2022-04-28 17:43:32.174583	31
101	2022-04-28 17:43:31.276583	93
102	2022-04-28 17:43:32.298583	88
103	2022-04-28 17:43:31.795583	128
104	2022-04-28 17:43:31.906583	22
105	2022-04-28 17:43:32.124583	110
106	2022-04-28 17:43:31.604583	40
107	2022-04-28 17:43:31.288583	75
108	2022-04-28 17:43:32.586583	62
109	2022-04-28 17:43:31.728583	19
110	2022-04-28 17:43:31.954583	74
111	2022-04-28 17:43:32.517583	101
112	2022-04-28 17:43:31.970583	45
113	2022-04-28 17:43:32.430583	25
114	2022-04-28 17:43:31.530583	13
115	2022-04-28 17:43:31.879583	49
116	2022-04-28 17:43:32.466583	40
117	2022-04-28 17:43:32.010583	58
118	2022-04-28 17:43:31.900583	84
119	2022-04-28 17:43:32.621583	131
120	2022-04-28 17:43:31.314583	136
121	2022-04-28 17:43:31.558583	91
122	2022-04-28 17:43:31.928583	36
123	2022-04-28 17:43:31.935583	68
124	2022-04-28 17:43:32.686583	80
125	2022-04-28 17:43:32.449583	5
126	2022-04-28 17:43:32.082583	62
127	2022-04-28 17:43:31.582583	39
128	2022-04-28 17:43:31.842583	51
129	2022-04-28 17:43:31.461583	76
130	2022-04-28 17:43:32.634583	45
131	2022-04-28 17:43:32.384583	67
132	2022-04-28 17:43:32.394583	55
133	2022-04-28 17:43:32.803583	7
134	2022-04-28 17:43:32.682583	93
135	2022-04-28 17:43:31.344583	55
136	2022-04-28 17:43:32.162583	68
137	2022-04-28 17:43:31.485583	87
138	2022-04-28 17:43:31.764583	36
139	2022-04-28 17:43:31.630583	42
140	2022-04-28 17:43:32.894583	48
141	2022-04-28 17:43:31.779583	99
142	2022-04-28 17:43:31.926583	62
143	2022-04-28 17:43:32.790583	63
144	2022-04-28 17:43:31.362583	33
145	2022-04-28 17:43:31.364583	15
146	2022-04-28 17:43:32.096583	57
147	2022-04-28 17:43:31.368583	105
148	2022-04-28 17:43:31.814583	111
149	2022-04-28 17:43:33.011583	15
150	2022-04-28 17:43:31.974583	55
151	2022-04-28 17:43:32.584583	34
152	2022-04-28 17:43:32.290583	50
153	2022-04-28 17:43:32.298583	11
154	2022-04-28 17:43:31.844583	88
155	2022-04-28 17:43:33.244583	15
156	2022-04-28 17:43:31.542583	121
157	2022-04-28 17:43:32.487583	72
5	2022-05-05 10:03:33.481401	0
158	2022-04-28 17:43:31.232583	141
159	2022-04-28 17:43:31.392583	41
160	2022-04-28 17:43:32.514583	69
161	2022-04-28 17:43:33.328583	83
162	2022-04-28 17:43:32.532583	141
163	2022-04-28 17:43:33.193583	19
164	2022-04-28 17:43:32.058583	56
165	2022-04-28 17:43:31.899583	76
166	2022-04-28 17:43:31.904583	19
167	2022-04-28 17:43:33.412583	77
168	2022-04-28 17:43:32.754583	12
169	2022-04-28 17:43:31.750583	6
170	2022-04-28 17:43:33.284583	108
171	2022-04-28 17:43:31.587583	68
172	2022-04-28 17:43:31.762583	140
173	2022-04-28 17:43:33.496583	93
174	2022-04-28 17:43:32.988583	86
175	2022-04-28 17:43:32.999583	46
176	2022-04-28 17:43:32.834583	96
177	2022-04-28 17:43:32.490583	126
178	2022-04-28 17:43:32.320583	16
179	2022-04-28 17:43:32.864583	75
180	2022-04-28 17:43:32.334583	59
181	2022-04-28 17:43:32.884583	136
182	2022-04-28 17:43:31.984583	68
183	2022-04-28 17:43:33.087583	145
184	2022-04-28 17:43:33.466583	16
185	2022-04-28 17:43:33.294583	136
186	2022-04-28 17:43:33.120583	10
187	2022-04-28 17:43:32.196583	120
188	2022-04-28 17:43:32.202583	73
189	2022-04-28 17:43:32.208583	91
190	2022-04-28 17:43:33.734583	41
191	2022-04-28 17:43:32.220583	115
192	2022-04-28 17:43:32.994583	145
193	2022-04-28 17:43:33.390583	96
194	2022-04-28 17:43:32.820583	13
195	2022-04-28 17:43:31.659583	81
196	2022-04-28 17:43:32.446583	101
197	2022-04-28 17:43:32.847583	74
198	2022-04-28 17:43:31.470583	26
199	2022-04-28 17:43:31.671583	113
200	2022-04-28 17:43:31.874583	142
201	2022-04-28 17:43:33.285583	96
202	2022-04-28 17:43:33.296583	114
203	2022-04-28 17:43:32.698583	90
204	2022-04-28 17:43:32.094583	103
205	2022-04-28 17:43:32.714583	131
206	2022-04-28 17:43:33.340583	5
207	2022-04-28 17:43:32.730583	23
208	2022-04-28 17:43:31.490583	130
209	2022-04-28 17:43:32.119583	45
210	2022-04-28 17:43:32.964583	19
211	2022-04-28 17:43:32.340583	117
212	2022-04-28 17:43:34.042583	43
213	2022-04-28 17:43:32.778583	13
214	2022-04-28 17:43:32.572583	126
215	2022-04-28 17:43:33.439583	29
216	2022-04-28 17:43:32.370583	81
217	2022-04-28 17:43:32.593583	3
218	2022-04-28 17:43:32.818583	102
219	2022-04-28 17:43:31.512583	130
220	2022-04-28 17:43:32.614583	34
221	2022-04-28 17:43:32.400583	130
222	2022-04-28 17:43:33.072583	33
223	2022-04-28 17:43:33.527583	59
224	2022-04-28 17:43:31.970583	66
225	2022-04-28 17:43:32.649583	24
226	2022-04-28 17:43:34.012583	126
227	2022-04-28 17:43:31.755583	9
228	2022-04-28 17:43:33.126583	138
229	2022-04-28 17:43:33.364583	68
230	2022-04-28 17:43:32.224583	67
231	2022-04-28 17:43:31.767583	62
232	2022-04-28 17:43:34.090583	46
233	2022-04-28 17:43:33.171583	33
234	2022-04-28 17:43:33.180583	73
235	2022-04-28 17:43:33.424583	50
236	2022-04-28 17:43:33.906583	56
237	2022-04-28 17:43:33.918583	59
238	2022-04-28 17:43:33.692583	75
239	2022-04-28 17:43:32.030583	112
240	2022-04-28 17:43:32.994583	16
7	2022-04-28 17:54:31.447703	0
9	2022-04-28 17:54:31.447703	0
1	2022-05-05 10:20:40.051217	0
\.


--
-- TOC entry 2566 (class 0 OID 94378)
-- Dependencies: 238
-- Data for Name: integer_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_archive (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2564 (class 0 OID 94356)
-- Dependencies: 236
-- Data for Name: order_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_actual (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2565 (class 0 OID 94367)
-- Dependencies: 237
-- Data for Name: order_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_archive (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2563 (class 0 OID 94350)
-- Dependencies: 235
-- Data for Name: synchronization; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.synchronization (xpath, fix, status) FROM stdin;
\.


--
-- TOC entry 2413 (class 2606 OID 94347)
-- Name: glossary glossary_communication_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_communication_key UNIQUE (communication);


--
-- TOC entry 2415 (class 2606 OID 94345)
-- Name: glossary glossary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);


--
-- TOC entry 2419 (class 1259 OID 94448)
-- Name: _hyper_1_2_chunk_integer_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (fix DESC);


--
-- TOC entry 2420 (class 1259 OID 94463)
-- Name: _hyper_1_3_chunk_integer_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree (fix DESC);


--
-- TOC entry 2418 (class 1259 OID 94438)
-- Name: _hyper_2_1_chunk_float_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_1_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (fix DESC);


--
-- TOC entry 2421 (class 1259 OID 94475)
-- Name: _hyper_2_4_chunk_float_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_4_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (fix DESC);


--
-- TOC entry 2417 (class 1259 OID 94405)
-- Name: float_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX float_archive_fix_idx ON public.float_archive USING btree (fix DESC);


--
-- TOC entry 2416 (class 1259 OID 94387)
-- Name: integer_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX integer_archive_fix_idx ON public.integer_archive USING btree (fix DESC);


--
-- TOC entry 2432 (class 2620 OID 94349)
-- Name: glossary existence_check_or_creation_table; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();


--
-- TOC entry 2434 (class 2620 OID 94404)
-- Name: float_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.float_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 2433 (class 2620 OID 94386)
-- Name: integer_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.integer_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 2428 (class 2606 OID 94433)
-- Name: _hyper_2_1_chunk 1_1_float_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk
    ADD CONSTRAINT "1_1_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2429 (class 2606 OID 94443)
-- Name: _hyper_1_2_chunk 2_2_integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2430 (class 2606 OID 94458)
-- Name: _hyper_1_3_chunk 3_3_integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk
    ADD CONSTRAINT "3_3_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2431 (class 2606 OID 94470)
-- Name: _hyper_2_4_chunk 4_4_float_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk
    ADD CONSTRAINT "4_4_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2427 (class 2606 OID 94409)
-- Name: float_actual float_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_actual
    ADD CONSTRAINT float_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2426 (class 2606 OID 94399)
-- Name: float_archive float_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_archive
    ADD CONSTRAINT float_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2425 (class 2606 OID 94391)
-- Name: integer_actual integer_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_actual
    ADD CONSTRAINT integer_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2424 (class 2606 OID 94381)
-- Name: integer_archive integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_archive
    ADD CONSTRAINT integer_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2422 (class 2606 OID 94362)
-- Name: order_actual order_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_actual
    ADD CONSTRAINT order_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2423 (class 2606 OID 94373)
-- Name: order_archive order_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_archive
    ADD CONSTRAINT order_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


-- Completed on 2022-05-05 10:55:15

--
-- PostgreSQL database dump complete
--

