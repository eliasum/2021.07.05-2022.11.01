Рабочий исходный код, вариант Martin Honnen. Релиз. Теги Widget должны быть обёрнуты в 
теги с уникальными именами. 

Консультации на сайте stackoverflow.com.

Проверка правильности слияния файлов конфигурации и профиля. 

- Входной файл тот же:
"_036CE061_min.xml"

- В файле профиля для тега Widget добавлены дополнительные 
атрибуты и дочерние теги:
"profile+additional attributes and child tags.xml"

- Файл трансформации:
"stylesheet+additional attributes and child tags.xsl"

Все данные тега Widget переносятся в выходной файл:
"stylesheet+additional attributes and child tags.xml"

Так же проверка работоспособности при изменении пути к файлу профиля, 
который теперь вынесен в директорию на 1 уровень выше:
<xsl:param name="updates" select="document('../profile+additional attributes and child tags.xml')"/> 

2022.05.11 14:58 IMM