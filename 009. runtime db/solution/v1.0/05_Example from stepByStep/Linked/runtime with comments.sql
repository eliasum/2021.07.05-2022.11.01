
-- PostgreSQL database dump
--"%PROGRAM_PATH%\PostgresPro\13\bin\psql" --username=postgres -d postgres -f D:\TEMP\runtime.sql
\connect runtime 						-- подключение к базе данных "runtime"
SET statement_timeout = 0;				-- Задаёт максимальное время выполнения оператора (в миллисекундах), начиная с момента получения сервером команды от клиента, по истечении которого оператор прерывается. 
SET lock_timeout = 0;					-- Задаёт максимальную длительность ожидания (в миллисекундах) любым оператором получения блокировки таблицы, индекса, строки или другого объекта базы данных. Если ожидание не закончилось за указанное время, оператор прерывается.
SET client_encoding = 'UTF8';			-- установка клиентской кодировки
SET standard_conforming_strings = on;	-- Этот параметр определяет, будет ли обратная косая черта в обычных строковых константах ('...') восприниматься буквально, как того требует стандарт SQL. Начиная с версии PostgreSQL 9.1, он имеет значение on
SET check_function_bodies = false;		-- Этот параметр обычно включён. Выключение этого параметра (присвоение ему значения off) отключает проверку строки с телом функции, передаваемой команде CREATE FUNCTION. Отключение проверки позволяет избежать побочных эффектов процесса проверки и исключить ложные срабатывания из-за таких проблем, как ссылки вперёд. Этому параметру нужно присваивать значение off перед загрузкой функций от лица других пользователей; pg_dump делает это автоматически.
SET client_min_messages = warning;		-- Управляет минимальным уровнем сообщений, посылаемых клиенту. Допустимые значения DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, LOG, NOTICE, WARNING и ERROR. Каждый из перечисленных уровней включает все идущие после него. Чем дальше в этом списке уровень сообщения, тем меньше сообщений будет посылаться клиенту. По умолчанию используется NOTICE.
SET row_security = off;					-- Эта переменная определяет, должна ли выдаваться ошибка при применении политик защиты строк. Со значением on политики применяются в обычном режиме. Со значением off запросы, ограничиваемые минимум одной политикой, будут выдавать ошибку. Значение по умолчанию — on. Значение off рекомендуется, когда ограничение видимости строк чревато некорректными результатами; например, pg_dump устанавливает это значение. Эта переменная не влияет на роли, которые обходят все политики защиты строк, а именно, на суперпользователей и роли с атрибутом BYPASSRLS

-- Установить расширение, если не существует, plpgsql со схемой pg_catalog
-- plpgsql - процедурное расширение языка SQL, используемое в СУБД PostgreSQL
-- База данных содержит одну или несколько именованных схем, которые в свою очередь содержат таблицы. Схемы также содержат именованные объекты других видов, включая типы данных, функции и операторы. Одно и то же имя объекта можно свободно использовать в разных схемах, например и schema1, и myschema могут содержать таблицы с именем mytable. В отличие от баз данных, схемы не ограничивают доступ к данным: пользователи могут обращаться к объектам в любой схеме текущей базы данных, если им назначены соответствующие права.
-- Системный каталог PostgreSQL это набор таблиц, представлений и функций и все они располагаются в схеме pg_catalog.
-- Посмотреть таблицы или представления из системного каталога можно как с помощью SQL запросов, так и с помощью команд psql.
-- Схема pg_catalog есть в каждой базе данных. Таблички в pg_catalog будут описывать объекты для своей базы. Но есть и общие
-- объекты кластера, которые не принадлежать какой-либо базе данных. Например список баз данных (pg_database), список табличных 
-- пространств, список пользователей – это общие объекты кластера. К общим объектам кластера можно обращаться из любой базы.
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;	-- Эта переменная определяет порядок, в котором будут просматриваться схемы при поиске объекта (таблицы, типа данных, функции и т. д.), к которому обращаются просто по имени, без указания схемы. Если объекты с одинаковым именем находятся в нескольких схемах, использоваться будет тот, что встретится первым при просмотре пути поиска. К объекту, который не относится к схемам, перечисленным в пути поиска, можно обратиться только по полному имени (с точкой), с указанием содержащей его схемы. Значением search_path должен быть список имён схем через запятую. 
SET default_tablespace = '';			-- Эта переменная устанавливает табличное пространство по умолчанию, в котором будут создаваться объекты (таблицы и индексы), когда в команде CREATE табличное пространство не указывается явно. Её значением может быть либо имя табличного пространства, либо пустая строка, подразумевающая использование табличного пространства по умолчанию в текущей базе данных.
SET default_with_oids = false;			-- В PostgreSQL 8.1 default_with_oids по умолчанию отключено; в предыдущих версиях PostgreSQL он был включен по умолчанию. Использование OID в пользовательских таблицах считается устаревшим, поэтому большинство установок должны оставлять эту переменную отключенной.

CREATE TABLE table_Glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);
COMMENT ON TABLE table_Glossary IS 'Словарь для индефикации переменных';
COMMENT ON COLUMN table_Glossary.key IS 'Уникальный ключ переменной для связи с друними таьлицами';
COMMENT ON COLUMN table_Glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
COMMENT ON COLUMN table_Glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
COMMENT ON COLUMN table_Glossary.allowance IS 'Допуск на изменение переменной';
COMMENT ON COLUMN table_Glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';

-- COPY перемещает данные между таблицами Postgres Pro и обычными файлами в файловой системе. COPY TO копирует содержимое
-- таблицы в файл, а COPY FROM — из файла в таблицу (добавляет данные к тем, что уже содержались в таблице). COPY TO может
-- также скопировать результаты запроса SELECT.
-- When STDIN or STDOUT is specified, data is transmitted via the connection between the client and the server.
COPY table_Glossary (configuration, allowance, tablename) FROM stdin;
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Voltage 3 table_Number
\.