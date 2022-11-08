--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.24
-- Dumped by pg_dump version 9.6.24

-- Started on 2022-04-28 16:03:57

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
-- TOC entry 1 (class 3079 OID 12387)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2187 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 195 (class 1255 OID 92153)
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
-- TOC entry 214 (class 1255 OID 92161)
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
-- TOC entry 213 (class 1255 OID 92160)
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
-- TOC entry 209 (class 1255 OID 92156)
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
-- TOC entry 208 (class 1255 OID 92155)
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
-- TOC entry 211 (class 1255 OID 92158)
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
-- TOC entry 210 (class 1255 OID 92157)
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
-- TOC entry 212 (class 1255 OID 92159)
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
-- TOC entry 194 (class 1255 OID 92091)
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
-- TOC entry 193 (class 1259 OID 92145)
-- Name: float_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_actual OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 92137)
-- Name: float_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.float_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE public.float_archive OWNER TO postgres;

--
-- TOC entry 186 (class 1259 OID 92080)
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
-- TOC entry 2188 (class 0 OID 0)
-- Dependencies: 186
-- Name: TABLE glossary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.glossary IS 'Словарь для индефикации переменных';


--
-- TOC entry 2189 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN glossary.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';


--
-- TOC entry 2190 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN glossary.communication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';


--
-- TOC entry 2191 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN glossary.configuration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';


--
-- TOC entry 2192 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN glossary.tablename; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';


--
-- TOC entry 185 (class 1259 OID 92078)
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
-- TOC entry 2193 (class 0 OID 0)
-- Dependencies: 185
-- Name: glossary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.glossary_key_seq OWNED BY public.glossary.key;


--
-- TOC entry 191 (class 1259 OID 92129)
-- Name: integer_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_actual OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 92121)
-- Name: integer_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integer_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.integer_archive OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 92099)
-- Name: order_actual; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_actual (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_actual OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 92110)
-- Name: order_archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_archive (
    key integer NOT NULL,
    fix timestamp without time zone NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.order_archive OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 92093)
-- Name: synchronization; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.synchronization (
    xpath text NOT NULL,
    fix timestamp without time zone NOT NULL,
    status text NOT NULL
);


ALTER TABLE public.synchronization OWNER TO postgres;

--
-- TOC entry 2042 (class 2604 OID 92083)
-- Name: glossary key; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary ALTER COLUMN key SET DEFAULT nextval('public.glossary_key_seq'::regclass);


--
-- TOC entry 2179 (class 0 OID 92145)
-- Dependencies: 193
-- Data for Name: float_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_actual (key, fix, value) FROM stdin;
1	2022-04-28 16:02:21.19125	44.979999999999997
2	2022-04-28 16:02:21.19225	98.790000000000006
3	2022-04-28 16:02:21.20425	5.5999999999999996
4	2022-04-28 16:02:21.23425	46.640000000000001
5	2022-04-28 16:02:21.23625	102.19
6	2022-04-28 16:02:21.24625	29.109999999999999
7	2022-04-28 16:02:21.27725	139.40000000000001
8	2022-04-28 16:02:21.25825	3.6800000000000002
9	2022-04-28 16:02:21.28525	70.030000000000001
10	2022-04-28 16:02:21.26625	71.989999999999995
11	2022-04-28 16:02:21.24125	80.409999999999997
12	2022-04-28 16:02:21.28225	8.9700000000000006
13	2022-04-28 16:02:21.25125	33
14	2022-04-28 16:02:21.28425	124.45
15	2022-04-28 16:02:21.21625	2.71
16	2022-04-28 16:02:21.28225	129.66
17	2022-04-28 16:02:21.22025	140.30000000000001
18	2022-04-28 16:02:21.38425	48.460000000000001
19	2022-04-28 16:02:21.39525	7.04
20	2022-04-28 16:02:21.28625	87.780000000000001
21	2022-04-28 16:02:21.33325	90.010000000000005
22	2022-04-28 16:02:21.23025	132.41999999999999
23	2022-04-28 16:02:21.32425	76.709999999999994
24	2022-04-28 16:02:21.52225	33.719999999999999
25	2022-04-28 16:02:21.23625	101.58
26	2022-04-28 16:02:21.31625	88.159999999999997
27	2022-04-28 16:02:21.32125	33.979999999999997
28	2022-04-28 16:02:21.55025	107.29000000000001
29	2022-04-28 16:02:21.53425	10.699999999999999
30	2022-04-28 16:02:21.36625	19.489999999999998
31	2022-04-28 16:02:21.46525	140.38999999999999
32	2022-04-28 16:02:21.31425	101.38
33	2022-04-28 16:02:21.38425	113.81
34	2022-04-28 16:02:21.28825	132.38999999999999
35	2022-04-28 16:02:21.32625	41.5
36	2022-04-28 16:02:21.36625	100.78
37	2022-04-28 16:02:21.33425	132.97999999999999
38	2022-04-28 16:02:21.26225	101.59999999999999
39	2022-04-28 16:02:21.49825	87.689999999999998
40	2022-04-28 16:02:21.58625	109.54000000000001
41	2022-04-28 16:02:21.35025	35.689999999999998
42	2022-04-28 16:02:21.69025	56.369999999999997
43	2022-04-28 16:02:21.61625	110.17
44	2022-04-28 16:02:21.58225	115.95999999999999
45	2022-04-28 16:02:21.27625	1.8899999999999999
46	2022-04-28 16:02:21.55425	94.900000000000006
47	2022-04-28 16:02:21.65625	21.859999999999999
48	2022-04-28 16:02:21.28225	68.159999999999997
49	2022-04-28 16:02:21.48025	54.479999999999997
50	2022-04-28 16:02:21.63625	84.730000000000004
51	2022-04-28 16:02:21.49225	11.279999999999999
52	2022-04-28 16:02:21.23825	112.93000000000001
53	2022-04-28 16:02:21.50425	89.969999999999999
54	2022-04-28 16:02:21.51025	60.079999999999998
55	2022-04-28 16:02:21.35125	30.690000000000001
56	2022-04-28 16:02:21.46625	29.09
57	2022-04-28 16:02:21.52825	94.909999999999997
58	2022-04-28 16:02:21.94025	48.259999999999998
59	2022-04-28 16:02:21.36325	124.20999999999999
60	2022-04-28 16:02:22.02625	85.590000000000003
61	2022-04-28 16:02:21.43025	55.109999999999999
62	2022-04-28 16:02:21.93025	31.960000000000001
63	2022-04-28 16:02:21.87925	95.069999999999993
64	2022-04-28 16:02:21.31425	10.470000000000001
65	2022-04-28 16:02:22.03125	87.180000000000007
66	2022-04-28 16:02:21.51625	17.84
67	2022-04-28 16:02:21.32025	17.600000000000001
68	2022-04-28 16:02:21.59425	25.82
69	2022-04-28 16:02:21.46225	4.8700000000000001
70	2022-04-28 16:02:22.16625	13.890000000000001
71	2022-04-28 16:02:21.61225	24.289999999999999
72	2022-04-28 16:02:21.83425	125.09
73	2022-04-28 16:02:21.98925	50.380000000000003
74	2022-04-28 16:02:21.55625	143.72
75	2022-04-28 16:02:21.56125	103.33
76	2022-04-28 16:02:21.56625	77.109999999999999
77	2022-04-28 16:02:21.64825	142.97999999999999
78	2022-04-28 16:02:21.65425	142.43000000000001
79	2022-04-28 16:02:21.50225	115.68000000000001
80	2022-04-28 16:02:21.34625	108.43000000000001
81	2022-04-28 16:02:21.91525	49.020000000000003
82	2022-04-28 16:02:21.84225	83.349999999999994
83	2022-04-28 16:02:22.26525	20.77
84	2022-04-28 16:02:21.43825	38.549999999999997
85	2022-04-28 16:02:21.61125	104.34999999999999
86	2022-04-28 16:02:21.35825	21.379999999999999
87	2022-04-28 16:02:22.31725	131.41
88	2022-04-28 16:02:21.53825	8.8000000000000007
89	2022-04-28 16:02:22.16525	143.43000000000001
90	2022-04-28 16:02:21.81625	59.439999999999998
91	2022-04-28 16:02:21.73225	10.34
92	2022-04-28 16:02:22.29025	25.82
93	2022-04-28 16:02:21.65125	115.06
94	2022-04-28 16:02:22.22025	8.0500000000000007
95	2022-04-28 16:02:22.23125	61.469999999999999
96	2022-04-28 16:02:22.53025	64.269999999999996
97	2022-04-28 16:02:22.54425	36.329999999999998
98	2022-04-28 16:02:21.97025	5.3099999999999996
99	2022-04-28 16:02:22.07725	9.8499999999999996
100	2022-04-28 16:02:22.58625	90.280000000000001
101	2022-04-28 16:02:21.59025	3.8500000000000001
102	2022-04-28 16:02:22.30825	79.25
103	2022-04-28 16:02:22.11325	24.18
104	2022-04-28 16:02:22.22625	69.670000000000002
105	2022-04-28 16:02:22.34125	46.479999999999997
106	2022-04-28 16:02:21.61025	35.369999999999997
107	2022-04-28 16:02:21.82825	91.450000000000003
108	2022-04-28 16:02:21.83425	73.349999999999994
109	2022-04-28 16:02:22.05825	52.869999999999997
110	2022-04-28 16:02:21.73625	15.35
111	2022-04-28 16:02:21.85225	17.789999999999999
112	2022-04-28 16:02:22.08225	121.43000000000001
113	2022-04-28 16:02:22.42925	95.939999999999998
114	2022-04-28 16:02:21.52825	90.890000000000001
115	2022-04-28 16:02:21.87625	29.579999999999998
116	2022-04-28 16:02:21.99825	99.819999999999993
117	2022-04-28 16:02:21.30325	122.52
118	2022-04-28 16:02:21.65825	52.469999999999999
119	2022-04-28 16:02:21.90025	39.530000000000001
120	2022-04-28 16:02:22.26625	21.09
121	2022-04-28 16:02:21.54925	38.990000000000002
122	2022-04-28 16:02:21.79625	63.609999999999999
123	2022-04-28 16:02:21.67825	103.56
124	2022-04-28 16:02:21.55825	54.43
125	2022-04-28 16:02:22.81125	4.6200000000000001
126	2022-04-28 16:02:22.19425	40.490000000000002
127	2022-04-28 16:02:22.71025	127.09999999999999
128	2022-04-28 16:02:21.69825	10.390000000000001
129	2022-04-28 16:02:22.21825	131.28
130	2022-04-28 16:02:22.61625	139.08000000000001
131	2022-04-28 16:02:21.31725	6.7800000000000002
132	2022-04-28 16:02:21.45025	82.140000000000001
133	2022-04-28 16:02:22.91525	80.700000000000003
134	2022-04-28 16:02:21.72225	72.25
135	2022-04-28 16:02:21.99625	3.29
136	2022-04-28 16:02:21.59425	38.479999999999997
137	2022-04-28 16:02:22.83025	20.629999999999999
138	2022-04-28 16:02:23.11825	20.890000000000001
139	2022-04-28 16:02:22.85425	12.619999999999999
140	2022-04-28 16:02:22.58625	9.6300000000000008
141	2022-04-28 16:02:22.31425	112.95999999999999
142	2022-04-28 16:02:22.74825	52.450000000000003
143	2022-04-28 16:02:22.61625	22.719999999999999
144	2022-04-28 16:02:23.05825	21.649999999999999
145	2022-04-28 16:02:22.49125	24.5
146	2022-04-28 16:02:22.93825	62.369999999999997
147	2022-04-28 16:02:22.36225	87.75
148	2022-04-28 16:02:21.63025	14.26
149	2022-04-28 16:02:21.63325	106.08
150	2022-04-28 16:02:22.38625	92.140000000000001
151	2022-04-28 16:02:22.39425	89.140000000000001
152	2022-04-28 16:02:23.31425	125.06
153	2022-04-28 16:02:23.02225	36.590000000000003
154	2022-04-28 16:02:22.26425	95.269999999999996
155	2022-04-28 16:02:23.20125	13.16
156	2022-04-28 16:02:21.81025	62.780000000000001
157	2022-04-28 16:02:21.97125	104.19
158	2022-04-28 16:02:22.13425	35.710000000000001
159	2022-04-28 16:02:21.98125	107.92
160	2022-04-28 16:02:23.26625	108.31999999999999
161	2022-04-28 16:02:22.79625	12.73
162	2022-04-28 16:02:23.29225	35.689999999999998
163	2022-04-28 16:02:21.67525	109.23
164	2022-04-28 16:02:22.99025	30.190000000000001
165	2022-04-28 16:02:21.35125	127.81999999999999
166	2022-04-28 16:02:23.51025	15.380000000000001
167	2022-04-28 16:02:22.52225	4.2199999999999998
168	2022-04-28 16:02:22.69825	137.31999999999999
169	2022-04-28 16:02:23.21425	129.38
170	2022-04-28 16:02:22.54625	65.689999999999998
171	2022-04-28 16:02:22.89625	36.420000000000002
172	2022-04-28 16:02:21.87425	78.959999999999994
173	2022-04-28 16:02:23.43525	62.060000000000002
174	2022-04-28 16:02:21.70825	113.41
175	2022-04-28 16:02:21.88625	128.59999999999999
176	2022-04-28 16:02:23.29825	62.600000000000001
177	2022-04-28 16:02:23.31025	116.15000000000001
178	2022-04-28 16:02:23.67825	60.079999999999998
179	2022-04-28 16:02:23.15525	106.31999999999999
180	2022-04-28 16:02:22.98625	15.69
181	2022-04-28 16:02:22.63425	40.130000000000003
182	2022-04-28 16:02:23.00625	4.9699999999999998
183	2022-04-28 16:02:21.73525	21.309999999999999
184	2022-04-28 16:02:23.57825	34.340000000000003
185	2022-04-28 16:02:21.74125	67.209999999999994
186	2022-04-28 16:02:22.48825	58.979999999999997
187	2022-04-28 16:02:21.93425	61.939999999999998
188	2022-04-28 16:02:21.56225	60.359999999999999
189	2022-04-28 16:02:23.45425	48.950000000000003
190	2022-04-28 16:02:22.13625	108.28
191	2022-04-28 16:02:22.90525	143.49000000000001
192	2022-04-28 16:02:21.37825	19.609999999999999
193	2022-04-28 16:02:21.57225	79.670000000000002
194	2022-04-28 16:02:21.96225	108.02
195	2022-04-28 16:02:21.57625	24.510000000000002
196	2022-04-28 16:02:21.97025	12.41
197	2022-04-28 16:02:21.97425	59.609999999999999
198	2022-04-28 16:02:23.95825	60.030000000000001
199	2022-04-28 16:02:22.97725	31.66
200	2022-04-28 16:02:22.58625	114.26000000000001
201	2022-04-28 16:02:22.79425	137.24000000000001
202	2022-04-28 16:02:23.20625	107.91
203	2022-04-28 16:02:22.60725	58.82
204	2022-04-28 16:02:22.00225	64.280000000000001
205	2022-04-28 16:02:23.44125	82.780000000000001
206	2022-04-28 16:02:23.04025	60.060000000000002
207	2022-04-28 16:02:22.63525	138.34
208	2022-04-28 16:02:22.85025	72.219999999999999
209	2022-04-28 16:02:22.23125	75.219999999999999
210	2022-04-28 16:02:24.12625	83.120000000000005
211	2022-04-28 16:02:23.92925	22.48
212	2022-04-28 16:02:22.03425	142.86000000000001
213	2022-04-28 16:02:22.25125	52.350000000000001
214	2022-04-28 16:02:22.04225	120.77
215	2022-04-28 16:02:22.69125	95.890000000000001
216	2022-04-28 16:02:23.77825	92.209999999999994
217	2022-04-28 16:02:24.00725	77.75
218	2022-04-28 16:02:22.05825	92.299999999999997
219	2022-04-28 16:02:22.50025	39.060000000000002
220	2022-04-28 16:02:23.38625	98.969999999999999
221	2022-04-28 16:02:22.51225	116.78
222	2022-04-28 16:02:21.40825	70.200000000000003
223	2022-04-28 16:02:23.19325	116.02
224	2022-04-28 16:02:23.42625	36.329999999999998
225	2022-04-28 16:02:24.11125	69.650000000000006
226	2022-04-28 16:02:21.86425	14.140000000000001
227	2022-04-28 16:02:22.32125	124.95
228	2022-04-28 16:02:24.15025	56.850000000000001
229	2022-04-28 16:02:23.70525	95.090000000000003
230	2022-04-28 16:02:23.02625	15.130000000000001
231	2022-04-28 16:02:22.11025	53.340000000000003
232	2022-04-28 16:02:24.43425	12.1
233	2022-04-28 16:02:23.74925	135.91
234	2022-04-28 16:02:23.05825	128.44999999999999
235	2022-04-28 16:02:23.77125	129.87
236	2022-04-28 16:02:21.89425	1.8799999999999999
237	2022-04-28 16:02:24.03025	40.109999999999999
238	2022-04-28 16:02:22.13825	15.380000000000001
239	2022-04-28 16:02:21.90325	103.06
240	2022-04-28 16:02:22.62625	67
\.


--
-- TOC entry 2178 (class 0 OID 92137)
-- Dependencies: 192
-- Data for Name: float_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.float_archive (key, fix, value) FROM stdin;
1	2022-04-28 16:02:21.19625	139.88
2	2022-04-28 16:02:21.21425	142.31
3	2022-04-28 16:02:21.21025	104.63
4	2022-04-28 16:02:21.21025	7.8300000000000001
5	2022-04-28 16:02:21.23625	119.87
6	2022-04-28 16:02:21.26425	102.36
7	2022-04-28 16:02:21.26325	84.769999999999996
8	2022-04-28 16:02:21.25025	144.11000000000001
9	2022-04-28 16:02:21.29425	135.69999999999999
10	2022-04-28 16:02:21.29625	96.519999999999996
11	2022-04-28 16:02:21.24125	113.78
12	2022-04-28 16:02:21.28225	143.59
13	2022-04-28 16:02:21.26425	20.870000000000001
14	2022-04-28 16:02:21.25625	144.37
15	2022-04-28 16:02:21.33625	114.51000000000001
16	2022-04-28 16:02:21.25025	8.6999999999999993
17	2022-04-28 16:02:21.27125	5.6500000000000004
18	2022-04-28 16:02:21.31225	34.619999999999997
19	2022-04-28 16:02:21.31925	1.9099999999999999
20	2022-04-28 16:02:21.36625	7.1600000000000001
21	2022-04-28 16:02:21.37525	67.230000000000004
22	2022-04-28 16:02:21.27425	133.63999999999999
23	2022-04-28 16:02:21.20925	64.310000000000002
24	2022-04-28 16:02:21.28225	38.32
25	2022-04-28 16:02:21.48625	33.450000000000003
26	2022-04-28 16:02:21.31625	30.870000000000001
27	2022-04-28 16:02:21.56425	105.81999999999999
28	2022-04-28 16:02:21.27025	132.36000000000001
29	2022-04-28 16:02:21.38925	139.74000000000001
30	2022-04-28 16:02:21.48625	55.920000000000002
31	2022-04-28 16:02:21.40325	55.259999999999998
32	2022-04-28 16:02:21.37825	125.26000000000001
33	2022-04-28 16:02:21.48325	119.62
34	2022-04-28 16:02:21.42425	108.52
35	2022-04-28 16:02:21.29125	37.630000000000003
36	2022-04-28 16:02:21.51025	118.42
37	2022-04-28 16:02:21.40825	99.019999999999996
38	2022-04-28 16:02:21.26225	121.51000000000001
39	2022-04-28 16:02:21.49825	85.200000000000003
40	2022-04-28 16:02:21.74625	130.56999999999999
41	2022-04-28 16:02:21.71925	144.63
42	2022-04-28 16:02:21.35425	61.700000000000003
43	2022-04-28 16:02:21.53025	7.1699999999999999
44	2022-04-28 16:02:21.27425	78.840000000000003
45	2022-04-28 16:02:21.77125	72.659999999999997
46	2022-04-28 16:02:21.69225	66.299999999999997
47	2022-04-28 16:02:21.46825	27.16
48	2022-04-28 16:02:21.61825	28.789999999999999
49	2022-04-28 16:02:21.28425	55.32
50	2022-04-28 16:02:21.48625	29.710000000000001
51	2022-04-28 16:02:21.23725	71.090000000000003
52	2022-04-28 16:02:21.29025	78.010000000000005
53	2022-04-28 16:02:21.71625	68.519999999999996
54	2022-04-28 16:02:21.83425	45.619999999999997
55	2022-04-28 16:02:21.68125	48.649999999999999
56	2022-04-28 16:02:21.52225	127.75
57	2022-04-28 16:02:21.98425	108.76000000000001
58	2022-04-28 16:02:21.59225	68.950000000000003
59	2022-04-28 16:02:21.36325	142.86000000000001
60	2022-04-28 16:02:21.54625	78.299999999999997
61	2022-04-28 16:02:21.85725	130.77000000000001
62	2022-04-28 16:02:21.99225	98.989999999999995
63	2022-04-28 16:02:21.69025	19.539999999999999
64	2022-04-28 16:02:21.63425	29.109999999999999
65	2022-04-28 16:02:21.38125	131.44999999999999
66	2022-04-28 16:02:21.91225	25.649999999999999
67	2022-04-28 16:02:21.45425	112.33
68	2022-04-28 16:02:22.07025	62.079999999999998
69	2022-04-28 16:02:22.08325	98.489999999999995
70	2022-04-28 16:02:21.95625	6.8099999999999996
71	2022-04-28 16:02:21.47025	110.33
72	2022-04-28 16:02:22.12225	78.739999999999995
73	2022-04-28 16:02:21.40525	129.96000000000001
74	2022-04-28 16:02:21.70425	89.849999999999994
75	2022-04-28 16:02:22.01125	16.539999999999999
76	2022-04-28 16:02:21.33825	11.699999999999999
77	2022-04-28 16:02:21.26325	117.64
78	2022-04-28 16:02:21.73225	15.84
79	2022-04-28 16:02:21.89725	59.579999999999998
80	2022-04-28 16:02:21.34625	75.840000000000003
81	2022-04-28 16:02:21.26725	93.260000000000005
82	2022-04-28 16:02:21.51425	106.03
83	2022-04-28 16:02:21.85025	29.379999999999999
84	2022-04-28 16:02:22.02625	33.140000000000001
85	2022-04-28 16:02:22.20625	8.4499999999999993
86	2022-04-28 16:02:21.96025	72.170000000000002
87	2022-04-28 16:02:21.53425	46.759999999999998
88	2022-04-28 16:02:21.62625	145.22999999999999
89	2022-04-28 16:02:22.43225	50.159999999999997
90	2022-04-28 16:02:21.90625	85.989999999999995
91	2022-04-28 16:02:22.09625	121.86
92	2022-04-28 16:02:21.92225	144.77000000000001
93	2022-04-28 16:02:22.39525	103.02
94	2022-04-28 16:02:21.46825	63.520000000000003
95	2022-04-28 16:02:21.75625	115.89
96	2022-04-28 16:02:22.33825	74.25
97	2022-04-28 16:02:22.05925	38.259999999999998
98	2022-04-28 16:02:21.38225	83.430000000000007
99	2022-04-28 16:02:21.97825	27.23
100	2022-04-28 16:02:22.58625	136.00999999999999
101	2022-04-28 16:02:21.69125	35.460000000000001
102	2022-04-28 16:02:22.30825	95.950000000000003
103	2022-04-28 16:02:22.01025	77.849999999999994
104	2022-04-28 16:02:22.53825	102.76000000000001
105	2022-04-28 16:02:22.02625	64.939999999999998
106	2022-04-28 16:02:21.50425	39.799999999999997
107	2022-04-28 16:02:22.47025	67.969999999999999
108	2022-04-28 16:02:22.48225	26.850000000000001
109	2022-04-28 16:02:21.51325	31.440000000000001
110	2022-04-28 16:02:22.50625	122.81
111	2022-04-28 16:02:21.40825	30.850000000000001
112	2022-04-28 16:02:22.64225	8.9100000000000001
113	2022-04-28 16:02:21.63825	8.6400000000000006
114	2022-04-28 16:02:22.66825	138.28
115	2022-04-28 16:02:21.76125	110.06999999999999
116	2022-04-28 16:02:21.99825	118.04000000000001
117	2022-04-28 16:02:21.88825	89.480000000000004
118	2022-04-28 16:02:21.89425	63.25
119	2022-04-28 16:02:21.42425	120.66
120	2022-04-28 16:02:22.02625	51.350000000000001
121	2022-04-28 16:02:22.63825	65.269999999999996
122	2022-04-28 16:02:22.89425	129.12
123	2022-04-28 16:02:22.41625	80.090000000000003
124	2022-04-28 16:02:22.42625	24.329999999999998
125	2022-04-28 16:02:22.06125	123.15000000000001
126	2022-04-28 16:02:22.06825	50.450000000000003
127	2022-04-28 16:02:21.94825	22
128	2022-04-28 16:02:22.85025	8.3900000000000006
129	2022-04-28 16:02:21.96025	103.90000000000001
130	2022-04-28 16:02:22.09625	72.780000000000001
131	2022-04-28 16:02:22.49625	132.90000000000001
132	2022-04-28 16:02:22.11025	105.95999999999999
133	2022-04-28 16:02:23.04825	44.420000000000002
134	2022-04-28 16:02:22.92825	36.5
135	2022-04-28 16:02:21.59125	61.649999999999999
136	2022-04-28 16:02:21.59425	47.890000000000001
137	2022-04-28 16:02:22.69325	73.260000000000005
138	2022-04-28 16:02:21.32425	87.980000000000004
139	2022-04-28 16:02:21.88125	1.8700000000000001
140	2022-04-28 16:02:22.02625	100.37
141	2022-04-28 16:02:22.03225	103.31
142	2022-04-28 16:02:22.32225	65.510000000000005
143	2022-04-28 16:02:22.04425	16.539999999999999
144	2022-04-28 16:02:22.19425	31.120000000000001
145	2022-04-28 16:02:22.78125	42.020000000000003
146	2022-04-28 16:02:21.47825	52.920000000000002
147	2022-04-28 16:02:22.21525	138.34
148	2022-04-28 16:02:22.66625	134.96000000000001
149	2022-04-28 16:02:21.48425	33.43
150	2022-04-28 16:02:23.13625	56.770000000000003
151	2022-04-28 16:02:22.69625	59.530000000000001
152	2022-04-28 16:02:21.49025	143.59999999999999
153	2022-04-28 16:02:22.86925	14.77
154	2022-04-28 16:02:22.57225	121.28
155	2022-04-28 16:02:21.65125	42.560000000000002
156	2022-04-28 16:02:23.05825	50.390000000000001
157	2022-04-28 16:02:22.12825	107.02
158	2022-04-28 16:02:21.50225	138.80000000000001
159	2022-04-28 16:02:22.14025	140.47999999999999
160	2022-04-28 16:02:22.14625	129.18000000000001
161	2022-04-28 16:02:23.11825	103.33
162	2022-04-28 16:02:22.48225	123.31
163	2022-04-28 16:02:22.16425	109.01000000000001
164	2022-04-28 16:02:23.31825	118.02
165	2022-04-28 16:02:23.16625	11.869999999999999
166	2022-04-28 16:02:22.68025	5.7999999999999998
167	2022-04-28 16:02:21.68725	142.84999999999999
168	2022-04-28 16:02:21.52225	144.97
169	2022-04-28 16:02:22.87625	81.329999999999998
170	2022-04-28 16:02:22.88625	36.289999999999999
171	2022-04-28 16:02:22.55425	94.129999999999995
172	2022-04-28 16:02:21.53025	64.159999999999997
173	2022-04-28 16:02:22.57025	108.38
174	2022-04-28 16:02:21.36025	98.159999999999997
175	2022-04-28 16:02:23.28625	106.47
176	2022-04-28 16:02:22.77025	10.699999999999999
177	2022-04-28 16:02:23.31025	1.99
178	2022-04-28 16:02:22.78825	134.21000000000001
179	2022-04-28 16:02:23.51325	27.59
180	2022-04-28 16:02:22.98625	144.12
181	2022-04-28 16:02:21.91025	112.09999999999999
182	2022-04-28 16:02:21.36825	11.06
183	2022-04-28 16:02:23.19925	111.12
184	2022-04-28 16:02:21.92225	53.329999999999998
185	2022-04-28 16:02:23.03625	15.210000000000001
186	2022-04-28 16:02:22.11625	118.55
187	2022-04-28 16:02:22.12125	22.239999999999998
188	2022-04-28 16:02:22.31425	26.780000000000001
189	2022-04-28 16:02:23.07625	13.4
190	2022-04-28 16:02:22.32625	86.409999999999997
191	2022-04-28 16:02:23.28725	36.450000000000003
192	2022-04-28 16:02:23.87425	13.42
193	2022-04-28 16:02:22.73025	73.870000000000005
194	2022-04-28 16:02:21.96225	16.48
195	2022-04-28 16:02:22.55125	20.510000000000002
196	2022-04-28 16:02:21.77425	72.590000000000003
197	2022-04-28 16:02:23.74725	104.29000000000001
198	2022-04-28 16:02:21.58225	110.34
199	2022-04-28 16:02:22.97725	144.88999999999999
200	2022-04-28 16:02:23.38625	105.87
201	2022-04-28 16:02:22.79425	95.310000000000002
202	2022-04-28 16:02:24.01425	110.72
203	2022-04-28 16:02:22.60725	108.44
204	2022-04-28 16:02:23.63425	100.42
205	2022-04-28 16:02:23.23625	56.850000000000001
206	2022-04-28 16:02:22.21625	116.34
207	2022-04-28 16:02:23.67025	10.17
208	2022-04-28 16:02:22.22625	135.59999999999999
209	2022-04-28 16:02:23.69425	135.74000000000001
210	2022-04-28 16:02:22.86625	31.890000000000001
211	2022-04-28 16:02:23.08525	19.079999999999998
212	2022-04-28 16:02:24.15425	79.560000000000002
213	2022-04-28 16:02:24.16825	113.8
214	2022-04-28 16:02:23.96825	79.680000000000007
215	2022-04-28 16:02:21.61625	88.280000000000001
216	2022-04-28 16:02:22.91425	94.379999999999995
217	2022-04-28 16:02:22.48825	92.349999999999994
218	2022-04-28 16:02:21.62225	12.84
219	2022-04-28 16:02:22.06225	29.140000000000001
220	2022-04-28 16:02:23.16625	112.47
221	2022-04-28 16:02:23.39625	74.620000000000005
222	2022-04-28 16:02:22.74025	6.0199999999999996
223	2022-04-28 16:02:23.86225	46.659999999999997
224	2022-04-28 16:02:23.42625	122.34
225	2022-04-28 16:02:22.76125	20.530000000000001
226	2022-04-28 16:02:24.35025	101.13
227	2022-04-28 16:02:22.77525	74.269999999999996
228	2022-04-28 16:02:21.87025	57.380000000000003
229	2022-04-28 16:02:23.70525	66.299999999999997
230	2022-04-28 16:02:23.71625	98.180000000000007
231	2022-04-28 16:02:23.95825	38.950000000000003
232	2022-04-28 16:02:23.27425	6.9800000000000004
233	2022-04-28 16:02:23.98225	92.459999999999994
234	2022-04-28 16:02:22.82425	28.920000000000002
235	2022-04-28 16:02:24.47625	26.780000000000001
236	2022-04-28 16:02:23.54625	90.870000000000005
237	2022-04-28 16:02:22.37125	113.70999999999999
238	2022-04-28 16:02:23.09025	9.2400000000000002
239	2022-04-28 16:02:23.57625	132.22
240	2022-04-28 16:02:23.58625	97.450000000000003
1	2022-04-28 16:02:21.18925	11.460000000000001
2	2022-04-28 16:02:21.19025	137.47999999999999
3	2022-04-28 16:02:21.21625	124.8
4	2022-04-28 16:02:21.20225	124.87
5	2022-04-28 16:02:21.22125	100.34
6	2022-04-28 16:02:21.22225	116.2
7	2022-04-28 16:02:21.23525	139.28
8	2022-04-28 16:02:21.29825	64.069999999999993
9	2022-04-28 16:02:21.30325	62
10	2022-04-28 16:02:21.22625	33.109999999999999
11	2022-04-28 16:02:21.32925	70.170000000000002
12	2022-04-28 16:02:21.33025	41.539999999999999
13	2022-04-28 16:02:21.27725	47.229999999999997
14	2022-04-28 16:02:21.27025	96.909999999999997
15	2022-04-28 16:02:21.39625	16.43
16	2022-04-28 16:02:21.36225	116.75
17	2022-04-28 16:02:21.37325	16.920000000000002
18	2022-04-28 16:02:21.34825	110.95
19	2022-04-28 16:02:21.26225	96.819999999999993
20	2022-04-28 16:02:21.30625	142.13999999999999
21	2022-04-28 16:02:21.33325	84.219999999999999
22	2022-04-28 16:02:21.42825	44.020000000000003
23	2022-04-28 16:02:21.46225	128.81
24	2022-04-28 16:02:21.28225	50.890000000000001
25	2022-04-28 16:02:21.48625	12.58
26	2022-04-28 16:02:21.26425	35.880000000000003
27	2022-04-28 16:02:21.48325	68.650000000000006
28	2022-04-28 16:02:21.52225	92.299999999999997
29	2022-04-28 16:02:21.30225	117.59
30	2022-04-28 16:02:21.42625	50.719999999999999
31	2022-04-28 16:02:21.40325	78.75
32	2022-04-28 16:02:21.60225	53.899999999999999
33	2022-04-28 16:02:21.64825	83.150000000000006
34	2022-04-28 16:02:21.25425	45.609999999999999
35	2022-04-28 16:02:21.39625	26.879999999999999
36	2022-04-28 16:02:21.36625	35.390000000000001
37	2022-04-28 16:02:21.26025	32.960000000000001
38	2022-04-28 16:02:21.64225	45.229999999999997
39	2022-04-28 16:02:21.61525	81.739999999999995
40	2022-04-28 16:02:21.46625	82.739999999999995
41	2022-04-28 16:02:21.30925	7.8399999999999999
42	2022-04-28 16:02:21.69025	132.81
43	2022-04-28 16:02:21.78825	71.400000000000006
44	2022-04-28 16:02:21.27425	43.649999999999999
45	2022-04-28 16:02:21.41125	135.31
46	2022-04-28 16:02:21.55425	54.130000000000003
47	2022-04-28 16:02:21.32725	6.0800000000000001
48	2022-04-28 16:02:21.57025	129.94
49	2022-04-28 16:02:21.72525	52.460000000000001
50	2022-04-28 16:02:21.48625	35.630000000000003
51	2022-04-28 16:02:21.79825	130.5
52	2022-04-28 16:02:21.91425	96.769999999999996
53	2022-04-28 16:02:21.82225	133.53999999999999
54	2022-04-28 16:02:21.40225	71.930000000000007
55	2022-04-28 16:02:21.73625	70.540000000000006
56	2022-04-28 16:02:21.91425	95.870000000000005
57	2022-04-28 16:02:21.52825	135.09999999999999
58	2022-04-28 16:02:21.41825	61.880000000000003
59	2022-04-28 16:02:21.83525	138.58000000000001
60	2022-04-28 16:02:21.60625	69.430000000000007
61	2022-04-28 16:02:21.61325	108.01000000000001
62	2022-04-28 16:02:22.05425	68.260000000000005
63	2022-04-28 16:02:21.81625	130.13
64	2022-04-28 16:02:21.31425	2.75
65	2022-04-28 16:02:21.90125	130.50999999999999
66	2022-04-28 16:02:21.78025	59.119999999999997
67	2022-04-28 16:02:21.45425	34.899999999999999
68	2022-04-28 16:02:21.93425	32.520000000000003
69	2022-04-28 16:02:21.32425	24.260000000000002
70	2022-04-28 16:02:21.32625	5.8700000000000001
71	2022-04-28 16:02:21.54125	87.700000000000003
72	2022-04-28 16:02:21.83425	122.52
73	2022-04-28 16:02:21.33225	129.38
74	2022-04-28 16:02:21.33425	35.789999999999999
75	2022-04-28 16:02:22.08625	14.19
76	2022-04-28 16:02:21.49025	110.29000000000001
77	2022-04-28 16:02:22.26425	125.66
78	2022-04-28 16:02:22.04425	16.899999999999999
79	2022-04-28 16:02:22.21325	70.959999999999994
80	2022-04-28 16:02:21.34625	134.22999999999999
81	2022-04-28 16:02:22.15825	27.93
82	2022-04-28 16:02:22.08825	113.72
83	2022-04-28 16:02:22.26525	69.370000000000005
84	2022-04-28 16:02:21.77425	15.800000000000001
85	2022-04-28 16:02:21.52625	2.96
86	2022-04-28 16:02:21.61625	81.239999999999995
87	2022-04-28 16:02:22.23025	56.399999999999999
88	2022-04-28 16:02:21.53825	127.72
89	2022-04-28 16:02:21.45325	21.940000000000001
90	2022-04-28 16:02:21.81625	108.28
91	2022-04-28 16:02:22.36925	120.61
92	2022-04-28 16:02:21.55425	90.480000000000004
93	2022-04-28 16:02:22.20925	122.11
94	2022-04-28 16:02:21.84425	52.890000000000001
95	2022-04-28 16:02:21.85125	88.700000000000003
96	2022-04-28 16:02:21.66625	89.560000000000002
97	2022-04-28 16:02:21.47725	26.120000000000001
98	2022-04-28 16:02:21.57825	16.43
99	2022-04-28 16:02:22.37425	121.73
100	2022-04-28 16:02:22.58625	85.219999999999999
101	2022-04-28 16:02:21.89325	135.40000000000001
102	2022-04-28 16:02:21.39025	115.42
103	2022-04-28 16:02:22.31925	90.980000000000004
104	2022-04-28 16:02:22.53825	81.560000000000002
105	2022-04-28 16:02:22.23625	128.52000000000001
106	2022-04-28 16:02:22.67025	111.88
107	2022-04-28 16:02:21.40025	42.729999999999997
108	2022-04-28 16:02:21.40225	4.2999999999999998
109	2022-04-28 16:02:22.71225	24.559999999999999
110	2022-04-28 16:02:21.40625	7.9400000000000004
111	2022-04-28 16:02:21.29725	12.19
112	2022-04-28 16:02:22.19425	88.579999999999998
113	2022-04-28 16:02:22.31625	103.7
114	2022-04-28 16:02:21.98425	99.879999999999995
115	2022-04-28 16:02:21.64625	12.279999999999999
116	2022-04-28 16:02:21.41825	42.729999999999997
117	2022-04-28 16:02:21.65425	120.34999999999999
118	2022-04-28 16:02:21.77625	135.43000000000001
119	2022-04-28 16:02:22.61425	60.859999999999999
120	2022-04-28 16:02:22.62625	15.09
121	2022-04-28 16:02:22.88025	131.49000000000001
122	2022-04-28 16:02:22.40625	86.159999999999997
123	2022-04-28 16:02:22.29325	78.730000000000004
124	2022-04-28 16:02:22.17825	122.41
125	2022-04-28 16:02:21.56125	24.43
126	2022-04-28 16:02:21.56425	95.870000000000005
127	2022-04-28 16:02:22.58325	132.31
128	2022-04-28 16:02:22.33825	55.740000000000002
129	2022-04-28 16:02:21.83125	61.840000000000003
130	2022-04-28 16:02:21.44625	9.1199999999999992
131	2022-04-28 16:02:21.71025	32.170000000000002
132	2022-04-28 16:02:21.97825	88.310000000000002
133	2022-04-28 16:02:22.78225	101.59999999999999
134	2022-04-28 16:02:22.39225	36.939999999999998
135	2022-04-28 16:02:23.07625	19.870000000000001
136	2022-04-28 16:02:21.73025	82.700000000000003
137	2022-04-28 16:02:21.87125	140.34
138	2022-04-28 16:02:21.60025	16.73
139	2022-04-28 16:02:22.02025	6.8499999999999996
140	2022-04-28 16:02:23.14625	25.52
141	2022-04-28 16:02:21.60925	85.579999999999998
142	2022-04-28 16:02:22.46425	6.8899999999999997
143	2022-04-28 16:02:23.18825	59.189999999999998
144	2022-04-28 16:02:22.33825	41.280000000000001
145	2022-04-28 16:02:21.91125	132.38
146	2022-04-28 16:02:22.50025	56.130000000000003
147	2022-04-28 16:02:22.06825	116.3
148	2022-04-28 16:02:23.11025	105.65000000000001
149	2022-04-28 16:02:22.37825	11.77
150	2022-04-28 16:02:22.83625	134.66
151	2022-04-28 16:02:23.30025	43.100000000000001
152	2022-04-28 16:02:23.01025	142.84
153	2022-04-28 16:02:23.32825	82.079999999999998
154	2022-04-28 16:02:22.11025	117.86
155	2022-04-28 16:02:23.04625	68.040000000000006
156	2022-04-28 16:02:23.37025	39.170000000000002
157	2022-04-28 16:02:22.28525	133.43000000000001
158	2022-04-28 16:02:23.24025	89.299999999999997
159	2022-04-28 16:02:22.77625	46.990000000000002
160	2022-04-28 16:02:22.78625	62.030000000000001
161	2022-04-28 16:02:21.83025	44.780000000000001
162	2022-04-28 16:02:23.45425	14.140000000000001
163	2022-04-28 16:02:22.49025	122.11
164	2022-04-28 16:02:21.84225	74.739999999999995
165	2022-04-28 16:02:21.51625	56.359999999999999
166	2022-04-28 16:02:22.68025	48.119999999999997
167	2022-04-28 16:02:22.02125	9.5600000000000005
168	2022-04-28 16:02:21.85825	128.31999999999999
169	2022-04-28 16:02:23.04525	86.230000000000004
170	2022-04-28 16:02:21.69625	57.32
171	2022-04-28 16:02:21.52825	102.7
172	2022-04-28 16:02:22.39025	115.31
173	2022-04-28 16:02:23.43525	53.880000000000003
174	2022-04-28 16:02:23.62225	60.390000000000001
175	2022-04-28 16:02:23.46125	42.789999999999999
176	2022-04-28 16:02:21.53825	34.259999999999998
177	2022-04-28 16:02:22.42525	50.68
178	2022-04-28 16:02:23.14425	95.659999999999997
179	2022-04-28 16:02:22.08125	109.52
180	2022-04-28 16:02:22.62625	15.99
181	2022-04-28 16:02:22.09125	122
182	2022-04-28 16:02:23.18825	61.700000000000003
183	2022-04-28 16:02:23.56525	95.5
184	2022-04-28 16:02:23.76225	55.840000000000003
185	2022-04-28 16:02:23.03625	1.27
186	2022-04-28 16:02:23.60425	8.7699999999999996
187	2022-04-28 16:02:21.93425	39.350000000000001
188	2022-04-28 16:02:22.31425	70.239999999999995
189	2022-04-28 16:02:23.45425	30.18
190	2022-04-28 16:02:21.75625	20.710000000000001
191	2022-04-28 16:02:23.66925	120.40000000000001
192	2022-04-28 16:02:22.91425	113.22
193	2022-04-28 16:02:22.15125	48.990000000000002
194	2022-04-28 16:02:23.70825	135.37
195	2022-04-28 16:02:22.16125	81.310000000000002
196	2022-04-28 16:02:22.95025	144.30000000000001
197	2022-04-28 16:02:21.77725	144.69999999999999
198	2022-04-28 16:02:21.58225	32.369999999999997
199	2022-04-28 16:02:23.97225	9.2799999999999994
200	2022-04-28 16:02:23.78625	41.030000000000001
201	2022-04-28 16:02:22.39225	82.670000000000002
202	2022-04-28 16:02:23.20625	133.21000000000001
203	2022-04-28 16:02:22.60725	5.5199999999999996
204	2022-04-28 16:02:21.39025	23.510000000000002
205	2022-04-28 16:02:24.05625	39.25
206	2022-04-28 16:02:23.65825	15.210000000000001
207	2022-04-28 16:02:23.04925	51.189999999999998
208	2022-04-28 16:02:22.01825	72.799999999999997
209	2022-04-28 16:02:22.02225	140.53
210	2022-04-28 16:02:21.81625	83.579999999999998
211	2022-04-28 16:02:23.50725	9.6600000000000001
212	2022-04-28 16:02:21.61025	22.91
213	2022-04-28 16:02:22.67725	127.22
214	2022-04-28 16:02:24.18225	33.5
215	2022-04-28 16:02:22.04625	23.079999999999998
216	2022-04-28 16:02:22.91425	112.29000000000001
217	2022-04-28 16:02:22.27125	128.47999999999999
218	2022-04-28 16:02:23.58425	48.700000000000003
219	2022-04-28 16:02:21.84325	98.939999999999998
220	2022-04-28 16:02:22.50625	40.189999999999998
221	2022-04-28 16:02:22.29125	109.51000000000001
222	2022-04-28 16:02:24.29425	8.5899999999999999
223	2022-04-28 16:02:23.63925	71.370000000000005
224	2022-04-28 16:02:22.53025	110.92
225	2022-04-28 16:02:23.88625	83.219999999999999
226	2022-04-28 16:02:24.35025	144.44
227	2022-04-28 16:02:24.36425	46.920000000000002
228	2022-04-28 16:02:23.01025	46.960000000000001
229	2022-04-28 16:02:23.01825	81.030000000000001
230	2022-04-28 16:02:23.02625	80.090000000000003
231	2022-04-28 16:02:21.64825	114.45
232	2022-04-28 16:02:24.43425	119.93000000000001
233	2022-04-28 16:02:23.74925	9.5700000000000003
234	2022-04-28 16:02:23.99425	103.43000000000001
235	2022-04-28 16:02:23.30125	127.81999999999999
236	2022-04-28 16:02:22.60225	82.799999999999997
237	2022-04-28 16:02:23.31925	123.56
238	2022-04-28 16:02:22.13825	144.87
239	2022-04-28 16:02:21.90325	3.04
240	2022-04-28 16:02:22.86625	135.22
\.


--
-- TOC entry 2172 (class 0 OID 92080)
-- Dependencies: 186
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
-- TOC entry 2194 (class 0 OID 0)
-- Dependencies: 185
-- Name: glossary_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.glossary_key_seq', 240, true);


--
-- TOC entry 2177 (class 0 OID 92129)
-- Dependencies: 191
-- Data for Name: integer_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_actual (key, fix, value) FROM stdin;
1	2022-04-28 16:02:21.19325	28
2	2022-04-28 16:02:21.20025	92
3	2022-04-28 16:02:21.19825	77
4	2022-04-28 16:02:21.23425	145
5	2022-04-28 16:02:21.21625	65
6	2022-04-28 16:02:21.25825	83
7	2022-04-28 16:02:21.21425	118
8	2022-04-28 16:02:21.21825	78
9	2022-04-28 16:02:21.29425	20
10	2022-04-28 16:02:21.23625	98
11	2022-04-28 16:02:21.29625	101
12	2022-04-28 16:02:21.22225	132
13	2022-04-28 16:02:21.23825	60
14	2022-04-28 16:02:21.27025	14
15	2022-04-28 16:02:21.21625	78
16	2022-04-28 16:02:21.25025	72
17	2022-04-28 16:02:21.23725	83
18	2022-04-28 16:02:21.22225	131
19	2022-04-28 16:02:21.30025	48
20	2022-04-28 16:02:21.38625	33
21	2022-04-28 16:02:21.27025	115
22	2022-04-28 16:02:21.31825	22
23	2022-04-28 16:02:21.23225	117
24	2022-04-28 16:02:21.33025	117
25	2022-04-28 16:02:21.43625	104
26	2022-04-28 16:02:21.29025	141
27	2022-04-28 16:02:21.45625	110
28	2022-04-28 16:02:21.29825	114
29	2022-04-28 16:02:21.21525	77
30	2022-04-28 16:02:21.39625	113
31	2022-04-28 16:02:21.27925	109
32	2022-04-28 16:02:21.60225	120
33	2022-04-28 16:02:21.31825	50
34	2022-04-28 16:02:21.42425	89
35	2022-04-28 16:02:21.57125	42
36	2022-04-28 16:02:21.33025	69
37	2022-04-28 16:02:21.48225	14
38	2022-04-28 16:02:21.45225	133
39	2022-04-28 16:02:21.42025	5
40	2022-04-28 16:02:21.66625	57
41	2022-04-28 16:02:21.22725	85
42	2022-04-28 16:02:21.48025	52
43	2022-04-28 16:02:21.44425	36
44	2022-04-28 16:02:21.67025	55
45	2022-04-28 16:02:21.45625	43
46	2022-04-28 16:02:21.78425	120
47	2022-04-28 16:02:21.79725	127
48	2022-04-28 16:02:21.28225	70
49	2022-04-28 16:02:21.82325	78
50	2022-04-28 16:02:21.83625	104
51	2022-04-28 16:02:21.49225	113
52	2022-04-28 16:02:21.29025	56
53	2022-04-28 16:02:21.61025	107
54	2022-04-28 16:02:21.61825	91
55	2022-04-28 16:02:21.46125	47
56	2022-04-28 16:02:21.57825	143
57	2022-04-28 16:02:21.75625	8
58	2022-04-28 16:02:21.82425	82
59	2022-04-28 16:02:21.48125	84
60	2022-04-28 16:02:21.66625	143
61	2022-04-28 16:02:21.73525	10
62	2022-04-28 16:02:21.49625	65
63	2022-04-28 16:02:21.56425	54
64	2022-04-28 16:02:21.76225	90
65	2022-04-28 16:02:21.25125	141
66	2022-04-28 16:02:21.31825	117
67	2022-04-28 16:02:21.38725	23
68	2022-04-28 16:02:21.32225	36
69	2022-04-28 16:02:21.73825	7
70	2022-04-28 16:02:22.02625	88
71	2022-04-28 16:02:21.96725	24
72	2022-04-28 16:02:21.33025	5
73	2022-04-28 16:02:22.06225	132
74	2022-04-28 16:02:21.40825	123
75	2022-04-28 16:02:21.41125	76
76	2022-04-28 16:02:21.41425	43
77	2022-04-28 16:02:21.34025	136
78	2022-04-28 16:02:21.42025	45
79	2022-04-28 16:02:21.81825	91
80	2022-04-28 16:02:22.30625	25
81	2022-04-28 16:02:21.42925	126
82	2022-04-28 16:02:21.92425	50
83	2022-04-28 16:02:21.60125	93
84	2022-04-28 16:02:22.27825	76
85	2022-04-28 16:02:21.35625	75
86	2022-04-28 16:02:21.35825	41
87	2022-04-28 16:02:22.14325	130
88	2022-04-28 16:02:21.53825	59
89	2022-04-28 16:02:22.43225	36
90	2022-04-28 16:02:21.99625	71
91	2022-04-28 16:02:21.55025	107
92	2022-04-28 16:02:21.92225	72
93	2022-04-28 16:02:22.30225	111
94	2022-04-28 16:02:22.22025	27
95	2022-04-28 16:02:22.51625	105
96	2022-04-28 16:02:22.24225	129
97	2022-04-28 16:02:21.38025	97
98	2022-04-28 16:02:21.87225	130
99	2022-04-28 16:02:21.97825	106
100	2022-04-28 16:02:22.28625	31
101	2022-04-28 16:02:21.38825	93
102	2022-04-28 16:02:22.41025	88
103	2022-04-28 16:02:21.90725	128
104	2022-04-28 16:02:22.01825	22
105	2022-04-28 16:02:22.23625	110
106	2022-04-28 16:02:21.71625	40
107	2022-04-28 16:02:21.40025	75
108	2022-04-28 16:02:22.69825	62
109	2022-04-28 16:02:21.84025	19
110	2022-04-28 16:02:22.06625	74
111	2022-04-28 16:02:22.62925	101
112	2022-04-28 16:02:22.08225	45
113	2022-04-28 16:02:22.54225	25
114	2022-04-28 16:02:21.64225	13
115	2022-04-28 16:02:21.99125	49
116	2022-04-28 16:02:22.57825	40
117	2022-04-28 16:02:22.12225	58
118	2022-04-28 16:02:22.01225	84
119	2022-04-28 16:02:22.73325	131
120	2022-04-28 16:02:21.42625	136
121	2022-04-28 16:02:21.67025	91
122	2022-04-28 16:02:22.04025	36
123	2022-04-28 16:02:22.04725	68
124	2022-04-28 16:02:22.79825	80
125	2022-04-28 16:02:22.56125	5
126	2022-04-28 16:02:22.19425	62
127	2022-04-28 16:02:21.69425	39
128	2022-04-28 16:02:21.95425	51
129	2022-04-28 16:02:21.57325	76
130	2022-04-28 16:02:22.74625	45
131	2022-04-28 16:02:22.49625	67
132	2022-04-28 16:02:22.50625	55
133	2022-04-28 16:02:22.91525	7
134	2022-04-28 16:02:22.79425	93
135	2022-04-28 16:02:21.45625	55
136	2022-04-28 16:02:22.27425	68
137	2022-04-28 16:02:21.59725	87
138	2022-04-28 16:02:21.87625	36
139	2022-04-28 16:02:21.74225	42
140	2022-04-28 16:02:23.00625	48
141	2022-04-28 16:02:21.89125	99
142	2022-04-28 16:02:22.03825	62
143	2022-04-28 16:02:22.90225	63
144	2022-04-28 16:02:21.47425	33
145	2022-04-28 16:02:21.47625	15
146	2022-04-28 16:02:22.20825	57
147	2022-04-28 16:02:21.48025	105
148	2022-04-28 16:02:21.92625	111
149	2022-04-28 16:02:23.12325	15
150	2022-04-28 16:02:22.08625	55
151	2022-04-28 16:02:22.69625	34
152	2022-04-28 16:02:22.40225	50
153	2022-04-28 16:02:22.41025	11
154	2022-04-28 16:02:21.95625	88
155	2022-04-28 16:02:23.35625	15
156	2022-04-28 16:02:21.65425	121
157	2022-04-28 16:02:22.59925	72
158	2022-04-28 16:02:21.34425	141
159	2022-04-28 16:02:21.50425	41
160	2022-04-28 16:02:22.62625	69
161	2022-04-28 16:02:23.44025	83
162	2022-04-28 16:02:22.64425	141
163	2022-04-28 16:02:23.30525	19
164	2022-04-28 16:02:22.17025	56
165	2022-04-28 16:02:22.01125	76
166	2022-04-28 16:02:22.01625	19
167	2022-04-28 16:02:23.52425	77
168	2022-04-28 16:02:22.86625	12
169	2022-04-28 16:02:21.86225	6
170	2022-04-28 16:02:23.39625	108
171	2022-04-28 16:02:21.69925	68
172	2022-04-28 16:02:21.87425	140
173	2022-04-28 16:02:23.60825	93
174	2022-04-28 16:02:23.10025	86
175	2022-04-28 16:02:23.11125	46
176	2022-04-28 16:02:22.94625	96
177	2022-04-28 16:02:22.60225	126
178	2022-04-28 16:02:22.43225	16
179	2022-04-28 16:02:22.97625	75
180	2022-04-28 16:02:22.44625	59
181	2022-04-28 16:02:22.99625	136
182	2022-04-28 16:02:22.09625	68
183	2022-04-28 16:02:23.19925	145
184	2022-04-28 16:02:23.57825	16
185	2022-04-28 16:02:23.40625	136
186	2022-04-28 16:02:23.23225	10
187	2022-04-28 16:02:22.30825	120
188	2022-04-28 16:02:22.31425	73
189	2022-04-28 16:02:22.32025	91
190	2022-04-28 16:02:23.84625	41
191	2022-04-28 16:02:22.33225	115
192	2022-04-28 16:02:23.10625	145
193	2022-04-28 16:02:23.50225	96
194	2022-04-28 16:02:22.93225	13
195	2022-04-28 16:02:21.77125	81
196	2022-04-28 16:02:22.55825	101
197	2022-04-28 16:02:22.95925	74
198	2022-04-28 16:02:21.58225	26
199	2022-04-28 16:02:21.78325	113
200	2022-04-28 16:02:21.98625	142
201	2022-04-28 16:02:23.39725	96
202	2022-04-28 16:02:23.40825	114
203	2022-04-28 16:02:22.81025	90
204	2022-04-28 16:02:22.20625	103
205	2022-04-28 16:02:22.82625	131
206	2022-04-28 16:02:23.45225	5
207	2022-04-28 16:02:22.84225	23
208	2022-04-28 16:02:21.60225	130
209	2022-04-28 16:02:22.23125	45
210	2022-04-28 16:02:23.07625	19
211	2022-04-28 16:02:22.45225	117
212	2022-04-28 16:02:24.15425	43
213	2022-04-28 16:02:22.89025	13
214	2022-04-28 16:02:22.68425	126
215	2022-04-28 16:02:23.55125	29
216	2022-04-28 16:02:22.48225	81
217	2022-04-28 16:02:22.70525	3
218	2022-04-28 16:02:22.93025	102
219	2022-04-28 16:02:21.62425	130
220	2022-04-28 16:02:22.72625	34
221	2022-04-28 16:02:22.51225	130
222	2022-04-28 16:02:23.18425	33
223	2022-04-28 16:02:23.63925	59
224	2022-04-28 16:02:22.08225	66
225	2022-04-28 16:02:22.76125	24
226	2022-04-28 16:02:24.12425	126
227	2022-04-28 16:02:21.86725	9
228	2022-04-28 16:02:23.23825	138
229	2022-04-28 16:02:23.47625	68
230	2022-04-28 16:02:22.33625	67
231	2022-04-28 16:02:21.87925	62
232	2022-04-28 16:02:24.20225	46
233	2022-04-28 16:02:23.28325	33
234	2022-04-28 16:02:23.29225	73
235	2022-04-28 16:02:23.53625	50
236	2022-04-28 16:02:24.01825	56
237	2022-04-28 16:02:24.03025	59
238	2022-04-28 16:02:23.80425	75
239	2022-04-28 16:02:22.14225	112
240	2022-04-28 16:02:23.10625	16
\.


--
-- TOC entry 2176 (class 0 OID 92121)
-- Dependencies: 190
-- Data for Name: integer_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integer_archive (key, fix, value) FROM stdin;
1	2022-04-28 16:02:21.19925	2
2	2022-04-28 16:02:21.19825	89
3	2022-04-28 16:02:21.20125	68
4	2022-04-28 16:02:21.21025	57
5	2022-04-28 16:02:21.22125	84
6	2022-04-28 16:02:21.19825	85
7	2022-04-28 16:02:21.24925	145
8	2022-04-28 16:02:21.20225	138
9	2022-04-28 16:02:21.31225	39
10	2022-04-28 16:02:21.28625	81
11	2022-04-28 16:02:21.31825	99
12	2022-04-28 16:02:21.33025	20
13	2022-04-28 16:02:21.25125	77
14	2022-04-28 16:02:21.20025	110
15	2022-04-28 16:02:21.26125	11
16	2022-04-28 16:02:21.36225	132
17	2022-04-28 16:02:21.42425	27
18	2022-04-28 16:02:21.33025	24
19	2022-04-28 16:02:21.20525	48
20	2022-04-28 16:02:21.22625	16
21	2022-04-28 16:02:21.43825	30
22	2022-04-28 16:02:21.23025	10
23	2022-04-28 16:02:21.30125	42
24	2022-04-28 16:02:21.45025	123
25	2022-04-28 16:02:21.33625	117
26	2022-04-28 16:02:21.39425	140
27	2022-04-28 16:02:21.26725	139
28	2022-04-28 16:02:21.32625	34
29	2022-04-28 16:02:21.30225	40
30	2022-04-28 16:02:21.33625	110
31	2022-04-28 16:02:21.40325	94
32	2022-04-28 16:02:21.25025	54
33	2022-04-28 16:02:21.58225	19
34	2022-04-28 16:02:21.52625	64
35	2022-04-28 16:02:21.43125	132
36	2022-04-28 16:02:21.65425	92
37	2022-04-28 16:02:21.33425	79
38	2022-04-28 16:02:21.60425	91
39	2022-04-28 16:02:21.53725	110
40	2022-04-28 16:02:21.66625	4
41	2022-04-28 16:02:21.63725	26
42	2022-04-28 16:02:21.48025	72
43	2022-04-28 16:02:21.53025	111
44	2022-04-28 16:02:21.71425	144
45	2022-04-28 16:02:21.77125	48
46	2022-04-28 16:02:21.83025	109
47	2022-04-28 16:02:21.23325	40
48	2022-04-28 16:02:21.66625	28
49	2022-04-28 16:02:21.33325	101
50	2022-04-28 16:02:21.38625	27
51	2022-04-28 16:02:21.69625	48
52	2022-04-28 16:02:21.49825	63
53	2022-04-28 16:02:21.87525	134
54	2022-04-28 16:02:21.78025	84
55	2022-04-28 16:02:21.40625	96
56	2022-04-28 16:02:21.69025	63
57	2022-04-28 16:02:21.58525	43
58	2022-04-28 16:02:21.99825	40
59	2022-04-28 16:02:21.42225	88
60	2022-04-28 16:02:21.90625	15
61	2022-04-28 16:02:21.55225	94
62	2022-04-28 16:02:21.68225	19
63	2022-04-28 16:02:22.06825	28
64	2022-04-28 16:02:21.76225	141
65	2022-04-28 16:02:22.03125	80
66	2022-04-28 16:02:21.71425	134
67	2022-04-28 16:02:21.72225	94
68	2022-04-28 16:02:21.59425	65
69	2022-04-28 16:02:21.94525	144
70	2022-04-28 16:02:21.81625	87
71	2022-04-28 16:02:21.32825	32
72	2022-04-28 16:02:21.97825	35
73	2022-04-28 16:02:21.98925	79
74	2022-04-28 16:02:21.55625	106
75	2022-04-28 16:02:21.56125	57
76	2022-04-28 16:02:22.25025	75
77	2022-04-28 16:02:22.11025	18
78	2022-04-28 16:02:22.12225	2
79	2022-04-28 16:02:22.05525	41
80	2022-04-28 16:02:21.82625	101
81	2022-04-28 16:02:21.59125	110
82	2022-04-28 16:02:22.00625	100
83	2022-04-28 16:02:21.43525	100
84	2022-04-28 16:02:22.27825	117
85	2022-04-28 16:02:22.29125	81
86	2022-04-28 16:02:21.87425	34
87	2022-04-28 16:02:22.40425	38
88	2022-04-28 16:02:21.36225	20
89	2022-04-28 16:02:22.34325	45
90	2022-04-28 16:02:21.81625	58
91	2022-04-28 16:02:22.36925	130
92	2022-04-28 16:02:22.10625	72
93	2022-04-28 16:02:22.02325	2
94	2022-04-28 16:02:21.37425	64
95	2022-04-28 16:02:22.32625	54
96	2022-04-28 16:02:22.14625	73
97	2022-04-28 16:02:21.96225	134
98	2022-04-28 16:02:21.67625	42
99	2022-04-28 16:02:21.97825	12
100	2022-04-28 16:02:21.38625	5
101	2022-04-28 16:02:22.19625	72
102	2022-04-28 16:02:22.41025	106
103	2022-04-28 16:02:22.52525	107
104	2022-04-28 16:02:22.01825	86
105	2022-04-28 16:02:21.39625	104
106	2022-04-28 16:02:21.50425	70
107	2022-04-28 16:02:22.57725	15
108	2022-04-28 16:02:22.48225	61
109	2022-04-28 16:02:21.40425	30
110	2022-04-28 16:02:21.51625	21
111	2022-04-28 16:02:22.18525	65
112	2022-04-28 16:02:21.29825	81
113	2022-04-28 16:02:22.65525	145
114	2022-04-28 16:02:22.44025	10
115	2022-04-28 16:02:22.79625	113
116	2022-04-28 16:02:22.23025	119
117	2022-04-28 16:02:21.65425	56
118	2022-04-28 16:02:22.48425	58
119	2022-04-28 16:02:21.42425	141
120	2022-04-28 16:02:22.26625	124
121	2022-04-28 16:02:22.15425	71
122	2022-04-28 16:02:21.91825	14
123	2022-04-28 16:02:21.67825	28
124	2022-04-28 16:02:22.30225	59
125	2022-04-28 16:02:21.56125	128
126	2022-04-28 16:02:21.69025	47
127	2022-04-28 16:02:22.96425	139
128	2022-04-28 16:02:22.08225	33
129	2022-04-28 16:02:22.21825	38
130	2022-04-28 16:02:22.74625	131
131	2022-04-28 16:02:21.31725	68
132	2022-04-28 16:02:22.37425	42
133	2022-04-28 16:02:21.58525	45
134	2022-04-28 16:02:21.85625	72
135	2022-04-28 16:02:21.99625	61
136	2022-04-28 16:02:22.00225	14
137	2022-04-28 16:02:22.41925	38
138	2022-04-28 16:02:22.56625	19
139	2022-04-28 16:02:21.46425	133
140	2022-04-28 16:02:21.88625	103
141	2022-04-28 16:02:22.03225	49
142	2022-04-28 16:02:23.17425	13
143	2022-04-28 16:02:22.33025	44
144	2022-04-28 16:02:22.91425	39
145	2022-04-28 16:02:23.21625	76
146	2022-04-28 16:02:23.08425	121
147	2022-04-28 16:02:21.62725	102
148	2022-04-28 16:02:22.96225	4
149	2022-04-28 16:02:22.97425	16
150	2022-04-28 16:02:23.28625	137
151	2022-04-28 16:02:23.14925	20
152	2022-04-28 16:02:21.49025	103
153	2022-04-28 16:02:22.41025	20
154	2022-04-28 16:02:22.88025	105
155	2022-04-28 16:02:21.96125	44
156	2022-04-28 16:02:21.65425	83
157	2022-04-28 16:02:23.38425	19
158	2022-04-28 16:02:22.45025	98
159	2022-04-28 16:02:22.45825	80
160	2022-04-28 16:02:22.94625	117
161	2022-04-28 16:02:22.31325	1
162	2022-04-28 16:02:22.48225	123
163	2022-04-28 16:02:22.49025	73
164	2022-04-28 16:02:23.48225	132
165	2022-04-28 16:02:22.34125	94
166	2022-04-28 16:02:22.01625	140
167	2022-04-28 16:02:23.35725	54
168	2022-04-28 16:02:23.20225	35
169	2022-04-28 16:02:22.03125	36
170	2022-04-28 16:02:22.54625	62
171	2022-04-28 16:02:22.72525	19
172	2022-04-28 16:02:23.59425	97
173	2022-04-28 16:02:22.22425	50
174	2022-04-28 16:02:23.44825	3
175	2022-04-28 16:02:21.71125	27
176	2022-04-28 16:02:22.59425	45
177	2022-04-28 16:02:22.24825	28
178	2022-04-28 16:02:22.61025	134
179	2022-04-28 16:02:22.79725	30
180	2022-04-28 16:02:21.90625	9
181	2022-04-28 16:02:21.91025	118
182	2022-04-28 16:02:22.09625	96
183	2022-04-28 16:02:21.55225	30
184	2022-04-28 16:02:23.02625	85
185	2022-04-28 16:02:22.29625	43
186	2022-04-28 16:02:22.30225	42
187	2022-04-28 16:02:21.37325	45
188	2022-04-28 16:02:21.93825	50
189	2022-04-28 16:02:21.56425	127
190	2022-04-28 16:02:22.70625	26
191	2022-04-28 16:02:22.90525	137
192	2022-04-28 16:02:23.29825	34
193	2022-04-28 16:02:21.76525	140
194	2022-04-28 16:02:22.93225	108
195	2022-04-28 16:02:23.72125	125
196	2022-04-28 16:02:23.14625	15
197	2022-04-28 16:02:21.58025	70
198	2022-04-28 16:02:21.97825	113
199	2022-04-28 16:02:23.57425	45
200	2022-04-28 16:02:23.18625	25
201	2022-04-28 16:02:23.19625	44
202	2022-04-28 16:02:23.20625	128
203	2022-04-28 16:02:23.62225	32
204	2022-04-28 16:02:22.20625	12
205	2022-04-28 16:02:24.05625	22
206	2022-04-28 16:02:23.86425	106
207	2022-04-28 16:02:23.46325	5
208	2022-04-28 16:02:22.64225	36
209	2022-04-28 16:02:21.60425	14
210	2022-04-28 16:02:22.86625	10
211	2022-04-28 16:02:23.08525	132
212	2022-04-28 16:02:23.30625	70
213	2022-04-28 16:02:23.31625	42
214	2022-04-28 16:02:22.04225	80
215	2022-04-28 16:02:21.61625	65
216	2022-04-28 16:02:22.91425	107
217	2022-04-28 16:02:22.05425	47
218	2022-04-28 16:02:22.71225	47
219	2022-04-28 16:02:22.28125	124
220	2022-04-28 16:02:22.72625	135
221	2022-04-28 16:02:23.39625	75
222	2022-04-28 16:02:23.62825	108
223	2022-04-28 16:02:24.30825	133
224	2022-04-28 16:02:22.53025	4
225	2022-04-28 16:02:21.63625	2
226	2022-04-28 16:02:23.44625	105
227	2022-04-28 16:02:23.91025	85
228	2022-04-28 16:02:23.01025	115
229	2022-04-28 16:02:23.24725	30
230	2022-04-28 16:02:22.10625	76
231	2022-04-28 16:02:24.42025	108
232	2022-04-28 16:02:21.41825	77
233	2022-04-28 16:02:23.28325	24
234	2022-04-28 16:02:23.05825	58
235	2022-04-28 16:02:23.06625	19
236	2022-04-28 16:02:24.49025	33
237	2022-04-28 16:02:23.55625	85
238	2022-04-28 16:02:22.61425	16
239	2022-04-28 16:02:21.90325	140
240	2022-04-28 16:02:23.10625	108
1	2022-04-28 16:02:21.19925	32
2	2022-04-28 16:02:21.20225	9
3	2022-04-28 16:02:21.21925	117
4	2022-04-28 16:02:21.23825	95
5	2022-04-28 16:02:21.24125	101
6	2022-04-28 16:02:21.25225	11
7	2022-04-28 16:02:21.24925	131
8	2022-04-28 16:02:21.29825	137
9	2022-04-28 16:02:21.25825	37
10	2022-04-28 16:02:21.21625	119
11	2022-04-28 16:02:21.26325	143
12	2022-04-28 16:02:21.27025	133
13	2022-04-28 16:02:21.21225	71
14	2022-04-28 16:02:21.21425	33
15	2022-04-28 16:02:21.24625	66
16	2022-04-28 16:02:21.34625	93
17	2022-04-28 16:02:21.35625	72
18	2022-04-28 16:02:21.34825	112
19	2022-04-28 16:02:21.26225	139
20	2022-04-28 16:02:21.42625	119
21	2022-04-28 16:02:21.27025	124
22	2022-04-28 16:02:21.38425	125
23	2022-04-28 16:02:21.34725	132
24	2022-04-28 16:02:21.40225	112
25	2022-04-28 16:02:21.41125	65
26	2022-04-28 16:02:21.42025	129
27	2022-04-28 16:02:21.51025	100
28	2022-04-28 16:02:21.32625	133
29	2022-04-28 16:02:21.50525	86
30	2022-04-28 16:02:21.24625	38
31	2022-04-28 16:02:21.52725	104
32	2022-04-28 16:02:21.41025	47
33	2022-04-28 16:02:21.25225	13
34	2022-04-28 16:02:21.39025	21
35	2022-04-28 16:02:21.36125	27
36	2022-04-28 16:02:21.54625	80
37	2022-04-28 16:02:21.44525	44
38	2022-04-28 16:02:21.52825	82
39	2022-04-28 16:02:21.42025	91
40	2022-04-28 16:02:21.50625	18
41	2022-04-28 16:02:21.71925	43
42	2022-04-28 16:02:21.56425	111
43	2022-04-28 16:02:21.70225	112
44	2022-04-28 16:02:21.71425	3
45	2022-04-28 16:02:21.32125	103
46	2022-04-28 16:02:21.27825	94
47	2022-04-28 16:02:21.79725	78
48	2022-04-28 16:02:21.28225	74
49	2022-04-28 16:02:21.52925	46
50	2022-04-28 16:02:21.78625	47
51	2022-04-28 16:02:21.59425	67
52	2022-04-28 16:02:21.60225	66
53	2022-04-28 16:02:21.76925	9
54	2022-04-28 16:02:21.56425	80
55	2022-04-28 16:02:21.29625	111
56	2022-04-28 16:02:21.69025	18
57	2022-04-28 16:02:21.30025	132
58	2022-04-28 16:02:21.53425	66
59	2022-04-28 16:02:21.36325	100
60	2022-04-28 16:02:21.60625	40
61	2022-04-28 16:02:21.49125	53
62	2022-04-28 16:02:22.05425	84
63	2022-04-28 16:02:21.37525	11
64	2022-04-28 16:02:21.76225	134
65	2022-04-28 16:02:21.44625	14
66	2022-04-28 16:02:21.38425	8
67	2022-04-28 16:02:21.99025	29
68	2022-04-28 16:02:21.79825	64
69	2022-04-28 16:02:22.01425	21
70	2022-04-28 16:02:21.32625	117
71	2022-04-28 16:02:21.61225	36
72	2022-04-28 16:02:22.12225	60
73	2022-04-28 16:02:21.40525	134
74	2022-04-28 16:02:21.85225	4
75	2022-04-28 16:02:21.48625	91
76	2022-04-28 16:02:21.64225	106
77	2022-04-28 16:02:22.11025	81
78	2022-04-28 16:02:21.26425	27
79	2022-04-28 16:02:21.81825	132
80	2022-04-28 16:02:21.58625	97
81	2022-04-28 16:02:21.75325	75
82	2022-04-28 16:02:21.67825	145
83	2022-04-28 16:02:21.93325	75
84	2022-04-28 16:02:21.60625	129
85	2022-04-28 16:02:21.69625	134
86	2022-04-28 16:02:22.04625	144
87	2022-04-28 16:02:22.05625	97
88	2022-04-28 16:02:22.33025	10
89	2022-04-28 16:02:21.80925	83
90	2022-04-28 16:02:21.81625	34
91	2022-04-28 16:02:21.91425	88
92	2022-04-28 16:02:22.19825	87
93	2022-04-28 16:02:22.20925	64
94	2022-04-28 16:02:21.56225	36
95	2022-04-28 16:02:21.47125	59
96	2022-04-28 16:02:22.53025	131
97	2022-04-28 16:02:22.35025	54
98	2022-04-28 16:02:21.77425	120
99	2022-04-28 16:02:22.47325	135
100	2022-04-28 16:02:22.38625	92
101	2022-04-28 16:02:22.09525	99
102	2022-04-28 16:02:22.20625	38
103	2022-04-28 16:02:22.62825	57
104	2022-04-28 16:02:21.39425	27
105	2022-04-28 16:02:22.13125	140
106	2022-04-28 16:02:22.35225	134
107	2022-04-28 16:02:21.93525	13
108	2022-04-28 16:02:21.51025	121
109	2022-04-28 16:02:22.38525	106
110	2022-04-28 16:02:21.73625	26
111	2022-04-28 16:02:21.74125	12
112	2022-04-28 16:02:22.41825	135
113	2022-04-28 16:02:22.76825	109
114	2022-04-28 16:02:21.52825	43
115	2022-04-28 16:02:21.76125	16
116	2022-04-28 16:02:21.53425	75
117	2022-04-28 16:02:22.47325	117
118	2022-04-28 16:02:22.24825	120
119	2022-04-28 16:02:22.73325	72
120	2022-04-28 16:02:22.26625	49
121	2022-04-28 16:02:21.91225	5
122	2022-04-28 16:02:22.28425	32
123	2022-04-28 16:02:22.41625	5
124	2022-04-28 16:02:22.05425	109
125	2022-04-28 16:02:21.68625	79
126	2022-04-28 16:02:21.43825	27
127	2022-04-28 16:02:22.45625	92
128	2022-04-28 16:02:21.82625	78
129	2022-04-28 16:02:22.99225	111
130	2022-04-28 16:02:21.83625	35
131	2022-04-28 16:02:21.71025	114
132	2022-04-28 16:02:22.90225	77
133	2022-04-28 16:02:22.78225	33
134	2022-04-28 16:02:21.58825	98
135	2022-04-28 16:02:22.13125	50
136	2022-04-28 16:02:22.95425	40
137	2022-04-28 16:02:21.59725	138
138	2022-04-28 16:02:22.84225	42
139	2022-04-28 16:02:22.15925	73
140	2022-04-28 16:02:21.88625	138
141	2022-04-28 16:02:21.89125	62
142	2022-04-28 16:02:21.47025	111
143	2022-04-28 16:02:21.47225	141
144	2022-04-28 16:02:23.05825	20
145	2022-04-28 16:02:22.34625	14
146	2022-04-28 16:02:22.93825	23
147	2022-04-28 16:02:21.77425	57
148	2022-04-28 16:02:21.63025	84
149	2022-04-28 16:02:21.63325	15
150	2022-04-28 16:02:22.08625	65
151	2022-04-28 16:02:23.14925	111
152	2022-04-28 16:02:21.94625	126
153	2022-04-28 16:02:22.56325	115
154	2022-04-28 16:02:21.49425	101
155	2022-04-28 16:02:23.04625	6
156	2022-04-28 16:02:21.49825	68
157	2022-04-28 16:02:22.44225	48
158	2022-04-28 16:02:23.24025	116
159	2022-04-28 16:02:22.77625	18
160	2022-04-28 16:02:22.46625	123
161	2022-04-28 16:02:22.15225	5
162	2022-04-28 16:02:21.83425	55
163	2022-04-28 16:02:22.49025	111
164	2022-04-28 16:02:21.51425	105
165	2022-04-28 16:02:23.16625	35
166	2022-04-28 16:02:21.68425	53
167	2022-04-28 16:02:21.68725	119
168	2022-04-28 16:02:21.52225	81
169	2022-04-28 16:02:21.69325	34
170	2022-04-28 16:02:21.69625	37
171	2022-04-28 16:02:23.40925	26
172	2022-04-28 16:02:22.04625	66
173	2022-04-28 16:02:21.35925	58
174	2022-04-28 16:02:22.92625	129
175	2022-04-28 16:02:22.41125	46
176	2022-04-28 16:02:23.47425	5
177	2022-04-28 16:02:22.77925	81
178	2022-04-28 16:02:21.54225	123
179	2022-04-28 16:02:22.79725	132
180	2022-04-28 16:02:22.26625	125
181	2022-04-28 16:02:23.17725	52
182	2022-04-28 16:02:23.37025	86
183	2022-04-28 16:02:23.56525	105
184	2022-04-28 16:02:22.29025	99
185	2022-04-28 16:02:21.92625	53
186	2022-04-28 16:02:23.04625	69
187	2022-04-28 16:02:23.80425	36
188	2022-04-28 16:02:23.81825	27
189	2022-04-28 16:02:23.26525	107
190	2022-04-28 16:02:22.32625	14
191	2022-04-28 16:02:21.75925	25
192	2022-04-28 16:02:22.14625	77
193	2022-04-28 16:02:22.34425	17
194	2022-04-28 16:02:23.32025	81
195	2022-04-28 16:02:23.33125	36
196	2022-04-28 16:02:23.93025	34
197	2022-04-28 16:02:23.55025	41
198	2022-04-28 16:02:22.77025	80
199	2022-04-28 16:02:22.18125	105
200	2022-04-28 16:02:22.78625	43
201	2022-04-28 16:02:21.58825	142
202	2022-04-28 16:02:23.20625	17
203	2022-04-28 16:02:23.21625	60
204	2022-04-28 16:02:21.59425	54
205	2022-04-28 16:02:23.03125	132
206	2022-04-28 16:02:21.80425	122
207	2022-04-28 16:02:22.84225	44
208	2022-04-28 16:02:23.47425	84
209	2022-04-28 16:02:21.60425	48
210	2022-04-28 16:02:22.02625	114
211	2022-04-28 16:02:24.14025	118
212	2022-04-28 16:02:24.15425	2
213	2022-04-28 16:02:22.46425	64
214	2022-04-28 16:02:23.11225	102
215	2022-04-28 16:02:23.55125	59
216	2022-04-28 16:02:23.99425	144
217	2022-04-28 16:02:22.05425	12
218	2022-04-28 16:02:21.62225	20
219	2022-04-28 16:02:22.93825	22
220	2022-04-28 16:02:24.04625	138
221	2022-04-28 16:02:21.62825	57
222	2022-04-28 16:02:24.29425	119
223	2022-04-28 16:02:21.85525	22
224	2022-04-28 16:02:23.42625	80
225	2022-04-28 16:02:22.98625	136
226	2022-04-28 16:02:22.76825	144
227	2022-04-28 16:02:23.00225	112
228	2022-04-28 16:02:22.32625	32
229	2022-04-28 16:02:21.41525	93
230	2022-04-28 16:02:23.71625	33
231	2022-04-28 16:02:23.72725	52
232	2022-04-28 16:02:23.50625	30
233	2022-04-28 16:02:21.65225	21
234	2022-04-28 16:02:23.52625	69
235	2022-04-28 16:02:22.12625	91
236	2022-04-28 16:02:21.65825	139
237	2022-04-28 16:02:22.84525	42
238	2022-04-28 16:02:23.80425	85
239	2022-04-28 16:02:24.29325	21
240	2022-04-28 16:02:24.30625	35
\.


--
-- TOC entry 2174 (class 0 OID 92099)
-- Dependencies: 188
-- Data for Name: order_actual; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_actual (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2175 (class 0 OID 92110)
-- Dependencies: 189
-- Data for Name: order_archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_archive (key, fix, value) FROM stdin;
\.


--
-- TOC entry 2173 (class 0 OID 92093)
-- Dependencies: 187
-- Data for Name: synchronization; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.synchronization (xpath, fix, status) FROM stdin;
\.


--
-- TOC entry 2044 (class 2606 OID 92090)
-- Name: glossary glossary_communication_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_communication_key UNIQUE (communication);


--
-- TOC entry 2046 (class 2606 OID 92088)
-- Name: glossary glossary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);


--
-- TOC entry 2053 (class 2620 OID 92092)
-- Name: glossary existence_check_or_creation_table; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER existence_check_or_creation_table BEFORE INSERT ON public.glossary FOR EACH ROW EXECUTE PROCEDURE public.before_insert_in_glossary();


--
-- TOC entry 2052 (class 2606 OID 92148)
-- Name: float_actual float_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_actual
    ADD CONSTRAINT float_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2051 (class 2606 OID 92140)
-- Name: float_archive float_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.float_archive
    ADD CONSTRAINT float_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2050 (class 2606 OID 92132)
-- Name: integer_actual integer_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_actual
    ADD CONSTRAINT integer_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2049 (class 2606 OID 92124)
-- Name: integer_archive integer_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integer_archive
    ADD CONSTRAINT integer_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2047 (class 2606 OID 92105)
-- Name: order_actual order_actual_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_actual
    ADD CONSTRAINT order_actual_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


--
-- TOC entry 2048 (class 2606 OID 92116)
-- Name: order_archive order_archive_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_archive
    ADD CONSTRAINT order_archive_key_fkey FOREIGN KEY (key) REFERENCES public.glossary(key);


-- Completed on 2022-04-28 16:03:58

--
-- PostgreSQL database dump complete
--

