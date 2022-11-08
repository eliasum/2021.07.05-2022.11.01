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

	CREATE TABLE IF NOT EXISTS %I( 
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));',
	_HyperTable, 	
	_TableName,
		
	_Table,			
	_TableName);	
	
	RETURN NEW; 
	
END;

$$;


ALTER FUNCTION public.before_insert_in_glossary() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

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
-- Name: float_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_archive OWNER TO postgres;

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
-- Name: integer_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_archive OWNER TO postgres;

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
-- Data for Name: float_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_actual (key, fix, value) FROM stdin;
1	2022-04-28 16:21:05.971419	44.979999999999997
2	2022-04-28 16:21:05.972419	98.790000000000006
3	2022-04-28 16:21:05.984419	5.5999999999999996
4	2022-04-28 16:21:06.014419	46.640000000000001
5	2022-04-28 16:21:06.016419	102.19
6	2022-04-28 16:21:06.026419	29.109999999999999
7	2022-04-28 16:21:06.057419	139.40000000000001
8	2022-04-28 16:21:06.038419	3.6800000000000002
9	2022-04-28 16:21:06.065419	70.030000000000001
10	2022-04-28 16:21:06.046419	71.989999999999995
11	2022-04-28 16:21:06.021419	80.409999999999997
12	2022-04-28 16:21:06.062419	8.9700000000000006
13	2022-04-28 16:21:06.031419	33
14	2022-04-28 16:21:06.064419	124.45
15	2022-04-28 16:21:05.996419	2.71
16	2022-04-28 16:21:06.062419	129.66
17	2022-04-28 16:21:06.000419	140.30000000000001
18	2022-04-28 16:21:06.164419	48.460000000000001
19	2022-04-28 16:21:06.175419	7.04
20	2022-04-28 16:21:06.066419	87.780000000000001
21	2022-04-28 16:21:06.113419	90.010000000000005
22	2022-04-28 16:21:06.010419	132.41999999999999
23	2022-04-28 16:21:06.104419	76.709999999999994
24	2022-04-28 16:21:06.302419	33.719999999999999
25	2022-04-28 16:21:06.016419	101.58
26	2022-04-28 16:21:06.096419	88.159999999999997
27	2022-04-28 16:21:06.101419	33.979999999999997
28	2022-04-28 16:21:06.330419	107.29000000000001
29	2022-04-28 16:21:06.314419	10.699999999999999
30	2022-04-28 16:21:06.146419	19.489999999999998
31	2022-04-28 16:21:06.245419	140.38999999999999
32	2022-04-28 16:21:06.094419	101.38
33	2022-04-28 16:21:06.164419	113.81
34	2022-04-28 16:21:06.068419	132.38999999999999
35	2022-04-28 16:21:06.106419	41.5
36	2022-04-28 16:21:06.146419	100.78
37	2022-04-28 16:21:06.114419	132.97999999999999
38	2022-04-28 16:21:06.042419	101.59999999999999
39	2022-04-28 16:21:06.278419	87.689999999999998
40	2022-04-28 16:21:06.366419	109.54000000000001
41	2022-04-28 16:21:06.130419	35.689999999999998
42	2022-04-28 16:21:06.470419	56.369999999999997
43	2022-04-28 16:21:06.396419	110.17
44	2022-04-28 16:21:06.362419	115.95999999999999
45	2022-04-28 16:21:06.056419	1.8899999999999999
46	2022-04-28 16:21:06.334419	94.900000000000006
47	2022-04-28 16:21:06.436419	21.859999999999999
48	2022-04-28 16:21:06.062419	68.159999999999997
49	2022-04-28 16:21:06.260419	54.479999999999997
50	2022-04-28 16:21:06.416419	84.730000000000004
51	2022-04-28 16:21:06.272419	11.279999999999999
52	2022-04-28 16:21:06.018419	112.93000000000001
53	2022-04-28 16:21:06.284419	89.969999999999999
54	2022-04-28 16:21:06.290419	60.079999999999998
55	2022-04-28 16:21:06.131419	30.690000000000001
56	2022-04-28 16:21:06.246419	29.09
57	2022-04-28 16:21:06.308419	94.909999999999997
58	2022-04-28 16:21:06.720419	48.259999999999998
59	2022-04-28 16:21:06.143419	124.20999999999999
60	2022-04-28 16:21:06.806419	85.590000000000003
61	2022-04-28 16:21:06.210419	55.109999999999999
62	2022-04-28 16:21:06.710419	31.960000000000001
63	2022-04-28 16:21:06.659419	95.069999999999993
64	2022-04-28 16:21:06.094419	10.470000000000001
65	2022-04-28 16:21:06.811419	87.180000000000007
66	2022-04-28 16:21:06.296419	17.84
67	2022-04-28 16:21:06.100419	17.600000000000001
68	2022-04-28 16:21:06.374419	25.82
69	2022-04-28 16:21:06.242419	4.8700000000000001
70	2022-04-28 16:21:06.946419	13.890000000000001
71	2022-04-28 16:21:06.392419	24.289999999999999
72	2022-04-28 16:21:06.614419	125.09
73	2022-04-28 16:21:06.769419	50.380000000000003
74	2022-04-28 16:21:06.336419	143.72
75	2022-04-28 16:21:06.341419	103.33
76	2022-04-28 16:21:06.346419	77.109999999999999
77	2022-04-28 16:21:06.428419	142.97999999999999
78	2022-04-28 16:21:06.434419	142.43000000000001
79	2022-04-28 16:21:06.282419	115.68000000000001
80	2022-04-28 16:21:06.126419	108.43000000000001
81	2022-04-28 16:21:06.695419	49.020000000000003
82	2022-04-28 16:21:06.622419	83.349999999999994
83	2022-04-28 16:21:07.045419	20.77
84	2022-04-28 16:21:06.218419	38.549999999999997
85	2022-04-28 16:21:06.391419	104.34999999999999
86	2022-04-28 16:21:06.138419	21.379999999999999
87	2022-04-28 16:21:07.097419	131.41
88	2022-04-28 16:21:06.318419	8.8000000000000007
89	2022-04-28 16:21:06.945419	143.43000000000001
90	2022-04-28 16:21:06.596419	59.439999999999998
91	2022-04-28 16:21:06.512419	10.34
92	2022-04-28 16:21:07.070419	25.82
93	2022-04-28 16:21:06.431419	115.06
94	2022-04-28 16:21:07.000419	8.0500000000000007
95	2022-04-28 16:21:07.011419	61.469999999999999
96	2022-04-28 16:21:07.310419	64.269999999999996
97	2022-04-28 16:21:07.324419	36.329999999999998
98	2022-04-28 16:21:06.750419	5.3099999999999996
99	2022-04-28 16:21:06.857419	9.8499999999999996
100	2022-04-28 16:21:07.366419	90.280000000000001
101	2022-04-28 16:21:06.370419	3.8500000000000001
102	2022-04-28 16:21:07.088419	79.25
103	2022-04-28 16:21:06.893419	24.18
104	2022-04-28 16:21:07.006419	69.670000000000002
105	2022-04-28 16:21:07.121419	46.479999999999997
106	2022-04-28 16:21:06.390419	35.369999999999997
107	2022-04-28 16:21:06.608419	91.450000000000003
108	2022-04-28 16:21:06.614419	73.349999999999994
109	2022-04-28 16:21:06.838419	52.869999999999997
110	2022-04-28 16:21:06.516419	15.35
111	2022-04-28 16:21:06.632419	17.789999999999999
112	2022-04-28 16:21:06.862419	121.43000000000001
113	2022-04-28 16:21:07.209419	95.939999999999998
114	2022-04-28 16:21:06.308419	90.890000000000001
115	2022-04-28 16:21:06.656419	29.579999999999998
116	2022-04-28 16:21:06.778419	99.819999999999993
117	2022-04-28 16:21:06.083419	122.52
118	2022-04-28 16:21:06.438419	52.469999999999999
119	2022-04-28 16:21:06.680419	39.530000000000001
120	2022-04-28 16:21:07.046419	21.09
121	2022-04-28 16:21:06.329419	38.990000000000002
122	2022-04-28 16:21:06.576419	63.609999999999999
123	2022-04-28 16:21:06.458419	103.56
124	2022-04-28 16:21:06.338419	54.43
125	2022-04-28 16:21:07.591419	4.6200000000000001
126	2022-04-28 16:21:06.974419	40.490000000000002
127	2022-04-28 16:21:07.490419	127.09999999999999
128	2022-04-28 16:21:06.478419	10.390000000000001
129	2022-04-28 16:21:06.998419	131.28
130	2022-04-28 16:21:07.396419	139.08000000000001
131	2022-04-28 16:21:06.097419	6.7800000000000002
132	2022-04-28 16:21:06.230419	82.140000000000001
133	2022-04-28 16:21:07.695419	80.700000000000003
134	2022-04-28 16:21:06.502419	72.25
135	2022-04-28 16:21:06.776419	3.29
136	2022-04-28 16:21:06.374419	38.479999999999997
137	2022-04-28 16:21:07.610419	20.629999999999999
138	2022-04-28 16:21:07.898419	20.890000000000001
139	2022-04-28 16:21:07.634419	12.619999999999999
140	2022-04-28 16:21:07.366419	9.6300000000000008
141	2022-04-28 16:21:07.094419	112.95999999999999
142	2022-04-28 16:21:07.528419	52.450000000000003
143	2022-04-28 16:21:07.396419	22.719999999999999
144	2022-04-28 16:21:07.838419	21.649999999999999
145	2022-04-28 16:21:07.271419	24.5
146	2022-04-28 16:21:07.718419	62.369999999999997
147	2022-04-28 16:21:07.142419	87.75
148	2022-04-28 16:21:06.410419	14.26
149	2022-04-28 16:21:06.413419	106.08
150	2022-04-28 16:21:07.166419	92.140000000000001
151	2022-04-28 16:21:07.174419	89.140000000000001
152	2022-04-28 16:21:08.094419	125.06
153	2022-04-28 16:21:07.802419	36.590000000000003
154	2022-04-28 16:21:07.044419	95.269999999999996
155	2022-04-28 16:21:07.981419	13.16
156	2022-04-28 16:21:06.590419	62.780000000000001
157	2022-04-28 16:21:06.751419	104.19
158	2022-04-28 16:21:06.914419	35.710000000000001
159	2022-04-28 16:21:06.761419	107.92
160	2022-04-28 16:21:08.046419	108.31999999999999
161	2022-04-28 16:21:07.576419	12.73
162	2022-04-28 16:21:08.072419	35.689999999999998
163	2022-04-28 16:21:06.455419	109.23
164	2022-04-28 16:21:07.770419	30.190000000000001
165	2022-04-28 16:21:06.131419	127.81999999999999
166	2022-04-28 16:21:08.290419	15.380000000000001
167	2022-04-28 16:21:07.302419	4.2199999999999998
168	2022-04-28 16:21:07.478419	137.31999999999999
169	2022-04-28 16:21:07.994419	129.38
170	2022-04-28 16:21:07.326419	65.689999999999998
171	2022-04-28 16:21:07.676419	36.420000000000002
172	2022-04-28 16:21:06.654419	78.959999999999994
173	2022-04-28 16:21:08.215419	62.060000000000002
174	2022-04-28 16:21:06.488419	113.41
175	2022-04-28 16:21:06.666419	128.59999999999999
176	2022-04-28 16:21:08.078419	62.600000000000001
177	2022-04-28 16:21:08.090419	116.15000000000001
178	2022-04-28 16:21:08.458419	60.079999999999998
179	2022-04-28 16:21:07.935419	106.31999999999999
180	2022-04-28 16:21:07.766419	15.69
181	2022-04-28 16:21:07.414419	40.130000000000003
182	2022-04-28 16:21:07.786419	4.9699999999999998
183	2022-04-28 16:21:06.515419	21.309999999999999
184	2022-04-28 16:21:08.358419	34.340000000000003
185	2022-04-28 16:21:06.521419	67.209999999999994
186	2022-04-28 16:21:07.268419	58.979999999999997
187	2022-04-28 16:21:06.714419	61.939999999999998
188	2022-04-28 16:21:06.342419	60.359999999999999
189	2022-04-28 16:21:08.234419	48.950000000000003
190	2022-04-28 16:21:06.916419	108.28
191	2022-04-28 16:21:07.685419	143.49000000000001
192	2022-04-28 16:21:06.158419	19.609999999999999
193	2022-04-28 16:21:06.352419	79.670000000000002
194	2022-04-28 16:21:06.742419	108.02
195	2022-04-28 16:21:06.356419	24.510000000000002
196	2022-04-28 16:21:06.750419	12.41
197	2022-04-28 16:21:06.754419	59.609999999999999
198	2022-04-28 16:21:08.738419	60.030000000000001
199	2022-04-28 16:21:07.757419	31.66
200	2022-04-28 16:21:07.366419	114.26000000000001
201	2022-04-28 16:21:07.574419	137.24000000000001
202	2022-04-28 16:21:07.986419	107.91
203	2022-04-28 16:21:07.387419	58.82
204	2022-04-28 16:21:06.782419	64.280000000000001
205	2022-04-28 16:21:08.221419	82.780000000000001
206	2022-04-28 16:21:07.820419	60.060000000000002
207	2022-04-28 16:21:07.415419	138.34
208	2022-04-28 16:21:07.630419	72.219999999999999
209	2022-04-28 16:21:07.011419	75.219999999999999
210	2022-04-28 16:21:08.906419	83.120000000000005
211	2022-04-28 16:21:08.709419	22.48
212	2022-04-28 16:21:06.814419	142.86000000000001
213	2022-04-28 16:21:07.031419	52.350000000000001
214	2022-04-28 16:21:06.822419	120.77
215	2022-04-28 16:21:07.471419	95.890000000000001
216	2022-04-28 16:21:08.558419	92.209999999999994
217	2022-04-28 16:21:08.787419	77.75
218	2022-04-28 16:21:06.838419	92.299999999999997
219	2022-04-28 16:21:07.280419	39.060000000000002
220	2022-04-28 16:21:08.166419	98.969999999999999
221	2022-04-28 16:21:07.292419	116.78
222	2022-04-28 16:21:06.188419	70.200000000000003
223	2022-04-28 16:21:07.973419	116.02
224	2022-04-28 16:21:08.206419	36.329999999999998
225	2022-04-28 16:21:08.891419	69.650000000000006
226	2022-04-28 16:21:06.644419	14.140000000000001
227	2022-04-28 16:21:07.101419	124.95
228	2022-04-28 16:21:08.930419	56.850000000000001
229	2022-04-28 16:21:08.485419	95.090000000000003
230	2022-04-28 16:21:07.806419	15.130000000000001
231	2022-04-28 16:21:06.890419	53.340000000000003
232	2022-04-28 16:21:09.214419	12.1
233	2022-04-28 16:21:08.529419	135.91
234	2022-04-28 16:21:07.838419	128.44999999999999
235	2022-04-28 16:21:08.551419	129.87
236	2022-04-28 16:21:06.674419	1.8799999999999999
237	2022-04-28 16:21:08.810419	40.109999999999999
238	2022-04-28 16:21:06.918419	15.380000000000001
239	2022-04-28 16:21:06.683419	103.06
240	2022-04-28 16:21:07.406419	67
\.


--
-- Data for Name: float_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_archive (key, fix, value) FROM stdin;
1	2022-04-28 16:21:05.976419	139.88
2	2022-04-28 16:21:05.994419	142.31
3	2022-04-28 16:21:05.990419	104.63
4	2022-04-28 16:21:05.990419	7.8300000000000001
5	2022-04-28 16:21:06.016419	119.87
6	2022-04-28 16:21:06.044419	102.36
7	2022-04-28 16:21:06.043419	84.769999999999996
8	2022-04-28 16:21:06.030419	144.11000000000001
9	2022-04-28 16:21:06.074419	135.69999999999999
10	2022-04-28 16:21:06.076419	96.519999999999996
11	2022-04-28 16:21:06.021419	113.78
12	2022-04-28 16:21:06.062419	143.59
13	2022-04-28 16:21:06.044419	20.870000000000001
14	2022-04-28 16:21:06.036419	144.37
15	2022-04-28 16:21:06.116419	114.51000000000001
16	2022-04-28 16:21:06.030419	8.6999999999999993
17	2022-04-28 16:21:06.051419	5.6500000000000004
18	2022-04-28 16:21:06.092419	34.619999999999997
19	2022-04-28 16:21:06.099419	1.9099999999999999
20	2022-04-28 16:21:06.146419	7.1600000000000001
21	2022-04-28 16:21:06.155419	67.230000000000004
22	2022-04-28 16:21:06.054419	133.63999999999999
23	2022-04-28 16:21:05.989419	64.310000000000002
24	2022-04-28 16:21:06.062419	38.32
25	2022-04-28 16:21:06.266419	33.450000000000003
26	2022-04-28 16:21:06.096419	30.870000000000001
27	2022-04-28 16:21:06.344419	105.81999999999999
28	2022-04-28 16:21:06.050419	132.36000000000001
29	2022-04-28 16:21:06.169419	139.74000000000001
30	2022-04-28 16:21:06.266419	55.920000000000002
31	2022-04-28 16:21:06.183419	55.259999999999998
32	2022-04-28 16:21:06.158419	125.26000000000001
33	2022-04-28 16:21:06.263419	119.62
34	2022-04-28 16:21:06.204419	108.52
35	2022-04-28 16:21:06.071419	37.630000000000003
36	2022-04-28 16:21:06.290419	118.42
37	2022-04-28 16:21:06.188419	99.019999999999996
38	2022-04-28 16:21:06.042419	121.51000000000001
39	2022-04-28 16:21:06.278419	85.200000000000003
40	2022-04-28 16:21:06.526419	130.56999999999999
41	2022-04-28 16:21:06.499419	144.63
42	2022-04-28 16:21:06.134419	61.700000000000003
43	2022-04-28 16:21:06.310419	7.1699999999999999
44	2022-04-28 16:21:06.054419	78.840000000000003
45	2022-04-28 16:21:06.551419	72.659999999999997
46	2022-04-28 16:21:06.472419	66.299999999999997
47	2022-04-28 16:21:06.248419	27.16
48	2022-04-28 16:21:06.398419	28.789999999999999
49	2022-04-28 16:21:06.064419	55.32
50	2022-04-28 16:21:06.266419	29.710000000000001
51	2022-04-28 16:21:06.017419	71.090000000000003
52	2022-04-28 16:21:06.070419	78.010000000000005
53	2022-04-28 16:21:06.496419	68.519999999999996
54	2022-04-28 16:21:06.614419	45.619999999999997
55	2022-04-28 16:21:06.461419	48.649999999999999
56	2022-04-28 16:21:06.302419	127.75
57	2022-04-28 16:21:06.764419	108.76000000000001
58	2022-04-28 16:21:06.372419	68.950000000000003
59	2022-04-28 16:21:06.143419	142.86000000000001
60	2022-04-28 16:21:06.326419	78.299999999999997
61	2022-04-28 16:21:06.637419	130.77000000000001
62	2022-04-28 16:21:06.772419	98.989999999999995
63	2022-04-28 16:21:06.470419	19.539999999999999
64	2022-04-28 16:21:06.414419	29.109999999999999
65	2022-04-28 16:21:06.161419	131.44999999999999
66	2022-04-28 16:21:06.692419	25.649999999999999
67	2022-04-28 16:21:06.234419	112.33
68	2022-04-28 16:21:06.850419	62.079999999999998
69	2022-04-28 16:21:06.863419	98.489999999999995
70	2022-04-28 16:21:06.736419	6.8099999999999996
71	2022-04-28 16:21:06.250419	110.33
72	2022-04-28 16:21:06.902419	78.739999999999995
73	2022-04-28 16:21:06.185419	129.96000000000001
74	2022-04-28 16:21:06.484419	89.849999999999994
75	2022-04-28 16:21:06.791419	16.539999999999999
76	2022-04-28 16:21:06.118419	11.699999999999999
77	2022-04-28 16:21:06.043419	117.64
78	2022-04-28 16:21:06.512419	15.84
79	2022-04-28 16:21:06.677419	59.579999999999998
80	2022-04-28 16:21:06.126419	75.840000000000003
81	2022-04-28 16:21:06.047419	93.260000000000005
82	2022-04-28 16:21:06.294419	106.03
83	2022-04-28 16:21:06.630419	29.379999999999999
84	2022-04-28 16:21:06.806419	33.140000000000001
85	2022-04-28 16:21:06.986419	8.4499999999999993
86	2022-04-28 16:21:06.740419	72.170000000000002
87	2022-04-28 16:21:06.314419	46.759999999999998
88	2022-04-28 16:21:06.406419	145.22999999999999
89	2022-04-28 16:21:07.212419	50.159999999999997
90	2022-04-28 16:21:06.686419	85.989999999999995
91	2022-04-28 16:21:06.876419	121.86
92	2022-04-28 16:21:06.702419	144.77000000000001
93	2022-04-28 16:21:07.175419	103.02
94	2022-04-28 16:21:06.248419	63.520000000000003
95	2022-04-28 16:21:06.536419	115.89
96	2022-04-28 16:21:07.118419	74.25
97	2022-04-28 16:21:06.839419	38.259999999999998
98	2022-04-28 16:21:06.162419	83.430000000000007
99	2022-04-28 16:21:06.758419	27.23
100	2022-04-28 16:21:07.366419	136.00999999999999
101	2022-04-28 16:21:06.471419	35.460000000000001
102	2022-04-28 16:21:07.088419	95.950000000000003
103	2022-04-28 16:21:06.790419	77.849999999999994
104	2022-04-28 16:21:07.318419	102.76000000000001
105	2022-04-28 16:21:06.806419	64.939999999999998
106	2022-04-28 16:21:06.284419	39.799999999999997
107	2022-04-28 16:21:07.250419	67.969999999999999
108	2022-04-28 16:21:07.262419	26.850000000000001
109	2022-04-28 16:21:06.293419	31.440000000000001
110	2022-04-28 16:21:07.286419	122.81
111	2022-04-28 16:21:06.188419	30.850000000000001
112	2022-04-28 16:21:07.422419	8.9100000000000001
113	2022-04-28 16:21:06.418419	8.6400000000000006
114	2022-04-28 16:21:07.448419	138.28
115	2022-04-28 16:21:06.541419	110.06999999999999
116	2022-04-28 16:21:06.778419	118.04000000000001
117	2022-04-28 16:21:06.668419	89.480000000000004
118	2022-04-28 16:21:06.674419	63.25
119	2022-04-28 16:21:06.204419	120.66
120	2022-04-28 16:21:06.806419	51.350000000000001
121	2022-04-28 16:21:07.418419	65.269999999999996
122	2022-04-28 16:21:07.674419	129.12
123	2022-04-28 16:21:07.196419	80.090000000000003
124	2022-04-28 16:21:07.206419	24.329999999999998
125	2022-04-28 16:21:06.841419	123.15000000000001
126	2022-04-28 16:21:06.848419	50.450000000000003
127	2022-04-28 16:21:06.728419	22
128	2022-04-28 16:21:07.630419	8.3900000000000006
129	2022-04-28 16:21:06.740419	103.90000000000001
130	2022-04-28 16:21:06.876419	72.780000000000001
131	2022-04-28 16:21:07.276419	132.90000000000001
132	2022-04-28 16:21:06.890419	105.95999999999999
133	2022-04-28 16:21:07.828419	44.420000000000002
134	2022-04-28 16:21:07.708419	36.5
135	2022-04-28 16:21:06.371419	61.649999999999999
136	2022-04-28 16:21:06.374419	47.890000000000001
137	2022-04-28 16:21:07.473419	73.260000000000005
138	2022-04-28 16:21:06.104419	87.980000000000004
139	2022-04-28 16:21:06.661419	1.8700000000000001
140	2022-04-28 16:21:06.806419	100.37
141	2022-04-28 16:21:06.812419	103.31
142	2022-04-28 16:21:07.102419	65.510000000000005
143	2022-04-28 16:21:06.824419	16.539999999999999
144	2022-04-28 16:21:06.974419	31.120000000000001
145	2022-04-28 16:21:07.561419	42.020000000000003
146	2022-04-28 16:21:06.258419	52.920000000000002
147	2022-04-28 16:21:06.995419	138.34
148	2022-04-28 16:21:07.446419	134.96000000000001
149	2022-04-28 16:21:06.264419	33.43
150	2022-04-28 16:21:07.916419	56.770000000000003
151	2022-04-28 16:21:07.476419	59.530000000000001
152	2022-04-28 16:21:06.270419	143.59999999999999
153	2022-04-28 16:21:07.649419	14.77
154	2022-04-28 16:21:07.352419	121.28
155	2022-04-28 16:21:06.431419	42.560000000000002
156	2022-04-28 16:21:07.838419	50.390000000000001
157	2022-04-28 16:21:06.908419	107.02
158	2022-04-28 16:21:06.282419	138.80000000000001
159	2022-04-28 16:21:06.920419	140.47999999999999
160	2022-04-28 16:21:06.926419	129.18000000000001
161	2022-04-28 16:21:07.898419	103.33
162	2022-04-28 16:21:07.262419	123.31
163	2022-04-28 16:21:06.944419	109.01000000000001
164	2022-04-28 16:21:08.098419	118.02
165	2022-04-28 16:21:07.946419	11.869999999999999
166	2022-04-28 16:21:07.460419	5.7999999999999998
167	2022-04-28 16:21:06.467419	142.84999999999999
168	2022-04-28 16:21:06.302419	144.97
169	2022-04-28 16:21:07.656419	81.329999999999998
170	2022-04-28 16:21:07.666419	36.289999999999999
171	2022-04-28 16:21:07.334419	94.129999999999995
172	2022-04-28 16:21:06.310419	64.159999999999997
173	2022-04-28 16:21:07.350419	108.38
174	2022-04-28 16:21:06.140419	98.159999999999997
175	2022-04-28 16:21:08.066419	106.47
176	2022-04-28 16:21:07.550419	10.699999999999999
177	2022-04-28 16:21:08.090419	1.99
178	2022-04-28 16:21:07.568419	134.21000000000001
179	2022-04-28 16:21:08.293419	27.59
180	2022-04-28 16:21:07.766419	144.12
181	2022-04-28 16:21:06.690419	112.09999999999999
182	2022-04-28 16:21:06.148419	11.06
183	2022-04-28 16:21:07.979419	111.12
184	2022-04-28 16:21:06.702419	53.329999999999998
185	2022-04-28 16:21:07.816419	15.210000000000001
186	2022-04-28 16:21:06.896419	118.55
187	2022-04-28 16:21:06.901419	22.239999999999998
188	2022-04-28 16:21:07.094419	26.780000000000001
189	2022-04-28 16:21:07.856419	13.4
190	2022-04-28 16:21:07.106419	86.409999999999997
191	2022-04-28 16:21:08.067419	36.450000000000003
192	2022-04-28 16:21:08.654419	13.42
193	2022-04-28 16:21:07.510419	73.870000000000005
194	2022-04-28 16:21:06.742419	16.48
195	2022-04-28 16:21:07.331419	20.510000000000002
196	2022-04-28 16:21:06.554419	72.590000000000003
197	2022-04-28 16:21:08.527419	104.29000000000001
198	2022-04-28 16:21:06.362419	110.34
199	2022-04-28 16:21:07.757419	144.88999999999999
200	2022-04-28 16:21:08.166419	105.87
201	2022-04-28 16:21:07.574419	95.310000000000002
202	2022-04-28 16:21:08.794419	110.72
203	2022-04-28 16:21:07.387419	108.44
204	2022-04-28 16:21:08.414419	100.42
205	2022-04-28 16:21:08.016419	56.850000000000001
206	2022-04-28 16:21:06.996419	116.34
207	2022-04-28 16:21:08.450419	10.17
208	2022-04-28 16:21:07.006419	135.59999999999999
209	2022-04-28 16:21:08.474419	135.74000000000001
210	2022-04-28 16:21:07.646419	31.890000000000001
211	2022-04-28 16:21:07.865419	19.079999999999998
212	2022-04-28 16:21:08.934419	79.560000000000002
213	2022-04-28 16:21:08.948419	113.8
214	2022-04-28 16:21:08.748419	79.680000000000007
215	2022-04-28 16:21:06.396419	88.280000000000001
216	2022-04-28 16:21:07.694419	94.379999999999995
217	2022-04-28 16:21:07.268419	92.349999999999994
218	2022-04-28 16:21:06.402419	12.84
219	2022-04-28 16:21:06.842419	29.140000000000001
220	2022-04-28 16:21:07.946419	112.47
221	2022-04-28 16:21:08.176419	74.620000000000005
222	2022-04-28 16:21:07.520419	6.0199999999999996
223	2022-04-28 16:21:08.642419	46.659999999999997
224	2022-04-28 16:21:08.206419	122.34
225	2022-04-28 16:21:07.541419	20.530000000000001
226	2022-04-28 16:21:09.130419	101.13
227	2022-04-28 16:21:07.555419	74.269999999999996
228	2022-04-28 16:21:06.650419	57.380000000000003
229	2022-04-28 16:21:08.485419	66.299999999999997
230	2022-04-28 16:21:08.496419	98.180000000000007
231	2022-04-28 16:21:08.738419	38.950000000000003
232	2022-04-28 16:21:08.054419	6.9800000000000004
233	2022-04-28 16:21:08.762419	92.459999999999994
234	2022-04-28 16:21:07.604419	28.920000000000002
235	2022-04-28 16:21:09.256419	26.780000000000001
236	2022-04-28 16:21:08.326419	90.870000000000005
237	2022-04-28 16:21:07.151419	113.70999999999999
238	2022-04-28 16:21:07.870419	9.2400000000000002
239	2022-04-28 16:21:08.356419	132.22
240	2022-04-28 16:21:08.366419	97.450000000000003
1	2022-04-28 16:21:05.969419	11.460000000000001
2	2022-04-28 16:21:05.970419	137.47999999999999
3	2022-04-28 16:21:05.996419	124.8
4	2022-04-28 16:21:05.982419	124.87
5	2022-04-28 16:21:06.001419	100.34
6	2022-04-28 16:21:06.002419	116.2
7	2022-04-28 16:21:06.015419	139.28
8	2022-04-28 16:21:06.078419	64.069999999999993
9	2022-04-28 16:21:06.083419	62
10	2022-04-28 16:21:06.006419	33.109999999999999
11	2022-04-28 16:21:06.109419	70.170000000000002
12	2022-04-28 16:21:06.110419	41.539999999999999
13	2022-04-28 16:21:06.057419	47.229999999999997
14	2022-04-28 16:21:06.050419	96.909999999999997
15	2022-04-28 16:21:06.176419	16.43
16	2022-04-28 16:21:06.142419	116.75
17	2022-04-28 16:21:06.153419	16.920000000000002
18	2022-04-28 16:21:06.128419	110.95
19	2022-04-28 16:21:06.042419	96.819999999999993
20	2022-04-28 16:21:06.086419	142.13999999999999
21	2022-04-28 16:21:06.113419	84.219999999999999
22	2022-04-28 16:21:06.208419	44.020000000000003
23	2022-04-28 16:21:06.242419	128.81
24	2022-04-28 16:21:06.062419	50.890000000000001
25	2022-04-28 16:21:06.266419	12.58
26	2022-04-28 16:21:06.044419	35.880000000000003
27	2022-04-28 16:21:06.263419	68.650000000000006
28	2022-04-28 16:21:06.302419	92.299999999999997
29	2022-04-28 16:21:06.082419	117.59
30	2022-04-28 16:21:06.206419	50.719999999999999
31	2022-04-28 16:21:06.183419	78.75
32	2022-04-28 16:21:06.382419	53.899999999999999
33	2022-04-28 16:21:06.428419	83.150000000000006
34	2022-04-28 16:21:06.034419	45.609999999999999
35	2022-04-28 16:21:06.176419	26.879999999999999
36	2022-04-28 16:21:06.146419	35.390000000000001
37	2022-04-28 16:21:06.040419	32.960000000000001
38	2022-04-28 16:21:06.422419	45.229999999999997
39	2022-04-28 16:21:06.395419	81.739999999999995
40	2022-04-28 16:21:06.246419	82.739999999999995
41	2022-04-28 16:21:06.089419	7.8399999999999999
42	2022-04-28 16:21:06.470419	132.81
43	2022-04-28 16:21:06.568419	71.400000000000006
44	2022-04-28 16:21:06.054419	43.649999999999999
45	2022-04-28 16:21:06.191419	135.31
46	2022-04-28 16:21:06.334419	54.130000000000003
47	2022-04-28 16:21:06.107419	6.0800000000000001
48	2022-04-28 16:21:06.350419	129.94
49	2022-04-28 16:21:06.505419	52.460000000000001
50	2022-04-28 16:21:06.266419	35.630000000000003
51	2022-04-28 16:21:06.578419	130.5
52	2022-04-28 16:21:06.694419	96.769999999999996
53	2022-04-28 16:21:06.602419	133.53999999999999
54	2022-04-28 16:21:06.182419	71.930000000000007
55	2022-04-28 16:21:06.516419	70.540000000000006
56	2022-04-28 16:21:06.694419	95.870000000000005
57	2022-04-28 16:21:06.308419	135.09999999999999
58	2022-04-28 16:21:06.198419	61.880000000000003
59	2022-04-28 16:21:06.615419	138.58000000000001
60	2022-04-28 16:21:06.386419	69.430000000000007
61	2022-04-28 16:21:06.393419	108.01000000000001
62	2022-04-28 16:21:06.834419	68.260000000000005
63	2022-04-28 16:21:06.596419	130.13
64	2022-04-28 16:21:06.094419	2.75
65	2022-04-28 16:21:06.681419	130.50999999999999
66	2022-04-28 16:21:06.560419	59.119999999999997
67	2022-04-28 16:21:06.234419	34.899999999999999
68	2022-04-28 16:21:06.714419	32.520000000000003
69	2022-04-28 16:21:06.104419	24.260000000000002
70	2022-04-28 16:21:06.106419	5.8700000000000001
71	2022-04-28 16:21:06.321419	87.700000000000003
72	2022-04-28 16:21:06.614419	122.52
73	2022-04-28 16:21:06.112419	129.38
74	2022-04-28 16:21:06.114419	35.789999999999999
75	2022-04-28 16:21:06.866419	14.19
76	2022-04-28 16:21:06.270419	110.29000000000001
77	2022-04-28 16:21:07.044419	125.66
78	2022-04-28 16:21:06.824419	16.899999999999999
79	2022-04-28 16:21:06.993419	70.959999999999994
80	2022-04-28 16:21:06.126419	134.22999999999999
81	2022-04-28 16:21:06.938419	27.93
82	2022-04-28 16:21:06.868419	113.72
83	2022-04-28 16:21:07.045419	69.370000000000005
84	2022-04-28 16:21:06.554419	15.800000000000001
85	2022-04-28 16:21:06.306419	2.96
86	2022-04-28 16:21:06.396419	81.239999999999995
87	2022-04-28 16:21:07.010419	56.399999999999999
88	2022-04-28 16:21:06.318419	127.72
89	2022-04-28 16:21:06.233419	21.940000000000001
90	2022-04-28 16:21:06.596419	108.28
91	2022-04-28 16:21:07.149419	120.61
92	2022-04-28 16:21:06.334419	90.480000000000004
93	2022-04-28 16:21:06.989419	122.11
94	2022-04-28 16:21:06.624419	52.890000000000001
95	2022-04-28 16:21:06.631419	88.700000000000003
96	2022-04-28 16:21:06.446419	89.560000000000002
97	2022-04-28 16:21:06.257419	26.120000000000001
98	2022-04-28 16:21:06.358419	16.43
99	2022-04-28 16:21:07.154419	121.73
100	2022-04-28 16:21:07.366419	85.219999999999999
101	2022-04-28 16:21:06.673419	135.40000000000001
102	2022-04-28 16:21:06.170419	115.42
103	2022-04-28 16:21:07.099419	90.980000000000004
104	2022-04-28 16:21:07.318419	81.560000000000002
105	2022-04-28 16:21:07.016419	128.52000000000001
106	2022-04-28 16:21:07.450419	111.88
107	2022-04-28 16:21:06.180419	42.729999999999997
108	2022-04-28 16:21:06.182419	4.2999999999999998
109	2022-04-28 16:21:07.492419	24.559999999999999
110	2022-04-28 16:21:06.186419	7.9400000000000004
111	2022-04-28 16:21:06.077419	12.19
112	2022-04-28 16:21:06.974419	88.579999999999998
113	2022-04-28 16:21:07.096419	103.7
114	2022-04-28 16:21:06.764419	99.879999999999995
115	2022-04-28 16:21:06.426419	12.279999999999999
116	2022-04-28 16:21:06.198419	42.729999999999997
117	2022-04-28 16:21:06.434419	120.34999999999999
118	2022-04-28 16:21:06.556419	135.43000000000001
119	2022-04-28 16:21:07.394419	60.859999999999999
120	2022-04-28 16:21:07.406419	15.09
121	2022-04-28 16:21:07.660419	131.49000000000001
122	2022-04-28 16:21:07.186419	86.159999999999997
123	2022-04-28 16:21:07.073419	78.730000000000004
124	2022-04-28 16:21:06.958419	122.41
125	2022-04-28 16:21:06.341419	24.43
126	2022-04-28 16:21:06.344419	95.870000000000005
127	2022-04-28 16:21:07.363419	132.31
128	2022-04-28 16:21:07.118419	55.740000000000002
129	2022-04-28 16:21:06.611419	61.840000000000003
130	2022-04-28 16:21:06.226419	9.1199999999999992
131	2022-04-28 16:21:06.490419	32.170000000000002
132	2022-04-28 16:21:06.758419	88.310000000000002
133	2022-04-28 16:21:07.562419	101.59999999999999
134	2022-04-28 16:21:07.172419	36.939999999999998
135	2022-04-28 16:21:07.856419	19.870000000000001
136	2022-04-28 16:21:06.510419	82.700000000000003
137	2022-04-28 16:21:06.651419	140.34
138	2022-04-28 16:21:06.380419	16.73
139	2022-04-28 16:21:06.800419	6.8499999999999996
140	2022-04-28 16:21:07.926419	25.52
141	2022-04-28 16:21:06.389419	85.579999999999998
142	2022-04-28 16:21:07.244419	6.8899999999999997
143	2022-04-28 16:21:07.968419	59.189999999999998
144	2022-04-28 16:21:07.118419	41.280000000000001
145	2022-04-28 16:21:06.691419	132.38
146	2022-04-28 16:21:07.280419	56.130000000000003
147	2022-04-28 16:21:06.848419	116.3
148	2022-04-28 16:21:07.890419	105.65000000000001
149	2022-04-28 16:21:07.158419	11.77
150	2022-04-28 16:21:07.616419	134.66
151	2022-04-28 16:21:08.080419	43.100000000000001
152	2022-04-28 16:21:07.790419	142.84
153	2022-04-28 16:21:08.108419	82.079999999999998
154	2022-04-28 16:21:06.890419	117.86
155	2022-04-28 16:21:07.826419	68.040000000000006
156	2022-04-28 16:21:08.150419	39.170000000000002
157	2022-04-28 16:21:07.065419	133.43000000000001
158	2022-04-28 16:21:08.020419	89.299999999999997
159	2022-04-28 16:21:07.556419	46.990000000000002
160	2022-04-28 16:21:07.566419	62.030000000000001
161	2022-04-28 16:21:06.610419	44.780000000000001
162	2022-04-28 16:21:08.234419	14.140000000000001
163	2022-04-28 16:21:07.270419	122.11
164	2022-04-28 16:21:06.622419	74.739999999999995
165	2022-04-28 16:21:06.296419	56.359999999999999
166	2022-04-28 16:21:07.460419	48.119999999999997
167	2022-04-28 16:21:06.801419	9.5600000000000005
168	2022-04-28 16:21:06.638419	128.31999999999999
169	2022-04-28 16:21:07.825419	86.230000000000004
170	2022-04-28 16:21:06.476419	57.32
171	2022-04-28 16:21:06.308419	102.7
172	2022-04-28 16:21:07.170419	115.31
173	2022-04-28 16:21:08.215419	53.880000000000003
174	2022-04-28 16:21:08.402419	60.390000000000001
175	2022-04-28 16:21:08.241419	42.789999999999999
176	2022-04-28 16:21:06.318419	34.259999999999998
177	2022-04-28 16:21:07.205419	50.68
178	2022-04-28 16:21:07.924419	95.659999999999997
179	2022-04-28 16:21:06.861419	109.52
180	2022-04-28 16:21:07.406419	15.99
181	2022-04-28 16:21:06.871419	122
182	2022-04-28 16:21:07.968419	61.700000000000003
183	2022-04-28 16:21:08.345419	95.5
184	2022-04-28 16:21:08.542419	55.840000000000003
185	2022-04-28 16:21:07.816419	1.27
186	2022-04-28 16:21:08.384419	8.7699999999999996
187	2022-04-28 16:21:06.714419	39.350000000000001
188	2022-04-28 16:21:07.094419	70.239999999999995
189	2022-04-28 16:21:08.234419	30.18
190	2022-04-28 16:21:06.536419	20.710000000000001
191	2022-04-28 16:21:08.449419	120.40000000000001
192	2022-04-28 16:21:07.694419	113.22
193	2022-04-28 16:21:06.931419	48.990000000000002
194	2022-04-28 16:21:08.488419	135.37
195	2022-04-28 16:21:06.941419	81.310000000000002
196	2022-04-28 16:21:07.730419	144.30000000000001
197	2022-04-28 16:21:06.557419	144.69999999999999
198	2022-04-28 16:21:06.362419	32.369999999999997
199	2022-04-28 16:21:08.752419	9.2799999999999994
200	2022-04-28 16:21:08.566419	41.030000000000001
201	2022-04-28 16:21:07.172419	82.670000000000002
202	2022-04-28 16:21:07.986419	133.21000000000001
203	2022-04-28 16:21:07.387419	5.5199999999999996
204	2022-04-28 16:21:06.170419	23.510000000000002
205	2022-04-28 16:21:08.836419	39.25
206	2022-04-28 16:21:08.438419	15.210000000000001
207	2022-04-28 16:21:07.829419	51.189999999999998
208	2022-04-28 16:21:06.798419	72.799999999999997
209	2022-04-28 16:21:06.802419	140.53
210	2022-04-28 16:21:06.596419	83.579999999999998
211	2022-04-28 16:21:08.287419	9.6600000000000001
212	2022-04-28 16:21:06.390419	22.91
213	2022-04-28 16:21:07.457419	127.22
214	2022-04-28 16:21:08.962419	33.5
215	2022-04-28 16:21:06.826419	23.079999999999998
216	2022-04-28 16:21:07.694419	112.29000000000001
217	2022-04-28 16:21:07.051419	128.47999999999999
218	2022-04-28 16:21:08.364419	48.700000000000003
219	2022-04-28 16:21:06.623419	98.939999999999998
220	2022-04-28 16:21:07.286419	40.189999999999998
221	2022-04-28 16:21:07.071419	109.51000000000001
222	2022-04-28 16:21:09.074419	8.5899999999999999
223	2022-04-28 16:21:08.419419	71.370000000000005
224	2022-04-28 16:21:07.310419	110.92
225	2022-04-28 16:21:08.666419	83.219999999999999
226	2022-04-28 16:21:09.130419	144.44
227	2022-04-28 16:21:09.144419	46.920000000000002
228	2022-04-28 16:21:07.790419	46.960000000000001
229	2022-04-28 16:21:07.798419	81.030000000000001
230	2022-04-28 16:21:07.806419	80.090000000000003
231	2022-04-28 16:21:06.428419	114.45
232	2022-04-28 16:21:09.214419	119.93000000000001
233	2022-04-28 16:21:08.529419	9.5700000000000003
234	2022-04-28 16:21:08.774419	103.43000000000001
235	2022-04-28 16:21:08.081419	127.81999999999999
236	2022-04-28 16:21:07.382419	82.799999999999997
237	2022-04-28 16:21:08.099419	123.56
238	2022-04-28 16:21:06.918419	144.87
239	2022-04-28 16:21:06.683419	3.04
240	2022-04-28 16:21:07.646419	135.22
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
1	2022-04-28 16:21:05.973419	28
2	2022-04-28 16:21:05.980419	92
3	2022-04-28 16:21:05.978419	77
4	2022-04-28 16:21:06.014419	145
5	2022-04-28 16:21:05.996419	65
6	2022-04-28 16:21:06.038419	83
7	2022-04-28 16:21:05.994419	118
8	2022-04-28 16:21:05.998419	78
9	2022-04-28 16:21:06.074419	20
10	2022-04-28 16:21:06.016419	98
11	2022-04-28 16:21:06.076419	101
12	2022-04-28 16:21:06.002419	132
13	2022-04-28 16:21:06.018419	60
14	2022-04-28 16:21:06.050419	14
15	2022-04-28 16:21:05.996419	78
16	2022-04-28 16:21:06.030419	72
17	2022-04-28 16:21:06.017419	83
18	2022-04-28 16:21:06.002419	131
19	2022-04-28 16:21:06.080419	48
20	2022-04-28 16:21:06.166419	33
21	2022-04-28 16:21:06.050419	115
22	2022-04-28 16:21:06.098419	22
23	2022-04-28 16:21:06.012419	117
24	2022-04-28 16:21:06.110419	117
25	2022-04-28 16:21:06.216419	104
26	2022-04-28 16:21:06.070419	141
27	2022-04-28 16:21:06.236419	110
28	2022-04-28 16:21:06.078419	114
29	2022-04-28 16:21:05.995419	77
30	2022-04-28 16:21:06.176419	113
31	2022-04-28 16:21:06.059419	109
32	2022-04-28 16:21:06.382419	120
33	2022-04-28 16:21:06.098419	50
34	2022-04-28 16:21:06.204419	89
35	2022-04-28 16:21:06.351419	42
36	2022-04-28 16:21:06.110419	69
37	2022-04-28 16:21:06.262419	14
38	2022-04-28 16:21:06.232419	133
39	2022-04-28 16:21:06.200419	5
40	2022-04-28 16:21:06.446419	57
41	2022-04-28 16:21:06.007419	85
42	2022-04-28 16:21:06.260419	52
43	2022-04-28 16:21:06.224419	36
44	2022-04-28 16:21:06.450419	55
45	2022-04-28 16:21:06.236419	43
46	2022-04-28 16:21:06.564419	120
47	2022-04-28 16:21:06.577419	127
48	2022-04-28 16:21:06.062419	70
49	2022-04-28 16:21:06.603419	78
50	2022-04-28 16:21:06.616419	104
51	2022-04-28 16:21:06.272419	113
52	2022-04-28 16:21:06.070419	56
53	2022-04-28 16:21:06.390419	107
54	2022-04-28 16:21:06.398419	91
55	2022-04-28 16:21:06.241419	47
56	2022-04-28 16:21:06.358419	143
57	2022-04-28 16:21:06.536419	8
58	2022-04-28 16:21:06.604419	82
59	2022-04-28 16:21:06.261419	84
60	2022-04-28 16:21:06.446419	143
61	2022-04-28 16:21:06.515419	10
62	2022-04-28 16:21:06.276419	65
63	2022-04-28 16:21:06.344419	54
64	2022-04-28 16:21:06.542419	90
65	2022-04-28 16:21:06.031419	141
66	2022-04-28 16:21:06.098419	117
67	2022-04-28 16:21:06.167419	23
68	2022-04-28 16:21:06.102419	36
69	2022-04-28 16:21:06.518419	7
70	2022-04-28 16:21:06.806419	88
71	2022-04-28 16:21:06.747419	24
72	2022-04-28 16:21:06.110419	5
73	2022-04-28 16:21:06.842419	132
74	2022-04-28 16:21:06.188419	123
75	2022-04-28 16:21:06.191419	76
76	2022-04-28 16:21:06.194419	43
77	2022-04-28 16:21:06.120419	136
78	2022-04-28 16:21:06.200419	45
79	2022-04-28 16:21:06.598419	91
80	2022-04-28 16:21:07.086419	25
81	2022-04-28 16:21:06.209419	126
82	2022-04-28 16:21:06.704419	50
83	2022-04-28 16:21:06.381419	93
84	2022-04-28 16:21:07.058419	76
85	2022-04-28 16:21:06.136419	75
86	2022-04-28 16:21:06.138419	41
87	2022-04-28 16:21:06.923419	130
88	2022-04-28 16:21:06.318419	59
89	2022-04-28 16:21:07.212419	36
90	2022-04-28 16:21:06.776419	71
91	2022-04-28 16:21:06.330419	107
92	2022-04-28 16:21:06.702419	72
93	2022-04-28 16:21:07.082419	111
94	2022-04-28 16:21:07.000419	27
95	2022-04-28 16:21:07.296419	105
96	2022-04-28 16:21:07.022419	129
97	2022-04-28 16:21:06.160419	97
98	2022-04-28 16:21:06.652419	130
99	2022-04-28 16:21:06.758419	106
100	2022-04-28 16:21:07.066419	31
101	2022-04-28 16:21:06.168419	93
102	2022-04-28 16:21:07.190419	88
103	2022-04-28 16:21:06.687419	128
104	2022-04-28 16:21:06.798419	22
105	2022-04-28 16:21:07.016419	110
106	2022-04-28 16:21:06.496419	40
107	2022-04-28 16:21:06.180419	75
108	2022-04-28 16:21:07.478419	62
109	2022-04-28 16:21:06.620419	19
110	2022-04-28 16:21:06.846419	74
111	2022-04-28 16:21:07.409419	101
112	2022-04-28 16:21:06.862419	45
113	2022-04-28 16:21:07.322419	25
114	2022-04-28 16:21:06.422419	13
115	2022-04-28 16:21:06.771419	49
116	2022-04-28 16:21:07.358419	40
117	2022-04-28 16:21:06.902419	58
118	2022-04-28 16:21:06.792419	84
119	2022-04-28 16:21:07.513419	131
120	2022-04-28 16:21:06.206419	136
121	2022-04-28 16:21:06.450419	91
122	2022-04-28 16:21:06.820419	36
123	2022-04-28 16:21:06.827419	68
124	2022-04-28 16:21:07.578419	80
125	2022-04-28 16:21:07.341419	5
126	2022-04-28 16:21:06.974419	62
127	2022-04-28 16:21:06.474419	39
128	2022-04-28 16:21:06.734419	51
129	2022-04-28 16:21:06.353419	76
130	2022-04-28 16:21:07.526419	45
131	2022-04-28 16:21:07.276419	67
132	2022-04-28 16:21:07.286419	55
133	2022-04-28 16:21:07.695419	7
134	2022-04-28 16:21:07.574419	93
135	2022-04-28 16:21:06.236419	55
136	2022-04-28 16:21:07.054419	68
137	2022-04-28 16:21:06.377419	87
138	2022-04-28 16:21:06.656419	36
139	2022-04-28 16:21:06.522419	42
140	2022-04-28 16:21:07.786419	48
141	2022-04-28 16:21:06.671419	99
142	2022-04-28 16:21:06.818419	62
143	2022-04-28 16:21:07.682419	63
144	2022-04-28 16:21:06.254419	33
145	2022-04-28 16:21:06.256419	15
146	2022-04-28 16:21:06.988419	57
147	2022-04-28 16:21:06.260419	105
148	2022-04-28 16:21:06.706419	111
149	2022-04-28 16:21:07.903419	15
150	2022-04-28 16:21:06.866419	55
151	2022-04-28 16:21:07.476419	34
152	2022-04-28 16:21:07.182419	50
153	2022-04-28 16:21:07.190419	11
154	2022-04-28 16:21:06.736419	88
155	2022-04-28 16:21:08.136419	15
156	2022-04-28 16:21:06.434419	121
157	2022-04-28 16:21:07.379419	72
158	2022-04-28 16:21:06.124419	141
159	2022-04-28 16:21:06.284419	41
160	2022-04-28 16:21:07.406419	69
161	2022-04-28 16:21:08.220419	83
162	2022-04-28 16:21:07.424419	141
163	2022-04-28 16:21:08.085419	19
164	2022-04-28 16:21:06.950419	56
165	2022-04-28 16:21:06.791419	76
166	2022-04-28 16:21:06.796419	19
167	2022-04-28 16:21:08.304419	77
168	2022-04-28 16:21:07.646419	12
169	2022-04-28 16:21:06.642419	6
170	2022-04-28 16:21:08.176419	108
171	2022-04-28 16:21:06.479419	68
172	2022-04-28 16:21:06.654419	140
173	2022-04-28 16:21:08.388419	93
174	2022-04-28 16:21:07.880419	86
175	2022-04-28 16:21:07.891419	46
176	2022-04-28 16:21:07.726419	96
177	2022-04-28 16:21:07.382419	126
178	2022-04-28 16:21:07.212419	16
179	2022-04-28 16:21:07.756419	75
180	2022-04-28 16:21:07.226419	59
181	2022-04-28 16:21:07.776419	136
182	2022-04-28 16:21:06.876419	68
183	2022-04-28 16:21:07.979419	145
184	2022-04-28 16:21:08.358419	16
185	2022-04-28 16:21:08.186419	136
186	2022-04-28 16:21:08.012419	10
187	2022-04-28 16:21:07.088419	120
188	2022-04-28 16:21:07.094419	73
189	2022-04-28 16:21:07.100419	91
190	2022-04-28 16:21:08.626419	41
191	2022-04-28 16:21:07.112419	115
192	2022-04-28 16:21:07.886419	145
193	2022-04-28 16:21:08.282419	96
194	2022-04-28 16:21:07.712419	13
195	2022-04-28 16:21:06.551419	81
196	2022-04-28 16:21:07.338419	101
197	2022-04-28 16:21:07.739419	74
198	2022-04-28 16:21:06.362419	26
199	2022-04-28 16:21:06.563419	113
200	2022-04-28 16:21:06.766419	142
201	2022-04-28 16:21:08.177419	96
202	2022-04-28 16:21:08.188419	114
203	2022-04-28 16:21:07.590419	90
204	2022-04-28 16:21:06.986419	103
205	2022-04-28 16:21:07.606419	131
206	2022-04-28 16:21:08.232419	5
207	2022-04-28 16:21:07.622419	23
208	2022-04-28 16:21:06.382419	130
209	2022-04-28 16:21:07.011419	45
210	2022-04-28 16:21:07.856419	19
211	2022-04-28 16:21:07.232419	117
212	2022-04-28 16:21:08.934419	43
213	2022-04-28 16:21:07.670419	13
214	2022-04-28 16:21:07.464419	126
215	2022-04-28 16:21:08.331419	29
216	2022-04-28 16:21:07.262419	81
217	2022-04-28 16:21:07.485419	3
218	2022-04-28 16:21:07.710419	102
219	2022-04-28 16:21:06.404419	130
220	2022-04-28 16:21:07.506419	34
221	2022-04-28 16:21:07.292419	130
222	2022-04-28 16:21:07.964419	33
223	2022-04-28 16:21:08.419419	59
224	2022-04-28 16:21:06.862419	66
225	2022-04-28 16:21:07.541419	24
226	2022-04-28 16:21:08.904419	126
227	2022-04-28 16:21:06.647419	9
228	2022-04-28 16:21:08.018419	138
229	2022-04-28 16:21:08.256419	68
230	2022-04-28 16:21:07.116419	67
231	2022-04-28 16:21:06.659419	62
232	2022-04-28 16:21:08.982419	46
233	2022-04-28 16:21:08.063419	33
234	2022-04-28 16:21:08.072419	73
235	2022-04-28 16:21:08.316419	50
236	2022-04-28 16:21:08.798419	56
237	2022-04-28 16:21:08.810419	59
238	2022-04-28 16:21:08.584419	75
239	2022-04-28 16:21:06.922419	112
240	2022-04-28 16:21:07.886419	16
\.


--
-- Data for Name: integer_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_archive (key, fix, value) FROM stdin;
1	2022-04-28 16:21:05.979419	2
2	2022-04-28 16:21:05.978419	89
3	2022-04-28 16:21:05.981419	68
4	2022-04-28 16:21:05.990419	57
5	2022-04-28 16:21:06.001419	84
6	2022-04-28 16:21:05.978419	85
7	2022-04-28 16:21:06.029419	145
8	2022-04-28 16:21:05.982419	138
9	2022-04-28 16:21:06.092419	39
10	2022-04-28 16:21:06.066419	81
11	2022-04-28 16:21:06.098419	99
12	2022-04-28 16:21:06.110419	20
13	2022-04-28 16:21:06.031419	77
14	2022-04-28 16:21:05.980419	110
15	2022-04-28 16:21:06.041419	11
16	2022-04-28 16:21:06.142419	132
17	2022-04-28 16:21:06.204419	27
18	2022-04-28 16:21:06.110419	24
19	2022-04-28 16:21:05.985419	48
20	2022-04-28 16:21:06.006419	16
21	2022-04-28 16:21:06.218419	30
22	2022-04-28 16:21:06.010419	10
23	2022-04-28 16:21:06.081419	42
24	2022-04-28 16:21:06.230419	123
25	2022-04-28 16:21:06.116419	117
26	2022-04-28 16:21:06.174419	140
27	2022-04-28 16:21:06.047419	139
28	2022-04-28 16:21:06.106419	34
29	2022-04-28 16:21:06.082419	40
30	2022-04-28 16:21:06.116419	110
31	2022-04-28 16:21:06.183419	94
32	2022-04-28 16:21:06.030419	54
33	2022-04-28 16:21:06.362419	19
34	2022-04-28 16:21:06.306419	64
35	2022-04-28 16:21:06.211419	132
36	2022-04-28 16:21:06.434419	92
37	2022-04-28 16:21:06.114419	79
38	2022-04-28 16:21:06.384419	91
39	2022-04-28 16:21:06.317419	110
40	2022-04-28 16:21:06.446419	4
41	2022-04-28 16:21:06.417419	26
42	2022-04-28 16:21:06.260419	72
43	2022-04-28 16:21:06.310419	111
44	2022-04-28 16:21:06.494419	144
45	2022-04-28 16:21:06.551419	48
46	2022-04-28 16:21:06.610419	109
47	2022-04-28 16:21:06.013419	40
48	2022-04-28 16:21:06.446419	28
49	2022-04-28 16:21:06.113419	101
50	2022-04-28 16:21:06.166419	27
51	2022-04-28 16:21:06.476419	48
52	2022-04-28 16:21:06.278419	63
53	2022-04-28 16:21:06.655419	134
54	2022-04-28 16:21:06.560419	84
55	2022-04-28 16:21:06.186419	96
56	2022-04-28 16:21:06.470419	63
57	2022-04-28 16:21:06.365419	43
58	2022-04-28 16:21:06.778419	40
59	2022-04-28 16:21:06.202419	88
60	2022-04-28 16:21:06.686419	15
61	2022-04-28 16:21:06.332419	94
62	2022-04-28 16:21:06.462419	19
63	2022-04-28 16:21:06.848419	28
64	2022-04-28 16:21:06.542419	141
65	2022-04-28 16:21:06.811419	80
66	2022-04-28 16:21:06.494419	134
67	2022-04-28 16:21:06.502419	94
68	2022-04-28 16:21:06.374419	65
69	2022-04-28 16:21:06.725419	144
70	2022-04-28 16:21:06.596419	87
71	2022-04-28 16:21:06.108419	32
72	2022-04-28 16:21:06.758419	35
73	2022-04-28 16:21:06.769419	79
74	2022-04-28 16:21:06.336419	106
75	2022-04-28 16:21:06.341419	57
76	2022-04-28 16:21:07.030419	75
77	2022-04-28 16:21:06.890419	18
78	2022-04-28 16:21:06.902419	2
79	2022-04-28 16:21:06.835419	41
80	2022-04-28 16:21:06.606419	101
81	2022-04-28 16:21:06.371419	110
82	2022-04-28 16:21:06.786419	100
83	2022-04-28 16:21:06.215419	100
84	2022-04-28 16:21:07.058419	117
85	2022-04-28 16:21:07.071419	81
86	2022-04-28 16:21:06.654419	34
87	2022-04-28 16:21:07.184419	38
88	2022-04-28 16:21:06.142419	20
89	2022-04-28 16:21:07.123419	45
90	2022-04-28 16:21:06.596419	58
91	2022-04-28 16:21:07.149419	130
92	2022-04-28 16:21:06.886419	72
93	2022-04-28 16:21:06.803419	2
94	2022-04-28 16:21:06.154419	64
95	2022-04-28 16:21:07.106419	54
96	2022-04-28 16:21:06.926419	73
97	2022-04-28 16:21:06.742419	134
98	2022-04-28 16:21:06.456419	42
99	2022-04-28 16:21:06.758419	12
100	2022-04-28 16:21:06.166419	5
101	2022-04-28 16:21:06.976419	72
102	2022-04-28 16:21:07.190419	106
103	2022-04-28 16:21:07.305419	107
104	2022-04-28 16:21:06.798419	86
105	2022-04-28 16:21:06.176419	104
106	2022-04-28 16:21:06.284419	70
107	2022-04-28 16:21:07.357419	15
108	2022-04-28 16:21:07.262419	61
109	2022-04-28 16:21:06.184419	30
110	2022-04-28 16:21:06.296419	21
111	2022-04-28 16:21:06.965419	65
112	2022-04-28 16:21:06.078419	81
113	2022-04-28 16:21:07.435419	145
114	2022-04-28 16:21:07.220419	10
115	2022-04-28 16:21:07.576419	113
116	2022-04-28 16:21:07.010419	119
117	2022-04-28 16:21:06.434419	56
118	2022-04-28 16:21:07.264419	58
119	2022-04-28 16:21:06.204419	141
120	2022-04-28 16:21:07.046419	124
121	2022-04-28 16:21:06.934419	71
122	2022-04-28 16:21:06.698419	14
123	2022-04-28 16:21:06.458419	28
124	2022-04-28 16:21:07.082419	59
125	2022-04-28 16:21:06.341419	128
126	2022-04-28 16:21:06.470419	47
127	2022-04-28 16:21:07.744419	139
128	2022-04-28 16:21:06.862419	33
129	2022-04-28 16:21:06.998419	38
130	2022-04-28 16:21:07.526419	131
131	2022-04-28 16:21:06.097419	68
132	2022-04-28 16:21:07.154419	42
133	2022-04-28 16:21:06.365419	45
134	2022-04-28 16:21:06.636419	72
135	2022-04-28 16:21:06.776419	61
136	2022-04-28 16:21:06.782419	14
137	2022-04-28 16:21:07.199419	38
138	2022-04-28 16:21:07.346419	19
139	2022-04-28 16:21:06.244419	133
140	2022-04-28 16:21:06.666419	103
141	2022-04-28 16:21:06.812419	49
142	2022-04-28 16:21:07.954419	13
143	2022-04-28 16:21:07.110419	44
144	2022-04-28 16:21:07.694419	39
145	2022-04-28 16:21:07.996419	76
146	2022-04-28 16:21:07.864419	121
147	2022-04-28 16:21:06.407419	102
148	2022-04-28 16:21:07.742419	4
149	2022-04-28 16:21:07.754419	16
150	2022-04-28 16:21:08.066419	137
151	2022-04-28 16:21:07.929419	20
152	2022-04-28 16:21:06.270419	103
153	2022-04-28 16:21:07.190419	20
154	2022-04-28 16:21:07.660419	105
155	2022-04-28 16:21:06.741419	44
156	2022-04-28 16:21:06.434419	83
157	2022-04-28 16:21:08.164419	19
158	2022-04-28 16:21:07.230419	98
159	2022-04-28 16:21:07.238419	80
160	2022-04-28 16:21:07.726419	117
161	2022-04-28 16:21:07.093419	1
162	2022-04-28 16:21:07.262419	123
163	2022-04-28 16:21:07.270419	73
164	2022-04-28 16:21:08.262419	132
165	2022-04-28 16:21:07.121419	94
166	2022-04-28 16:21:06.796419	140
167	2022-04-28 16:21:08.137419	54
168	2022-04-28 16:21:07.982419	35
169	2022-04-28 16:21:06.811419	36
170	2022-04-28 16:21:07.326419	62
171	2022-04-28 16:21:07.505419	19
172	2022-04-28 16:21:08.374419	97
173	2022-04-28 16:21:07.004419	50
174	2022-04-28 16:21:08.228419	3
175	2022-04-28 16:21:06.491419	27
176	2022-04-28 16:21:07.374419	45
177	2022-04-28 16:21:07.028419	28
178	2022-04-28 16:21:07.390419	134
179	2022-04-28 16:21:07.577419	30
180	2022-04-28 16:21:06.686419	9
181	2022-04-28 16:21:06.690419	118
182	2022-04-28 16:21:06.876419	96
183	2022-04-28 16:21:06.332419	30
184	2022-04-28 16:21:07.806419	85
185	2022-04-28 16:21:07.076419	43
186	2022-04-28 16:21:07.082419	42
187	2022-04-28 16:21:06.153419	45
188	2022-04-28 16:21:06.718419	50
189	2022-04-28 16:21:06.344419	127
190	2022-04-28 16:21:07.486419	26
191	2022-04-28 16:21:07.685419	137
192	2022-04-28 16:21:08.078419	34
193	2022-04-28 16:21:06.545419	140
194	2022-04-28 16:21:07.712419	108
195	2022-04-28 16:21:08.501419	125
196	2022-04-28 16:21:07.926419	15
197	2022-04-28 16:21:06.360419	70
198	2022-04-28 16:21:06.758419	113
199	2022-04-28 16:21:08.354419	45
200	2022-04-28 16:21:07.966419	25
201	2022-04-28 16:21:07.976419	44
202	2022-04-28 16:21:07.986419	128
203	2022-04-28 16:21:08.402419	32
204	2022-04-28 16:21:06.986419	12
205	2022-04-28 16:21:08.836419	22
206	2022-04-28 16:21:08.644419	106
207	2022-04-28 16:21:08.243419	5
208	2022-04-28 16:21:07.422419	36
209	2022-04-28 16:21:06.384419	14
210	2022-04-28 16:21:07.646419	10
211	2022-04-28 16:21:07.865419	132
212	2022-04-28 16:21:08.086419	70
213	2022-04-28 16:21:08.096419	42
214	2022-04-28 16:21:06.822419	80
215	2022-04-28 16:21:06.396419	65
216	2022-04-28 16:21:07.694419	107
217	2022-04-28 16:21:06.834419	47
218	2022-04-28 16:21:07.492419	47
219	2022-04-28 16:21:07.061419	124
220	2022-04-28 16:21:07.506419	135
221	2022-04-28 16:21:08.176419	75
222	2022-04-28 16:21:08.408419	108
223	2022-04-28 16:21:09.088419	133
224	2022-04-28 16:21:07.310419	4
225	2022-04-28 16:21:06.416419	2
226	2022-04-28 16:21:08.226419	105
227	2022-04-28 16:21:08.690419	85
228	2022-04-28 16:21:07.790419	115
229	2022-04-28 16:21:08.027419	30
230	2022-04-28 16:21:06.886419	76
231	2022-04-28 16:21:09.200419	108
232	2022-04-28 16:21:06.198419	77
233	2022-04-28 16:21:08.063419	24
234	2022-04-28 16:21:07.838419	58
235	2022-04-28 16:21:07.846419	19
236	2022-04-28 16:21:09.270419	33
237	2022-04-28 16:21:08.336419	85
238	2022-04-28 16:21:07.394419	16
239	2022-04-28 16:21:06.683419	140
240	2022-04-28 16:21:07.886419	108
1	2022-04-28 16:21:05.979419	32
2	2022-04-28 16:21:05.982419	9
3	2022-04-28 16:21:05.999419	117
4	2022-04-28 16:21:06.018419	95
5	2022-04-28 16:21:06.021419	101
6	2022-04-28 16:21:06.032419	11
7	2022-04-28 16:21:06.029419	131
8	2022-04-28 16:21:06.078419	137
9	2022-04-28 16:21:06.038419	37
10	2022-04-28 16:21:05.996419	119
11	2022-04-28 16:21:06.043419	143
12	2022-04-28 16:21:06.050419	133
13	2022-04-28 16:21:05.992419	71
14	2022-04-28 16:21:05.994419	33
15	2022-04-28 16:21:06.026419	66
16	2022-04-28 16:21:06.126419	93
17	2022-04-28 16:21:06.136419	72
18	2022-04-28 16:21:06.128419	112
19	2022-04-28 16:21:06.042419	139
20	2022-04-28 16:21:06.206419	119
21	2022-04-28 16:21:06.050419	124
22	2022-04-28 16:21:06.164419	125
23	2022-04-28 16:21:06.127419	132
24	2022-04-28 16:21:06.182419	112
25	2022-04-28 16:21:06.191419	65
26	2022-04-28 16:21:06.200419	129
27	2022-04-28 16:21:06.290419	100
28	2022-04-28 16:21:06.106419	133
29	2022-04-28 16:21:06.285419	86
30	2022-04-28 16:21:06.026419	38
31	2022-04-28 16:21:06.307419	104
32	2022-04-28 16:21:06.190419	47
33	2022-04-28 16:21:06.032419	13
34	2022-04-28 16:21:06.170419	21
35	2022-04-28 16:21:06.141419	27
36	2022-04-28 16:21:06.326419	80
37	2022-04-28 16:21:06.225419	44
38	2022-04-28 16:21:06.308419	82
39	2022-04-28 16:21:06.200419	91
40	2022-04-28 16:21:06.286419	18
41	2022-04-28 16:21:06.499419	43
42	2022-04-28 16:21:06.344419	111
43	2022-04-28 16:21:06.482419	112
44	2022-04-28 16:21:06.494419	3
45	2022-04-28 16:21:06.101419	103
46	2022-04-28 16:21:06.058419	94
47	2022-04-28 16:21:06.577419	78
48	2022-04-28 16:21:06.062419	74
49	2022-04-28 16:21:06.309419	46
50	2022-04-28 16:21:06.566419	47
51	2022-04-28 16:21:06.374419	67
52	2022-04-28 16:21:06.382419	66
53	2022-04-28 16:21:06.549419	9
54	2022-04-28 16:21:06.344419	80
55	2022-04-28 16:21:06.076419	111
56	2022-04-28 16:21:06.470419	18
57	2022-04-28 16:21:06.080419	132
58	2022-04-28 16:21:06.314419	66
59	2022-04-28 16:21:06.143419	100
60	2022-04-28 16:21:06.386419	40
61	2022-04-28 16:21:06.271419	53
62	2022-04-28 16:21:06.834419	84
63	2022-04-28 16:21:06.155419	11
64	2022-04-28 16:21:06.542419	134
65	2022-04-28 16:21:06.226419	14
66	2022-04-28 16:21:06.164419	8
67	2022-04-28 16:21:06.770419	29
68	2022-04-28 16:21:06.578419	64
69	2022-04-28 16:21:06.794419	21
70	2022-04-28 16:21:06.106419	117
71	2022-04-28 16:21:06.392419	36
72	2022-04-28 16:21:06.902419	60
73	2022-04-28 16:21:06.185419	134
74	2022-04-28 16:21:06.632419	4
75	2022-04-28 16:21:06.266419	91
76	2022-04-28 16:21:06.422419	106
77	2022-04-28 16:21:06.890419	81
78	2022-04-28 16:21:06.044419	27
79	2022-04-28 16:21:06.598419	132
80	2022-04-28 16:21:06.366419	97
81	2022-04-28 16:21:06.533419	75
82	2022-04-28 16:21:06.458419	145
83	2022-04-28 16:21:06.713419	75
84	2022-04-28 16:21:06.386419	129
85	2022-04-28 16:21:06.476419	134
86	2022-04-28 16:21:06.826419	144
87	2022-04-28 16:21:06.836419	97
88	2022-04-28 16:21:07.110419	10
89	2022-04-28 16:21:06.589419	83
90	2022-04-28 16:21:06.596419	34
91	2022-04-28 16:21:06.694419	88
92	2022-04-28 16:21:06.978419	87
93	2022-04-28 16:21:06.989419	64
94	2022-04-28 16:21:06.342419	36
95	2022-04-28 16:21:06.251419	59
96	2022-04-28 16:21:07.310419	131
97	2022-04-28 16:21:07.130419	54
98	2022-04-28 16:21:06.554419	120
99	2022-04-28 16:21:07.253419	135
100	2022-04-28 16:21:07.166419	92
101	2022-04-28 16:21:06.875419	99
102	2022-04-28 16:21:06.986419	38
103	2022-04-28 16:21:07.408419	57
104	2022-04-28 16:21:06.174419	27
105	2022-04-28 16:21:06.911419	140
106	2022-04-28 16:21:07.132419	134
107	2022-04-28 16:21:06.715419	13
108	2022-04-28 16:21:06.290419	121
109	2022-04-28 16:21:07.165419	106
110	2022-04-28 16:21:06.516419	26
111	2022-04-28 16:21:06.521419	12
112	2022-04-28 16:21:07.198419	135
113	2022-04-28 16:21:07.548419	109
114	2022-04-28 16:21:06.308419	43
115	2022-04-28 16:21:06.541419	16
116	2022-04-28 16:21:06.314419	75
117	2022-04-28 16:21:07.253419	117
118	2022-04-28 16:21:07.028419	120
119	2022-04-28 16:21:07.513419	72
120	2022-04-28 16:21:07.046419	49
121	2022-04-28 16:21:06.692419	5
122	2022-04-28 16:21:07.064419	32
123	2022-04-28 16:21:07.196419	5
124	2022-04-28 16:21:06.834419	109
125	2022-04-28 16:21:06.466419	79
126	2022-04-28 16:21:06.218419	27
127	2022-04-28 16:21:07.236419	92
128	2022-04-28 16:21:06.606419	78
129	2022-04-28 16:21:07.772419	111
130	2022-04-28 16:21:06.616419	35
131	2022-04-28 16:21:06.490419	114
132	2022-04-28 16:21:07.682419	77
133	2022-04-28 16:21:07.562419	33
134	2022-04-28 16:21:06.368419	98
135	2022-04-28 16:21:06.911419	50
136	2022-04-28 16:21:07.734419	40
137	2022-04-28 16:21:06.377419	138
138	2022-04-28 16:21:07.622419	42
139	2022-04-28 16:21:06.939419	73
140	2022-04-28 16:21:06.666419	138
141	2022-04-28 16:21:06.671419	62
142	2022-04-28 16:21:06.250419	111
143	2022-04-28 16:21:06.252419	141
144	2022-04-28 16:21:07.838419	20
145	2022-04-28 16:21:07.126419	14
146	2022-04-28 16:21:07.718419	23
147	2022-04-28 16:21:06.554419	57
148	2022-04-28 16:21:06.410419	84
149	2022-04-28 16:21:06.413419	15
150	2022-04-28 16:21:06.866419	65
151	2022-04-28 16:21:07.929419	111
152	2022-04-28 16:21:06.726419	126
153	2022-04-28 16:21:07.343419	115
154	2022-04-28 16:21:06.274419	101
155	2022-04-28 16:21:07.826419	6
156	2022-04-28 16:21:06.278419	68
157	2022-04-28 16:21:07.222419	48
158	2022-04-28 16:21:08.020419	116
159	2022-04-28 16:21:07.556419	18
160	2022-04-28 16:21:07.246419	123
161	2022-04-28 16:21:06.932419	5
162	2022-04-28 16:21:06.614419	55
163	2022-04-28 16:21:07.270419	111
164	2022-04-28 16:21:06.294419	105
165	2022-04-28 16:21:07.946419	35
166	2022-04-28 16:21:06.464419	53
167	2022-04-28 16:21:06.467419	119
168	2022-04-28 16:21:06.302419	81
169	2022-04-28 16:21:06.473419	34
170	2022-04-28 16:21:06.476419	37
171	2022-04-28 16:21:08.189419	26
172	2022-04-28 16:21:06.826419	66
173	2022-04-28 16:21:06.139419	58
174	2022-04-28 16:21:07.706419	129
175	2022-04-28 16:21:07.191419	46
176	2022-04-28 16:21:08.254419	5
177	2022-04-28 16:21:07.559419	81
178	2022-04-28 16:21:06.322419	123
179	2022-04-28 16:21:07.577419	132
180	2022-04-28 16:21:07.046419	125
181	2022-04-28 16:21:07.957419	52
182	2022-04-28 16:21:08.150419	86
183	2022-04-28 16:21:08.345419	105
184	2022-04-28 16:21:07.070419	99
185	2022-04-28 16:21:06.706419	53
186	2022-04-28 16:21:07.826419	69
187	2022-04-28 16:21:08.584419	36
188	2022-04-28 16:21:08.598419	27
189	2022-04-28 16:21:08.045419	107
190	2022-04-28 16:21:07.106419	14
191	2022-04-28 16:21:06.539419	25
192	2022-04-28 16:21:06.926419	77
193	2022-04-28 16:21:07.124419	17
194	2022-04-28 16:21:08.100419	81
195	2022-04-28 16:21:08.111419	36
196	2022-04-28 16:21:08.710419	34
197	2022-04-28 16:21:08.330419	41
198	2022-04-28 16:21:07.550419	80
199	2022-04-28 16:21:06.961419	105
200	2022-04-28 16:21:07.566419	43
201	2022-04-28 16:21:06.368419	142
202	2022-04-28 16:21:07.986419	17
203	2022-04-28 16:21:07.996419	60
204	2022-04-28 16:21:06.374419	54
205	2022-04-28 16:21:07.811419	132
206	2022-04-28 16:21:06.584419	122
207	2022-04-28 16:21:07.622419	44
208	2022-04-28 16:21:08.254419	84
209	2022-04-28 16:21:06.384419	48
210	2022-04-28 16:21:06.806419	114
211	2022-04-28 16:21:08.920419	118
212	2022-04-28 16:21:08.934419	2
213	2022-04-28 16:21:07.244419	64
214	2022-04-28 16:21:07.892419	102
215	2022-04-28 16:21:08.331419	59
216	2022-04-28 16:21:08.774419	144
217	2022-04-28 16:21:06.834419	12
218	2022-04-28 16:21:06.402419	20
219	2022-04-28 16:21:07.718419	22
220	2022-04-28 16:21:08.826419	138
221	2022-04-28 16:21:06.408419	57
222	2022-04-28 16:21:09.074419	119
223	2022-04-28 16:21:06.635419	22
224	2022-04-28 16:21:08.206419	80
225	2022-04-28 16:21:07.766419	136
226	2022-04-28 16:21:07.548419	144
227	2022-04-28 16:21:07.782419	112
228	2022-04-28 16:21:07.106419	32
229	2022-04-28 16:21:06.195419	93
230	2022-04-28 16:21:08.496419	33
231	2022-04-28 16:21:08.507419	52
232	2022-04-28 16:21:08.286419	30
233	2022-04-28 16:21:06.432419	21
234	2022-04-28 16:21:08.306419	69
235	2022-04-28 16:21:06.906419	91
236	2022-04-28 16:21:06.438419	139
237	2022-04-28 16:21:07.625419	42
238	2022-04-28 16:21:08.584419	85
239	2022-04-28 16:21:09.073419	21
240	2022-04-28 16:21:09.086419	35
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
-- Name: glossary existence_check_or_creation_table; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();


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

