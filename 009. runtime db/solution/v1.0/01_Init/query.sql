-- Создание таблицы Dictionary
CREATE TABLE IF NOT EXISTS public."Dictionary"
(
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "XPath" character varying(200) COLLATE pg_catalog."default",
    "Format" character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT "Dictionary_pkey" PRIMARY KEY (key)
)
	
-- Вывод спика всех доступных таблиц
select table_schema, table_name from information_schema.tables where not table_schema='pg_catalog' and not table_schema='information_schema';

-- Вывод содержимого таблицы Dictionary
SELECT * FROM public."Dictionary";

-- Добавление данных в таблицу Dictionary
INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ('iPhone X', 'Apple');

INSERT INTO public."Dictionary" ("Format") 
VALUES ('Apple');

-- Удаление данных из таблицы Dictionary
TRUNCATE public."Dictionary";

-- Создание таблицы Dictionary2
CREATE TABLE IF NOT EXISTS public."Dictionary"
(
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "XPath" character varying(200) COLLATE pg_catalog."default",
    "Format" character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT "Dictionary_pkey2" PRIMARY KEY (key)
)

-- Удаление таблицы Dictionary2
DROP TABLE public."Dictionary";
