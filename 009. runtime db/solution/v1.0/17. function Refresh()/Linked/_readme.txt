_036CE063.xml - входной xml файл
stylesheet.xsl - преобразующий файл стилей
stylesheet.txt - выходной файл (UTF-8 c BOM)
runtime.sql - вручную доработанный sql скрипт из выходного файла (UTF-8)

1. FUNCTION _refresh(xpath VARCHAR) теперь вместо значения val возвращает соответствующую ему запись. 
2. Добавлена FUNCTION _Refresh().
3. Триггерная FUNCTION before_insert_in_glossary() теперь правильно генерирует таблицы (Integer вместо Float)
в одной из таблиц.
4. Изменены несуществующие в postgresql типы number на integer, string на vatchar.
5. PROCEDURE _communication(xpath VARCHAR, valnew anyelement) теперь принимает униварнсальное значение valnew.
6. Добавлена FUNCTION _refreshold(st TIMESTAMP, fin TIMESTAMP).

2022.01.25 16:28 IMM