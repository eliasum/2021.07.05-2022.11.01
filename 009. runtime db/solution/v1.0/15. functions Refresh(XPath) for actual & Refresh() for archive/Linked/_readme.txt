_036CE063.xml - входной xml файл
stylesheet.xsl - преобразующий файл стилей
stylesheet.txt - выходной файл (UTF-8 c BOM)
runtime.sql - вручную доработанный sql скрипт из выходного файла (UTF-8)

1. В runtime.sql добавлен код создания БД runtime.
2. Исправлена кодировка на UTF-8 (c BOM ошибка - ERROR: syntax error at or near "п>ї").
3. Добавлены/исправлены комментарии.
4. Скрипт runtime.sql полностью приведен к stylesheet.txt (кроме кодировки, т.к. у 
последнего она UTF-8 c BOM.
5. Реализована функция _Refresh(xpath VARCHAR).
6. Реализована функция _Refresh(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP).
7. Код скрипта runtime.sql запускается из командной строки без ошибок.

2022.01.20 18:33 IMM