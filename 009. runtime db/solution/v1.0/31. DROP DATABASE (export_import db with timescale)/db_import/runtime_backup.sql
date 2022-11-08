--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.24
-- Dumped by pg_dump version 9.6.24

-- Started on 2022-04-28 15:14:30

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
-- TOC entry 2 (class 3079 OID 89040)
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- TOC entry 2565 (class 0 OID 0)
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
-- TOC entry 2566 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 383 (class 1255 OID 89651)
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
			EXECUTE FORMAT('UPDATE %I SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM %I WHERE key = %s) AND key = %s;', _HyperTable, _HyperTable, _Key, _Key);
		END IF;	
	END IF;

END;

$$;


ALTER FUNCTION public._communication(xpath text, valuenew anyelement) OWNER TO postgres;

--
-- TOC entry 390 (class 1255 OID 89659)
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
-- TOC entry 389 (class 1255 OID 89658)
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
-- TOC entry 385 (class 1255 OID 89654)
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
-- TOC entry 384 (class 1255 OID 89653)
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
-- TOC entry 387 (class 1255 OID 89656)
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
-- TOC entry 386 (class 1255 OID 89655)
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
-- TOC entry 388 (class 1255 OID 89657)
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
-- TOC entry 382 (class 1255 OID 89585)
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
-- TOC entry 238 (class 1259 OID 89615)
-- Name: integer_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_archive OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 89676)
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);


ALTER TABLE _timescaledb_internal._hyper_1_2_chunk OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 89633)
-- Name: float_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_archive OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 89666)
-- Name: _hyper_2_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_2_1_chunk (
    CONSTRAINT constraint_1 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);


ALTER TABLE _timescaledb_internal._hyper_2_1_chunk OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 89643)
-- Name: float_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_actual OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 89574)
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
-- TOC entry 2567 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE glossary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.glossary IS 'Словарь для индефикации переменных';


--
-- TOC entry 2568 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';


--
-- TOC entry 2569 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.communication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';


--
-- TOC entry 2570 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.configuration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';


--
-- TOC entry 2571 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN glossary.tablename; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';


--
-- TOC entry 233 (class 1259 OID 89572)
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
-- TOC entry 2572 (class 0 OID 0)
-- Dependencies: 233
-- Name: glossary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.glossary_key_seq OWNED BY public.glossary.key;


--
-- TOC entry 239 (class 1259 OID 89625)
-- Name: integer_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_actual OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 89593)
-- Name: order_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_actual OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 89604)
-- Name: order_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_archive OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 89587)
-- Name: synchronization; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synchronization (
    xpath text NOT NULL,
    fix timestamp without time zone NOT NULL,
    status text NOT NULL
);


ALTER TABLE public.synchronization OWNER TO postgres;

--
-- TOC entry 2399 (class 2604 OID 89577)
-- Name: glossary key; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary ALTER COLUMN key SET DEFAULT nextval('public.glossary_key_seq'::regclass);


--
-- TOC entry 2376 (class 0 OID 89486)
-- Dependencies: 222
-- Data for Name: cache_inval_bgw_job; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--



--
-- TOC entry 2375 (class 0 OID 89489)
-- Dependencies: 223
-- Data for Name: cache_inval_extension; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--



--
-- TOC entry 2374 (class 0 OID 89483)
-- Dependencies: 221
-- Data for Name: cache_inval_hypertable; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--



--
-- TOC entry 2349 (class 0 OID 89057)
-- Dependencies: 193
-- Data for Name: hypertable; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compressed, compressed_hypertable_id) VALUES (1, 'public', 'integer_archive', '_timescaledb_internal', '_hyper_1', 1, '_timescaledb_internal', 'calculate_chunk_interval', 0, false, NULL);
INSERT INTO _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compressed, compressed_hypertable_id) VALUES (2, 'public', 'float_archive', '_timescaledb_internal', '_hyper_2', 1, '_timescaledb_internal', 'calculate_chunk_interval', 0, false, NULL);


--
-- TOC entry 2356 (class 0 OID 89131)
-- Dependencies: 201
-- Data for Name: chunk; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped) VALUES (1, 2, '_timescaledb_internal', '_hyper_2_1_chunk', NULL, false);
INSERT INTO _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped) VALUES (2, 1, '_timescaledb_internal', '_hyper_1_2_chunk', NULL, false);


--
-- TOC entry 2352 (class 0 OID 89096)
-- Dependencies: 197
-- Data for Name: dimension; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, integer_now_func_schema, integer_now_func) VALUES (1, 1, 'fix', 'timestamp without time zone', true, NULL, NULL, NULL, 86400000000, NULL, NULL);
INSERT INTO _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, integer_now_func_schema, integer_now_func) VALUES (2, 2, 'fix', 'timestamp without time zone', true, NULL, NULL, NULL, 86400000000, NULL, NULL);


--
-- TOC entry 2354 (class 0 OID 89115)
-- Dependencies: 199
-- Data for Name: dimension_slice; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) VALUES (1, 2, 1651104000000000, 1651190400000000);
INSERT INTO _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) VALUES (2, 1, 1651104000000000, 1651190400000000);


--
-- TOC entry 2358 (class 0 OID 89152)
-- Dependencies: 202
-- Data for Name: chunk_constraint; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) VALUES (1, 1, 'constraint_1', NULL);
INSERT INTO _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) VALUES (1, NULL, '1_1_float_archive_key_fkey', 'float_archive_key_fkey');
INSERT INTO _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) VALUES (2, 2, 'constraint_2', NULL);
INSERT INTO _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) VALUES (2, NULL, '2_2_integer_archive_key_fkey', 'integer_archive_key_fkey');


--
-- TOC entry 2573 (class 0 OID 0)
-- Dependencies: 203
-- Name: chunk_constraint_name; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 2, true);


--
-- TOC entry 2574 (class 0 OID 0)
-- Dependencies: 200
-- Name: chunk_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 2, true);


--
-- TOC entry 2360 (class 0 OID 89170)
-- Dependencies: 204
-- Data for Name: chunk_index; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) VALUES (1, '_hyper_2_1_chunk_float_archive_fix_idx', 2, 'float_archive_fix_idx');
INSERT INTO _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) VALUES (2, '_hyper_1_2_chunk_integer_archive_fix_idx', 1, 'integer_archive_fix_idx');


--
-- TOC entry 2372 (class 0 OID 89355)
-- Dependencies: 219
-- Data for Name: compression_chunk_size; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2362 (class 0 OID 89188)
-- Dependencies: 206
-- Data for Name: bgw_job; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--



--
-- TOC entry 2366 (class 0 OID 89267)
-- Dependencies: 212
-- Data for Name: continuous_agg; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2368 (class 0 OID 89305)
-- Dependencies: 214
-- Data for Name: continuous_aggs_completed_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2369 (class 0 OID 89315)
-- Dependencies: 215
-- Data for Name: continuous_aggs_hypertable_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2367 (class 0 OID 89295)
-- Dependencies: 213
-- Data for Name: continuous_aggs_invalidation_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2370 (class 0 OID 89319)
-- Dependencies: 216
-- Data for Name: continuous_aggs_materialization_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2575 (class 0 OID 0)
-- Dependencies: 196
-- Name: dimension_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 2, true);


--
-- TOC entry 2576 (class 0 OID 0)
-- Dependencies: 198
-- Name: dimension_slice_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 2, true);


--
-- TOC entry 2371 (class 0 OID 89336)
-- Dependencies: 218
-- Data for Name: hypertable_compression; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2577 (class 0 OID 0)
-- Dependencies: 192
-- Name: hypertable_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 2, true);


--
-- TOC entry 2365 (class 0 OID 89259)
-- Dependencies: 211
-- Data for Name: metadata; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

INSERT INTO _timescaledb_catalog.metadata (key, value, include_in_telemetry) VALUES ('exported_uuid', '00000000-0000-4000-ab4c-b42eb1800200', true);


--
-- TOC entry 2351 (class 0 OID 89081)
-- Dependencies: 195
-- Data for Name: tablespace; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--



--
-- TOC entry 2578 (class 0 OID 0)
-- Dependencies: 205
-- Name: bgw_job_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_config; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1000, false);


--
-- TOC entry 2373 (class 0 OID 89370)
-- Dependencies: 220
-- Data for Name: bgw_policy_compress_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--



--
-- TOC entry 2364 (class 0 OID 89223)
-- Dependencies: 209
-- Data for Name: bgw_policy_drop_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--



--
-- TOC entry 2363 (class 0 OID 89206)
-- Dependencies: 208
-- Data for Name: bgw_policy_reorder; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--



--
-- TOC entry 2557 (class 0 OID 89676)
-- Dependencies: 243
-- Data for Name: _hyper_1_2_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (1, '2022-04-28 15:07:37.485481', 2);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (2, '2022-04-28 15:07:37.484481', 89);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (3, '2022-04-28 15:07:37.487481', 68);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (4, '2022-04-28 15:07:37.496481', 57);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (5, '2022-04-28 15:07:37.507481', 84);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (6, '2022-04-28 15:07:37.484481', 85);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (7, '2022-04-28 15:07:37.535481', 145);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (8, '2022-04-28 15:07:37.488481', 138);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (9, '2022-04-28 15:07:37.598481', 39);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (10, '2022-04-28 15:07:37.572481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (11, '2022-04-28 15:07:37.604481', 99);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (12, '2022-04-28 15:07:37.616481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (13, '2022-04-28 15:07:37.537481', 77);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (14, '2022-04-28 15:07:37.486481', 110);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (15, '2022-04-28 15:07:37.547481', 11);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (16, '2022-04-28 15:07:37.648481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (17, '2022-04-28 15:07:37.710481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (18, '2022-04-28 15:07:37.616481', 24);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (19, '2022-04-28 15:07:37.491481', 48);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (20, '2022-04-28 15:07:37.512481', 16);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (21, '2022-04-28 15:07:37.724481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (22, '2022-04-28 15:07:37.516481', 10);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (23, '2022-04-28 15:07:37.587481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (24, '2022-04-28 15:07:37.736481', 123);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (25, '2022-04-28 15:07:37.622481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (26, '2022-04-28 15:07:37.680481', 140);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (27, '2022-04-28 15:07:37.553481', 139);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (28, '2022-04-28 15:07:37.612481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (29, '2022-04-28 15:07:37.588481', 40);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (30, '2022-04-28 15:07:37.622481', 110);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (31, '2022-04-28 15:07:37.689481', 94);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (32, '2022-04-28 15:07:37.536481', 54);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (33, '2022-04-28 15:07:37.868481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (34, '2022-04-28 15:07:37.812481', 64);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (35, '2022-04-28 15:07:37.717481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (36, '2022-04-28 15:07:37.940481', 92);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (37, '2022-04-28 15:07:37.620481', 79);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (38, '2022-04-28 15:07:37.890481', 91);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (39, '2022-04-28 15:07:37.823481', 110);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (40, '2022-04-28 15:07:37.952481', 4);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (41, '2022-04-28 15:07:37.923481', 26);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (42, '2022-04-28 15:07:37.766481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (43, '2022-04-28 15:07:37.816481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (44, '2022-04-28 15:07:38.000481', 144);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (45, '2022-04-28 15:07:38.057481', 48);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (46, '2022-04-28 15:07:38.116481', 109);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (47, '2022-04-28 15:07:37.519481', 40);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (48, '2022-04-28 15:07:37.952481', 28);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (49, '2022-04-28 15:07:37.619481', 101);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (50, '2022-04-28 15:07:37.672481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (51, '2022-04-28 15:07:37.982481', 48);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (52, '2022-04-28 15:07:37.784481', 63);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (53, '2022-04-28 15:07:38.161481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (54, '2022-04-28 15:07:38.066481', 84);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (55, '2022-04-28 15:07:37.692481', 96);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (56, '2022-04-28 15:07:37.976481', 63);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (57, '2022-04-28 15:07:37.871481', 43);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (58, '2022-04-28 15:07:38.284481', 40);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (59, '2022-04-28 15:07:37.708481', 88);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (60, '2022-04-28 15:07:38.192481', 15);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (61, '2022-04-28 15:07:37.838481', 94);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (62, '2022-04-28 15:07:37.968481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (63, '2022-04-28 15:07:38.354481', 28);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (64, '2022-04-28 15:07:38.048481', 141);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (65, '2022-04-28 15:07:38.317481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (66, '2022-04-28 15:07:38.000481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (67, '2022-04-28 15:07:38.008481', 94);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (68, '2022-04-28 15:07:37.880481', 65);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (69, '2022-04-28 15:07:38.231481', 144);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (70, '2022-04-28 15:07:38.102481', 87);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (71, '2022-04-28 15:07:37.614481', 32);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (72, '2022-04-28 15:07:38.264481', 35);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (73, '2022-04-28 15:07:38.275481', 79);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (74, '2022-04-28 15:07:37.842481', 106);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (75, '2022-04-28 15:07:37.847481', 57);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (76, '2022-04-28 15:07:38.536481', 75);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (77, '2022-04-28 15:07:38.396481', 18);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (78, '2022-04-28 15:07:38.408481', 2);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (79, '2022-04-28 15:07:38.341481', 41);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (80, '2022-04-28 15:07:38.112481', 101);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (81, '2022-04-28 15:07:37.877481', 110);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (82, '2022-04-28 15:07:38.292481', 100);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (83, '2022-04-28 15:07:37.721481', 100);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (84, '2022-04-28 15:07:38.564481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (85, '2022-04-28 15:07:38.577481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (86, '2022-04-28 15:07:38.160481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (87, '2022-04-28 15:07:38.690481', 38);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (88, '2022-04-28 15:07:37.648481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (89, '2022-04-28 15:07:38.629481', 45);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (90, '2022-04-28 15:07:38.102481', 58);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (91, '2022-04-28 15:07:38.655481', 130);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (92, '2022-04-28 15:07:38.392481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (93, '2022-04-28 15:07:38.309481', 2);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (94, '2022-04-28 15:07:37.660481', 64);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (95, '2022-04-28 15:07:38.612481', 54);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (96, '2022-04-28 15:07:38.432481', 73);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (97, '2022-04-28 15:07:38.248481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (98, '2022-04-28 15:07:37.962481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (99, '2022-04-28 15:07:38.264481', 12);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (100, '2022-04-28 15:07:37.672481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (101, '2022-04-28 15:07:38.482481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (102, '2022-04-28 15:07:38.696481', 106);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (103, '2022-04-28 15:07:38.811481', 107);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (104, '2022-04-28 15:07:38.304481', 86);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (105, '2022-04-28 15:07:37.682481', 104);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (106, '2022-04-28 15:07:37.790481', 70);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (107, '2022-04-28 15:07:38.863481', 15);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (108, '2022-04-28 15:07:38.768481', 61);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (109, '2022-04-28 15:07:37.690481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (110, '2022-04-28 15:07:37.802481', 21);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (111, '2022-04-28 15:07:38.471481', 65);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (112, '2022-04-28 15:07:37.584481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (113, '2022-04-28 15:07:38.941481', 145);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (114, '2022-04-28 15:07:38.726481', 10);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (115, '2022-04-28 15:07:39.082481', 113);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (116, '2022-04-28 15:07:38.516481', 119);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (117, '2022-04-28 15:07:37.940481', 56);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (118, '2022-04-28 15:07:38.770481', 58);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (119, '2022-04-28 15:07:37.710481', 141);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (120, '2022-04-28 15:07:38.552481', 124);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (121, '2022-04-28 15:07:38.440481', 71);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (122, '2022-04-28 15:07:38.204481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (123, '2022-04-28 15:07:37.964481', 28);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (124, '2022-04-28 15:07:38.588481', 59);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (125, '2022-04-28 15:07:37.847481', 128);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (126, '2022-04-28 15:07:37.976481', 47);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (127, '2022-04-28 15:07:39.250481', 139);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (128, '2022-04-28 15:07:38.368481', 33);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (129, '2022-04-28 15:07:38.504481', 38);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (130, '2022-04-28 15:07:39.032481', 131);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (131, '2022-04-28 15:07:37.603481', 68);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (132, '2022-04-28 15:07:38.660481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (133, '2022-04-28 15:07:37.871481', 45);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (134, '2022-04-28 15:07:38.142481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (135, '2022-04-28 15:07:38.282481', 61);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (136, '2022-04-28 15:07:38.288481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (137, '2022-04-28 15:07:38.705481', 38);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (138, '2022-04-28 15:07:38.852481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (139, '2022-04-28 15:07:37.750481', 133);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (140, '2022-04-28 15:07:38.172481', 103);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (141, '2022-04-28 15:07:38.318481', 49);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (142, '2022-04-28 15:07:39.460481', 13);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (143, '2022-04-28 15:07:38.616481', 44);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (144, '2022-04-28 15:07:39.200481', 39);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (145, '2022-04-28 15:07:39.502481', 76);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (146, '2022-04-28 15:07:39.370481', 121);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (147, '2022-04-28 15:07:37.913481', 102);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (148, '2022-04-28 15:07:39.248481', 4);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (149, '2022-04-28 15:07:39.260481', 16);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (150, '2022-04-28 15:07:39.572481', 137);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (151, '2022-04-28 15:07:39.435481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (152, '2022-04-28 15:07:37.776481', 103);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (153, '2022-04-28 15:07:38.696481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (154, '2022-04-28 15:07:39.166481', 105);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (155, '2022-04-28 15:07:38.247481', 44);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (156, '2022-04-28 15:07:37.940481', 83);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (157, '2022-04-28 15:07:39.670481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (158, '2022-04-28 15:07:38.736481', 98);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (159, '2022-04-28 15:07:38.744481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (160, '2022-04-28 15:07:39.232481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (161, '2022-04-28 15:07:38.599481', 1);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (162, '2022-04-28 15:07:38.768481', 123);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (163, '2022-04-28 15:07:38.776481', 73);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (164, '2022-04-28 15:07:39.768481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (165, '2022-04-28 15:07:38.627481', 94);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (166, '2022-04-28 15:07:38.302481', 140);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (167, '2022-04-28 15:07:39.643481', 54);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (168, '2022-04-28 15:07:39.488481', 35);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (169, '2022-04-28 15:07:38.317481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (170, '2022-04-28 15:07:38.832481', 62);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (171, '2022-04-28 15:07:39.011481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (172, '2022-04-28 15:07:39.880481', 97);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (173, '2022-04-28 15:07:38.510481', 50);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (174, '2022-04-28 15:07:39.734481', 3);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (175, '2022-04-28 15:07:37.997481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (176, '2022-04-28 15:07:38.880481', 45);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (177, '2022-04-28 15:07:38.534481', 28);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (178, '2022-04-28 15:07:38.896481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (179, '2022-04-28 15:07:39.083481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (180, '2022-04-28 15:07:38.192481', 9);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (181, '2022-04-28 15:07:38.196481', 118);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (182, '2022-04-28 15:07:38.382481', 96);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (183, '2022-04-28 15:07:37.838481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (184, '2022-04-28 15:07:39.312481', 85);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (185, '2022-04-28 15:07:38.582481', 43);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (186, '2022-04-28 15:07:38.588481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (187, '2022-04-28 15:07:37.659481', 45);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (188, '2022-04-28 15:07:38.224481', 50);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (189, '2022-04-28 15:07:37.850481', 127);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (190, '2022-04-28 15:07:38.992481', 26);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (191, '2022-04-28 15:07:39.191481', 137);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (192, '2022-04-28 15:07:39.584481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (193, '2022-04-28 15:07:38.051481', 140);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (194, '2022-04-28 15:07:39.218481', 108);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (195, '2022-04-28 15:07:40.007481', 125);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (196, '2022-04-28 15:07:39.432481', 15);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (197, '2022-04-28 15:07:37.866481', 70);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (198, '2022-04-28 15:07:38.264481', 113);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (199, '2022-04-28 15:07:39.860481', 45);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (200, '2022-04-28 15:07:39.472481', 25);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (201, '2022-04-28 15:07:39.482481', 44);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (202, '2022-04-28 15:07:39.492481', 128);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (203, '2022-04-28 15:07:39.908481', 32);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (204, '2022-04-28 15:07:38.492481', 12);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (205, '2022-04-28 15:07:40.342481', 22);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (206, '2022-04-28 15:07:40.150481', 106);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (207, '2022-04-28 15:07:39.749481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (208, '2022-04-28 15:07:38.928481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (209, '2022-04-28 15:07:37.890481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (210, '2022-04-28 15:07:39.152481', 10);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (211, '2022-04-28 15:07:39.371481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (212, '2022-04-28 15:07:39.592481', 70);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (213, '2022-04-28 15:07:39.602481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (214, '2022-04-28 15:07:38.328481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (215, '2022-04-28 15:07:37.902481', 65);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (216, '2022-04-28 15:07:39.200481', 107);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (217, '2022-04-28 15:07:38.340481', 47);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (218, '2022-04-28 15:07:38.998481', 47);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (219, '2022-04-28 15:07:38.567481', 124);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (220, '2022-04-28 15:07:39.012481', 135);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (221, '2022-04-28 15:07:39.682481', 75);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (222, '2022-04-28 15:07:39.914481', 108);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (223, '2022-04-28 15:07:40.594481', 133);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (224, '2022-04-28 15:07:38.816481', 4);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (225, '2022-04-28 15:07:37.922481', 2);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (226, '2022-04-28 15:07:39.732481', 105);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (227, '2022-04-28 15:07:40.196481', 85);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (228, '2022-04-28 15:07:39.296481', 115);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (229, '2022-04-28 15:07:39.533481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (230, '2022-04-28 15:07:38.392481', 76);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (231, '2022-04-28 15:07:40.706481', 108);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (232, '2022-04-28 15:07:37.704481', 77);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (233, '2022-04-28 15:07:39.569481', 24);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (234, '2022-04-28 15:07:39.344481', 58);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (235, '2022-04-28 15:07:39.352481', 19);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (236, '2022-04-28 15:07:40.776481', 33);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (237, '2022-04-28 15:07:39.842481', 85);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (238, '2022-04-28 15:07:38.900481', 16);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (239, '2022-04-28 15:07:38.189481', 140);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (240, '2022-04-28 15:07:39.392481', 108);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (1, '2022-04-28 15:07:37.485481', 32);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (2, '2022-04-28 15:07:37.488481', 9);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (3, '2022-04-28 15:07:37.505481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (4, '2022-04-28 15:07:37.524481', 95);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (5, '2022-04-28 15:07:37.527481', 101);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (6, '2022-04-28 15:07:37.538481', 11);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (7, '2022-04-28 15:07:37.535481', 131);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (8, '2022-04-28 15:07:37.584481', 137);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (9, '2022-04-28 15:07:37.544481', 37);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (10, '2022-04-28 15:07:37.502481', 119);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (11, '2022-04-28 15:07:37.549481', 143);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (12, '2022-04-28 15:07:37.556481', 133);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (13, '2022-04-28 15:07:37.498481', 71);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (14, '2022-04-28 15:07:37.500481', 33);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (15, '2022-04-28 15:07:37.532481', 66);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (16, '2022-04-28 15:07:37.632481', 93);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (17, '2022-04-28 15:07:37.642481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (18, '2022-04-28 15:07:37.634481', 112);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (19, '2022-04-28 15:07:37.548481', 139);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (20, '2022-04-28 15:07:37.712481', 119);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (21, '2022-04-28 15:07:37.556481', 124);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (22, '2022-04-28 15:07:37.670481', 125);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (23, '2022-04-28 15:07:37.633481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (24, '2022-04-28 15:07:37.688481', 112);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (25, '2022-04-28 15:07:37.697481', 65);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (26, '2022-04-28 15:07:37.706481', 129);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (27, '2022-04-28 15:07:37.796481', 100);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (28, '2022-04-28 15:07:37.612481', 133);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (29, '2022-04-28 15:07:37.791481', 86);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (30, '2022-04-28 15:07:37.532481', 38);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (31, '2022-04-28 15:07:37.813481', 104);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (32, '2022-04-28 15:07:37.696481', 47);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (33, '2022-04-28 15:07:37.538481', 13);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (34, '2022-04-28 15:07:37.676481', 21);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (35, '2022-04-28 15:07:37.647481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (36, '2022-04-28 15:07:37.832481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (37, '2022-04-28 15:07:37.731481', 44);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (38, '2022-04-28 15:07:37.814481', 82);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (39, '2022-04-28 15:07:37.706481', 91);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (40, '2022-04-28 15:07:37.792481', 18);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (41, '2022-04-28 15:07:38.005481', 43);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (42, '2022-04-28 15:07:37.850481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (43, '2022-04-28 15:07:37.988481', 112);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (44, '2022-04-28 15:07:38.000481', 3);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (45, '2022-04-28 15:07:37.607481', 103);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (46, '2022-04-28 15:07:37.564481', 94);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (47, '2022-04-28 15:07:38.083481', 78);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (48, '2022-04-28 15:07:37.568481', 74);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (49, '2022-04-28 15:07:37.815481', 46);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (50, '2022-04-28 15:07:38.072481', 47);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (51, '2022-04-28 15:07:37.880481', 67);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (52, '2022-04-28 15:07:37.888481', 66);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (53, '2022-04-28 15:07:38.055481', 9);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (54, '2022-04-28 15:07:37.850481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (55, '2022-04-28 15:07:37.582481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (56, '2022-04-28 15:07:37.976481', 18);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (57, '2022-04-28 15:07:37.586481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (58, '2022-04-28 15:07:37.820481', 66);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (59, '2022-04-28 15:07:37.649481', 100);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (60, '2022-04-28 15:07:37.892481', 40);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (61, '2022-04-28 15:07:37.777481', 53);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (62, '2022-04-28 15:07:38.340481', 84);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (63, '2022-04-28 15:07:37.661481', 11);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (64, '2022-04-28 15:07:38.048481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (65, '2022-04-28 15:07:37.732481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (66, '2022-04-28 15:07:37.670481', 8);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (67, '2022-04-28 15:07:38.276481', 29);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (68, '2022-04-28 15:07:38.084481', 64);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (69, '2022-04-28 15:07:38.300481', 21);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (70, '2022-04-28 15:07:37.612481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (71, '2022-04-28 15:07:37.898481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (72, '2022-04-28 15:07:38.408481', 60);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (73, '2022-04-28 15:07:37.691481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (74, '2022-04-28 15:07:38.138481', 4);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (75, '2022-04-28 15:07:37.772481', 91);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (76, '2022-04-28 15:07:37.928481', 106);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (77, '2022-04-28 15:07:38.396481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (78, '2022-04-28 15:07:37.550481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (79, '2022-04-28 15:07:38.104481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (80, '2022-04-28 15:07:37.872481', 97);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (81, '2022-04-28 15:07:38.039481', 75);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (82, '2022-04-28 15:07:37.964481', 145);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (83, '2022-04-28 15:07:38.219481', 75);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (84, '2022-04-28 15:07:37.892481', 129);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (85, '2022-04-28 15:07:37.982481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (86, '2022-04-28 15:07:38.332481', 144);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (87, '2022-04-28 15:07:38.342481', 97);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (88, '2022-04-28 15:07:38.616481', 10);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (89, '2022-04-28 15:07:38.095481', 83);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (90, '2022-04-28 15:07:38.102481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (91, '2022-04-28 15:07:38.200481', 88);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (92, '2022-04-28 15:07:38.484481', 87);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (93, '2022-04-28 15:07:38.495481', 64);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (94, '2022-04-28 15:07:37.848481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (95, '2022-04-28 15:07:37.757481', 59);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (96, '2022-04-28 15:07:38.816481', 131);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (97, '2022-04-28 15:07:38.636481', 54);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (98, '2022-04-28 15:07:38.060481', 120);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (99, '2022-04-28 15:07:38.759481', 135);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (100, '2022-04-28 15:07:38.672481', 92);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (101, '2022-04-28 15:07:38.381481', 99);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (102, '2022-04-28 15:07:38.492481', 38);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (103, '2022-04-28 15:07:38.914481', 57);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (104, '2022-04-28 15:07:37.680481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (105, '2022-04-28 15:07:38.417481', 140);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (106, '2022-04-28 15:07:38.638481', 134);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (107, '2022-04-28 15:07:38.221481', 13);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (108, '2022-04-28 15:07:37.796481', 121);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (109, '2022-04-28 15:07:38.671481', 106);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (110, '2022-04-28 15:07:38.022481', 26);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (111, '2022-04-28 15:07:38.027481', 12);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (112, '2022-04-28 15:07:38.704481', 135);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (113, '2022-04-28 15:07:39.054481', 109);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (114, '2022-04-28 15:07:37.814481', 43);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (115, '2022-04-28 15:07:38.047481', 16);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (116, '2022-04-28 15:07:37.820481', 75);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (117, '2022-04-28 15:07:38.759481', 117);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (118, '2022-04-28 15:07:38.534481', 120);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (119, '2022-04-28 15:07:39.019481', 72);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (120, '2022-04-28 15:07:38.552481', 49);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (121, '2022-04-28 15:07:38.198481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (122, '2022-04-28 15:07:38.570481', 32);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (123, '2022-04-28 15:07:38.702481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (124, '2022-04-28 15:07:38.340481', 109);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (125, '2022-04-28 15:07:37.972481', 79);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (126, '2022-04-28 15:07:37.724481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (127, '2022-04-28 15:07:38.742481', 92);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (128, '2022-04-28 15:07:38.112481', 78);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (129, '2022-04-28 15:07:39.278481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (130, '2022-04-28 15:07:38.122481', 35);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (131, '2022-04-28 15:07:37.996481', 114);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (132, '2022-04-28 15:07:39.188481', 77);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (133, '2022-04-28 15:07:39.068481', 33);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (134, '2022-04-28 15:07:37.874481', 98);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (135, '2022-04-28 15:07:38.417481', 50);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (136, '2022-04-28 15:07:39.240481', 40);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (137, '2022-04-28 15:07:37.883481', 138);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (138, '2022-04-28 15:07:39.128481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (139, '2022-04-28 15:07:38.445481', 73);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (140, '2022-04-28 15:07:38.172481', 138);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (141, '2022-04-28 15:07:38.177481', 62);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (142, '2022-04-28 15:07:37.756481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (143, '2022-04-28 15:07:37.758481', 141);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (144, '2022-04-28 15:07:39.344481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (145, '2022-04-28 15:07:38.632481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (146, '2022-04-28 15:07:39.224481', 23);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (147, '2022-04-28 15:07:38.060481', 57);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (148, '2022-04-28 15:07:37.916481', 84);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (149, '2022-04-28 15:07:37.919481', 15);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (150, '2022-04-28 15:07:38.372481', 65);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (151, '2022-04-28 15:07:39.435481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (152, '2022-04-28 15:07:38.232481', 126);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (153, '2022-04-28 15:07:38.849481', 115);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (154, '2022-04-28 15:07:37.780481', 101);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (155, '2022-04-28 15:07:39.332481', 6);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (156, '2022-04-28 15:07:37.784481', 68);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (157, '2022-04-28 15:07:38.728481', 48);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (158, '2022-04-28 15:07:39.526481', 116);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (159, '2022-04-28 15:07:39.062481', 18);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (160, '2022-04-28 15:07:38.752481', 123);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (161, '2022-04-28 15:07:38.438481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (162, '2022-04-28 15:07:38.120481', 55);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (163, '2022-04-28 15:07:38.776481', 111);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (164, '2022-04-28 15:07:37.800481', 105);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (165, '2022-04-28 15:07:39.452481', 35);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (166, '2022-04-28 15:07:37.970481', 53);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (167, '2022-04-28 15:07:37.973481', 119);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (168, '2022-04-28 15:07:37.808481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (169, '2022-04-28 15:07:37.979481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (170, '2022-04-28 15:07:37.982481', 37);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (171, '2022-04-28 15:07:39.695481', 26);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (172, '2022-04-28 15:07:38.332481', 66);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (173, '2022-04-28 15:07:37.645481', 58);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (174, '2022-04-28 15:07:39.212481', 129);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (175, '2022-04-28 15:07:38.697481', 46);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (176, '2022-04-28 15:07:39.760481', 5);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (177, '2022-04-28 15:07:39.065481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (178, '2022-04-28 15:07:37.828481', 123);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (179, '2022-04-28 15:07:39.083481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (180, '2022-04-28 15:07:38.552481', 125);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (181, '2022-04-28 15:07:39.463481', 52);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (182, '2022-04-28 15:07:39.656481', 86);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (183, '2022-04-28 15:07:39.851481', 105);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (184, '2022-04-28 15:07:38.576481', 99);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (185, '2022-04-28 15:07:38.212481', 53);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (186, '2022-04-28 15:07:39.332481', 69);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (187, '2022-04-28 15:07:40.090481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (188, '2022-04-28 15:07:40.104481', 27);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (189, '2022-04-28 15:07:39.551481', 107);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (190, '2022-04-28 15:07:38.612481', 14);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (191, '2022-04-28 15:07:38.045481', 25);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (192, '2022-04-28 15:07:38.432481', 77);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (193, '2022-04-28 15:07:38.630481', 17);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (194, '2022-04-28 15:07:39.606481', 81);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (195, '2022-04-28 15:07:39.617481', 36);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (196, '2022-04-28 15:07:40.216481', 34);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (197, '2022-04-28 15:07:39.836481', 41);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (198, '2022-04-28 15:07:39.056481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (199, '2022-04-28 15:07:38.467481', 105);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (200, '2022-04-28 15:07:39.072481', 43);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (201, '2022-04-28 15:07:37.874481', 142);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (202, '2022-04-28 15:07:39.492481', 17);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (203, '2022-04-28 15:07:39.502481', 60);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (204, '2022-04-28 15:07:37.880481', 54);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (205, '2022-04-28 15:07:39.317481', 132);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (206, '2022-04-28 15:07:38.090481', 122);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (207, '2022-04-28 15:07:39.128481', 44);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (208, '2022-04-28 15:07:39.760481', 84);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (209, '2022-04-28 15:07:37.890481', 48);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (210, '2022-04-28 15:07:38.312481', 114);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (211, '2022-04-28 15:07:40.426481', 118);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (212, '2022-04-28 15:07:40.440481', 2);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (213, '2022-04-28 15:07:38.750481', 64);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (214, '2022-04-28 15:07:39.398481', 102);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (215, '2022-04-28 15:07:39.837481', 59);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (216, '2022-04-28 15:07:40.280481', 144);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (217, '2022-04-28 15:07:38.340481', 12);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (218, '2022-04-28 15:07:37.908481', 20);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (219, '2022-04-28 15:07:39.224481', 22);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (220, '2022-04-28 15:07:40.332481', 138);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (221, '2022-04-28 15:07:37.914481', 57);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (222, '2022-04-28 15:07:40.580481', 119);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (223, '2022-04-28 15:07:38.141481', 22);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (224, '2022-04-28 15:07:39.712481', 80);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (225, '2022-04-28 15:07:39.272481', 136);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (226, '2022-04-28 15:07:39.054481', 144);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (227, '2022-04-28 15:07:39.288481', 112);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (228, '2022-04-28 15:07:38.612481', 32);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (229, '2022-04-28 15:07:37.701481', 93);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (230, '2022-04-28 15:07:40.002481', 33);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (231, '2022-04-28 15:07:40.013481', 52);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (232, '2022-04-28 15:07:39.792481', 30);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (233, '2022-04-28 15:07:37.938481', 21);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (234, '2022-04-28 15:07:39.812481', 69);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (235, '2022-04-28 15:07:38.412481', 91);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (236, '2022-04-28 15:07:37.944481', 139);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (237, '2022-04-28 15:07:39.131481', 42);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (238, '2022-04-28 15:07:40.090481', 85);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (239, '2022-04-28 15:07:40.579481', 21);
INSERT INTO _timescaledb_internal._hyper_1_2_chunk (key, fix, value) VALUES (240, '2022-04-28 15:07:40.592481', 35);


--
-- TOC entry 2556 (class 0 OID 89666)
-- Dependencies: 242
-- Data for Name: _hyper_2_1_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (1, '2022-04-28 15:07:37.482481', 139.88);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (2, '2022-04-28 15:07:37.500481', 142.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (3, '2022-04-28 15:07:37.496481', 104.63);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (4, '2022-04-28 15:07:37.496481', 7.8300000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (5, '2022-04-28 15:07:37.522481', 119.87);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (6, '2022-04-28 15:07:37.550481', 102.36);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (7, '2022-04-28 15:07:37.549481', 84.769999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (8, '2022-04-28 15:07:37.536481', 144.11000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (9, '2022-04-28 15:07:37.580481', 135.69999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (10, '2022-04-28 15:07:37.582481', 96.519999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (11, '2022-04-28 15:07:37.527481', 113.78);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (12, '2022-04-28 15:07:37.568481', 143.59);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (13, '2022-04-28 15:07:37.550481', 20.870000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (14, '2022-04-28 15:07:37.542481', 144.37);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (15, '2022-04-28 15:07:37.622481', 114.51000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (16, '2022-04-28 15:07:37.536481', 8.6999999999999993);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (17, '2022-04-28 15:07:37.557481', 5.6500000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (18, '2022-04-28 15:07:37.598481', 34.619999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (19, '2022-04-28 15:07:37.605481', 1.9099999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (20, '2022-04-28 15:07:37.652481', 7.1600000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (21, '2022-04-28 15:07:37.661481', 67.230000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (22, '2022-04-28 15:07:37.560481', 133.63999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (23, '2022-04-28 15:07:37.495481', 64.310000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (24, '2022-04-28 15:07:37.568481', 38.32);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (25, '2022-04-28 15:07:37.772481', 33.450000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (26, '2022-04-28 15:07:37.602481', 30.870000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (27, '2022-04-28 15:07:37.850481', 105.81999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (28, '2022-04-28 15:07:37.556481', 132.36000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (29, '2022-04-28 15:07:37.675481', 139.74000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (30, '2022-04-28 15:07:37.772481', 55.920000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (31, '2022-04-28 15:07:37.689481', 55.259999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (32, '2022-04-28 15:07:37.664481', 125.26000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (33, '2022-04-28 15:07:37.769481', 119.62);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (34, '2022-04-28 15:07:37.710481', 108.52);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (35, '2022-04-28 15:07:37.577481', 37.630000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (36, '2022-04-28 15:07:37.796481', 118.42);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (37, '2022-04-28 15:07:37.694481', 99.019999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (38, '2022-04-28 15:07:37.548481', 121.51000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (39, '2022-04-28 15:07:37.784481', 85.200000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (40, '2022-04-28 15:07:38.032481', 130.56999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (41, '2022-04-28 15:07:38.005481', 144.63);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (42, '2022-04-28 15:07:37.640481', 61.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (43, '2022-04-28 15:07:37.816481', 7.1699999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (44, '2022-04-28 15:07:37.560481', 78.840000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (45, '2022-04-28 15:07:38.057481', 72.659999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (46, '2022-04-28 15:07:37.978481', 66.299999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (47, '2022-04-28 15:07:37.754481', 27.16);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (48, '2022-04-28 15:07:37.904481', 28.789999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (49, '2022-04-28 15:07:37.570481', 55.32);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (50, '2022-04-28 15:07:37.772481', 29.710000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (51, '2022-04-28 15:07:37.523481', 71.090000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (52, '2022-04-28 15:07:37.576481', 78.010000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (53, '2022-04-28 15:07:38.002481', 68.519999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (54, '2022-04-28 15:07:38.120481', 45.619999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (55, '2022-04-28 15:07:37.967481', 48.649999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (56, '2022-04-28 15:07:37.808481', 127.75);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (57, '2022-04-28 15:07:38.270481', 108.76000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (58, '2022-04-28 15:07:37.878481', 68.950000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (59, '2022-04-28 15:07:37.649481', 142.86000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (60, '2022-04-28 15:07:37.832481', 78.299999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (61, '2022-04-28 15:07:38.143481', 130.77000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (62, '2022-04-28 15:07:38.278481', 98.989999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (63, '2022-04-28 15:07:37.976481', 19.539999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (64, '2022-04-28 15:07:37.920481', 29.109999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (65, '2022-04-28 15:07:37.667481', 131.44999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (66, '2022-04-28 15:07:38.198481', 25.649999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (67, '2022-04-28 15:07:37.740481', 112.33);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (68, '2022-04-28 15:07:38.356481', 62.079999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (69, '2022-04-28 15:07:38.369481', 98.489999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (70, '2022-04-28 15:07:38.242481', 6.8099999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (71, '2022-04-28 15:07:37.756481', 110.33);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (72, '2022-04-28 15:07:38.408481', 78.739999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (73, '2022-04-28 15:07:37.691481', 129.96000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (74, '2022-04-28 15:07:37.990481', 89.849999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (75, '2022-04-28 15:07:38.297481', 16.539999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (76, '2022-04-28 15:07:37.624481', 11.699999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (77, '2022-04-28 15:07:37.549481', 117.64);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (78, '2022-04-28 15:07:38.018481', 15.84);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (79, '2022-04-28 15:07:38.183481', 59.579999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (80, '2022-04-28 15:07:37.632481', 75.840000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (81, '2022-04-28 15:07:37.553481', 93.260000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (82, '2022-04-28 15:07:37.800481', 106.03);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (83, '2022-04-28 15:07:38.136481', 29.379999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (84, '2022-04-28 15:07:38.312481', 33.140000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (85, '2022-04-28 15:07:38.492481', 8.4499999999999993);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (86, '2022-04-28 15:07:38.246481', 72.170000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (87, '2022-04-28 15:07:37.820481', 46.759999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (88, '2022-04-28 15:07:37.912481', 145.22999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (89, '2022-04-28 15:07:38.718481', 50.159999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (90, '2022-04-28 15:07:38.192481', 85.989999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (91, '2022-04-28 15:07:38.382481', 121.86);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (92, '2022-04-28 15:07:38.208481', 144.77000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (93, '2022-04-28 15:07:38.681481', 103.02);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (94, '2022-04-28 15:07:37.754481', 63.520000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (95, '2022-04-28 15:07:38.042481', 115.89);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (96, '2022-04-28 15:07:38.624481', 74.25);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (97, '2022-04-28 15:07:38.345481', 38.259999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (98, '2022-04-28 15:07:37.668481', 83.430000000000007);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (99, '2022-04-28 15:07:38.264481', 27.23);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (100, '2022-04-28 15:07:38.872481', 136.00999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (101, '2022-04-28 15:07:37.977481', 35.460000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (102, '2022-04-28 15:07:38.594481', 95.950000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (103, '2022-04-28 15:07:38.296481', 77.849999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (104, '2022-04-28 15:07:38.824481', 102.76000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (105, '2022-04-28 15:07:38.312481', 64.939999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (106, '2022-04-28 15:07:37.790481', 39.799999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (107, '2022-04-28 15:07:38.756481', 67.969999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (108, '2022-04-28 15:07:38.768481', 26.850000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (109, '2022-04-28 15:07:37.799481', 31.440000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (110, '2022-04-28 15:07:38.792481', 122.81);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (111, '2022-04-28 15:07:37.694481', 30.850000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (112, '2022-04-28 15:07:38.928481', 8.9100000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (113, '2022-04-28 15:07:37.924481', 8.6400000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (114, '2022-04-28 15:07:38.954481', 138.28);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (115, '2022-04-28 15:07:38.047481', 110.06999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (116, '2022-04-28 15:07:38.284481', 118.04000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (117, '2022-04-28 15:07:38.174481', 89.480000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (118, '2022-04-28 15:07:38.180481', 63.25);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (119, '2022-04-28 15:07:37.710481', 120.66);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (120, '2022-04-28 15:07:38.312481', 51.350000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (121, '2022-04-28 15:07:38.924481', 65.269999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (122, '2022-04-28 15:07:39.180481', 129.12);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (123, '2022-04-28 15:07:38.702481', 80.090000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (124, '2022-04-28 15:07:38.712481', 24.329999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (125, '2022-04-28 15:07:38.347481', 123.15000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (126, '2022-04-28 15:07:38.354481', 50.450000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (127, '2022-04-28 15:07:38.234481', 22);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (128, '2022-04-28 15:07:39.136481', 8.3900000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (129, '2022-04-28 15:07:38.246481', 103.90000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (130, '2022-04-28 15:07:38.382481', 72.780000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (131, '2022-04-28 15:07:38.782481', 132.90000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (132, '2022-04-28 15:07:38.396481', 105.95999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (133, '2022-04-28 15:07:39.334481', 44.420000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (134, '2022-04-28 15:07:39.214481', 36.5);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (135, '2022-04-28 15:07:37.877481', 61.649999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (136, '2022-04-28 15:07:37.880481', 47.890000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (137, '2022-04-28 15:07:38.979481', 73.260000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (138, '2022-04-28 15:07:37.610481', 87.980000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (139, '2022-04-28 15:07:38.167481', 1.8700000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (140, '2022-04-28 15:07:38.312481', 100.37);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (141, '2022-04-28 15:07:38.318481', 103.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (142, '2022-04-28 15:07:38.608481', 65.510000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (143, '2022-04-28 15:07:38.330481', 16.539999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (144, '2022-04-28 15:07:38.480481', 31.120000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (145, '2022-04-28 15:07:39.067481', 42.020000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (146, '2022-04-28 15:07:37.764481', 52.920000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (147, '2022-04-28 15:07:38.501481', 138.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (148, '2022-04-28 15:07:38.952481', 134.96000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (149, '2022-04-28 15:07:37.770481', 33.43);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (150, '2022-04-28 15:07:39.422481', 56.770000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (151, '2022-04-28 15:07:38.982481', 59.530000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (152, '2022-04-28 15:07:37.776481', 143.59999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (153, '2022-04-28 15:07:39.155481', 14.77);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (154, '2022-04-28 15:07:38.858481', 121.28);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (155, '2022-04-28 15:07:37.937481', 42.560000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (156, '2022-04-28 15:07:39.344481', 50.390000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (157, '2022-04-28 15:07:38.414481', 107.02);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (158, '2022-04-28 15:07:37.788481', 138.80000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (159, '2022-04-28 15:07:38.426481', 140.47999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (160, '2022-04-28 15:07:38.432481', 129.18000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (161, '2022-04-28 15:07:39.404481', 103.33);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (162, '2022-04-28 15:07:38.768481', 123.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (163, '2022-04-28 15:07:38.450481', 109.01000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (164, '2022-04-28 15:07:39.604481', 118.02);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (165, '2022-04-28 15:07:39.452481', 11.869999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (166, '2022-04-28 15:07:38.966481', 5.7999999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (167, '2022-04-28 15:07:37.973481', 142.84999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (168, '2022-04-28 15:07:37.808481', 144.97);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (169, '2022-04-28 15:07:39.162481', 81.329999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (170, '2022-04-28 15:07:39.172481', 36.289999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (171, '2022-04-28 15:07:38.840481', 94.129999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (172, '2022-04-28 15:07:37.816481', 64.159999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (173, '2022-04-28 15:07:38.856481', 108.38);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (174, '2022-04-28 15:07:37.646481', 98.159999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (175, '2022-04-28 15:07:39.572481', 106.47);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (176, '2022-04-28 15:07:39.056481', 10.699999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (177, '2022-04-28 15:07:39.596481', 1.99);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (178, '2022-04-28 15:07:39.074481', 134.21000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (179, '2022-04-28 15:07:39.799481', 27.59);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (180, '2022-04-28 15:07:39.272481', 144.12);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (181, '2022-04-28 15:07:38.196481', 112.09999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (182, '2022-04-28 15:07:37.654481', 11.06);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (183, '2022-04-28 15:07:39.485481', 111.12);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (184, '2022-04-28 15:07:38.208481', 53.329999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (185, '2022-04-28 15:07:39.322481', 15.210000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (186, '2022-04-28 15:07:38.402481', 118.55);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (187, '2022-04-28 15:07:38.407481', 22.239999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (188, '2022-04-28 15:07:38.600481', 26.780000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (189, '2022-04-28 15:07:39.362481', 13.4);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (190, '2022-04-28 15:07:38.612481', 86.409999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (191, '2022-04-28 15:07:39.573481', 36.450000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (192, '2022-04-28 15:07:40.160481', 13.42);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (193, '2022-04-28 15:07:39.016481', 73.870000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (194, '2022-04-28 15:07:38.248481', 16.48);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (195, '2022-04-28 15:07:38.837481', 20.510000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (196, '2022-04-28 15:07:38.060481', 72.590000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (197, '2022-04-28 15:07:40.033481', 104.29000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (198, '2022-04-28 15:07:37.868481', 110.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (199, '2022-04-28 15:07:39.263481', 144.88999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (200, '2022-04-28 15:07:39.672481', 105.87);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (201, '2022-04-28 15:07:39.080481', 95.310000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (202, '2022-04-28 15:07:40.300481', 110.72);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (203, '2022-04-28 15:07:38.893481', 108.44);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (204, '2022-04-28 15:07:39.920481', 100.42);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (205, '2022-04-28 15:07:39.522481', 56.850000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (206, '2022-04-28 15:07:38.502481', 116.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (207, '2022-04-28 15:07:39.956481', 10.17);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (208, '2022-04-28 15:07:38.512481', 135.59999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (209, '2022-04-28 15:07:39.980481', 135.74000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (210, '2022-04-28 15:07:39.152481', 31.890000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (211, '2022-04-28 15:07:39.371481', 19.079999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (212, '2022-04-28 15:07:40.440481', 79.560000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (213, '2022-04-28 15:07:40.454481', 113.8);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (214, '2022-04-28 15:07:40.254481', 79.680000000000007);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (215, '2022-04-28 15:07:37.902481', 88.280000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (216, '2022-04-28 15:07:39.200481', 94.379999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (217, '2022-04-28 15:07:38.774481', 92.349999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (218, '2022-04-28 15:07:37.908481', 12.84);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (219, '2022-04-28 15:07:38.348481', 29.140000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (220, '2022-04-28 15:07:39.452481', 112.47);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (221, '2022-04-28 15:07:39.682481', 74.620000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (222, '2022-04-28 15:07:39.026481', 6.0199999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (223, '2022-04-28 15:07:40.148481', 46.659999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (224, '2022-04-28 15:07:39.712481', 122.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (225, '2022-04-28 15:07:39.047481', 20.530000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (226, '2022-04-28 15:07:40.636481', 101.13);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (227, '2022-04-28 15:07:39.061481', 74.269999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (228, '2022-04-28 15:07:38.156481', 57.380000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (229, '2022-04-28 15:07:39.991481', 66.299999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (230, '2022-04-28 15:07:40.002481', 98.180000000000007);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (231, '2022-04-28 15:07:40.244481', 38.950000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (232, '2022-04-28 15:07:39.560481', 6.9800000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (233, '2022-04-28 15:07:40.268481', 92.459999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (234, '2022-04-28 15:07:39.110481', 28.920000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (235, '2022-04-28 15:07:40.762481', 26.780000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (236, '2022-04-28 15:07:39.832481', 90.870000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (237, '2022-04-28 15:07:38.657481', 113.70999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (238, '2022-04-28 15:07:39.376481', 9.2400000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (239, '2022-04-28 15:07:39.862481', 132.22);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (240, '2022-04-28 15:07:39.872481', 97.450000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (1, '2022-04-28 15:07:37.475481', 11.460000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (2, '2022-04-28 15:07:37.476481', 137.47999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (3, '2022-04-28 15:07:37.502481', 124.8);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (4, '2022-04-28 15:07:37.488481', 124.87);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (5, '2022-04-28 15:07:37.507481', 100.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (6, '2022-04-28 15:07:37.508481', 116.2);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (7, '2022-04-28 15:07:37.521481', 139.28);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (8, '2022-04-28 15:07:37.584481', 64.069999999999993);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (9, '2022-04-28 15:07:37.589481', 62);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (10, '2022-04-28 15:07:37.512481', 33.109999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (11, '2022-04-28 15:07:37.615481', 70.170000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (12, '2022-04-28 15:07:37.616481', 41.539999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (13, '2022-04-28 15:07:37.563481', 47.229999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (14, '2022-04-28 15:07:37.556481', 96.909999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (15, '2022-04-28 15:07:37.682481', 16.43);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (16, '2022-04-28 15:07:37.648481', 116.75);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (17, '2022-04-28 15:07:37.659481', 16.920000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (18, '2022-04-28 15:07:37.634481', 110.95);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (19, '2022-04-28 15:07:37.548481', 96.819999999999993);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (20, '2022-04-28 15:07:37.592481', 142.13999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (21, '2022-04-28 15:07:37.619481', 84.219999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (22, '2022-04-28 15:07:37.714481', 44.020000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (23, '2022-04-28 15:07:37.748481', 128.81);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (24, '2022-04-28 15:07:37.568481', 50.890000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (25, '2022-04-28 15:07:37.772481', 12.58);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (26, '2022-04-28 15:07:37.550481', 35.880000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (27, '2022-04-28 15:07:37.769481', 68.650000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (28, '2022-04-28 15:07:37.808481', 92.299999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (29, '2022-04-28 15:07:37.588481', 117.59);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (30, '2022-04-28 15:07:37.712481', 50.719999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (31, '2022-04-28 15:07:37.689481', 78.75);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (32, '2022-04-28 15:07:37.888481', 53.899999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (33, '2022-04-28 15:07:37.934481', 83.150000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (34, '2022-04-28 15:07:37.540481', 45.609999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (35, '2022-04-28 15:07:37.682481', 26.879999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (36, '2022-04-28 15:07:37.652481', 35.390000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (37, '2022-04-28 15:07:37.546481', 32.960000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (38, '2022-04-28 15:07:37.928481', 45.229999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (39, '2022-04-28 15:07:37.901481', 81.739999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (40, '2022-04-28 15:07:37.752481', 82.739999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (41, '2022-04-28 15:07:37.595481', 7.8399999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (42, '2022-04-28 15:07:37.976481', 132.81);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (43, '2022-04-28 15:07:38.074481', 71.400000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (44, '2022-04-28 15:07:37.560481', 43.649999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (45, '2022-04-28 15:07:37.697481', 135.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (46, '2022-04-28 15:07:37.840481', 54.130000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (47, '2022-04-28 15:07:37.613481', 6.0800000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (48, '2022-04-28 15:07:37.856481', 129.94);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (49, '2022-04-28 15:07:38.011481', 52.460000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (50, '2022-04-28 15:07:37.772481', 35.630000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (51, '2022-04-28 15:07:38.084481', 130.5);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (52, '2022-04-28 15:07:38.200481', 96.769999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (53, '2022-04-28 15:07:38.108481', 133.53999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (54, '2022-04-28 15:07:37.688481', 71.930000000000007);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (55, '2022-04-28 15:07:38.022481', 70.540000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (56, '2022-04-28 15:07:38.200481', 95.870000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (57, '2022-04-28 15:07:37.814481', 135.09999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (58, '2022-04-28 15:07:37.704481', 61.880000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (59, '2022-04-28 15:07:38.121481', 138.58000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (60, '2022-04-28 15:07:37.892481', 69.430000000000007);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (61, '2022-04-28 15:07:37.899481', 108.01000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (62, '2022-04-28 15:07:38.340481', 68.260000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (63, '2022-04-28 15:07:38.102481', 130.13);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (64, '2022-04-28 15:07:37.600481', 2.75);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (65, '2022-04-28 15:07:38.187481', 130.50999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (66, '2022-04-28 15:07:38.066481', 59.119999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (67, '2022-04-28 15:07:37.740481', 34.899999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (68, '2022-04-28 15:07:38.220481', 32.520000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (69, '2022-04-28 15:07:37.610481', 24.260000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (70, '2022-04-28 15:07:37.612481', 5.8700000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (71, '2022-04-28 15:07:37.827481', 87.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (72, '2022-04-28 15:07:38.120481', 122.52);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (73, '2022-04-28 15:07:37.618481', 129.38);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (74, '2022-04-28 15:07:37.620481', 35.789999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (75, '2022-04-28 15:07:38.372481', 14.19);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (76, '2022-04-28 15:07:37.776481', 110.29000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (77, '2022-04-28 15:07:38.550481', 125.66);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (78, '2022-04-28 15:07:38.330481', 16.899999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (79, '2022-04-28 15:07:38.499481', 70.959999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (80, '2022-04-28 15:07:37.632481', 134.22999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (81, '2022-04-28 15:07:38.444481', 27.93);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (82, '2022-04-28 15:07:38.374481', 113.72);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (83, '2022-04-28 15:07:38.551481', 69.370000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (84, '2022-04-28 15:07:38.060481', 15.800000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (85, '2022-04-28 15:07:37.812481', 2.96);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (86, '2022-04-28 15:07:37.902481', 81.239999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (87, '2022-04-28 15:07:38.516481', 56.399999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (88, '2022-04-28 15:07:37.824481', 127.72);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (89, '2022-04-28 15:07:37.739481', 21.940000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (90, '2022-04-28 15:07:38.102481', 108.28);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (91, '2022-04-28 15:07:38.655481', 120.61);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (92, '2022-04-28 15:07:37.840481', 90.480000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (93, '2022-04-28 15:07:38.495481', 122.11);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (94, '2022-04-28 15:07:38.130481', 52.890000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (95, '2022-04-28 15:07:38.137481', 88.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (96, '2022-04-28 15:07:37.952481', 89.560000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (97, '2022-04-28 15:07:37.763481', 26.120000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (98, '2022-04-28 15:07:37.864481', 16.43);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (99, '2022-04-28 15:07:38.660481', 121.73);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (100, '2022-04-28 15:07:38.872481', 85.219999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (101, '2022-04-28 15:07:38.179481', 135.40000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (102, '2022-04-28 15:07:37.676481', 115.42);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (103, '2022-04-28 15:07:38.605481', 90.980000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (104, '2022-04-28 15:07:38.824481', 81.560000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (105, '2022-04-28 15:07:38.522481', 128.52000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (106, '2022-04-28 15:07:38.956481', 111.88);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (107, '2022-04-28 15:07:37.686481', 42.729999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (108, '2022-04-28 15:07:37.688481', 4.2999999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (109, '2022-04-28 15:07:38.998481', 24.559999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (110, '2022-04-28 15:07:37.692481', 7.9400000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (111, '2022-04-28 15:07:37.583481', 12.19);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (112, '2022-04-28 15:07:38.480481', 88.579999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (113, '2022-04-28 15:07:38.602481', 103.7);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (114, '2022-04-28 15:07:38.270481', 99.879999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (115, '2022-04-28 15:07:37.932481', 12.279999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (116, '2022-04-28 15:07:37.704481', 42.729999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (117, '2022-04-28 15:07:37.940481', 120.34999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (118, '2022-04-28 15:07:38.062481', 135.43000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (119, '2022-04-28 15:07:38.900481', 60.859999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (120, '2022-04-28 15:07:38.912481', 15.09);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (121, '2022-04-28 15:07:39.166481', 131.49000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (122, '2022-04-28 15:07:38.692481', 86.159999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (123, '2022-04-28 15:07:38.579481', 78.730000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (124, '2022-04-28 15:07:38.464481', 122.41);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (125, '2022-04-28 15:07:37.847481', 24.43);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (126, '2022-04-28 15:07:37.850481', 95.870000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (127, '2022-04-28 15:07:38.869481', 132.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (128, '2022-04-28 15:07:38.624481', 55.740000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (129, '2022-04-28 15:07:38.117481', 61.840000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (130, '2022-04-28 15:07:37.732481', 9.1199999999999992);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (131, '2022-04-28 15:07:37.996481', 32.170000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (132, '2022-04-28 15:07:38.264481', 88.310000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (133, '2022-04-28 15:07:39.068481', 101.59999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (134, '2022-04-28 15:07:38.678481', 36.939999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (135, '2022-04-28 15:07:39.362481', 19.870000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (136, '2022-04-28 15:07:38.016481', 82.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (137, '2022-04-28 15:07:38.157481', 140.34);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (138, '2022-04-28 15:07:37.886481', 16.73);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (139, '2022-04-28 15:07:38.306481', 6.8499999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (140, '2022-04-28 15:07:39.432481', 25.52);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (141, '2022-04-28 15:07:37.895481', 85.579999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (142, '2022-04-28 15:07:38.750481', 6.8899999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (143, '2022-04-28 15:07:39.474481', 59.189999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (144, '2022-04-28 15:07:38.624481', 41.280000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (145, '2022-04-28 15:07:38.197481', 132.38);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (146, '2022-04-28 15:07:38.786481', 56.130000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (147, '2022-04-28 15:07:38.354481', 116.3);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (148, '2022-04-28 15:07:39.396481', 105.65000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (149, '2022-04-28 15:07:38.664481', 11.77);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (150, '2022-04-28 15:07:39.122481', 134.66);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (151, '2022-04-28 15:07:39.586481', 43.100000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (152, '2022-04-28 15:07:39.296481', 142.84);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (153, '2022-04-28 15:07:39.614481', 82.079999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (154, '2022-04-28 15:07:38.396481', 117.86);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (155, '2022-04-28 15:07:39.332481', 68.040000000000006);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (156, '2022-04-28 15:07:39.656481', 39.170000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (157, '2022-04-28 15:07:38.571481', 133.43000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (158, '2022-04-28 15:07:39.526481', 89.299999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (159, '2022-04-28 15:07:39.062481', 46.990000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (160, '2022-04-28 15:07:39.072481', 62.030000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (161, '2022-04-28 15:07:38.116481', 44.780000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (162, '2022-04-28 15:07:39.740481', 14.140000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (163, '2022-04-28 15:07:38.776481', 122.11);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (164, '2022-04-28 15:07:38.128481', 74.739999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (165, '2022-04-28 15:07:37.802481', 56.359999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (166, '2022-04-28 15:07:38.966481', 48.119999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (167, '2022-04-28 15:07:38.307481', 9.5600000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (168, '2022-04-28 15:07:38.144481', 128.31999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (169, '2022-04-28 15:07:39.331481', 86.230000000000004);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (170, '2022-04-28 15:07:37.982481', 57.32);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (171, '2022-04-28 15:07:37.814481', 102.7);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (172, '2022-04-28 15:07:38.676481', 115.31);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (173, '2022-04-28 15:07:39.721481', 53.880000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (174, '2022-04-28 15:07:39.908481', 60.390000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (175, '2022-04-28 15:07:39.747481', 42.789999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (176, '2022-04-28 15:07:37.824481', 34.259999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (177, '2022-04-28 15:07:38.711481', 50.68);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (178, '2022-04-28 15:07:39.430481', 95.659999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (179, '2022-04-28 15:07:38.367481', 109.52);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (180, '2022-04-28 15:07:38.912481', 15.99);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (181, '2022-04-28 15:07:38.377481', 122);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (182, '2022-04-28 15:07:39.474481', 61.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (183, '2022-04-28 15:07:39.851481', 95.5);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (184, '2022-04-28 15:07:40.048481', 55.840000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (185, '2022-04-28 15:07:39.322481', 1.27);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (186, '2022-04-28 15:07:39.890481', 8.7699999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (187, '2022-04-28 15:07:38.220481', 39.350000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (188, '2022-04-28 15:07:38.600481', 70.239999999999995);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (189, '2022-04-28 15:07:39.740481', 30.18);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (190, '2022-04-28 15:07:38.042481', 20.710000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (191, '2022-04-28 15:07:39.955481', 120.40000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (192, '2022-04-28 15:07:39.200481', 113.22);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (193, '2022-04-28 15:07:38.437481', 48.990000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (194, '2022-04-28 15:07:39.994481', 135.37);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (195, '2022-04-28 15:07:38.447481', 81.310000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (196, '2022-04-28 15:07:39.236481', 144.30000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (197, '2022-04-28 15:07:38.063481', 144.69999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (198, '2022-04-28 15:07:37.868481', 32.369999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (199, '2022-04-28 15:07:40.258481', 9.2799999999999994);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (200, '2022-04-28 15:07:40.072481', 41.030000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (201, '2022-04-28 15:07:38.678481', 82.670000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (202, '2022-04-28 15:07:39.492481', 133.21000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (203, '2022-04-28 15:07:38.893481', 5.5199999999999996);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (204, '2022-04-28 15:07:37.676481', 23.510000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (205, '2022-04-28 15:07:40.342481', 39.25);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (206, '2022-04-28 15:07:39.944481', 15.210000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (207, '2022-04-28 15:07:39.335481', 51.189999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (208, '2022-04-28 15:07:38.304481', 72.799999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (209, '2022-04-28 15:07:38.308481', 140.53);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (210, '2022-04-28 15:07:38.102481', 83.579999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (211, '2022-04-28 15:07:39.793481', 9.6600000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (212, '2022-04-28 15:07:37.896481', 22.91);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (213, '2022-04-28 15:07:38.963481', 127.22);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (214, '2022-04-28 15:07:40.468481', 33.5);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (215, '2022-04-28 15:07:38.332481', 23.079999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (216, '2022-04-28 15:07:39.200481', 112.29000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (217, '2022-04-28 15:07:38.557481', 128.47999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (218, '2022-04-28 15:07:39.870481', 48.700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (219, '2022-04-28 15:07:38.129481', 98.939999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (220, '2022-04-28 15:07:38.792481', 40.189999999999998);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (221, '2022-04-28 15:07:38.577481', 109.51000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (222, '2022-04-28 15:07:40.580481', 8.5899999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (223, '2022-04-28 15:07:39.925481', 71.370000000000005);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (224, '2022-04-28 15:07:38.816481', 110.92);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (225, '2022-04-28 15:07:40.172481', 83.219999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (226, '2022-04-28 15:07:40.636481', 144.44);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (227, '2022-04-28 15:07:40.650481', 46.920000000000002);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (228, '2022-04-28 15:07:39.296481', 46.960000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (229, '2022-04-28 15:07:39.304481', 81.030000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (230, '2022-04-28 15:07:39.312481', 80.090000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (231, '2022-04-28 15:07:37.934481', 114.45);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (232, '2022-04-28 15:07:40.720481', 119.93000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (233, '2022-04-28 15:07:40.035481', 9.5700000000000003);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (234, '2022-04-28 15:07:40.280481', 103.43000000000001);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (235, '2022-04-28 15:07:39.587481', 127.81999999999999);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (236, '2022-04-28 15:07:38.888481', 82.799999999999997);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (237, '2022-04-28 15:07:39.605481', 123.56);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (238, '2022-04-28 15:07:38.424481', 144.87);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (239, '2022-04-28 15:07:38.189481', 3.04);
INSERT INTO _timescaledb_internal._hyper_2_1_chunk (key, fix, value) VALUES (240, '2022-04-28 15:07:39.152481', 135.22);


--
-- TOC entry 2555 (class 0 OID 89643)
-- Dependencies: 241
-- Data for Name: float_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.float_actual (key, fix, value) VALUES (1, '2022-04-28 15:07:37.477481', 44.979999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (2, '2022-04-28 15:07:37.478481', 98.790000000000006);
INSERT INTO public.float_actual (key, fix, value) VALUES (3, '2022-04-28 15:07:37.490481', 5.5999999999999996);
INSERT INTO public.float_actual (key, fix, value) VALUES (4, '2022-04-28 15:07:37.520481', 46.640000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (5, '2022-04-28 15:07:37.522481', 102.19);
INSERT INTO public.float_actual (key, fix, value) VALUES (6, '2022-04-28 15:07:37.532481', 29.109999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (7, '2022-04-28 15:07:37.563481', 139.40000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (8, '2022-04-28 15:07:37.544481', 3.6800000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (9, '2022-04-28 15:07:37.571481', 70.030000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (10, '2022-04-28 15:07:37.552481', 71.989999999999995);
INSERT INTO public.float_actual (key, fix, value) VALUES (11, '2022-04-28 15:07:37.527481', 80.409999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (12, '2022-04-28 15:07:37.568481', 8.9700000000000006);
INSERT INTO public.float_actual (key, fix, value) VALUES (13, '2022-04-28 15:07:37.537481', 33);
INSERT INTO public.float_actual (key, fix, value) VALUES (14, '2022-04-28 15:07:37.570481', 124.45);
INSERT INTO public.float_actual (key, fix, value) VALUES (15, '2022-04-28 15:07:37.502481', 2.71);
INSERT INTO public.float_actual (key, fix, value) VALUES (16, '2022-04-28 15:07:37.568481', 129.66);
INSERT INTO public.float_actual (key, fix, value) VALUES (17, '2022-04-28 15:07:37.506481', 140.30000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (18, '2022-04-28 15:07:37.670481', 48.460000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (19, '2022-04-28 15:07:37.681481', 7.04);
INSERT INTO public.float_actual (key, fix, value) VALUES (20, '2022-04-28 15:07:37.572481', 87.780000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (21, '2022-04-28 15:07:37.619481', 90.010000000000005);
INSERT INTO public.float_actual (key, fix, value) VALUES (22, '2022-04-28 15:07:37.516481', 132.41999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (23, '2022-04-28 15:07:37.610481', 76.709999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (24, '2022-04-28 15:07:37.808481', 33.719999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (25, '2022-04-28 15:07:37.522481', 101.58);
INSERT INTO public.float_actual (key, fix, value) VALUES (26, '2022-04-28 15:07:37.602481', 88.159999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (27, '2022-04-28 15:07:37.607481', 33.979999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (28, '2022-04-28 15:07:37.836481', 107.29000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (29, '2022-04-28 15:07:37.820481', 10.699999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (30, '2022-04-28 15:07:37.652481', 19.489999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (31, '2022-04-28 15:07:37.751481', 140.38999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (32, '2022-04-28 15:07:37.600481', 101.38);
INSERT INTO public.float_actual (key, fix, value) VALUES (33, '2022-04-28 15:07:37.670481', 113.81);
INSERT INTO public.float_actual (key, fix, value) VALUES (34, '2022-04-28 15:07:37.574481', 132.38999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (35, '2022-04-28 15:07:37.612481', 41.5);
INSERT INTO public.float_actual (key, fix, value) VALUES (36, '2022-04-28 15:07:37.652481', 100.78);
INSERT INTO public.float_actual (key, fix, value) VALUES (37, '2022-04-28 15:07:37.620481', 132.97999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (38, '2022-04-28 15:07:37.548481', 101.59999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (39, '2022-04-28 15:07:37.784481', 87.689999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (40, '2022-04-28 15:07:37.872481', 109.54000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (41, '2022-04-28 15:07:37.636481', 35.689999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (42, '2022-04-28 15:07:37.976481', 56.369999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (43, '2022-04-28 15:07:37.902481', 110.17);
INSERT INTO public.float_actual (key, fix, value) VALUES (44, '2022-04-28 15:07:37.868481', 115.95999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (45, '2022-04-28 15:07:37.562481', 1.8899999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (46, '2022-04-28 15:07:37.840481', 94.900000000000006);
INSERT INTO public.float_actual (key, fix, value) VALUES (47, '2022-04-28 15:07:37.942481', 21.859999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (48, '2022-04-28 15:07:37.568481', 68.159999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (49, '2022-04-28 15:07:37.766481', 54.479999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (50, '2022-04-28 15:07:37.922481', 84.730000000000004);
INSERT INTO public.float_actual (key, fix, value) VALUES (51, '2022-04-28 15:07:37.778481', 11.279999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (52, '2022-04-28 15:07:37.524481', 112.93000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (53, '2022-04-28 15:07:37.790481', 89.969999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (54, '2022-04-28 15:07:37.796481', 60.079999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (55, '2022-04-28 15:07:37.637481', 30.690000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (56, '2022-04-28 15:07:37.752481', 29.09);
INSERT INTO public.float_actual (key, fix, value) VALUES (57, '2022-04-28 15:07:37.814481', 94.909999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (58, '2022-04-28 15:07:38.226481', 48.259999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (59, '2022-04-28 15:07:37.649481', 124.20999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (60, '2022-04-28 15:07:38.312481', 85.590000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (61, '2022-04-28 15:07:37.716481', 55.109999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (62, '2022-04-28 15:07:38.216481', 31.960000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (63, '2022-04-28 15:07:38.165481', 95.069999999999993);
INSERT INTO public.float_actual (key, fix, value) VALUES (64, '2022-04-28 15:07:37.600481', 10.470000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (65, '2022-04-28 15:07:38.317481', 87.180000000000007);
INSERT INTO public.float_actual (key, fix, value) VALUES (66, '2022-04-28 15:07:37.802481', 17.84);
INSERT INTO public.float_actual (key, fix, value) VALUES (67, '2022-04-28 15:07:37.606481', 17.600000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (68, '2022-04-28 15:07:37.880481', 25.82);
INSERT INTO public.float_actual (key, fix, value) VALUES (69, '2022-04-28 15:07:37.748481', 4.8700000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (70, '2022-04-28 15:07:38.452481', 13.890000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (71, '2022-04-28 15:07:37.898481', 24.289999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (72, '2022-04-28 15:07:38.120481', 125.09);
INSERT INTO public.float_actual (key, fix, value) VALUES (73, '2022-04-28 15:07:38.275481', 50.380000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (74, '2022-04-28 15:07:37.842481', 143.72);
INSERT INTO public.float_actual (key, fix, value) VALUES (75, '2022-04-28 15:07:37.847481', 103.33);
INSERT INTO public.float_actual (key, fix, value) VALUES (76, '2022-04-28 15:07:37.852481', 77.109999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (77, '2022-04-28 15:07:37.934481', 142.97999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (78, '2022-04-28 15:07:37.940481', 142.43000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (79, '2022-04-28 15:07:37.788481', 115.68000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (80, '2022-04-28 15:07:37.632481', 108.43000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (81, '2022-04-28 15:07:38.201481', 49.020000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (82, '2022-04-28 15:07:38.128481', 83.349999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (83, '2022-04-28 15:07:38.551481', 20.77);
INSERT INTO public.float_actual (key, fix, value) VALUES (84, '2022-04-28 15:07:37.724481', 38.549999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (85, '2022-04-28 15:07:37.897481', 104.34999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (86, '2022-04-28 15:07:37.644481', 21.379999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (87, '2022-04-28 15:07:38.603481', 131.41);
INSERT INTO public.float_actual (key, fix, value) VALUES (88, '2022-04-28 15:07:37.824481', 8.8000000000000007);
INSERT INTO public.float_actual (key, fix, value) VALUES (89, '2022-04-28 15:07:38.451481', 143.43000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (90, '2022-04-28 15:07:38.102481', 59.439999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (91, '2022-04-28 15:07:38.018481', 10.34);
INSERT INTO public.float_actual (key, fix, value) VALUES (92, '2022-04-28 15:07:38.576481', 25.82);
INSERT INTO public.float_actual (key, fix, value) VALUES (93, '2022-04-28 15:07:37.937481', 115.06);
INSERT INTO public.float_actual (key, fix, value) VALUES (94, '2022-04-28 15:07:38.506481', 8.0500000000000007);
INSERT INTO public.float_actual (key, fix, value) VALUES (95, '2022-04-28 15:07:38.517481', 61.469999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (96, '2022-04-28 15:07:38.816481', 64.269999999999996);
INSERT INTO public.float_actual (key, fix, value) VALUES (97, '2022-04-28 15:07:38.830481', 36.329999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (98, '2022-04-28 15:07:38.256481', 5.3099999999999996);
INSERT INTO public.float_actual (key, fix, value) VALUES (99, '2022-04-28 15:07:38.363481', 9.8499999999999996);
INSERT INTO public.float_actual (key, fix, value) VALUES (100, '2022-04-28 15:07:38.872481', 90.280000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (101, '2022-04-28 15:07:37.876481', 3.8500000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (102, '2022-04-28 15:07:38.594481', 79.25);
INSERT INTO public.float_actual (key, fix, value) VALUES (103, '2022-04-28 15:07:38.399481', 24.18);
INSERT INTO public.float_actual (key, fix, value) VALUES (104, '2022-04-28 15:07:38.512481', 69.670000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (105, '2022-04-28 15:07:38.627481', 46.479999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (106, '2022-04-28 15:07:37.896481', 35.369999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (107, '2022-04-28 15:07:38.114481', 91.450000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (108, '2022-04-28 15:07:38.120481', 73.349999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (109, '2022-04-28 15:07:38.344481', 52.869999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (110, '2022-04-28 15:07:38.022481', 15.35);
INSERT INTO public.float_actual (key, fix, value) VALUES (111, '2022-04-28 15:07:38.138481', 17.789999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (112, '2022-04-28 15:07:38.368481', 121.43000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (113, '2022-04-28 15:07:38.715481', 95.939999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (114, '2022-04-28 15:07:37.814481', 90.890000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (115, '2022-04-28 15:07:38.162481', 29.579999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (116, '2022-04-28 15:07:38.284481', 99.819999999999993);
INSERT INTO public.float_actual (key, fix, value) VALUES (117, '2022-04-28 15:07:37.589481', 122.52);
INSERT INTO public.float_actual (key, fix, value) VALUES (118, '2022-04-28 15:07:37.944481', 52.469999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (119, '2022-04-28 15:07:38.186481', 39.530000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (120, '2022-04-28 15:07:38.552481', 21.09);
INSERT INTO public.float_actual (key, fix, value) VALUES (121, '2022-04-28 15:07:37.835481', 38.990000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (122, '2022-04-28 15:07:38.082481', 63.609999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (123, '2022-04-28 15:07:37.964481', 103.56);
INSERT INTO public.float_actual (key, fix, value) VALUES (124, '2022-04-28 15:07:37.844481', 54.43);
INSERT INTO public.float_actual (key, fix, value) VALUES (125, '2022-04-28 15:07:39.097481', 4.6200000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (126, '2022-04-28 15:07:38.480481', 40.490000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (127, '2022-04-28 15:07:38.996481', 127.09999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (128, '2022-04-28 15:07:37.984481', 10.390000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (129, '2022-04-28 15:07:38.504481', 131.28);
INSERT INTO public.float_actual (key, fix, value) VALUES (130, '2022-04-28 15:07:38.902481', 139.08000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (131, '2022-04-28 15:07:37.603481', 6.7800000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (132, '2022-04-28 15:07:37.736481', 82.140000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (133, '2022-04-28 15:07:39.201481', 80.700000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (134, '2022-04-28 15:07:38.008481', 72.25);
INSERT INTO public.float_actual (key, fix, value) VALUES (135, '2022-04-28 15:07:38.282481', 3.29);
INSERT INTO public.float_actual (key, fix, value) VALUES (136, '2022-04-28 15:07:37.880481', 38.479999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (137, '2022-04-28 15:07:39.116481', 20.629999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (138, '2022-04-28 15:07:39.404481', 20.890000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (139, '2022-04-28 15:07:39.140481', 12.619999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (140, '2022-04-28 15:07:38.872481', 9.6300000000000008);
INSERT INTO public.float_actual (key, fix, value) VALUES (141, '2022-04-28 15:07:38.600481', 112.95999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (142, '2022-04-28 15:07:39.034481', 52.450000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (143, '2022-04-28 15:07:38.902481', 22.719999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (144, '2022-04-28 15:07:39.344481', 21.649999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (145, '2022-04-28 15:07:38.777481', 24.5);
INSERT INTO public.float_actual (key, fix, value) VALUES (146, '2022-04-28 15:07:39.224481', 62.369999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (147, '2022-04-28 15:07:38.648481', 87.75);
INSERT INTO public.float_actual (key, fix, value) VALUES (148, '2022-04-28 15:07:37.916481', 14.26);
INSERT INTO public.float_actual (key, fix, value) VALUES (149, '2022-04-28 15:07:37.919481', 106.08);
INSERT INTO public.float_actual (key, fix, value) VALUES (150, '2022-04-28 15:07:38.672481', 92.140000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (151, '2022-04-28 15:07:38.680481', 89.140000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (152, '2022-04-28 15:07:39.600481', 125.06);
INSERT INTO public.float_actual (key, fix, value) VALUES (153, '2022-04-28 15:07:39.308481', 36.590000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (154, '2022-04-28 15:07:38.550481', 95.269999999999996);
INSERT INTO public.float_actual (key, fix, value) VALUES (155, '2022-04-28 15:07:39.487481', 13.16);
INSERT INTO public.float_actual (key, fix, value) VALUES (156, '2022-04-28 15:07:38.096481', 62.780000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (157, '2022-04-28 15:07:38.257481', 104.19);
INSERT INTO public.float_actual (key, fix, value) VALUES (158, '2022-04-28 15:07:38.420481', 35.710000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (159, '2022-04-28 15:07:38.267481', 107.92);
INSERT INTO public.float_actual (key, fix, value) VALUES (160, '2022-04-28 15:07:39.552481', 108.31999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (161, '2022-04-28 15:07:39.082481', 12.73);
INSERT INTO public.float_actual (key, fix, value) VALUES (162, '2022-04-28 15:07:39.578481', 35.689999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (163, '2022-04-28 15:07:37.961481', 109.23);
INSERT INTO public.float_actual (key, fix, value) VALUES (164, '2022-04-28 15:07:39.276481', 30.190000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (165, '2022-04-28 15:07:37.637481', 127.81999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (166, '2022-04-28 15:07:39.796481', 15.380000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (167, '2022-04-28 15:07:38.808481', 4.2199999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (168, '2022-04-28 15:07:38.984481', 137.31999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (169, '2022-04-28 15:07:39.500481', 129.38);
INSERT INTO public.float_actual (key, fix, value) VALUES (170, '2022-04-28 15:07:38.832481', 65.689999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (171, '2022-04-28 15:07:39.182481', 36.420000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (172, '2022-04-28 15:07:38.160481', 78.959999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (173, '2022-04-28 15:07:39.721481', 62.060000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (174, '2022-04-28 15:07:37.994481', 113.41);
INSERT INTO public.float_actual (key, fix, value) VALUES (175, '2022-04-28 15:07:38.172481', 128.59999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (176, '2022-04-28 15:07:39.584481', 62.600000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (177, '2022-04-28 15:07:39.596481', 116.15000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (178, '2022-04-28 15:07:39.964481', 60.079999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (179, '2022-04-28 15:07:39.441481', 106.31999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (180, '2022-04-28 15:07:39.272481', 15.69);
INSERT INTO public.float_actual (key, fix, value) VALUES (181, '2022-04-28 15:07:38.920481', 40.130000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (182, '2022-04-28 15:07:39.292481', 4.9699999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (183, '2022-04-28 15:07:38.021481', 21.309999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (184, '2022-04-28 15:07:39.864481', 34.340000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (185, '2022-04-28 15:07:38.027481', 67.209999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (186, '2022-04-28 15:07:38.774481', 58.979999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (187, '2022-04-28 15:07:38.220481', 61.939999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (188, '2022-04-28 15:07:37.848481', 60.359999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (189, '2022-04-28 15:07:39.740481', 48.950000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (190, '2022-04-28 15:07:38.422481', 108.28);
INSERT INTO public.float_actual (key, fix, value) VALUES (191, '2022-04-28 15:07:39.191481', 143.49000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (192, '2022-04-28 15:07:37.664481', 19.609999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (193, '2022-04-28 15:07:37.858481', 79.670000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (194, '2022-04-28 15:07:38.248481', 108.02);
INSERT INTO public.float_actual (key, fix, value) VALUES (195, '2022-04-28 15:07:37.862481', 24.510000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (196, '2022-04-28 15:07:38.256481', 12.41);
INSERT INTO public.float_actual (key, fix, value) VALUES (197, '2022-04-28 15:07:38.260481', 59.609999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (198, '2022-04-28 15:07:40.244481', 60.030000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (199, '2022-04-28 15:07:39.263481', 31.66);
INSERT INTO public.float_actual (key, fix, value) VALUES (200, '2022-04-28 15:07:38.872481', 114.26000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (201, '2022-04-28 15:07:39.080481', 137.24000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (202, '2022-04-28 15:07:39.492481', 107.91);
INSERT INTO public.float_actual (key, fix, value) VALUES (203, '2022-04-28 15:07:38.893481', 58.82);
INSERT INTO public.float_actual (key, fix, value) VALUES (204, '2022-04-28 15:07:38.288481', 64.280000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (205, '2022-04-28 15:07:39.727481', 82.780000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (206, '2022-04-28 15:07:39.326481', 60.060000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (207, '2022-04-28 15:07:38.921481', 138.34);
INSERT INTO public.float_actual (key, fix, value) VALUES (208, '2022-04-28 15:07:39.136481', 72.219999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (209, '2022-04-28 15:07:38.517481', 75.219999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (210, '2022-04-28 15:07:40.412481', 83.120000000000005);
INSERT INTO public.float_actual (key, fix, value) VALUES (211, '2022-04-28 15:07:40.215481', 22.48);
INSERT INTO public.float_actual (key, fix, value) VALUES (212, '2022-04-28 15:07:38.320481', 142.86000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (213, '2022-04-28 15:07:38.537481', 52.350000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (214, '2022-04-28 15:07:38.328481', 120.77);
INSERT INTO public.float_actual (key, fix, value) VALUES (215, '2022-04-28 15:07:38.977481', 95.890000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (216, '2022-04-28 15:07:40.064481', 92.209999999999994);
INSERT INTO public.float_actual (key, fix, value) VALUES (217, '2022-04-28 15:07:40.293481', 77.75);
INSERT INTO public.float_actual (key, fix, value) VALUES (218, '2022-04-28 15:07:38.344481', 92.299999999999997);
INSERT INTO public.float_actual (key, fix, value) VALUES (219, '2022-04-28 15:07:38.786481', 39.060000000000002);
INSERT INTO public.float_actual (key, fix, value) VALUES (220, '2022-04-28 15:07:39.672481', 98.969999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (221, '2022-04-28 15:07:38.798481', 116.78);
INSERT INTO public.float_actual (key, fix, value) VALUES (222, '2022-04-28 15:07:37.694481', 70.200000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (223, '2022-04-28 15:07:39.479481', 116.02);
INSERT INTO public.float_actual (key, fix, value) VALUES (224, '2022-04-28 15:07:39.712481', 36.329999999999998);
INSERT INTO public.float_actual (key, fix, value) VALUES (225, '2022-04-28 15:07:40.397481', 69.650000000000006);
INSERT INTO public.float_actual (key, fix, value) VALUES (226, '2022-04-28 15:07:38.150481', 14.140000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (227, '2022-04-28 15:07:38.607481', 124.95);
INSERT INTO public.float_actual (key, fix, value) VALUES (228, '2022-04-28 15:07:40.436481', 56.850000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (229, '2022-04-28 15:07:39.991481', 95.090000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (230, '2022-04-28 15:07:39.312481', 15.130000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (231, '2022-04-28 15:07:38.396481', 53.340000000000003);
INSERT INTO public.float_actual (key, fix, value) VALUES (232, '2022-04-28 15:07:40.720481', 12.1);
INSERT INTO public.float_actual (key, fix, value) VALUES (233, '2022-04-28 15:07:40.035481', 135.91);
INSERT INTO public.float_actual (key, fix, value) VALUES (234, '2022-04-28 15:07:39.344481', 128.44999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (235, '2022-04-28 15:07:40.057481', 129.87);
INSERT INTO public.float_actual (key, fix, value) VALUES (236, '2022-04-28 15:07:38.180481', 1.8799999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (237, '2022-04-28 15:07:40.316481', 40.109999999999999);
INSERT INTO public.float_actual (key, fix, value) VALUES (238, '2022-04-28 15:07:38.424481', 15.380000000000001);
INSERT INTO public.float_actual (key, fix, value) VALUES (239, '2022-04-28 15:07:38.189481', 103.06);
INSERT INTO public.float_actual (key, fix, value) VALUES (240, '2022-04-28 15:07:38.912481', 67);


--
-- TOC entry 2554 (class 0 OID 89633)
-- Dependencies: 240
-- Data for Name: float_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2548 (class 0 OID 89574)
-- Dependencies: 234
-- Data for Name: glossary; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (2, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (1, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (8, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (7, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (4, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (3, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (10, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (9, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (6, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (5, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''1'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (12, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (11, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (18, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (17, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (14, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (13, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (20, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (19, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (16, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (15, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''2'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (22, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (21, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (28, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (27, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (24, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (23, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (30, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (29, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (26, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (25, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''03'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''3'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (32, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (31, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (38, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (37, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (34, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (33, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (40, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (39, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (36, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (35, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''04'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''4'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (42, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (41, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (48, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (47, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (44, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (43, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (50, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (49, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (46, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (45, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''05'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''5'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (52, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (51, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (58, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (57, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (54, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (53, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (60, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (59, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (56, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (55, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''06'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''6'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (62, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (61, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (68, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (67, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (64, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (63, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (70, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (69, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (66, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (65, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''07'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''7'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (72, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (71, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (78, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (77, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (74, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (73, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (80, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (79, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (76, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (75, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''08'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''8'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (82, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (81, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (88, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (87, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (84, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (83, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (90, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (89, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (86, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (85, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''09'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''9'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (92, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (91, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (98, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (97, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (94, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (93, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (100, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (99, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (96, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (95, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''10'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''10'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (102, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (101, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (108, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (107, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (104, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (103, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (110, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (109, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (106, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (105, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''11'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''11'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (112, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (111, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (118, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (117, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (114, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (113, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (120, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (119, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (116, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (115, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''12'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''12'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (122, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (121, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (128, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (127, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (124, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (123, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (130, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (129, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (126, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (125, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''13'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''13'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (132, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (131, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (138, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (137, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (134, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (133, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (140, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (139, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (136, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (135, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''14'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''14'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (142, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (141, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (148, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (147, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (144, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (143, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (150, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (149, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (146, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (145, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''15'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''15'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (152, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (151, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (158, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (157, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (154, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (153, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (160, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (159, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (156, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (155, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''16'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''16'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (162, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (161, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (168, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (167, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (164, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (163, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (170, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (169, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (166, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (165, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''17'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''17'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (172, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (171, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (178, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (177, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (174, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (173, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (180, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (179, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (176, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (175, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''18'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''18'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (182, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (181, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (188, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (187, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (184, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (183, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (190, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (189, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (186, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (185, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''19'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''19'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (192, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (191, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (198, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (197, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (194, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (193, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (200, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (199, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (196, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (195, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''20'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''20'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (202, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (201, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (208, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (207, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (204, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (203, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (210, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (209, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (206, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (205, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''21'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''21'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (212, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (211, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (218, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (217, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (214, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (213, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (220, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (219, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (216, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (215, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''22'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''22'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (222, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (221, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (228, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (227, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (224, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (223, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (230, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (229, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (226, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (225, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''23'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''23'']/Supply/Item[@key=''anode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (232, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''1'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''photocathode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (231, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''1'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''photocathode'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (238, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''2'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate1'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (237, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''2'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate1'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (234, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''3'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate12'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (233, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''3'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate12'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (240, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''4'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate2'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (239, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''4'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate2'']/Voltage', 'integer');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (236, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''5'']/Amperage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''anode'']/Amperage', 'float');
INSERT INTO public.glossary (key, communication, configuration, tablename) VALUES (235, 'Configuration[@key=''_036CE061.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''24'']/Channel/Item[@key=''5'']/Voltage', 'Configuration[@key=''_036CE061.ControlWorkstation'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Scale/Slot/Item[@key=''24'']/Supply/Item[@key=''anode'']/Voltage', 'integer');


--
-- TOC entry 2579 (class 0 OID 0)
-- Dependencies: 233
-- Name: glossary_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.glossary_key_seq', 240, true);


--
-- TOC entry 2553 (class 0 OID 89625)
-- Dependencies: 239
-- Data for Name: integer_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.integer_actual (key, fix, value) VALUES (1, '2022-04-28 15:07:37.479481', 28);
INSERT INTO public.integer_actual (key, fix, value) VALUES (2, '2022-04-28 15:07:37.486481', 92);
INSERT INTO public.integer_actual (key, fix, value) VALUES (3, '2022-04-28 15:07:37.484481', 77);
INSERT INTO public.integer_actual (key, fix, value) VALUES (4, '2022-04-28 15:07:37.520481', 145);
INSERT INTO public.integer_actual (key, fix, value) VALUES (5, '2022-04-28 15:07:37.502481', 65);
INSERT INTO public.integer_actual (key, fix, value) VALUES (6, '2022-04-28 15:07:37.544481', 83);
INSERT INTO public.integer_actual (key, fix, value) VALUES (7, '2022-04-28 15:07:37.500481', 118);
INSERT INTO public.integer_actual (key, fix, value) VALUES (8, '2022-04-28 15:07:37.504481', 78);
INSERT INTO public.integer_actual (key, fix, value) VALUES (9, '2022-04-28 15:07:37.580481', 20);
INSERT INTO public.integer_actual (key, fix, value) VALUES (10, '2022-04-28 15:07:37.522481', 98);
INSERT INTO public.integer_actual (key, fix, value) VALUES (11, '2022-04-28 15:07:37.582481', 101);
INSERT INTO public.integer_actual (key, fix, value) VALUES (12, '2022-04-28 15:07:37.508481', 132);
INSERT INTO public.integer_actual (key, fix, value) VALUES (13, '2022-04-28 15:07:37.524481', 60);
INSERT INTO public.integer_actual (key, fix, value) VALUES (14, '2022-04-28 15:07:37.556481', 14);
INSERT INTO public.integer_actual (key, fix, value) VALUES (15, '2022-04-28 15:07:37.502481', 78);
INSERT INTO public.integer_actual (key, fix, value) VALUES (16, '2022-04-28 15:07:37.536481', 72);
INSERT INTO public.integer_actual (key, fix, value) VALUES (17, '2022-04-28 15:07:37.523481', 83);
INSERT INTO public.integer_actual (key, fix, value) VALUES (18, '2022-04-28 15:07:37.508481', 131);
INSERT INTO public.integer_actual (key, fix, value) VALUES (19, '2022-04-28 15:07:37.586481', 48);
INSERT INTO public.integer_actual (key, fix, value) VALUES (20, '2022-04-28 15:07:37.672481', 33);
INSERT INTO public.integer_actual (key, fix, value) VALUES (21, '2022-04-28 15:07:37.556481', 115);
INSERT INTO public.integer_actual (key, fix, value) VALUES (22, '2022-04-28 15:07:37.604481', 22);
INSERT INTO public.integer_actual (key, fix, value) VALUES (23, '2022-04-28 15:07:37.518481', 117);
INSERT INTO public.integer_actual (key, fix, value) VALUES (24, '2022-04-28 15:07:37.616481', 117);
INSERT INTO public.integer_actual (key, fix, value) VALUES (25, '2022-04-28 15:07:37.722481', 104);
INSERT INTO public.integer_actual (key, fix, value) VALUES (26, '2022-04-28 15:07:37.576481', 141);
INSERT INTO public.integer_actual (key, fix, value) VALUES (27, '2022-04-28 15:07:37.742481', 110);
INSERT INTO public.integer_actual (key, fix, value) VALUES (28, '2022-04-28 15:07:37.584481', 114);
INSERT INTO public.integer_actual (key, fix, value) VALUES (29, '2022-04-28 15:07:37.501481', 77);
INSERT INTO public.integer_actual (key, fix, value) VALUES (30, '2022-04-28 15:07:37.682481', 113);
INSERT INTO public.integer_actual (key, fix, value) VALUES (31, '2022-04-28 15:07:37.565481', 109);
INSERT INTO public.integer_actual (key, fix, value) VALUES (32, '2022-04-28 15:07:37.888481', 120);
INSERT INTO public.integer_actual (key, fix, value) VALUES (33, '2022-04-28 15:07:37.604481', 50);
INSERT INTO public.integer_actual (key, fix, value) VALUES (34, '2022-04-28 15:07:37.710481', 89);
INSERT INTO public.integer_actual (key, fix, value) VALUES (35, '2022-04-28 15:07:37.857481', 42);
INSERT INTO public.integer_actual (key, fix, value) VALUES (36, '2022-04-28 15:07:37.616481', 69);
INSERT INTO public.integer_actual (key, fix, value) VALUES (37, '2022-04-28 15:07:37.768481', 14);
INSERT INTO public.integer_actual (key, fix, value) VALUES (38, '2022-04-28 15:07:37.738481', 133);
INSERT INTO public.integer_actual (key, fix, value) VALUES (39, '2022-04-28 15:07:37.706481', 5);
INSERT INTO public.integer_actual (key, fix, value) VALUES (40, '2022-04-28 15:07:37.952481', 57);
INSERT INTO public.integer_actual (key, fix, value) VALUES (41, '2022-04-28 15:07:37.513481', 85);
INSERT INTO public.integer_actual (key, fix, value) VALUES (42, '2022-04-28 15:07:37.766481', 52);
INSERT INTO public.integer_actual (key, fix, value) VALUES (43, '2022-04-28 15:07:37.730481', 36);
INSERT INTO public.integer_actual (key, fix, value) VALUES (44, '2022-04-28 15:07:37.956481', 55);
INSERT INTO public.integer_actual (key, fix, value) VALUES (45, '2022-04-28 15:07:37.742481', 43);
INSERT INTO public.integer_actual (key, fix, value) VALUES (46, '2022-04-28 15:07:38.070481', 120);
INSERT INTO public.integer_actual (key, fix, value) VALUES (47, '2022-04-28 15:07:38.083481', 127);
INSERT INTO public.integer_actual (key, fix, value) VALUES (48, '2022-04-28 15:07:37.568481', 70);
INSERT INTO public.integer_actual (key, fix, value) VALUES (49, '2022-04-28 15:07:38.109481', 78);
INSERT INTO public.integer_actual (key, fix, value) VALUES (50, '2022-04-28 15:07:38.122481', 104);
INSERT INTO public.integer_actual (key, fix, value) VALUES (51, '2022-04-28 15:07:37.778481', 113);
INSERT INTO public.integer_actual (key, fix, value) VALUES (52, '2022-04-28 15:07:37.576481', 56);
INSERT INTO public.integer_actual (key, fix, value) VALUES (53, '2022-04-28 15:07:37.896481', 107);
INSERT INTO public.integer_actual (key, fix, value) VALUES (54, '2022-04-28 15:07:37.904481', 91);
INSERT INTO public.integer_actual (key, fix, value) VALUES (55, '2022-04-28 15:07:37.747481', 47);
INSERT INTO public.integer_actual (key, fix, value) VALUES (56, '2022-04-28 15:07:37.864481', 143);
INSERT INTO public.integer_actual (key, fix, value) VALUES (57, '2022-04-28 15:07:38.042481', 8);
INSERT INTO public.integer_actual (key, fix, value) VALUES (58, '2022-04-28 15:07:38.110481', 82);
INSERT INTO public.integer_actual (key, fix, value) VALUES (59, '2022-04-28 15:07:37.767481', 84);
INSERT INTO public.integer_actual (key, fix, value) VALUES (60, '2022-04-28 15:07:37.952481', 143);
INSERT INTO public.integer_actual (key, fix, value) VALUES (61, '2022-04-28 15:07:38.021481', 10);
INSERT INTO public.integer_actual (key, fix, value) VALUES (62, '2022-04-28 15:07:37.782481', 65);
INSERT INTO public.integer_actual (key, fix, value) VALUES (63, '2022-04-28 15:07:37.850481', 54);
INSERT INTO public.integer_actual (key, fix, value) VALUES (64, '2022-04-28 15:07:38.048481', 90);
INSERT INTO public.integer_actual (key, fix, value) VALUES (65, '2022-04-28 15:07:37.537481', 141);
INSERT INTO public.integer_actual (key, fix, value) VALUES (66, '2022-04-28 15:07:37.604481', 117);
INSERT INTO public.integer_actual (key, fix, value) VALUES (67, '2022-04-28 15:07:37.673481', 23);
INSERT INTO public.integer_actual (key, fix, value) VALUES (68, '2022-04-28 15:07:37.608481', 36);
INSERT INTO public.integer_actual (key, fix, value) VALUES (69, '2022-04-28 15:07:38.024481', 7);
INSERT INTO public.integer_actual (key, fix, value) VALUES (70, '2022-04-28 15:07:38.312481', 88);
INSERT INTO public.integer_actual (key, fix, value) VALUES (71, '2022-04-28 15:07:38.253481', 24);
INSERT INTO public.integer_actual (key, fix, value) VALUES (72, '2022-04-28 15:07:37.616481', 5);
INSERT INTO public.integer_actual (key, fix, value) VALUES (73, '2022-04-28 15:07:38.348481', 132);
INSERT INTO public.integer_actual (key, fix, value) VALUES (74, '2022-04-28 15:07:37.694481', 123);
INSERT INTO public.integer_actual (key, fix, value) VALUES (75, '2022-04-28 15:07:37.697481', 76);
INSERT INTO public.integer_actual (key, fix, value) VALUES (76, '2022-04-28 15:07:37.700481', 43);
INSERT INTO public.integer_actual (key, fix, value) VALUES (77, '2022-04-28 15:07:37.626481', 136);
INSERT INTO public.integer_actual (key, fix, value) VALUES (78, '2022-04-28 15:07:37.706481', 45);
INSERT INTO public.integer_actual (key, fix, value) VALUES (79, '2022-04-28 15:07:38.104481', 91);
INSERT INTO public.integer_actual (key, fix, value) VALUES (80, '2022-04-28 15:07:38.592481', 25);
INSERT INTO public.integer_actual (key, fix, value) VALUES (81, '2022-04-28 15:07:37.715481', 126);
INSERT INTO public.integer_actual (key, fix, value) VALUES (82, '2022-04-28 15:07:38.210481', 50);
INSERT INTO public.integer_actual (key, fix, value) VALUES (83, '2022-04-28 15:07:37.887481', 93);
INSERT INTO public.integer_actual (key, fix, value) VALUES (84, '2022-04-28 15:07:38.564481', 76);
INSERT INTO public.integer_actual (key, fix, value) VALUES (85, '2022-04-28 15:07:37.642481', 75);
INSERT INTO public.integer_actual (key, fix, value) VALUES (86, '2022-04-28 15:07:37.644481', 41);
INSERT INTO public.integer_actual (key, fix, value) VALUES (87, '2022-04-28 15:07:38.429481', 130);
INSERT INTO public.integer_actual (key, fix, value) VALUES (88, '2022-04-28 15:07:37.824481', 59);
INSERT INTO public.integer_actual (key, fix, value) VALUES (89, '2022-04-28 15:07:38.718481', 36);
INSERT INTO public.integer_actual (key, fix, value) VALUES (90, '2022-04-28 15:07:38.282481', 71);
INSERT INTO public.integer_actual (key, fix, value) VALUES (91, '2022-04-28 15:07:37.836481', 107);
INSERT INTO public.integer_actual (key, fix, value) VALUES (92, '2022-04-28 15:07:38.208481', 72);
INSERT INTO public.integer_actual (key, fix, value) VALUES (93, '2022-04-28 15:07:38.588481', 111);
INSERT INTO public.integer_actual (key, fix, value) VALUES (94, '2022-04-28 15:07:38.506481', 27);
INSERT INTO public.integer_actual (key, fix, value) VALUES (95, '2022-04-28 15:07:38.802481', 105);
INSERT INTO public.integer_actual (key, fix, value) VALUES (96, '2022-04-28 15:07:38.528481', 129);
INSERT INTO public.integer_actual (key, fix, value) VALUES (97, '2022-04-28 15:07:37.666481', 97);
INSERT INTO public.integer_actual (key, fix, value) VALUES (98, '2022-04-28 15:07:38.158481', 130);
INSERT INTO public.integer_actual (key, fix, value) VALUES (99, '2022-04-28 15:07:38.264481', 106);
INSERT INTO public.integer_actual (key, fix, value) VALUES (100, '2022-04-28 15:07:38.572481', 31);
INSERT INTO public.integer_actual (key, fix, value) VALUES (101, '2022-04-28 15:07:37.674481', 93);
INSERT INTO public.integer_actual (key, fix, value) VALUES (102, '2022-04-28 15:07:38.696481', 88);
INSERT INTO public.integer_actual (key, fix, value) VALUES (103, '2022-04-28 15:07:38.193481', 128);
INSERT INTO public.integer_actual (key, fix, value) VALUES (104, '2022-04-28 15:07:38.304481', 22);
INSERT INTO public.integer_actual (key, fix, value) VALUES (105, '2022-04-28 15:07:38.522481', 110);
INSERT INTO public.integer_actual (key, fix, value) VALUES (106, '2022-04-28 15:07:38.002481', 40);
INSERT INTO public.integer_actual (key, fix, value) VALUES (107, '2022-04-28 15:07:37.686481', 75);
INSERT INTO public.integer_actual (key, fix, value) VALUES (108, '2022-04-28 15:07:38.984481', 62);
INSERT INTO public.integer_actual (key, fix, value) VALUES (109, '2022-04-28 15:07:38.126481', 19);
INSERT INTO public.integer_actual (key, fix, value) VALUES (110, '2022-04-28 15:07:38.352481', 74);
INSERT INTO public.integer_actual (key, fix, value) VALUES (111, '2022-04-28 15:07:38.915481', 101);
INSERT INTO public.integer_actual (key, fix, value) VALUES (112, '2022-04-28 15:07:38.368481', 45);
INSERT INTO public.integer_actual (key, fix, value) VALUES (113, '2022-04-28 15:07:38.828481', 25);
INSERT INTO public.integer_actual (key, fix, value) VALUES (114, '2022-04-28 15:07:37.928481', 13);
INSERT INTO public.integer_actual (key, fix, value) VALUES (115, '2022-04-28 15:07:38.277481', 49);
INSERT INTO public.integer_actual (key, fix, value) VALUES (116, '2022-04-28 15:07:38.864481', 40);
INSERT INTO public.integer_actual (key, fix, value) VALUES (117, '2022-04-28 15:07:38.408481', 58);
INSERT INTO public.integer_actual (key, fix, value) VALUES (118, '2022-04-28 15:07:38.298481', 84);
INSERT INTO public.integer_actual (key, fix, value) VALUES (119, '2022-04-28 15:07:39.019481', 131);
INSERT INTO public.integer_actual (key, fix, value) VALUES (120, '2022-04-28 15:07:37.712481', 136);
INSERT INTO public.integer_actual (key, fix, value) VALUES (121, '2022-04-28 15:07:37.956481', 91);
INSERT INTO public.integer_actual (key, fix, value) VALUES (122, '2022-04-28 15:07:38.326481', 36);
INSERT INTO public.integer_actual (key, fix, value) VALUES (123, '2022-04-28 15:07:38.333481', 68);
INSERT INTO public.integer_actual (key, fix, value) VALUES (124, '2022-04-28 15:07:39.084481', 80);
INSERT INTO public.integer_actual (key, fix, value) VALUES (125, '2022-04-28 15:07:38.847481', 5);
INSERT INTO public.integer_actual (key, fix, value) VALUES (126, '2022-04-28 15:07:38.480481', 62);
INSERT INTO public.integer_actual (key, fix, value) VALUES (127, '2022-04-28 15:07:37.980481', 39);
INSERT INTO public.integer_actual (key, fix, value) VALUES (128, '2022-04-28 15:07:38.240481', 51);
INSERT INTO public.integer_actual (key, fix, value) VALUES (129, '2022-04-28 15:07:37.859481', 76);
INSERT INTO public.integer_actual (key, fix, value) VALUES (130, '2022-04-28 15:07:39.032481', 45);
INSERT INTO public.integer_actual (key, fix, value) VALUES (131, '2022-04-28 15:07:38.782481', 67);
INSERT INTO public.integer_actual (key, fix, value) VALUES (132, '2022-04-28 15:07:38.792481', 55);
INSERT INTO public.integer_actual (key, fix, value) VALUES (133, '2022-04-28 15:07:39.201481', 7);
INSERT INTO public.integer_actual (key, fix, value) VALUES (134, '2022-04-28 15:07:39.080481', 93);
INSERT INTO public.integer_actual (key, fix, value) VALUES (135, '2022-04-28 15:07:37.742481', 55);
INSERT INTO public.integer_actual (key, fix, value) VALUES (136, '2022-04-28 15:07:38.560481', 68);
INSERT INTO public.integer_actual (key, fix, value) VALUES (137, '2022-04-28 15:07:37.883481', 87);
INSERT INTO public.integer_actual (key, fix, value) VALUES (138, '2022-04-28 15:07:38.162481', 36);
INSERT INTO public.integer_actual (key, fix, value) VALUES (139, '2022-04-28 15:07:38.028481', 42);
INSERT INTO public.integer_actual (key, fix, value) VALUES (140, '2022-04-28 15:07:39.292481', 48);
INSERT INTO public.integer_actual (key, fix, value) VALUES (141, '2022-04-28 15:07:38.177481', 99);
INSERT INTO public.integer_actual (key, fix, value) VALUES (142, '2022-04-28 15:07:38.324481', 62);
INSERT INTO public.integer_actual (key, fix, value) VALUES (143, '2022-04-28 15:07:39.188481', 63);
INSERT INTO public.integer_actual (key, fix, value) VALUES (144, '2022-04-28 15:07:37.760481', 33);
INSERT INTO public.integer_actual (key, fix, value) VALUES (145, '2022-04-28 15:07:37.762481', 15);
INSERT INTO public.integer_actual (key, fix, value) VALUES (146, '2022-04-28 15:07:38.494481', 57);
INSERT INTO public.integer_actual (key, fix, value) VALUES (147, '2022-04-28 15:07:37.766481', 105);
INSERT INTO public.integer_actual (key, fix, value) VALUES (148, '2022-04-28 15:07:38.212481', 111);
INSERT INTO public.integer_actual (key, fix, value) VALUES (149, '2022-04-28 15:07:39.409481', 15);
INSERT INTO public.integer_actual (key, fix, value) VALUES (150, '2022-04-28 15:07:38.372481', 55);
INSERT INTO public.integer_actual (key, fix, value) VALUES (151, '2022-04-28 15:07:38.982481', 34);
INSERT INTO public.integer_actual (key, fix, value) VALUES (152, '2022-04-28 15:07:38.688481', 50);
INSERT INTO public.integer_actual (key, fix, value) VALUES (153, '2022-04-28 15:07:38.696481', 11);
INSERT INTO public.integer_actual (key, fix, value) VALUES (154, '2022-04-28 15:07:38.242481', 88);
INSERT INTO public.integer_actual (key, fix, value) VALUES (155, '2022-04-28 15:07:39.642481', 15);
INSERT INTO public.integer_actual (key, fix, value) VALUES (156, '2022-04-28 15:07:37.940481', 121);
INSERT INTO public.integer_actual (key, fix, value) VALUES (157, '2022-04-28 15:07:38.885481', 72);
INSERT INTO public.integer_actual (key, fix, value) VALUES (158, '2022-04-28 15:07:37.630481', 141);
INSERT INTO public.integer_actual (key, fix, value) VALUES (159, '2022-04-28 15:07:37.790481', 41);
INSERT INTO public.integer_actual (key, fix, value) VALUES (160, '2022-04-28 15:07:38.912481', 69);
INSERT INTO public.integer_actual (key, fix, value) VALUES (161, '2022-04-28 15:07:39.726481', 83);
INSERT INTO public.integer_actual (key, fix, value) VALUES (162, '2022-04-28 15:07:38.930481', 141);
INSERT INTO public.integer_actual (key, fix, value) VALUES (163, '2022-04-28 15:07:39.591481', 19);
INSERT INTO public.integer_actual (key, fix, value) VALUES (164, '2022-04-28 15:07:38.456481', 56);
INSERT INTO public.integer_actual (key, fix, value) VALUES (165, '2022-04-28 15:07:38.297481', 76);
INSERT INTO public.integer_actual (key, fix, value) VALUES (166, '2022-04-28 15:07:38.302481', 19);
INSERT INTO public.integer_actual (key, fix, value) VALUES (167, '2022-04-28 15:07:39.810481', 77);
INSERT INTO public.integer_actual (key, fix, value) VALUES (168, '2022-04-28 15:07:39.152481', 12);
INSERT INTO public.integer_actual (key, fix, value) VALUES (169, '2022-04-28 15:07:38.148481', 6);
INSERT INTO public.integer_actual (key, fix, value) VALUES (170, '2022-04-28 15:07:39.682481', 108);
INSERT INTO public.integer_actual (key, fix, value) VALUES (171, '2022-04-28 15:07:37.985481', 68);
INSERT INTO public.integer_actual (key, fix, value) VALUES (172, '2022-04-28 15:07:38.160481', 140);
INSERT INTO public.integer_actual (key, fix, value) VALUES (173, '2022-04-28 15:07:39.894481', 93);
INSERT INTO public.integer_actual (key, fix, value) VALUES (174, '2022-04-28 15:07:39.386481', 86);
INSERT INTO public.integer_actual (key, fix, value) VALUES (175, '2022-04-28 15:07:39.397481', 46);
INSERT INTO public.integer_actual (key, fix, value) VALUES (176, '2022-04-28 15:07:39.232481', 96);
INSERT INTO public.integer_actual (key, fix, value) VALUES (177, '2022-04-28 15:07:38.888481', 126);
INSERT INTO public.integer_actual (key, fix, value) VALUES (178, '2022-04-28 15:07:38.718481', 16);
INSERT INTO public.integer_actual (key, fix, value) VALUES (179, '2022-04-28 15:07:39.262481', 75);
INSERT INTO public.integer_actual (key, fix, value) VALUES (180, '2022-04-28 15:07:38.732481', 59);
INSERT INTO public.integer_actual (key, fix, value) VALUES (181, '2022-04-28 15:07:39.282481', 136);
INSERT INTO public.integer_actual (key, fix, value) VALUES (182, '2022-04-28 15:07:38.382481', 68);
INSERT INTO public.integer_actual (key, fix, value) VALUES (183, '2022-04-28 15:07:39.485481', 145);
INSERT INTO public.integer_actual (key, fix, value) VALUES (184, '2022-04-28 15:07:39.864481', 16);
INSERT INTO public.integer_actual (key, fix, value) VALUES (185, '2022-04-28 15:07:39.692481', 136);
INSERT INTO public.integer_actual (key, fix, value) VALUES (186, '2022-04-28 15:07:39.518481', 10);
INSERT INTO public.integer_actual (key, fix, value) VALUES (187, '2022-04-28 15:07:38.594481', 120);
INSERT INTO public.integer_actual (key, fix, value) VALUES (188, '2022-04-28 15:07:38.600481', 73);
INSERT INTO public.integer_actual (key, fix, value) VALUES (189, '2022-04-28 15:07:38.606481', 91);
INSERT INTO public.integer_actual (key, fix, value) VALUES (190, '2022-04-28 15:07:40.132481', 41);
INSERT INTO public.integer_actual (key, fix, value) VALUES (191, '2022-04-28 15:07:38.618481', 115);
INSERT INTO public.integer_actual (key, fix, value) VALUES (192, '2022-04-28 15:07:39.392481', 145);
INSERT INTO public.integer_actual (key, fix, value) VALUES (193, '2022-04-28 15:07:39.788481', 96);
INSERT INTO public.integer_actual (key, fix, value) VALUES (194, '2022-04-28 15:07:39.218481', 13);
INSERT INTO public.integer_actual (key, fix, value) VALUES (195, '2022-04-28 15:07:38.057481', 81);
INSERT INTO public.integer_actual (key, fix, value) VALUES (196, '2022-04-28 15:07:38.844481', 101);
INSERT INTO public.integer_actual (key, fix, value) VALUES (197, '2022-04-28 15:07:39.245481', 74);
INSERT INTO public.integer_actual (key, fix, value) VALUES (198, '2022-04-28 15:07:37.868481', 26);
INSERT INTO public.integer_actual (key, fix, value) VALUES (199, '2022-04-28 15:07:38.069481', 113);
INSERT INTO public.integer_actual (key, fix, value) VALUES (200, '2022-04-28 15:07:38.272481', 142);
INSERT INTO public.integer_actual (key, fix, value) VALUES (201, '2022-04-28 15:07:39.683481', 96);
INSERT INTO public.integer_actual (key, fix, value) VALUES (202, '2022-04-28 15:07:39.694481', 114);
INSERT INTO public.integer_actual (key, fix, value) VALUES (203, '2022-04-28 15:07:39.096481', 90);
INSERT INTO public.integer_actual (key, fix, value) VALUES (204, '2022-04-28 15:07:38.492481', 103);
INSERT INTO public.integer_actual (key, fix, value) VALUES (205, '2022-04-28 15:07:39.112481', 131);
INSERT INTO public.integer_actual (key, fix, value) VALUES (206, '2022-04-28 15:07:39.738481', 5);
INSERT INTO public.integer_actual (key, fix, value) VALUES (207, '2022-04-28 15:07:39.128481', 23);
INSERT INTO public.integer_actual (key, fix, value) VALUES (208, '2022-04-28 15:07:37.888481', 130);
INSERT INTO public.integer_actual (key, fix, value) VALUES (209, '2022-04-28 15:07:38.517481', 45);
INSERT INTO public.integer_actual (key, fix, value) VALUES (210, '2022-04-28 15:07:39.362481', 19);
INSERT INTO public.integer_actual (key, fix, value) VALUES (211, '2022-04-28 15:07:38.738481', 117);
INSERT INTO public.integer_actual (key, fix, value) VALUES (212, '2022-04-28 15:07:40.440481', 43);
INSERT INTO public.integer_actual (key, fix, value) VALUES (213, '2022-04-28 15:07:39.176481', 13);
INSERT INTO public.integer_actual (key, fix, value) VALUES (214, '2022-04-28 15:07:38.970481', 126);
INSERT INTO public.integer_actual (key, fix, value) VALUES (215, '2022-04-28 15:07:39.837481', 29);
INSERT INTO public.integer_actual (key, fix, value) VALUES (216, '2022-04-28 15:07:38.768481', 81);
INSERT INTO public.integer_actual (key, fix, value) VALUES (217, '2022-04-28 15:07:38.991481', 3);
INSERT INTO public.integer_actual (key, fix, value) VALUES (218, '2022-04-28 15:07:39.216481', 102);
INSERT INTO public.integer_actual (key, fix, value) VALUES (219, '2022-04-28 15:07:37.910481', 130);
INSERT INTO public.integer_actual (key, fix, value) VALUES (220, '2022-04-28 15:07:39.012481', 34);
INSERT INTO public.integer_actual (key, fix, value) VALUES (221, '2022-04-28 15:07:38.798481', 130);
INSERT INTO public.integer_actual (key, fix, value) VALUES (222, '2022-04-28 15:07:39.470481', 33);
INSERT INTO public.integer_actual (key, fix, value) VALUES (223, '2022-04-28 15:07:39.925481', 59);
INSERT INTO public.integer_actual (key, fix, value) VALUES (224, '2022-04-28 15:07:38.368481', 66);
INSERT INTO public.integer_actual (key, fix, value) VALUES (225, '2022-04-28 15:07:39.047481', 24);
INSERT INTO public.integer_actual (key, fix, value) VALUES (226, '2022-04-28 15:07:40.410481', 126);
INSERT INTO public.integer_actual (key, fix, value) VALUES (227, '2022-04-28 15:07:38.153481', 9);
INSERT INTO public.integer_actual (key, fix, value) VALUES (228, '2022-04-28 15:07:39.524481', 138);
INSERT INTO public.integer_actual (key, fix, value) VALUES (229, '2022-04-28 15:07:39.762481', 68);
INSERT INTO public.integer_actual (key, fix, value) VALUES (230, '2022-04-28 15:07:38.622481', 67);
INSERT INTO public.integer_actual (key, fix, value) VALUES (231, '2022-04-28 15:07:38.165481', 62);
INSERT INTO public.integer_actual (key, fix, value) VALUES (232, '2022-04-28 15:07:40.488481', 46);
INSERT INTO public.integer_actual (key, fix, value) VALUES (233, '2022-04-28 15:07:39.569481', 33);
INSERT INTO public.integer_actual (key, fix, value) VALUES (234, '2022-04-28 15:07:39.578481', 73);
INSERT INTO public.integer_actual (key, fix, value) VALUES (235, '2022-04-28 15:07:39.822481', 50);
INSERT INTO public.integer_actual (key, fix, value) VALUES (236, '2022-04-28 15:07:40.304481', 56);
INSERT INTO public.integer_actual (key, fix, value) VALUES (237, '2022-04-28 15:07:40.316481', 59);
INSERT INTO public.integer_actual (key, fix, value) VALUES (238, '2022-04-28 15:07:40.090481', 75);
INSERT INTO public.integer_actual (key, fix, value) VALUES (239, '2022-04-28 15:07:38.428481', 112);
INSERT INTO public.integer_actual (key, fix, value) VALUES (240, '2022-04-28 15:07:39.392481', 16);


--
-- TOC entry 2552 (class 0 OID 89615)
-- Dependencies: 238
-- Data for Name: integer_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2550 (class 0 OID 89593)
-- Dependencies: 236
-- Data for Name: order_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2551 (class 0 OID 89604)
-- Dependencies: 237
-- Data for Name: order_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2549 (class 0 OID 89587)
-- Dependencies: 235
-- Data for Name: synchronization; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2403 (class 2606 OID 89584)
-- Name: glossary glossary_communication_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_communication_key UNIQUE (communication);


--
-- TOC entry 2405 (class 2606 OID 89582)
-- Name: glossary glossary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);


--
-- TOC entry 2409 (class 1259 OID 89685)
-- Name: _hyper_1_2_chunk_integer_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (fix DESC);


--
-- TOC entry 2408 (class 1259 OID 89675)
-- Name: _hyper_2_1_chunk_float_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_1_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (fix DESC);


--
-- TOC entry 2407 (class 1259 OID 89642)
-- Name: float_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX float_archive_fix_idx ON public.float_archive USING btree (fix DESC);


--
-- TOC entry 2406 (class 1259 OID 89624)
-- Name: integer_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX integer_archive_fix_idx ON public.integer_archive USING btree (fix DESC);


--
-- TOC entry 2418 (class 2620 OID 89586)
-- Name: glossary existence_check_or_creation_table; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();


--
-- TOC entry 2420 (class 2620 OID 89641)
-- Name: float_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.float_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 2419 (class 2620 OID 89623)
-- Name: integer_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.integer_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 2416 (class 2606 OID 89670)
-- Name: _hyper_2_1_chunk 1_1_float_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk
    ADD CONSTRAINT "1_1_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2417 (class 2606 OID 89680)
-- Name: _hyper_1_2_chunk 2_2_integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2415 (class 2606 OID 89646)
-- Name: float_actual float_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_actual
    ADD CONSTRAINT float_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2414 (class 2606 OID 89636)
-- Name: float_archive float_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_archive
    ADD CONSTRAINT float_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2413 (class 2606 OID 89628)
-- Name: integer_actual integer_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_actual
    ADD CONSTRAINT integer_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2412 (class 2606 OID 89618)
-- Name: integer_archive integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_archive
    ADD CONSTRAINT integer_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2410 (class 2606 OID 89599)
-- Name: order_actual order_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_actual
    ADD CONSTRAINT order_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2411 (class 2606 OID 89610)
-- Name: order_archive order_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_archive
    ADD CONSTRAINT order_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


-- Completed on 2022-04-28 15:14:30

--
-- PostgreSQL database dump complete
--

