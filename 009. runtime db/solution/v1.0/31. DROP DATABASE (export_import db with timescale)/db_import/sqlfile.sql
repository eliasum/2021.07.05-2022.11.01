--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.24
-- Dumped by pg_dump version 9.6.24

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
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
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
-- Name: integer_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_archive OWNER TO postgres;

--
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.integer_archive);


ALTER TABLE _timescaledb_internal._hyper_1_2_chunk OWNER TO postgres;

--
-- Name: float_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_archive OWNER TO postgres;

--
-- Name: _hyper_2_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_2_1_chunk (
    CONSTRAINT constraint_1 CHECK (((fix >= '2022-04-28 00:00:00'::timestamp without time zone) AND (fix < '2022-04-29 00:00:00'::timestamp without time zone)))
)
INHERITS (public.float_archive);


ALTER TABLE _timescaledb_internal._hyper_2_1_chunk OWNER TO postgres;

--
-- Name: float_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_actual OWNER TO postgres;

--
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
-- Name: TABLE glossary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.glossary IS 'Словарь для индефикации переменных';


--
-- Name: COLUMN glossary.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';


--
-- Name: COLUMN glossary.communication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';


--
-- Name: COLUMN glossary.configuration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';


--
-- Name: COLUMN glossary.tablename; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';


--
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
-- Name: glossary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.glossary_key_seq OWNED BY public.glossary.key;


--
-- Name: integer_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_actual OWNER TO postgres;

--
-- Name: order_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_actual OWNER TO postgres;

--
-- Name: order_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_archive OWNER TO postgres;

--
-- Name: synchronization; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synchronization (
    xpath text NOT NULL,
    fix timestamp without time zone NOT NULL,
    status text NOT NULL
);


ALTER TABLE public.synchronization OWNER TO postgres;

--
-- Name: glossary key; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary ALTER COLUMN key SET DEFAULT nextval('public.glossary_key_seq'::regclass);


--
-- Data for Name: cache_inval_bgw_job; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_bgw_job  FROM stdin;
\.


--
-- Data for Name: cache_inval_extension; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_extension  FROM stdin;
\.


--
-- Data for Name: cache_inval_hypertable; Type: TABLE DATA; Schema: _timescaledb_cache; Owner: postgres
--

COPY _timescaledb_cache.cache_inval_hypertable  FROM stdin;
\.


--
-- Data for Name: hypertable; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compressed, compressed_hypertable_id) FROM stdin;
1	public	integer_archive	_timescaledb_internal	_hyper_1	1	_timescaledb_internal	calculate_chunk_interval	0	f	\N
2	public	float_archive	_timescaledb_internal	_hyper_2	1	_timescaledb_internal	calculate_chunk_interval	0	f	\N
\.


--
-- Data for Name: chunk; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped) FROM stdin;
1	2	_timescaledb_internal	_hyper_2_1_chunk	\N	f
2	1	_timescaledb_internal	_hyper_1_2_chunk	\N	f
\.


--
-- Data for Name: dimension; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, integer_now_func_schema, integer_now_func) FROM stdin;
1	1	fix	timestamp without time zone	t	\N	\N	\N	86400000000	\N	\N
2	2	fix	timestamp without time zone	t	\N	\N	\N	86400000000	\N	\N
\.


--
-- Data for Name: dimension_slice; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) FROM stdin;
1	2	1651104000000000	1651190400000000
2	1	1651104000000000	1651190400000000
\.


--
-- Data for Name: chunk_constraint; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) FROM stdin;
1	1	constraint_1	\N
1	\N	1_1_float_archive_key_fkey	float_archive_key_fkey
2	2	constraint_2	\N
2	\N	2_2_integer_archive_key_fkey	integer_archive_key_fkey
\.


--
-- Name: chunk_constraint_name; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 2, true);


--
-- Name: chunk_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 2, true);


--
-- Data for Name: chunk_index; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) FROM stdin;
1	_hyper_2_1_chunk_float_archive_fix_idx	2	float_archive_fix_idx
2	_hyper_1_2_chunk_integer_archive_fix_idx	1	integer_archive_fix_idx
\.


--
-- Data for Name: compression_chunk_size; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.compression_chunk_size (chunk_id, compressed_chunk_id, uncompressed_heap_size, uncompressed_toast_size, uncompressed_index_size, compressed_heap_size, compressed_toast_size, compressed_index_size) FROM stdin;
\.


--
-- Data for Name: bgw_job; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_job (id, application_name, job_type, schedule_interval, max_runtime, max_retries, retry_period) FROM stdin;
\.


--
-- Data for Name: continuous_agg; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_agg (mat_hypertable_id, raw_hypertable_id, user_view_schema, user_view_name, partial_view_schema, partial_view_name, bucket_width, job_id, refresh_lag, direct_view_schema, direct_view_name, max_interval_per_job, ignore_invalidation_older_than) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_completed_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_completed_threshold (materialization_id, watermark) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_hypertable_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_hypertable_invalidation_log (hypertable_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_invalidation_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_invalidation_threshold (hypertable_id, watermark) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_materialization_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_materialization_invalidation_log (materialization_id, modification_time, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Name: dimension_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 2, true);


--
-- Name: dimension_slice_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 2, true);


--
-- Data for Name: hypertable_compression; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.hypertable_compression (hypertable_id, attname, compression_algorithm_id, segmentby_column_index, orderby_column_index, orderby_asc, orderby_nullsfirst) FROM stdin;
\.


--
-- Name: hypertable_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 2, true);


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.metadata (key, value, include_in_telemetry) FROM stdin;
exported_uuid	00000000-0000-4000-afca-1f1eb2800200	t
\.


--
-- Data for Name: tablespace; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.tablespace (id, hypertable_id, tablespace_name) FROM stdin;
\.


--
-- Name: bgw_job_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_config; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1000, false);


--
-- Data for Name: bgw_policy_compress_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_compress_chunks (job_id, hypertable_id, older_than) FROM stdin;
\.


--
-- Data for Name: bgw_policy_drop_chunks; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_drop_chunks (job_id, hypertable_id, older_than, cascade, cascade_to_materializations) FROM stdin;
\.


--
-- Data for Name: bgw_policy_reorder; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_policy_reorder (job_id, hypertable_id, hypertable_index_name) FROM stdin;
\.


--
-- Data for Name: _hyper_1_2_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_2_chunk (key, fix, value) FROM stdin;
1	2022-04-28 16:14:42.717687	2
2	2022-04-28 16:14:42.716687	89
3	2022-04-28 16:14:42.719687	68
4	2022-04-28 16:14:42.728687	57
5	2022-04-28 16:14:42.739687	84
6	2022-04-28 16:14:42.716687	85
7	2022-04-28 16:14:42.767687	145
8	2022-04-28 16:14:42.720687	138
9	2022-04-28 16:14:42.830687	39
10	2022-04-28 16:14:42.804687	81
11	2022-04-28 16:14:42.836687	99
12	2022-04-28 16:14:42.848687	20
13	2022-04-28 16:14:42.769687	77
14	2022-04-28 16:14:42.718687	110
15	2022-04-28 16:14:42.779687	11
16	2022-04-28 16:14:42.880687	132
17	2022-04-28 16:14:42.942687	27
18	2022-04-28 16:14:42.848687	24
19	2022-04-28 16:14:42.723687	48
20	2022-04-28 16:14:42.744687	16
21	2022-04-28 16:14:42.956687	30
22	2022-04-28 16:14:42.748687	10
23	2022-04-28 16:14:42.819687	42
24	2022-04-28 16:14:42.968687	123
25	2022-04-28 16:14:42.854687	117
26	2022-04-28 16:14:42.912687	140
27	2022-04-28 16:14:42.785687	139
28	2022-04-28 16:14:42.844687	34
29	2022-04-28 16:14:42.820687	40
30	2022-04-28 16:14:42.854687	110
31	2022-04-28 16:14:42.921687	94
32	2022-04-28 16:14:42.768687	54
33	2022-04-28 16:14:43.100687	19
34	2022-04-28 16:14:43.044687	64
35	2022-04-28 16:14:42.949687	132
36	2022-04-28 16:14:43.172687	92
37	2022-04-28 16:14:42.852687	79
38	2022-04-28 16:14:43.122687	91
39	2022-04-28 16:14:43.055687	110
40	2022-04-28 16:14:43.184687	4
41	2022-04-28 16:14:43.155687	26
42	2022-04-28 16:14:42.998687	72
43	2022-04-28 16:14:43.048687	111
44	2022-04-28 16:14:43.232687	144
45	2022-04-28 16:14:43.289687	48
46	2022-04-28 16:14:43.348687	109
47	2022-04-28 16:14:42.751687	40
48	2022-04-28 16:14:43.184687	28
49	2022-04-28 16:14:42.851687	101
50	2022-04-28 16:14:42.904687	27
51	2022-04-28 16:14:43.214687	48
52	2022-04-28 16:14:43.016687	63
53	2022-04-28 16:14:43.393687	134
54	2022-04-28 16:14:43.298687	84
55	2022-04-28 16:14:42.924687	96
56	2022-04-28 16:14:43.208687	63
57	2022-04-28 16:14:43.103687	43
58	2022-04-28 16:14:43.516687	40
59	2022-04-28 16:14:42.940687	88
60	2022-04-28 16:14:43.424687	15
61	2022-04-28 16:14:43.070687	94
62	2022-04-28 16:14:43.200687	19
63	2022-04-28 16:14:43.586687	28
64	2022-04-28 16:14:43.280687	141
65	2022-04-28 16:14:43.549687	80
66	2022-04-28 16:14:43.232687	134
67	2022-04-28 16:14:43.240687	94
68	2022-04-28 16:14:43.112687	65
69	2022-04-28 16:14:43.463687	144
70	2022-04-28 16:14:43.334687	87
71	2022-04-28 16:14:42.846687	32
72	2022-04-28 16:14:43.496687	35
73	2022-04-28 16:14:43.507687	79
74	2022-04-28 16:14:43.074687	106
75	2022-04-28 16:14:43.079687	57
76	2022-04-28 16:14:43.768687	75
77	2022-04-28 16:14:43.628687	18
78	2022-04-28 16:14:43.640687	2
79	2022-04-28 16:14:43.573687	41
80	2022-04-28 16:14:43.344687	101
81	2022-04-28 16:14:43.109687	110
82	2022-04-28 16:14:43.524687	100
83	2022-04-28 16:14:42.953687	100
84	2022-04-28 16:14:43.796687	117
85	2022-04-28 16:14:43.809687	81
86	2022-04-28 16:14:43.392687	34
87	2022-04-28 16:14:43.922687	38
88	2022-04-28 16:14:42.880687	20
89	2022-04-28 16:14:43.861687	45
90	2022-04-28 16:14:43.334687	58
91	2022-04-28 16:14:43.887687	130
92	2022-04-28 16:14:43.624687	72
93	2022-04-28 16:14:43.541687	2
94	2022-04-28 16:14:42.892687	64
95	2022-04-28 16:14:43.844687	54
96	2022-04-28 16:14:43.664687	73
97	2022-04-28 16:14:43.480687	134
98	2022-04-28 16:14:43.194687	42
99	2022-04-28 16:14:43.496687	12
100	2022-04-28 16:14:42.904687	5
101	2022-04-28 16:14:43.714687	72
102	2022-04-28 16:14:43.928687	106
103	2022-04-28 16:14:44.043687	107
104	2022-04-28 16:14:43.536687	86
105	2022-04-28 16:14:42.914687	104
106	2022-04-28 16:14:43.022687	70
107	2022-04-28 16:14:44.095687	15
108	2022-04-28 16:14:44.000687	61
109	2022-04-28 16:14:42.922687	30
110	2022-04-28 16:14:43.034687	21
111	2022-04-28 16:14:43.703687	65
112	2022-04-28 16:14:42.816687	81
113	2022-04-28 16:14:44.173687	145
114	2022-04-28 16:14:43.958687	10
115	2022-04-28 16:14:44.314687	113
116	2022-04-28 16:14:43.748687	119
117	2022-04-28 16:14:43.172687	56
118	2022-04-28 16:14:44.002687	58
119	2022-04-28 16:14:42.942687	141
120	2022-04-28 16:14:43.784687	124
121	2022-04-28 16:14:43.672687	71
122	2022-04-28 16:14:43.436687	14
123	2022-04-28 16:14:43.196687	28
124	2022-04-28 16:14:43.820687	59
125	2022-04-28 16:14:43.079687	128
126	2022-04-28 16:14:43.208687	47
127	2022-04-28 16:14:44.482687	139
128	2022-04-28 16:14:43.600687	33
129	2022-04-28 16:14:43.736687	38
130	2022-04-28 16:14:44.264687	131
131	2022-04-28 16:14:42.835687	68
132	2022-04-28 16:14:43.892687	42
133	2022-04-28 16:14:43.103687	45
134	2022-04-28 16:14:43.374687	72
135	2022-04-28 16:14:43.514687	61
136	2022-04-28 16:14:43.520687	14
137	2022-04-28 16:14:43.937687	38
138	2022-04-28 16:14:44.084687	19
139	2022-04-28 16:14:42.982687	133
140	2022-04-28 16:14:43.404687	103
141	2022-04-28 16:14:43.550687	49
142	2022-04-28 16:14:44.692687	13
143	2022-04-28 16:14:43.848687	44
144	2022-04-28 16:14:44.432687	39
145	2022-04-28 16:14:44.734687	76
146	2022-04-28 16:14:44.602687	121
147	2022-04-28 16:14:43.145687	102
148	2022-04-28 16:14:44.480687	4
149	2022-04-28 16:14:44.492687	16
150	2022-04-28 16:14:44.804687	137
151	2022-04-28 16:14:44.667687	20
152	2022-04-28 16:14:43.008687	103
153	2022-04-28 16:14:43.928687	20
154	2022-04-28 16:14:44.398687	105
155	2022-04-28 16:14:43.479687	44
156	2022-04-28 16:14:43.172687	83
157	2022-04-28 16:14:44.902687	19
158	2022-04-28 16:14:43.968687	98
159	2022-04-28 16:14:43.976687	80
160	2022-04-28 16:14:44.464687	117
161	2022-04-28 16:14:43.831687	1
162	2022-04-28 16:14:44.000687	123
163	2022-04-28 16:14:44.008687	73
164	2022-04-28 16:14:45.000687	132
165	2022-04-28 16:14:43.859687	94
166	2022-04-28 16:14:43.534687	140
167	2022-04-28 16:14:44.875687	54
168	2022-04-28 16:14:44.720687	35
169	2022-04-28 16:14:43.549687	36
170	2022-04-28 16:14:44.064687	62
171	2022-04-28 16:14:44.243687	19
172	2022-04-28 16:14:45.112687	97
173	2022-04-28 16:14:43.742687	50
174	2022-04-28 16:14:44.966687	3
175	2022-04-28 16:14:43.229687	27
176	2022-04-28 16:14:44.112687	45
177	2022-04-28 16:14:43.766687	28
178	2022-04-28 16:14:44.128687	134
179	2022-04-28 16:14:44.315687	30
180	2022-04-28 16:14:43.424687	9
181	2022-04-28 16:14:43.428687	118
182	2022-04-28 16:14:43.614687	96
183	2022-04-28 16:14:43.070687	30
184	2022-04-28 16:14:44.544687	85
185	2022-04-28 16:14:43.814687	43
186	2022-04-28 16:14:43.820687	42
187	2022-04-28 16:14:42.891687	45
188	2022-04-28 16:14:43.456687	50
189	2022-04-28 16:14:43.082687	127
190	2022-04-28 16:14:44.224687	26
191	2022-04-28 16:14:44.423687	137
192	2022-04-28 16:14:44.816687	34
193	2022-04-28 16:14:43.283687	140
194	2022-04-28 16:14:44.450687	108
195	2022-04-28 16:14:45.239687	125
196	2022-04-28 16:14:44.664687	15
197	2022-04-28 16:14:43.098687	70
198	2022-04-28 16:14:43.496687	113
199	2022-04-28 16:14:45.092687	45
200	2022-04-28 16:14:44.704687	25
201	2022-04-28 16:14:44.714687	44
202	2022-04-28 16:14:44.724687	128
203	2022-04-28 16:14:45.140687	32
204	2022-04-28 16:14:43.724687	12
205	2022-04-28 16:14:45.574687	22
206	2022-04-28 16:14:45.382687	106
207	2022-04-28 16:14:44.981687	5
208	2022-04-28 16:14:44.160687	36
209	2022-04-28 16:14:43.122687	14
210	2022-04-28 16:14:44.384687	10
211	2022-04-28 16:14:44.603687	132
212	2022-04-28 16:14:44.824687	70
213	2022-04-28 16:14:44.834687	42
214	2022-04-28 16:14:43.560687	80
215	2022-04-28 16:14:43.134687	65
216	2022-04-28 16:14:44.432687	107
217	2022-04-28 16:14:43.572687	47
218	2022-04-28 16:14:44.230687	47
219	2022-04-28 16:14:43.799687	124
220	2022-04-28 16:14:44.244687	135
221	2022-04-28 16:14:44.914687	75
222	2022-04-28 16:14:45.146687	108
223	2022-04-28 16:14:45.826687	133
224	2022-04-28 16:14:44.048687	4
225	2022-04-28 16:14:43.154687	2
226	2022-04-28 16:14:44.964687	105
227	2022-04-28 16:14:45.428687	85
228	2022-04-28 16:14:44.528687	115
229	2022-04-28 16:14:44.765687	30
230	2022-04-28 16:14:43.624687	76
231	2022-04-28 16:14:45.938687	108
232	2022-04-28 16:14:42.936687	77
233	2022-04-28 16:14:44.801687	24
234	2022-04-28 16:14:44.576687	58
235	2022-04-28 16:14:44.584687	19
236	2022-04-28 16:14:46.008687	33
237	2022-04-28 16:14:45.074687	85
238	2022-04-28 16:14:44.132687	16
239	2022-04-28 16:14:43.421687	140
240	2022-04-28 16:14:44.624687	108
1	2022-04-28 16:14:42.717687	32
2	2022-04-28 16:14:42.720687	9
3	2022-04-28 16:14:42.737687	117
4	2022-04-28 16:14:42.756687	95
5	2022-04-28 16:14:42.759687	101
6	2022-04-28 16:14:42.770687	11
7	2022-04-28 16:14:42.767687	131
8	2022-04-28 16:14:42.816687	137
9	2022-04-28 16:14:42.776687	37
10	2022-04-28 16:14:42.734687	119
11	2022-04-28 16:14:42.781687	143
12	2022-04-28 16:14:42.788687	133
13	2022-04-28 16:14:42.730687	71
14	2022-04-28 16:14:42.732687	33
15	2022-04-28 16:14:42.764687	66
16	2022-04-28 16:14:42.864687	93
17	2022-04-28 16:14:42.874687	72
18	2022-04-28 16:14:42.866687	112
19	2022-04-28 16:14:42.780687	139
20	2022-04-28 16:14:42.944687	119
21	2022-04-28 16:14:42.788687	124
22	2022-04-28 16:14:42.902687	125
23	2022-04-28 16:14:42.865687	132
24	2022-04-28 16:14:42.920687	112
25	2022-04-28 16:14:42.929687	65
26	2022-04-28 16:14:42.938687	129
27	2022-04-28 16:14:43.028687	100
28	2022-04-28 16:14:42.844687	133
29	2022-04-28 16:14:43.023687	86
30	2022-04-28 16:14:42.764687	38
31	2022-04-28 16:14:43.045687	104
32	2022-04-28 16:14:42.928687	47
33	2022-04-28 16:14:42.770687	13
34	2022-04-28 16:14:42.908687	21
35	2022-04-28 16:14:42.879687	27
36	2022-04-28 16:14:43.064687	80
37	2022-04-28 16:14:42.963687	44
38	2022-04-28 16:14:43.046687	82
39	2022-04-28 16:14:42.938687	91
40	2022-04-28 16:14:43.024687	18
41	2022-04-28 16:14:43.237687	43
42	2022-04-28 16:14:43.082687	111
43	2022-04-28 16:14:43.220687	112
44	2022-04-28 16:14:43.232687	3
45	2022-04-28 16:14:42.839687	103
46	2022-04-28 16:14:42.796687	94
47	2022-04-28 16:14:43.315687	78
48	2022-04-28 16:14:42.800687	74
49	2022-04-28 16:14:43.047687	46
50	2022-04-28 16:14:43.304687	47
51	2022-04-28 16:14:43.112687	67
52	2022-04-28 16:14:43.120687	66
53	2022-04-28 16:14:43.287687	9
54	2022-04-28 16:14:43.082687	80
55	2022-04-28 16:14:42.814687	111
56	2022-04-28 16:14:43.208687	18
57	2022-04-28 16:14:42.818687	132
58	2022-04-28 16:14:43.052687	66
59	2022-04-28 16:14:42.881687	100
60	2022-04-28 16:14:43.124687	40
61	2022-04-28 16:14:43.009687	53
62	2022-04-28 16:14:43.572687	84
63	2022-04-28 16:14:42.893687	11
64	2022-04-28 16:14:43.280687	134
65	2022-04-28 16:14:42.964687	14
66	2022-04-28 16:14:42.902687	8
67	2022-04-28 16:14:43.508687	29
68	2022-04-28 16:14:43.316687	64
69	2022-04-28 16:14:43.532687	21
70	2022-04-28 16:14:42.844687	117
71	2022-04-28 16:14:43.130687	36
72	2022-04-28 16:14:43.640687	60
73	2022-04-28 16:14:42.923687	134
74	2022-04-28 16:14:43.370687	4
75	2022-04-28 16:14:43.004687	91
76	2022-04-28 16:14:43.160687	106
77	2022-04-28 16:14:43.628687	81
78	2022-04-28 16:14:42.782687	27
79	2022-04-28 16:14:43.336687	132
80	2022-04-28 16:14:43.104687	97
81	2022-04-28 16:14:43.271687	75
82	2022-04-28 16:14:43.196687	145
83	2022-04-28 16:14:43.451687	75
84	2022-04-28 16:14:43.124687	129
85	2022-04-28 16:14:43.214687	134
86	2022-04-28 16:14:43.564687	144
87	2022-04-28 16:14:43.574687	97
88	2022-04-28 16:14:43.848687	10
89	2022-04-28 16:14:43.327687	83
90	2022-04-28 16:14:43.334687	34
91	2022-04-28 16:14:43.432687	88
92	2022-04-28 16:14:43.716687	87
93	2022-04-28 16:14:43.727687	64
94	2022-04-28 16:14:43.080687	36
95	2022-04-28 16:14:42.989687	59
96	2022-04-28 16:14:44.048687	131
97	2022-04-28 16:14:43.868687	54
98	2022-04-28 16:14:43.292687	120
99	2022-04-28 16:14:43.991687	135
100	2022-04-28 16:14:43.904687	92
101	2022-04-28 16:14:43.613687	99
102	2022-04-28 16:14:43.724687	38
103	2022-04-28 16:14:44.146687	57
104	2022-04-28 16:14:42.912687	27
105	2022-04-28 16:14:43.649687	140
106	2022-04-28 16:14:43.870687	134
107	2022-04-28 16:14:43.453687	13
108	2022-04-28 16:14:43.028687	121
109	2022-04-28 16:14:43.903687	106
110	2022-04-28 16:14:43.254687	26
111	2022-04-28 16:14:43.259687	12
112	2022-04-28 16:14:43.936687	135
113	2022-04-28 16:14:44.286687	109
114	2022-04-28 16:14:43.046687	43
115	2022-04-28 16:14:43.279687	16
116	2022-04-28 16:14:43.052687	75
117	2022-04-28 16:14:43.991687	117
118	2022-04-28 16:14:43.766687	120
119	2022-04-28 16:14:44.251687	72
120	2022-04-28 16:14:43.784687	49
121	2022-04-28 16:14:43.430687	5
122	2022-04-28 16:14:43.802687	32
123	2022-04-28 16:14:43.934687	5
124	2022-04-28 16:14:43.572687	109
125	2022-04-28 16:14:43.204687	79
126	2022-04-28 16:14:42.956687	27
127	2022-04-28 16:14:43.974687	92
128	2022-04-28 16:14:43.344687	78
129	2022-04-28 16:14:44.510687	111
130	2022-04-28 16:14:43.354687	35
131	2022-04-28 16:14:43.228687	114
132	2022-04-28 16:14:44.420687	77
133	2022-04-28 16:14:44.300687	33
134	2022-04-28 16:14:43.106687	98
135	2022-04-28 16:14:43.649687	50
136	2022-04-28 16:14:44.472687	40
137	2022-04-28 16:14:43.115687	138
138	2022-04-28 16:14:44.360687	42
139	2022-04-28 16:14:43.677687	73
140	2022-04-28 16:14:43.404687	138
141	2022-04-28 16:14:43.409687	62
142	2022-04-28 16:14:42.988687	111
143	2022-04-28 16:14:42.990687	141
144	2022-04-28 16:14:44.576687	20
145	2022-04-28 16:14:43.864687	14
146	2022-04-28 16:14:44.456687	23
147	2022-04-28 16:14:43.292687	57
148	2022-04-28 16:14:43.148687	84
149	2022-04-28 16:14:43.151687	15
150	2022-04-28 16:14:43.604687	65
151	2022-04-28 16:14:44.667687	111
152	2022-04-28 16:14:43.464687	126
153	2022-04-28 16:14:44.081687	115
154	2022-04-28 16:14:43.012687	101
155	2022-04-28 16:14:44.564687	6
156	2022-04-28 16:14:43.016687	68
157	2022-04-28 16:14:43.960687	48
158	2022-04-28 16:14:44.758687	116
159	2022-04-28 16:14:44.294687	18
160	2022-04-28 16:14:43.984687	123
161	2022-04-28 16:14:43.670687	5
162	2022-04-28 16:14:43.352687	55
163	2022-04-28 16:14:44.008687	111
164	2022-04-28 16:14:43.032687	105
165	2022-04-28 16:14:44.684687	35
166	2022-04-28 16:14:43.202687	53
167	2022-04-28 16:14:43.205687	119
168	2022-04-28 16:14:43.040687	81
169	2022-04-28 16:14:43.211687	34
170	2022-04-28 16:14:43.214687	37
171	2022-04-28 16:14:44.927687	26
172	2022-04-28 16:14:43.564687	66
173	2022-04-28 16:14:42.877687	58
174	2022-04-28 16:14:44.444687	129
175	2022-04-28 16:14:43.929687	46
176	2022-04-28 16:14:44.992687	5
177	2022-04-28 16:14:44.297687	81
178	2022-04-28 16:14:43.060687	123
179	2022-04-28 16:14:44.315687	132
180	2022-04-28 16:14:43.784687	125
181	2022-04-28 16:14:44.695687	52
182	2022-04-28 16:14:44.888687	86
183	2022-04-28 16:14:45.083687	105
184	2022-04-28 16:14:43.808687	99
185	2022-04-28 16:14:43.444687	53
186	2022-04-28 16:14:44.564687	69
187	2022-04-28 16:14:45.322687	36
188	2022-04-28 16:14:45.336687	27
189	2022-04-28 16:14:44.783687	107
190	2022-04-28 16:14:43.844687	14
191	2022-04-28 16:14:43.277687	25
192	2022-04-28 16:14:43.664687	77
193	2022-04-28 16:14:43.862687	17
194	2022-04-28 16:14:44.838687	81
195	2022-04-28 16:14:44.849687	36
196	2022-04-28 16:14:45.448687	34
197	2022-04-28 16:14:45.068687	41
198	2022-04-28 16:14:44.288687	80
199	2022-04-28 16:14:43.699687	105
200	2022-04-28 16:14:44.304687	43
201	2022-04-28 16:14:43.106687	142
202	2022-04-28 16:14:44.724687	17
203	2022-04-28 16:14:44.734687	60
204	2022-04-28 16:14:43.112687	54
205	2022-04-28 16:14:44.549687	132
206	2022-04-28 16:14:43.322687	122
207	2022-04-28 16:14:44.360687	44
208	2022-04-28 16:14:44.992687	84
209	2022-04-28 16:14:43.122687	48
210	2022-04-28 16:14:43.544687	114
211	2022-04-28 16:14:45.658687	118
212	2022-04-28 16:14:45.672687	2
213	2022-04-28 16:14:43.982687	64
214	2022-04-28 16:14:44.630687	102
215	2022-04-28 16:14:45.069687	59
216	2022-04-28 16:14:45.512687	144
217	2022-04-28 16:14:43.572687	12
218	2022-04-28 16:14:43.140687	20
219	2022-04-28 16:14:44.456687	22
220	2022-04-28 16:14:45.564687	138
221	2022-04-28 16:14:43.146687	57
222	2022-04-28 16:14:45.812687	119
223	2022-04-28 16:14:43.373687	22
224	2022-04-28 16:14:44.944687	80
225	2022-04-28 16:14:44.504687	136
226	2022-04-28 16:14:44.286687	144
227	2022-04-28 16:14:44.520687	112
228	2022-04-28 16:14:43.844687	32
229	2022-04-28 16:14:42.933687	93
230	2022-04-28 16:14:45.234687	33
231	2022-04-28 16:14:45.245687	52
232	2022-04-28 16:14:45.024687	30
233	2022-04-28 16:14:43.170687	21
234	2022-04-28 16:14:45.044687	69
235	2022-04-28 16:14:43.644687	91
236	2022-04-28 16:14:43.176687	139
237	2022-04-28 16:14:44.363687	42
238	2022-04-28 16:14:45.322687	85
239	2022-04-28 16:14:45.811687	21
240	2022-04-28 16:14:45.824687	35
\.


--
-- Data for Name: _hyper_2_1_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_2_1_chunk (key, fix, value) FROM stdin;
1	2022-04-28 16:14:42.714687	139.88
2	2022-04-28 16:14:42.732687	142.31
3	2022-04-28 16:14:42.728687	104.63
4	2022-04-28 16:14:42.728687	7.8300000000000001
5	2022-04-28 16:14:42.754687	119.87
6	2022-04-28 16:14:42.782687	102.36
7	2022-04-28 16:14:42.781687	84.769999999999996
8	2022-04-28 16:14:42.768687	144.11000000000001
9	2022-04-28 16:14:42.812687	135.69999999999999
10	2022-04-28 16:14:42.814687	96.519999999999996
11	2022-04-28 16:14:42.759687	113.78
12	2022-04-28 16:14:42.800687	143.59
13	2022-04-28 16:14:42.782687	20.870000000000001
14	2022-04-28 16:14:42.774687	144.37
15	2022-04-28 16:14:42.854687	114.51000000000001
16	2022-04-28 16:14:42.768687	8.6999999999999993
17	2022-04-28 16:14:42.789687	5.6500000000000004
18	2022-04-28 16:14:42.830687	34.619999999999997
19	2022-04-28 16:14:42.837687	1.9099999999999999
20	2022-04-28 16:14:42.884687	7.1600000000000001
21	2022-04-28 16:14:42.893687	67.230000000000004
22	2022-04-28 16:14:42.792687	133.63999999999999
23	2022-04-28 16:14:42.727687	64.310000000000002
24	2022-04-28 16:14:42.800687	38.32
25	2022-04-28 16:14:43.004687	33.450000000000003
26	2022-04-28 16:14:42.834687	30.870000000000001
27	2022-04-28 16:14:43.082687	105.81999999999999
28	2022-04-28 16:14:42.788687	132.36000000000001
29	2022-04-28 16:14:42.907687	139.74000000000001
30	2022-04-28 16:14:43.004687	55.920000000000002
31	2022-04-28 16:14:42.921687	55.259999999999998
32	2022-04-28 16:14:42.896687	125.26000000000001
33	2022-04-28 16:14:43.001687	119.62
34	2022-04-28 16:14:42.942687	108.52
35	2022-04-28 16:14:42.809687	37.630000000000003
36	2022-04-28 16:14:43.028687	118.42
37	2022-04-28 16:14:42.926687	99.019999999999996
38	2022-04-28 16:14:42.780687	121.51000000000001
39	2022-04-28 16:14:43.016687	85.200000000000003
40	2022-04-28 16:14:43.264687	130.56999999999999
41	2022-04-28 16:14:43.237687	144.63
42	2022-04-28 16:14:42.872687	61.700000000000003
43	2022-04-28 16:14:43.048687	7.1699999999999999
44	2022-04-28 16:14:42.792687	78.840000000000003
45	2022-04-28 16:14:43.289687	72.659999999999997
46	2022-04-28 16:14:43.210687	66.299999999999997
47	2022-04-28 16:14:42.986687	27.16
48	2022-04-28 16:14:43.136687	28.789999999999999
49	2022-04-28 16:14:42.802687	55.32
50	2022-04-28 16:14:43.004687	29.710000000000001
51	2022-04-28 16:14:42.755687	71.090000000000003
52	2022-04-28 16:14:42.808687	78.010000000000005
53	2022-04-28 16:14:43.234687	68.519999999999996
54	2022-04-28 16:14:43.352687	45.619999999999997
55	2022-04-28 16:14:43.199687	48.649999999999999
56	2022-04-28 16:14:43.040687	127.75
57	2022-04-28 16:14:43.502687	108.76000000000001
58	2022-04-28 16:14:43.110687	68.950000000000003
59	2022-04-28 16:14:42.881687	142.86000000000001
60	2022-04-28 16:14:43.064687	78.299999999999997
61	2022-04-28 16:14:43.375687	130.77000000000001
62	2022-04-28 16:14:43.510687	98.989999999999995
63	2022-04-28 16:14:43.208687	19.539999999999999
64	2022-04-28 16:14:43.152687	29.109999999999999
65	2022-04-28 16:14:42.899687	131.44999999999999
66	2022-04-28 16:14:43.430687	25.649999999999999
67	2022-04-28 16:14:42.972687	112.33
68	2022-04-28 16:14:43.588687	62.079999999999998
69	2022-04-28 16:14:43.601687	98.489999999999995
70	2022-04-28 16:14:43.474687	6.8099999999999996
71	2022-04-28 16:14:42.988687	110.33
72	2022-04-28 16:14:43.640687	78.739999999999995
73	2022-04-28 16:14:42.923687	129.96000000000001
74	2022-04-28 16:14:43.222687	89.849999999999994
75	2022-04-28 16:14:43.529687	16.539999999999999
76	2022-04-28 16:14:42.856687	11.699999999999999
77	2022-04-28 16:14:42.781687	117.64
78	2022-04-28 16:14:43.250687	15.84
79	2022-04-28 16:14:43.415687	59.579999999999998
80	2022-04-28 16:14:42.864687	75.840000000000003
81	2022-04-28 16:14:42.785687	93.260000000000005
82	2022-04-28 16:14:43.032687	106.03
83	2022-04-28 16:14:43.368687	29.379999999999999
84	2022-04-28 16:14:43.544687	33.140000000000001
85	2022-04-28 16:14:43.724687	8.4499999999999993
86	2022-04-28 16:14:43.478687	72.170000000000002
87	2022-04-28 16:14:43.052687	46.759999999999998
88	2022-04-28 16:14:43.144687	145.22999999999999
89	2022-04-28 16:14:43.950687	50.159999999999997
90	2022-04-28 16:14:43.424687	85.989999999999995
91	2022-04-28 16:14:43.614687	121.86
92	2022-04-28 16:14:43.440687	144.77000000000001
93	2022-04-28 16:14:43.913687	103.02
94	2022-04-28 16:14:42.986687	63.520000000000003
95	2022-04-28 16:14:43.274687	115.89
96	2022-04-28 16:14:43.856687	74.25
97	2022-04-28 16:14:43.577687	38.259999999999998
98	2022-04-28 16:14:42.900687	83.430000000000007
99	2022-04-28 16:14:43.496687	27.23
100	2022-04-28 16:14:44.104687	136.00999999999999
101	2022-04-28 16:14:43.209687	35.460000000000001
102	2022-04-28 16:14:43.826687	95.950000000000003
103	2022-04-28 16:14:43.528687	77.849999999999994
104	2022-04-28 16:14:44.056687	102.76000000000001
105	2022-04-28 16:14:43.544687	64.939999999999998
106	2022-04-28 16:14:43.022687	39.799999999999997
107	2022-04-28 16:14:43.988687	67.969999999999999
108	2022-04-28 16:14:44.000687	26.850000000000001
109	2022-04-28 16:14:43.031687	31.440000000000001
110	2022-04-28 16:14:44.024687	122.81
111	2022-04-28 16:14:42.926687	30.850000000000001
112	2022-04-28 16:14:44.160687	8.9100000000000001
113	2022-04-28 16:14:43.156687	8.6400000000000006
114	2022-04-28 16:14:44.186687	138.28
115	2022-04-28 16:14:43.279687	110.06999999999999
116	2022-04-28 16:14:43.516687	118.04000000000001
117	2022-04-28 16:14:43.406687	89.480000000000004
118	2022-04-28 16:14:43.412687	63.25
119	2022-04-28 16:14:42.942687	120.66
120	2022-04-28 16:14:43.544687	51.350000000000001
121	2022-04-28 16:14:44.156687	65.269999999999996
122	2022-04-28 16:14:44.412687	129.12
123	2022-04-28 16:14:43.934687	80.090000000000003
124	2022-04-28 16:14:43.944687	24.329999999999998
125	2022-04-28 16:14:43.579687	123.15000000000001
126	2022-04-28 16:14:43.586687	50.450000000000003
127	2022-04-28 16:14:43.466687	22
128	2022-04-28 16:14:44.368687	8.3900000000000006
129	2022-04-28 16:14:43.478687	103.90000000000001
130	2022-04-28 16:14:43.614687	72.780000000000001
131	2022-04-28 16:14:44.014687	132.90000000000001
132	2022-04-28 16:14:43.628687	105.95999999999999
133	2022-04-28 16:14:44.566687	44.420000000000002
134	2022-04-28 16:14:44.446687	36.5
135	2022-04-28 16:14:43.109687	61.649999999999999
136	2022-04-28 16:14:43.112687	47.890000000000001
137	2022-04-28 16:14:44.211687	73.260000000000005
138	2022-04-28 16:14:42.842687	87.980000000000004
139	2022-04-28 16:14:43.399687	1.8700000000000001
140	2022-04-28 16:14:43.544687	100.37
141	2022-04-28 16:14:43.550687	103.31
142	2022-04-28 16:14:43.840687	65.510000000000005
143	2022-04-28 16:14:43.562687	16.539999999999999
144	2022-04-28 16:14:43.712687	31.120000000000001
145	2022-04-28 16:14:44.299687	42.020000000000003
146	2022-04-28 16:14:42.996687	52.920000000000002
147	2022-04-28 16:14:43.733687	138.34
148	2022-04-28 16:14:44.184687	134.96000000000001
149	2022-04-28 16:14:43.002687	33.43
150	2022-04-28 16:14:44.654687	56.770000000000003
151	2022-04-28 16:14:44.214687	59.530000000000001
152	2022-04-28 16:14:43.008687	143.59999999999999
153	2022-04-28 16:14:44.387687	14.77
154	2022-04-28 16:14:44.090687	121.28
155	2022-04-28 16:14:43.169687	42.560000000000002
156	2022-04-28 16:14:44.576687	50.390000000000001
157	2022-04-28 16:14:43.646687	107.02
158	2022-04-28 16:14:43.020687	138.80000000000001
159	2022-04-28 16:14:43.658687	140.47999999999999
160	2022-04-28 16:14:43.664687	129.18000000000001
161	2022-04-28 16:14:44.636687	103.33
162	2022-04-28 16:14:44.000687	123.31
163	2022-04-28 16:14:43.682687	109.01000000000001
164	2022-04-28 16:14:44.836687	118.02
165	2022-04-28 16:14:44.684687	11.869999999999999
166	2022-04-28 16:14:44.198687	5.7999999999999998
167	2022-04-28 16:14:43.205687	142.84999999999999
168	2022-04-28 16:14:43.040687	144.97
169	2022-04-28 16:14:44.394687	81.329999999999998
170	2022-04-28 16:14:44.404687	36.289999999999999
171	2022-04-28 16:14:44.072687	94.129999999999995
172	2022-04-28 16:14:43.048687	64.159999999999997
173	2022-04-28 16:14:44.088687	108.38
174	2022-04-28 16:14:42.878687	98.159999999999997
175	2022-04-28 16:14:44.804687	106.47
176	2022-04-28 16:14:44.288687	10.699999999999999
177	2022-04-28 16:14:44.828687	1.99
178	2022-04-28 16:14:44.306687	134.21000000000001
179	2022-04-28 16:14:45.031687	27.59
180	2022-04-28 16:14:44.504687	144.12
181	2022-04-28 16:14:43.428687	112.09999999999999
182	2022-04-28 16:14:42.886687	11.06
183	2022-04-28 16:14:44.717687	111.12
184	2022-04-28 16:14:43.440687	53.329999999999998
185	2022-04-28 16:14:44.554687	15.210000000000001
186	2022-04-28 16:14:43.634687	118.55
187	2022-04-28 16:14:43.639687	22.239999999999998
188	2022-04-28 16:14:43.832687	26.780000000000001
189	2022-04-28 16:14:44.594687	13.4
190	2022-04-28 16:14:43.844687	86.409999999999997
191	2022-04-28 16:14:44.805687	36.450000000000003
192	2022-04-28 16:14:45.392687	13.42
193	2022-04-28 16:14:44.248687	73.870000000000005
194	2022-04-28 16:14:43.480687	16.48
195	2022-04-28 16:14:44.069687	20.510000000000002
196	2022-04-28 16:14:43.292687	72.590000000000003
197	2022-04-28 16:14:45.265687	104.29000000000001
198	2022-04-28 16:14:43.100687	110.34
199	2022-04-28 16:14:44.495687	144.88999999999999
200	2022-04-28 16:14:44.904687	105.87
201	2022-04-28 16:14:44.312687	95.310000000000002
202	2022-04-28 16:14:45.532687	110.72
203	2022-04-28 16:14:44.125687	108.44
204	2022-04-28 16:14:45.152687	100.42
205	2022-04-28 16:14:44.754687	56.850000000000001
206	2022-04-28 16:14:43.734687	116.34
207	2022-04-28 16:14:45.188687	10.17
208	2022-04-28 16:14:43.744687	135.59999999999999
209	2022-04-28 16:14:45.212687	135.74000000000001
210	2022-04-28 16:14:44.384687	31.890000000000001
211	2022-04-28 16:14:44.603687	19.079999999999998
212	2022-04-28 16:14:45.672687	79.560000000000002
213	2022-04-28 16:14:45.686687	113.8
214	2022-04-28 16:14:45.486687	79.680000000000007
215	2022-04-28 16:14:43.134687	88.280000000000001
216	2022-04-28 16:14:44.432687	94.379999999999995
217	2022-04-28 16:14:44.006687	92.349999999999994
218	2022-04-28 16:14:43.140687	12.84
219	2022-04-28 16:14:43.580687	29.140000000000001
220	2022-04-28 16:14:44.684687	112.47
221	2022-04-28 16:14:44.914687	74.620000000000005
222	2022-04-28 16:14:44.258687	6.0199999999999996
223	2022-04-28 16:14:45.380687	46.659999999999997
224	2022-04-28 16:14:44.944687	122.34
225	2022-04-28 16:14:44.279687	20.530000000000001
226	2022-04-28 16:14:45.868687	101.13
227	2022-04-28 16:14:44.293687	74.269999999999996
228	2022-04-28 16:14:43.388687	57.380000000000003
229	2022-04-28 16:14:45.223687	66.299999999999997
230	2022-04-28 16:14:45.234687	98.180000000000007
231	2022-04-28 16:14:45.476687	38.950000000000003
232	2022-04-28 16:14:44.792687	6.9800000000000004
233	2022-04-28 16:14:45.500687	92.459999999999994
234	2022-04-28 16:14:44.342687	28.920000000000002
235	2022-04-28 16:14:45.994687	26.780000000000001
236	2022-04-28 16:14:45.064687	90.870000000000005
237	2022-04-28 16:14:43.889687	113.70999999999999
238	2022-04-28 16:14:44.608687	9.2400000000000002
239	2022-04-28 16:14:45.094687	132.22
240	2022-04-28 16:14:45.104687	97.450000000000003
1	2022-04-28 16:14:42.707687	11.460000000000001
2	2022-04-28 16:14:42.708687	137.47999999999999
3	2022-04-28 16:14:42.734687	124.8
4	2022-04-28 16:14:42.720687	124.87
5	2022-04-28 16:14:42.739687	100.34
6	2022-04-28 16:14:42.740687	116.2
7	2022-04-28 16:14:42.753687	139.28
8	2022-04-28 16:14:42.816687	64.069999999999993
9	2022-04-28 16:14:42.821687	62
10	2022-04-28 16:14:42.744687	33.109999999999999
11	2022-04-28 16:14:42.847687	70.170000000000002
12	2022-04-28 16:14:42.848687	41.539999999999999
13	2022-04-28 16:14:42.795687	47.229999999999997
14	2022-04-28 16:14:42.788687	96.909999999999997
15	2022-04-28 16:14:42.914687	16.43
16	2022-04-28 16:14:42.880687	116.75
17	2022-04-28 16:14:42.891687	16.920000000000002
18	2022-04-28 16:14:42.866687	110.95
19	2022-04-28 16:14:42.780687	96.819999999999993
20	2022-04-28 16:14:42.824687	142.13999999999999
21	2022-04-28 16:14:42.851687	84.219999999999999
22	2022-04-28 16:14:42.946687	44.020000000000003
23	2022-04-28 16:14:42.980687	128.81
24	2022-04-28 16:14:42.800687	50.890000000000001
25	2022-04-28 16:14:43.004687	12.58
26	2022-04-28 16:14:42.782687	35.880000000000003
27	2022-04-28 16:14:43.001687	68.650000000000006
28	2022-04-28 16:14:43.040687	92.299999999999997
29	2022-04-28 16:14:42.820687	117.59
30	2022-04-28 16:14:42.944687	50.719999999999999
31	2022-04-28 16:14:42.921687	78.75
32	2022-04-28 16:14:43.120687	53.899999999999999
33	2022-04-28 16:14:43.166687	83.150000000000006
34	2022-04-28 16:14:42.772687	45.609999999999999
35	2022-04-28 16:14:42.914687	26.879999999999999
36	2022-04-28 16:14:42.884687	35.390000000000001
37	2022-04-28 16:14:42.778687	32.960000000000001
38	2022-04-28 16:14:43.160687	45.229999999999997
39	2022-04-28 16:14:43.133687	81.739999999999995
40	2022-04-28 16:14:42.984687	82.739999999999995
41	2022-04-28 16:14:42.827687	7.8399999999999999
42	2022-04-28 16:14:43.208687	132.81
43	2022-04-28 16:14:43.306687	71.400000000000006
44	2022-04-28 16:14:42.792687	43.649999999999999
45	2022-04-28 16:14:42.929687	135.31
46	2022-04-28 16:14:43.072687	54.130000000000003
47	2022-04-28 16:14:42.845687	6.0800000000000001
48	2022-04-28 16:14:43.088687	129.94
49	2022-04-28 16:14:43.243687	52.460000000000001
50	2022-04-28 16:14:43.004687	35.630000000000003
51	2022-04-28 16:14:43.316687	130.5
52	2022-04-28 16:14:43.432687	96.769999999999996
53	2022-04-28 16:14:43.340687	133.53999999999999
54	2022-04-28 16:14:42.920687	71.930000000000007
55	2022-04-28 16:14:43.254687	70.540000000000006
56	2022-04-28 16:14:43.432687	95.870000000000005
57	2022-04-28 16:14:43.046687	135.09999999999999
58	2022-04-28 16:14:42.936687	61.880000000000003
59	2022-04-28 16:14:43.353687	138.58000000000001
60	2022-04-28 16:14:43.124687	69.430000000000007
61	2022-04-28 16:14:43.131687	108.01000000000001
62	2022-04-28 16:14:43.572687	68.260000000000005
63	2022-04-28 16:14:43.334687	130.13
64	2022-04-28 16:14:42.832687	2.75
65	2022-04-28 16:14:43.419687	130.50999999999999
66	2022-04-28 16:14:43.298687	59.119999999999997
67	2022-04-28 16:14:42.972687	34.899999999999999
68	2022-04-28 16:14:43.452687	32.520000000000003
69	2022-04-28 16:14:42.842687	24.260000000000002
70	2022-04-28 16:14:42.844687	5.8700000000000001
71	2022-04-28 16:14:43.059687	87.700000000000003
72	2022-04-28 16:14:43.352687	122.52
73	2022-04-28 16:14:42.850687	129.38
74	2022-04-28 16:14:42.852687	35.789999999999999
75	2022-04-28 16:14:43.604687	14.19
76	2022-04-28 16:14:43.008687	110.29000000000001
77	2022-04-28 16:14:43.782687	125.66
78	2022-04-28 16:14:43.562687	16.899999999999999
79	2022-04-28 16:14:43.731687	70.959999999999994
80	2022-04-28 16:14:42.864687	134.22999999999999
81	2022-04-28 16:14:43.676687	27.93
82	2022-04-28 16:14:43.606687	113.72
83	2022-04-28 16:14:43.783687	69.370000000000005
84	2022-04-28 16:14:43.292687	15.800000000000001
85	2022-04-28 16:14:43.044687	2.96
86	2022-04-28 16:14:43.134687	81.239999999999995
87	2022-04-28 16:14:43.748687	56.399999999999999
88	2022-04-28 16:14:43.056687	127.72
89	2022-04-28 16:14:42.971687	21.940000000000001
90	2022-04-28 16:14:43.334687	108.28
91	2022-04-28 16:14:43.887687	120.61
92	2022-04-28 16:14:43.072687	90.480000000000004
93	2022-04-28 16:14:43.727687	122.11
94	2022-04-28 16:14:43.362687	52.890000000000001
95	2022-04-28 16:14:43.369687	88.700000000000003
96	2022-04-28 16:14:43.184687	89.560000000000002
97	2022-04-28 16:14:42.995687	26.120000000000001
98	2022-04-28 16:14:43.096687	16.43
99	2022-04-28 16:14:43.892687	121.73
100	2022-04-28 16:14:44.104687	85.219999999999999
101	2022-04-28 16:14:43.411687	135.40000000000001
102	2022-04-28 16:14:42.908687	115.42
103	2022-04-28 16:14:43.837687	90.980000000000004
104	2022-04-28 16:14:44.056687	81.560000000000002
105	2022-04-28 16:14:43.754687	128.52000000000001
106	2022-04-28 16:14:44.188687	111.88
107	2022-04-28 16:14:42.918687	42.729999999999997
108	2022-04-28 16:14:42.920687	4.2999999999999998
109	2022-04-28 16:14:44.230687	24.559999999999999
110	2022-04-28 16:14:42.924687	7.9400000000000004
111	2022-04-28 16:14:42.815687	12.19
112	2022-04-28 16:14:43.712687	88.579999999999998
113	2022-04-28 16:14:43.834687	103.7
114	2022-04-28 16:14:43.502687	99.879999999999995
115	2022-04-28 16:14:43.164687	12.279999999999999
116	2022-04-28 16:14:42.936687	42.729999999999997
117	2022-04-28 16:14:43.172687	120.34999999999999
118	2022-04-28 16:14:43.294687	135.43000000000001
119	2022-04-28 16:14:44.132687	60.859999999999999
120	2022-04-28 16:14:44.144687	15.09
121	2022-04-28 16:14:44.398687	131.49000000000001
122	2022-04-28 16:14:43.924687	86.159999999999997
123	2022-04-28 16:14:43.811687	78.730000000000004
124	2022-04-28 16:14:43.696687	122.41
125	2022-04-28 16:14:43.079687	24.43
126	2022-04-28 16:14:43.082687	95.870000000000005
127	2022-04-28 16:14:44.101687	132.31
128	2022-04-28 16:14:43.856687	55.740000000000002
129	2022-04-28 16:14:43.349687	61.840000000000003
130	2022-04-28 16:14:42.964687	9.1199999999999992
131	2022-04-28 16:14:43.228687	32.170000000000002
132	2022-04-28 16:14:43.496687	88.310000000000002
133	2022-04-28 16:14:44.300687	101.59999999999999
134	2022-04-28 16:14:43.910687	36.939999999999998
135	2022-04-28 16:14:44.594687	19.870000000000001
136	2022-04-28 16:14:43.248687	82.700000000000003
137	2022-04-28 16:14:43.389687	140.34
138	2022-04-28 16:14:43.118687	16.73
139	2022-04-28 16:14:43.538687	6.8499999999999996
140	2022-04-28 16:14:44.664687	25.52
141	2022-04-28 16:14:43.127687	85.579999999999998
142	2022-04-28 16:14:43.982687	6.8899999999999997
143	2022-04-28 16:14:44.706687	59.189999999999998
144	2022-04-28 16:14:43.856687	41.280000000000001
145	2022-04-28 16:14:43.429687	132.38
146	2022-04-28 16:14:44.018687	56.130000000000003
147	2022-04-28 16:14:43.586687	116.3
148	2022-04-28 16:14:44.628687	105.65000000000001
149	2022-04-28 16:14:43.896687	11.77
150	2022-04-28 16:14:44.354687	134.66
151	2022-04-28 16:14:44.818687	43.100000000000001
152	2022-04-28 16:14:44.528687	142.84
153	2022-04-28 16:14:44.846687	82.079999999999998
154	2022-04-28 16:14:43.628687	117.86
155	2022-04-28 16:14:44.564687	68.040000000000006
156	2022-04-28 16:14:44.888687	39.170000000000002
157	2022-04-28 16:14:43.803687	133.43000000000001
158	2022-04-28 16:14:44.758687	89.299999999999997
159	2022-04-28 16:14:44.294687	46.990000000000002
160	2022-04-28 16:14:44.304687	62.030000000000001
161	2022-04-28 16:14:43.348687	44.780000000000001
162	2022-04-28 16:14:44.972687	14.140000000000001
163	2022-04-28 16:14:44.008687	122.11
164	2022-04-28 16:14:43.360687	74.739999999999995
165	2022-04-28 16:14:43.034687	56.359999999999999
166	2022-04-28 16:14:44.198687	48.119999999999997
167	2022-04-28 16:14:43.539687	9.5600000000000005
168	2022-04-28 16:14:43.376687	128.31999999999999
169	2022-04-28 16:14:44.563687	86.230000000000004
170	2022-04-28 16:14:43.214687	57.32
171	2022-04-28 16:14:43.046687	102.7
172	2022-04-28 16:14:43.908687	115.31
173	2022-04-28 16:14:44.953687	53.880000000000003
174	2022-04-28 16:14:45.140687	60.390000000000001
175	2022-04-28 16:14:44.979687	42.789999999999999
176	2022-04-28 16:14:43.056687	34.259999999999998
177	2022-04-28 16:14:43.943687	50.68
178	2022-04-28 16:14:44.662687	95.659999999999997
179	2022-04-28 16:14:43.599687	109.52
180	2022-04-28 16:14:44.144687	15.99
181	2022-04-28 16:14:43.609687	122
182	2022-04-28 16:14:44.706687	61.700000000000003
183	2022-04-28 16:14:45.083687	95.5
184	2022-04-28 16:14:45.280687	55.840000000000003
185	2022-04-28 16:14:44.554687	1.27
186	2022-04-28 16:14:45.122687	8.7699999999999996
187	2022-04-28 16:14:43.452687	39.350000000000001
188	2022-04-28 16:14:43.832687	70.239999999999995
189	2022-04-28 16:14:44.972687	30.18
190	2022-04-28 16:14:43.274687	20.710000000000001
191	2022-04-28 16:14:45.187687	120.40000000000001
192	2022-04-28 16:14:44.432687	113.22
193	2022-04-28 16:14:43.669687	48.990000000000002
194	2022-04-28 16:14:45.226687	135.37
195	2022-04-28 16:14:43.679687	81.310000000000002
196	2022-04-28 16:14:44.468687	144.30000000000001
197	2022-04-28 16:14:43.295687	144.69999999999999
198	2022-04-28 16:14:43.100687	32.369999999999997
199	2022-04-28 16:14:45.490687	9.2799999999999994
200	2022-04-28 16:14:45.304687	41.030000000000001
201	2022-04-28 16:14:43.910687	82.670000000000002
202	2022-04-28 16:14:44.724687	133.21000000000001
203	2022-04-28 16:14:44.125687	5.5199999999999996
204	2022-04-28 16:14:42.908687	23.510000000000002
205	2022-04-28 16:14:45.574687	39.25
206	2022-04-28 16:14:45.176687	15.210000000000001
207	2022-04-28 16:14:44.567687	51.189999999999998
208	2022-04-28 16:14:43.536687	72.799999999999997
209	2022-04-28 16:14:43.540687	140.53
210	2022-04-28 16:14:43.334687	83.579999999999998
211	2022-04-28 16:14:45.025687	9.6600000000000001
212	2022-04-28 16:14:43.128687	22.91
213	2022-04-28 16:14:44.195687	127.22
214	2022-04-28 16:14:45.700687	33.5
215	2022-04-28 16:14:43.564687	23.079999999999998
216	2022-04-28 16:14:44.432687	112.29000000000001
217	2022-04-28 16:14:43.789687	128.47999999999999
218	2022-04-28 16:14:45.102687	48.700000000000003
219	2022-04-28 16:14:43.361687	98.939999999999998
220	2022-04-28 16:14:44.024687	40.189999999999998
221	2022-04-28 16:14:43.809687	109.51000000000001
222	2022-04-28 16:14:45.812687	8.5899999999999999
223	2022-04-28 16:14:45.157687	71.370000000000005
224	2022-04-28 16:14:44.048687	110.92
225	2022-04-28 16:14:45.404687	83.219999999999999
226	2022-04-28 16:14:45.868687	144.44
227	2022-04-28 16:14:45.882687	46.920000000000002
228	2022-04-28 16:14:44.528687	46.960000000000001
229	2022-04-28 16:14:44.536687	81.030000000000001
230	2022-04-28 16:14:44.544687	80.090000000000003
231	2022-04-28 16:14:43.166687	114.45
232	2022-04-28 16:14:45.952687	119.93000000000001
233	2022-04-28 16:14:45.267687	9.5700000000000003
234	2022-04-28 16:14:45.512687	103.43000000000001
235	2022-04-28 16:14:44.819687	127.81999999999999
236	2022-04-28 16:14:44.120687	82.799999999999997
237	2022-04-28 16:14:44.837687	123.56
238	2022-04-28 16:14:43.656687	144.87
239	2022-04-28 16:14:43.421687	3.04
240	2022-04-28 16:14:44.384687	135.22
\.


--
-- Data for Name: float_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_actual (key, fix, value) FROM stdin;
1	2022-04-28 16:14:42.709687	44.979999999999997
2	2022-04-28 16:14:42.710687	98.790000000000006
3	2022-04-28 16:14:42.722687	5.5999999999999996
4	2022-04-28 16:14:42.752687	46.640000000000001
5	2022-04-28 16:14:42.754687	102.19
6	2022-04-28 16:14:42.764687	29.109999999999999
7	2022-04-28 16:14:42.795687	139.40000000000001
8	2022-04-28 16:14:42.776687	3.6800000000000002
9	2022-04-28 16:14:42.803687	70.030000000000001
10	2022-04-28 16:14:42.784687	71.989999999999995
11	2022-04-28 16:14:42.759687	80.409999999999997
12	2022-04-28 16:14:42.800687	8.9700000000000006
13	2022-04-28 16:14:42.769687	33
14	2022-04-28 16:14:42.802687	124.45
15	2022-04-28 16:14:42.734687	2.71
16	2022-04-28 16:14:42.800687	129.66
17	2022-04-28 16:14:42.738687	140.30000000000001
18	2022-04-28 16:14:42.902687	48.460000000000001
19	2022-04-28 16:14:42.913687	7.04
20	2022-04-28 16:14:42.804687	87.780000000000001
21	2022-04-28 16:14:42.851687	90.010000000000005
22	2022-04-28 16:14:42.748687	132.41999999999999
23	2022-04-28 16:14:42.842687	76.709999999999994
24	2022-04-28 16:14:43.040687	33.719999999999999
25	2022-04-28 16:14:42.754687	101.58
26	2022-04-28 16:14:42.834687	88.159999999999997
27	2022-04-28 16:14:42.839687	33.979999999999997
28	2022-04-28 16:14:43.068687	107.29000000000001
29	2022-04-28 16:14:43.052687	10.699999999999999
30	2022-04-28 16:14:42.884687	19.489999999999998
31	2022-04-28 16:14:42.983687	140.38999999999999
32	2022-04-28 16:14:42.832687	101.38
33	2022-04-28 16:14:42.902687	113.81
34	2022-04-28 16:14:42.806687	132.38999999999999
35	2022-04-28 16:14:42.844687	41.5
36	2022-04-28 16:14:42.884687	100.78
37	2022-04-28 16:14:42.852687	132.97999999999999
38	2022-04-28 16:14:42.780687	101.59999999999999
39	2022-04-28 16:14:43.016687	87.689999999999998
40	2022-04-28 16:14:43.104687	109.54000000000001
41	2022-04-28 16:14:42.868687	35.689999999999998
42	2022-04-28 16:14:43.208687	56.369999999999997
43	2022-04-28 16:14:43.134687	110.17
44	2022-04-28 16:14:43.100687	115.95999999999999
45	2022-04-28 16:14:42.794687	1.8899999999999999
46	2022-04-28 16:14:43.072687	94.900000000000006
47	2022-04-28 16:14:43.174687	21.859999999999999
48	2022-04-28 16:14:42.800687	68.159999999999997
49	2022-04-28 16:14:42.998687	54.479999999999997
50	2022-04-28 16:14:43.154687	84.730000000000004
51	2022-04-28 16:14:43.010687	11.279999999999999
52	2022-04-28 16:14:42.756687	112.93000000000001
53	2022-04-28 16:14:43.022687	89.969999999999999
54	2022-04-28 16:14:43.028687	60.079999999999998
55	2022-04-28 16:14:42.869687	30.690000000000001
56	2022-04-28 16:14:42.984687	29.09
57	2022-04-28 16:14:43.046687	94.909999999999997
58	2022-04-28 16:14:43.458687	48.259999999999998
59	2022-04-28 16:14:42.881687	124.20999999999999
60	2022-04-28 16:14:43.544687	85.590000000000003
61	2022-04-28 16:14:42.948687	55.109999999999999
62	2022-04-28 16:14:43.448687	31.960000000000001
63	2022-04-28 16:14:43.397687	95.069999999999993
64	2022-04-28 16:14:42.832687	10.470000000000001
65	2022-04-28 16:14:43.549687	87.180000000000007
66	2022-04-28 16:14:43.034687	17.84
67	2022-04-28 16:14:42.838687	17.600000000000001
68	2022-04-28 16:14:43.112687	25.82
69	2022-04-28 16:14:42.980687	4.8700000000000001
70	2022-04-28 16:14:43.684687	13.890000000000001
71	2022-04-28 16:14:43.130687	24.289999999999999
72	2022-04-28 16:14:43.352687	125.09
73	2022-04-28 16:14:43.507687	50.380000000000003
74	2022-04-28 16:14:43.074687	143.72
75	2022-04-28 16:14:43.079687	103.33
76	2022-04-28 16:14:43.084687	77.109999999999999
77	2022-04-28 16:14:43.166687	142.97999999999999
78	2022-04-28 16:14:43.172687	142.43000000000001
79	2022-04-28 16:14:43.020687	115.68000000000001
80	2022-04-28 16:14:42.864687	108.43000000000001
81	2022-04-28 16:14:43.433687	49.020000000000003
82	2022-04-28 16:14:43.360687	83.349999999999994
83	2022-04-28 16:14:43.783687	20.77
84	2022-04-28 16:14:42.956687	38.549999999999997
85	2022-04-28 16:14:43.129687	104.34999999999999
86	2022-04-28 16:14:42.876687	21.379999999999999
87	2022-04-28 16:14:43.835687	131.41
88	2022-04-28 16:14:43.056687	8.8000000000000007
89	2022-04-28 16:14:43.683687	143.43000000000001
90	2022-04-28 16:14:43.334687	59.439999999999998
91	2022-04-28 16:14:43.250687	10.34
92	2022-04-28 16:14:43.808687	25.82
93	2022-04-28 16:14:43.169687	115.06
94	2022-04-28 16:14:43.738687	8.0500000000000007
95	2022-04-28 16:14:43.749687	61.469999999999999
96	2022-04-28 16:14:44.048687	64.269999999999996
97	2022-04-28 16:14:44.062687	36.329999999999998
98	2022-04-28 16:14:43.488687	5.3099999999999996
99	2022-04-28 16:14:43.595687	9.8499999999999996
100	2022-04-28 16:14:44.104687	90.280000000000001
101	2022-04-28 16:14:43.108687	3.8500000000000001
102	2022-04-28 16:14:43.826687	79.25
103	2022-04-28 16:14:43.631687	24.18
104	2022-04-28 16:14:43.744687	69.670000000000002
105	2022-04-28 16:14:43.859687	46.479999999999997
106	2022-04-28 16:14:43.128687	35.369999999999997
107	2022-04-28 16:14:43.346687	91.450000000000003
108	2022-04-28 16:14:43.352687	73.349999999999994
109	2022-04-28 16:14:43.576687	52.869999999999997
110	2022-04-28 16:14:43.254687	15.35
111	2022-04-28 16:14:43.370687	17.789999999999999
112	2022-04-28 16:14:43.600687	121.43000000000001
113	2022-04-28 16:14:43.947687	95.939999999999998
114	2022-04-28 16:14:43.046687	90.890000000000001
115	2022-04-28 16:14:43.394687	29.579999999999998
116	2022-04-28 16:14:43.516687	99.819999999999993
117	2022-04-28 16:14:42.821687	122.52
118	2022-04-28 16:14:43.176687	52.469999999999999
119	2022-04-28 16:14:43.418687	39.530000000000001
120	2022-04-28 16:14:43.784687	21.09
121	2022-04-28 16:14:43.067687	38.990000000000002
122	2022-04-28 16:14:43.314687	63.609999999999999
123	2022-04-28 16:14:43.196687	103.56
124	2022-04-28 16:14:43.076687	54.43
125	2022-04-28 16:14:44.329687	4.6200000000000001
126	2022-04-28 16:14:43.712687	40.490000000000002
127	2022-04-28 16:14:44.228687	127.09999999999999
128	2022-04-28 16:14:43.216687	10.390000000000001
129	2022-04-28 16:14:43.736687	131.28
130	2022-04-28 16:14:44.134687	139.08000000000001
131	2022-04-28 16:14:42.835687	6.7800000000000002
132	2022-04-28 16:14:42.968687	82.140000000000001
133	2022-04-28 16:14:44.433687	80.700000000000003
134	2022-04-28 16:14:43.240687	72.25
135	2022-04-28 16:14:43.514687	3.29
136	2022-04-28 16:14:43.112687	38.479999999999997
137	2022-04-28 16:14:44.348687	20.629999999999999
138	2022-04-28 16:14:44.636687	20.890000000000001
139	2022-04-28 16:14:44.372687	12.619999999999999
140	2022-04-28 16:14:44.104687	9.6300000000000008
141	2022-04-28 16:14:43.832687	112.95999999999999
142	2022-04-28 16:14:44.266687	52.450000000000003
143	2022-04-28 16:14:44.134687	22.719999999999999
144	2022-04-28 16:14:44.576687	21.649999999999999
145	2022-04-28 16:14:44.009687	24.5
146	2022-04-28 16:14:44.456687	62.369999999999997
147	2022-04-28 16:14:43.880687	87.75
148	2022-04-28 16:14:43.148687	14.26
149	2022-04-28 16:14:43.151687	106.08
150	2022-04-28 16:14:43.904687	92.140000000000001
151	2022-04-28 16:14:43.912687	89.140000000000001
152	2022-04-28 16:14:44.832687	125.06
153	2022-04-28 16:14:44.540687	36.590000000000003
154	2022-04-28 16:14:43.782687	95.269999999999996
155	2022-04-28 16:14:44.719687	13.16
156	2022-04-28 16:14:43.328687	62.780000000000001
157	2022-04-28 16:14:43.489687	104.19
158	2022-04-28 16:14:43.652687	35.710000000000001
159	2022-04-28 16:14:43.499687	107.92
160	2022-04-28 16:14:44.784687	108.31999999999999
161	2022-04-28 16:14:44.314687	12.73
162	2022-04-28 16:14:44.810687	35.689999999999998
163	2022-04-28 16:14:43.193687	109.23
164	2022-04-28 16:14:44.508687	30.190000000000001
165	2022-04-28 16:14:42.869687	127.81999999999999
166	2022-04-28 16:14:45.028687	15.380000000000001
167	2022-04-28 16:14:44.040687	4.2199999999999998
168	2022-04-28 16:14:44.216687	137.31999999999999
169	2022-04-28 16:14:44.732687	129.38
170	2022-04-28 16:14:44.064687	65.689999999999998
171	2022-04-28 16:14:44.414687	36.420000000000002
172	2022-04-28 16:14:43.392687	78.959999999999994
173	2022-04-28 16:14:44.953687	62.060000000000002
174	2022-04-28 16:14:43.226687	113.41
175	2022-04-28 16:14:43.404687	128.59999999999999
176	2022-04-28 16:14:44.816687	62.600000000000001
177	2022-04-28 16:14:44.828687	116.15000000000001
178	2022-04-28 16:14:45.196687	60.079999999999998
179	2022-04-28 16:14:44.673687	106.31999999999999
180	2022-04-28 16:14:44.504687	15.69
181	2022-04-28 16:14:44.152687	40.130000000000003
182	2022-04-28 16:14:44.524687	4.9699999999999998
183	2022-04-28 16:14:43.253687	21.309999999999999
184	2022-04-28 16:14:45.096687	34.340000000000003
185	2022-04-28 16:14:43.259687	67.209999999999994
186	2022-04-28 16:14:44.006687	58.979999999999997
187	2022-04-28 16:14:43.452687	61.939999999999998
188	2022-04-28 16:14:43.080687	60.359999999999999
189	2022-04-28 16:14:44.972687	48.950000000000003
190	2022-04-28 16:14:43.654687	108.28
191	2022-04-28 16:14:44.423687	143.49000000000001
192	2022-04-28 16:14:42.896687	19.609999999999999
193	2022-04-28 16:14:43.090687	79.670000000000002
194	2022-04-28 16:14:43.480687	108.02
195	2022-04-28 16:14:43.094687	24.510000000000002
196	2022-04-28 16:14:43.488687	12.41
197	2022-04-28 16:14:43.492687	59.609999999999999
198	2022-04-28 16:14:45.476687	60.030000000000001
199	2022-04-28 16:14:44.495687	31.66
200	2022-04-28 16:14:44.104687	114.26000000000001
201	2022-04-28 16:14:44.312687	137.24000000000001
202	2022-04-28 16:14:44.724687	107.91
203	2022-04-28 16:14:44.125687	58.82
204	2022-04-28 16:14:43.520687	64.280000000000001
205	2022-04-28 16:14:44.959687	82.780000000000001
206	2022-04-28 16:14:44.558687	60.060000000000002
207	2022-04-28 16:14:44.153687	138.34
208	2022-04-28 16:14:44.368687	72.219999999999999
209	2022-04-28 16:14:43.749687	75.219999999999999
210	2022-04-28 16:14:45.644687	83.120000000000005
211	2022-04-28 16:14:45.447687	22.48
212	2022-04-28 16:14:43.552687	142.86000000000001
213	2022-04-28 16:14:43.769687	52.350000000000001
214	2022-04-28 16:14:43.560687	120.77
215	2022-04-28 16:14:44.209687	95.890000000000001
216	2022-04-28 16:14:45.296687	92.209999999999994
217	2022-04-28 16:14:45.525687	77.75
218	2022-04-28 16:14:43.576687	92.299999999999997
219	2022-04-28 16:14:44.018687	39.060000000000002
220	2022-04-28 16:14:44.904687	98.969999999999999
221	2022-04-28 16:14:44.030687	116.78
222	2022-04-28 16:14:42.926687	70.200000000000003
223	2022-04-28 16:14:44.711687	116.02
224	2022-04-28 16:14:44.944687	36.329999999999998
225	2022-04-28 16:14:45.629687	69.650000000000006
226	2022-04-28 16:14:43.382687	14.140000000000001
227	2022-04-28 16:14:43.839687	124.95
228	2022-04-28 16:14:45.668687	56.850000000000001
229	2022-04-28 16:14:45.223687	95.090000000000003
230	2022-04-28 16:14:44.544687	15.130000000000001
231	2022-04-28 16:14:43.628687	53.340000000000003
232	2022-04-28 16:14:45.952687	12.1
233	2022-04-28 16:14:45.267687	135.91
234	2022-04-28 16:14:44.576687	128.44999999999999
235	2022-04-28 16:14:45.289687	129.87
236	2022-04-28 16:14:43.412687	1.8799999999999999
237	2022-04-28 16:14:45.548687	40.109999999999999
238	2022-04-28 16:14:43.656687	15.380000000000001
239	2022-04-28 16:14:43.421687	103.06
240	2022-04-28 16:14:44.144687	67
\.


--
-- Data for Name: float_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_archive (key, fix, value) FROM stdin;
\.


--
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
-- Name: glossary_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.glossary_key_seq', 240, true);


--
-- Data for Name: integer_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_actual (key, fix, value) FROM stdin;
1	2022-04-28 16:14:42.711687	28
2	2022-04-28 16:14:42.718687	92
3	2022-04-28 16:14:42.716687	77
4	2022-04-28 16:14:42.752687	145
5	2022-04-28 16:14:42.734687	65
6	2022-04-28 16:14:42.776687	83
7	2022-04-28 16:14:42.732687	118
8	2022-04-28 16:14:42.736687	78
9	2022-04-28 16:14:42.812687	20
10	2022-04-28 16:14:42.754687	98
11	2022-04-28 16:14:42.814687	101
12	2022-04-28 16:14:42.740687	132
13	2022-04-28 16:14:42.756687	60
14	2022-04-28 16:14:42.788687	14
15	2022-04-28 16:14:42.734687	78
16	2022-04-28 16:14:42.768687	72
17	2022-04-28 16:14:42.755687	83
18	2022-04-28 16:14:42.740687	131
19	2022-04-28 16:14:42.818687	48
20	2022-04-28 16:14:42.904687	33
21	2022-04-28 16:14:42.788687	115
22	2022-04-28 16:14:42.836687	22
23	2022-04-28 16:14:42.750687	117
24	2022-04-28 16:14:42.848687	117
25	2022-04-28 16:14:42.954687	104
26	2022-04-28 16:14:42.808687	141
27	2022-04-28 16:14:42.974687	110
28	2022-04-28 16:14:42.816687	114
29	2022-04-28 16:14:42.733687	77
30	2022-04-28 16:14:42.914687	113
31	2022-04-28 16:14:42.797687	109
32	2022-04-28 16:14:43.120687	120
33	2022-04-28 16:14:42.836687	50
34	2022-04-28 16:14:42.942687	89
35	2022-04-28 16:14:43.089687	42
36	2022-04-28 16:14:42.848687	69
37	2022-04-28 16:14:43.000687	14
38	2022-04-28 16:14:42.970687	133
39	2022-04-28 16:14:42.938687	5
40	2022-04-28 16:14:43.184687	57
41	2022-04-28 16:14:42.745687	85
42	2022-04-28 16:14:42.998687	52
43	2022-04-28 16:14:42.962687	36
44	2022-04-28 16:14:43.188687	55
45	2022-04-28 16:14:42.974687	43
46	2022-04-28 16:14:43.302687	120
47	2022-04-28 16:14:43.315687	127
48	2022-04-28 16:14:42.800687	70
49	2022-04-28 16:14:43.341687	78
50	2022-04-28 16:14:43.354687	104
51	2022-04-28 16:14:43.010687	113
52	2022-04-28 16:14:42.808687	56
53	2022-04-28 16:14:43.128687	107
54	2022-04-28 16:14:43.136687	91
55	2022-04-28 16:14:42.979687	47
56	2022-04-28 16:14:43.096687	143
57	2022-04-28 16:14:43.274687	8
58	2022-04-28 16:14:43.342687	82
59	2022-04-28 16:14:42.999687	84
60	2022-04-28 16:14:43.184687	143
61	2022-04-28 16:14:43.253687	10
62	2022-04-28 16:14:43.014687	65
63	2022-04-28 16:14:43.082687	54
64	2022-04-28 16:14:43.280687	90
65	2022-04-28 16:14:42.769687	141
66	2022-04-28 16:14:42.836687	117
67	2022-04-28 16:14:42.905687	23
68	2022-04-28 16:14:42.840687	36
69	2022-04-28 16:14:43.256687	7
70	2022-04-28 16:14:43.544687	88
71	2022-04-28 16:14:43.485687	24
72	2022-04-28 16:14:42.848687	5
73	2022-04-28 16:14:43.580687	132
74	2022-04-28 16:14:42.926687	123
75	2022-04-28 16:14:42.929687	76
76	2022-04-28 16:14:42.932687	43
77	2022-04-28 16:14:42.858687	136
78	2022-04-28 16:14:42.938687	45
79	2022-04-28 16:14:43.336687	91
80	2022-04-28 16:14:43.824687	25
81	2022-04-28 16:14:42.947687	126
82	2022-04-28 16:14:43.442687	50
83	2022-04-28 16:14:43.119687	93
84	2022-04-28 16:14:43.796687	76
85	2022-04-28 16:14:42.874687	75
86	2022-04-28 16:14:42.876687	41
87	2022-04-28 16:14:43.661687	130
88	2022-04-28 16:14:43.056687	59
89	2022-04-28 16:14:43.950687	36
90	2022-04-28 16:14:43.514687	71
91	2022-04-28 16:14:43.068687	107
92	2022-04-28 16:14:43.440687	72
93	2022-04-28 16:14:43.820687	111
94	2022-04-28 16:14:43.738687	27
95	2022-04-28 16:14:44.034687	105
96	2022-04-28 16:14:43.760687	129
97	2022-04-28 16:14:42.898687	97
98	2022-04-28 16:14:43.390687	130
99	2022-04-28 16:14:43.496687	106
100	2022-04-28 16:14:43.804687	31
101	2022-04-28 16:14:42.906687	93
102	2022-04-28 16:14:43.928687	88
103	2022-04-28 16:14:43.425687	128
104	2022-04-28 16:14:43.536687	22
105	2022-04-28 16:14:43.754687	110
106	2022-04-28 16:14:43.234687	40
107	2022-04-28 16:14:42.918687	75
108	2022-04-28 16:14:44.216687	62
109	2022-04-28 16:14:43.358687	19
110	2022-04-28 16:14:43.584687	74
111	2022-04-28 16:14:44.147687	101
112	2022-04-28 16:14:43.600687	45
113	2022-04-28 16:14:44.060687	25
114	2022-04-28 16:14:43.160687	13
115	2022-04-28 16:14:43.509687	49
116	2022-04-28 16:14:44.096687	40
117	2022-04-28 16:14:43.640687	58
118	2022-04-28 16:14:43.530687	84
119	2022-04-28 16:14:44.251687	131
120	2022-04-28 16:14:42.944687	136
121	2022-04-28 16:14:43.188687	91
122	2022-04-28 16:14:43.558687	36
123	2022-04-28 16:14:43.565687	68
124	2022-04-28 16:14:44.316687	80
125	2022-04-28 16:14:44.079687	5
126	2022-04-28 16:14:43.712687	62
127	2022-04-28 16:14:43.212687	39
128	2022-04-28 16:14:43.472687	51
129	2022-04-28 16:14:43.091687	76
130	2022-04-28 16:14:44.264687	45
131	2022-04-28 16:14:44.014687	67
132	2022-04-28 16:14:44.024687	55
133	2022-04-28 16:14:44.433687	7
134	2022-04-28 16:14:44.312687	93
135	2022-04-28 16:14:42.974687	55
136	2022-04-28 16:14:43.792687	68
137	2022-04-28 16:14:43.115687	87
138	2022-04-28 16:14:43.394687	36
139	2022-04-28 16:14:43.260687	42
140	2022-04-28 16:14:44.524687	48
141	2022-04-28 16:14:43.409687	99
142	2022-04-28 16:14:43.556687	62
143	2022-04-28 16:14:44.420687	63
144	2022-04-28 16:14:42.992687	33
145	2022-04-28 16:14:42.994687	15
146	2022-04-28 16:14:43.726687	57
147	2022-04-28 16:14:42.998687	105
148	2022-04-28 16:14:43.444687	111
149	2022-04-28 16:14:44.641687	15
150	2022-04-28 16:14:43.604687	55
151	2022-04-28 16:14:44.214687	34
152	2022-04-28 16:14:43.920687	50
153	2022-04-28 16:14:43.928687	11
154	2022-04-28 16:14:43.474687	88
155	2022-04-28 16:14:44.874687	15
156	2022-04-28 16:14:43.172687	121
157	2022-04-28 16:14:44.117687	72
158	2022-04-28 16:14:42.862687	141
159	2022-04-28 16:14:43.022687	41
160	2022-04-28 16:14:44.144687	69
161	2022-04-28 16:14:44.958687	83
162	2022-04-28 16:14:44.162687	141
163	2022-04-28 16:14:44.823687	19
164	2022-04-28 16:14:43.688687	56
165	2022-04-28 16:14:43.529687	76
166	2022-04-28 16:14:43.534687	19
167	2022-04-28 16:14:45.042687	77
168	2022-04-28 16:14:44.384687	12
169	2022-04-28 16:14:43.380687	6
170	2022-04-28 16:14:44.914687	108
171	2022-04-28 16:14:43.217687	68
172	2022-04-28 16:14:43.392687	140
173	2022-04-28 16:14:45.126687	93
174	2022-04-28 16:14:44.618687	86
175	2022-04-28 16:14:44.629687	46
176	2022-04-28 16:14:44.464687	96
177	2022-04-28 16:14:44.120687	126
178	2022-04-28 16:14:43.950687	16
179	2022-04-28 16:14:44.494687	75
180	2022-04-28 16:14:43.964687	59
181	2022-04-28 16:14:44.514687	136
182	2022-04-28 16:14:43.614687	68
183	2022-04-28 16:14:44.717687	145
184	2022-04-28 16:14:45.096687	16
185	2022-04-28 16:14:44.924687	136
186	2022-04-28 16:14:44.750687	10
187	2022-04-28 16:14:43.826687	120
188	2022-04-28 16:14:43.832687	73
189	2022-04-28 16:14:43.838687	91
190	2022-04-28 16:14:45.364687	41
191	2022-04-28 16:14:43.850687	115
192	2022-04-28 16:14:44.624687	145
193	2022-04-28 16:14:45.020687	96
194	2022-04-28 16:14:44.450687	13
195	2022-04-28 16:14:43.289687	81
196	2022-04-28 16:14:44.076687	101
197	2022-04-28 16:14:44.477687	74
198	2022-04-28 16:14:43.100687	26
199	2022-04-28 16:14:43.301687	113
200	2022-04-28 16:14:43.504687	142
201	2022-04-28 16:14:44.915687	96
202	2022-04-28 16:14:44.926687	114
203	2022-04-28 16:14:44.328687	90
204	2022-04-28 16:14:43.724687	103
205	2022-04-28 16:14:44.344687	131
206	2022-04-28 16:14:44.970687	5
207	2022-04-28 16:14:44.360687	23
208	2022-04-28 16:14:43.120687	130
209	2022-04-28 16:14:43.749687	45
210	2022-04-28 16:14:44.594687	19
211	2022-04-28 16:14:43.970687	117
212	2022-04-28 16:14:45.672687	43
213	2022-04-28 16:14:44.408687	13
214	2022-04-28 16:14:44.202687	126
215	2022-04-28 16:14:45.069687	29
216	2022-04-28 16:14:44.000687	81
217	2022-04-28 16:14:44.223687	3
218	2022-04-28 16:14:44.448687	102
219	2022-04-28 16:14:43.142687	130
220	2022-04-28 16:14:44.244687	34
221	2022-04-28 16:14:44.030687	130
222	2022-04-28 16:14:44.702687	33
223	2022-04-28 16:14:45.157687	59
224	2022-04-28 16:14:43.600687	66
225	2022-04-28 16:14:44.279687	24
226	2022-04-28 16:14:45.642687	126
227	2022-04-28 16:14:43.385687	9
228	2022-04-28 16:14:44.756687	138
229	2022-04-28 16:14:44.994687	68
230	2022-04-28 16:14:43.854687	67
231	2022-04-28 16:14:43.397687	62
232	2022-04-28 16:14:45.720687	46
233	2022-04-28 16:14:44.801687	33
234	2022-04-28 16:14:44.810687	73
235	2022-04-28 16:14:45.054687	50
236	2022-04-28 16:14:45.536687	56
237	2022-04-28 16:14:45.548687	59
238	2022-04-28 16:14:45.322687	75
239	2022-04-28 16:14:43.660687	112
240	2022-04-28 16:14:44.624687	16
\.


--
-- Data for Name: integer_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_archive (key, fix, value) FROM stdin;
\.


--
-- Data for Name: order_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_actual (key, fix, value) FROM stdin;
\.


--
-- Data for Name: order_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_archive (key, fix, value) FROM stdin;
\.


--
-- Data for Name: synchronization; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.synchronization (xpath, fix, status) FROM stdin;
\.


--
-- Name: glossary glossary_communication_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_communication_key UNIQUE (communication);


--
-- Name: glossary glossary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);


--
-- Name: _hyper_1_2_chunk_integer_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_integer_archive_fix_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree (fix DESC);


--
-- Name: _hyper_2_1_chunk_float_archive_fix_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_1_chunk_float_archive_fix_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (fix DESC);


--
-- Name: float_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX float_archive_fix_idx ON public.float_archive USING btree (fix DESC);


--
-- Name: integer_archive_fix_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX integer_archive_fix_idx ON public.integer_archive USING btree (fix DESC);


--
-- Name: glossary existence_check_or_creation_table; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();


--
-- Name: float_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.float_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- Name: integer_archive ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.integer_archive FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- Name: _hyper_2_1_chunk 1_1_float_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk
    ADD CONSTRAINT "1_1_float_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: _hyper_1_2_chunk 2_2_integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_integer_archive_key_fkey" FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: float_actual float_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_actual
    ADD CONSTRAINT float_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: float_archive float_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_archive
    ADD CONSTRAINT float_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: integer_actual integer_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_actual
    ADD CONSTRAINT integer_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: integer_archive integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_archive
    ADD CONSTRAINT integer_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: order_actual order_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_actual
    ADD CONSTRAINT order_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- Name: order_archive order_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_archive
    ADD CONSTRAINT order_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- PostgreSQL database dump complete
--

