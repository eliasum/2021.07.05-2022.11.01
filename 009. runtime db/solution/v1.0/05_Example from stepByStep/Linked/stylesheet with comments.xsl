<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--2021.11.17 09:40 IMM-->

  <!-- https://xsltdev.ru/xslt/xsl-output/
  - Элемент верхнего уровня xsl:output позволяет указывать, каким 
  образом должно быть выведено результирующее дерево.
  
  method - необязательный атрибут, который определяет, какой метод
  должен использоваться для вывода документа. Значением этого атрибута
  может быть любое имя, но при этом техническая рекомендация XSLT 
  определяет только три стандартных метода вывода — "xml", "html" и
  "text". В том случае, если процессор поддерживает нестандартный
  метод вывода, его реализация полностью зависит от производителя. -->
  <xsl:output method="text" encoding="UTF-8"/>
  <!-- https://xsltdev.ru/xslt/xsl-variable/
  - Для объявления переменных в XSLT служит элемент xsl:variable, 
  который может как присутствовать в теле шаблона, так и быть элементом
  верхнего уровня. Если объявление переменной было произведено элементом
  верхнего уровня, переменная называется глобальной переменной.
  
  name - обязательный атрибут, задает имя переменной-->
  <xsl:variable name="apostrophe">'</xsl:variable>
  <!-- https://xsltdev.ru/xslt/xsl-template/
  - Элемент верхнего уровня xsl:template определяет в преобразовании
  шаблонное правило, или просто шаблон.
        
  match - необязательный атрибут, задает паттерн — образец узлов дерева, 
  для преобразования которых следует применять этот шаблон.
  Паттерн на языке XPath.-->

  <!--Шаблон для корневого узла (узла документа)-->
  <xsl:template match="/">
    <xsl:text>
-- PostgreSQL database dump
--"%PROGRAM_PATH%\PostgresPro\10\bin\psql" --username=alex -d postgres -f D:\TEMP\runtime.sql
\connect runtime
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

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

COPY table_Glossary (configuration, allowance, name) FROM stdin;
    </xsl:text>
    <!-- https://xsltdev.ru/xslt/xsl-apply-templates/
    Элемент xsl:apply-templates применяет шаблонные правила к узлам, 
    которые возвращаются выражением, указанным в атрибуте select.

    Если атрибут select опущен, то xsl:apply-templates применяет
    шаблонные правила ко всем дочерним узлам текущего узла.
    
    Т.е. выводится блок текста, остальная часть документа обрабатывается
    другими шаблонами. Следующим шаблоном будет 
    <xsl:template match="node()[@format]">.
    
    В моём коде же в 4 версии один шаблон на весь документ.-->
    <xsl:apply-templates/>
    <xsl:text>
\.
    </xsl:text>
  </xsl:template>

  <!--Шаблон соответствует любому узлу с атрибутом @format. Т.е. шаблон
  задаёт логику обработки всех узлов с атрибутом @format.
  В моём коде в 4 версии вместо этой конструкции цикл xsl:for-each
  верхнего уровня. Т.е. тут смешанная реализация - через шаблон и цикл.
  А у меня через 2 вложенных цикла.-->
  <xsl:template match="node()[@format]">
    <!--Локальная переменная. Если в элементе xsl:variable определен 
    атрибут select, то значением присваиваемого выражения будет 
    результат вычисления выражения, указанного в этом атрибуте;
    По простому - значение @value в теге Allowance присваивается 
    переменной allowance-->
    <xsl:variable name="allowance" select="Allowance/@value"/>
    <!--Выбрать всё (*) МНОЖЕСТВО предков узла с атрибутом format. Цикл
    начинается с предка верхнего уровня и далее вниз по цепочке.-->
    <xsl:for-each select="ancestor::*">
      <!--Функция local-name возвращает локальную часть имени первого
      в порядке просмотра документа узла множества, переданного ей в
      качестве аргумента. Эта функция выполняется следующим образом.
      Если аргумент опущен, то значением функции по умолчанию является
      множество, содержащее единственный КОНТЕКСТНЫЙ узел. Иными 
      словами, функция возвратит локальную часть расширенного имени 
      КОНТЕКСТНОГО УЗЛА (если она существует).
      
      Локальной переменной element присвоить значение локальной части
      расширенного имени КОНТЕКСТНОГО УЗЛА-->
      <xsl:variable name="element" select="local-name()"/>
      <!--name() или name(.) - печатаем имя текущего узла, начиная с
      предка верхнего уровня-->
      <xsl:value-of select="$element"/>
      <!--Если текущий узел - Item, тогда выводим значение его атрибута key-->
      <xsl:if test="$element='Item'">
        <xsl:value-of select="concat('[@key=', $apostrophe, @key, $apostrophe, ']')"/>
      </xsl:if>
      <xsl:text>/</xsl:text>
      <!--Конец итерации (цикла) перебора всех предков узла с атрибутом format-->
    </xsl:for-each>
    <!--Обработка тегов с атрибутом @format. Такая логика обработки дана от stepByStep
    по ему одному веданой логике))-->

    <!-- https://xsltdev.ru/xslt/xsl-choose/
    - Элемент xsl:choose содержит один или несколько элементов xsl:when и 
    необязательный элемент xsl:otherwise.

    При обработке xsl:choose процессор поочередно вычисляет выражения, содержащиеся
    в атрибутах test элементов xsl:when, приводит их к булевому типу и выполняет
    содержимое первого (и только первого) элемента, тестовое выражение которого 
    будет равно true. В случае если ни одно из тестовых выражений не обратилось в
    "истину" и в xsl:choose присутствует xsl:otherwise, процессор выполнит 
    содержимое этого элемента.
    
    https://xsltdev.ru/xpath/starts-with/
    - Функция starts-with принимает на вход два строковых аргумента и возвращает true, 
    если первая строка начинается второй и false в противном случае.  
    
    4 варианта. Атрибут @format может начинаться с 'N', 'F', 'D', а так же с любой другой
    литеры. В зависимости от начальной буквы в конце 'пути к узлу с атрибутом @format'
    печатается имя узла, через пробел значение атрибута @value дочернего тега Allowance и
    через пробел имя связанной таблицы. Название связанной таблицы, которое будет
    напечатано, зависит от начальной литеры атрибута @format.-->
    <xsl:choose>
      <xsl:when test="starts-with(@format, 'N')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Number')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'F')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Float')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'D')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Decimal')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_String')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  <!--Завершение обработки шаблона для всех узлов с атрибутом @format-->
  </xsl:template>
  <!-- https://xsltdev.ru/xslt/xsl-template/
  - Элемент верхнего уровня xsl:template определяет в преобразовании
  шаблонное правило, или просто шаблон.
        
  match - необязательный атрибут, задает паттерн — образец узлов дерева, 
  для преобразования которых следует применять этот шаблон.
  Паттерн на языке XPath.-->

  <!--Шаблон для любого текстового узла-->
  <xsl:template match="text()"/>
</xsl:stylesheet>