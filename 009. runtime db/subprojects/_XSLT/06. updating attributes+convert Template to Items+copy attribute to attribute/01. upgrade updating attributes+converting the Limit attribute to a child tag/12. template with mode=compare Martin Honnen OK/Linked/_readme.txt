1. Замена входного файла на новый.
2. Замена файла Dictionary.xml. 
3. Новое правило: в файле Dictionary.xml для тега <Item key="Attribute"> все
дочерние теги с атрибутом const="?" обрабатываются по тому же правилу, что и
тег Allowance.

Примечание: если тег Allowance не содержится во входном файле, то всё равно он
в виде атрибута присутствует у тегов Amperage, Voltage и Temperature, поэтому
"по умолчанию" добавляется в качестве дочернего тега в выходном дереве со
значением по умолчанию const="1" (Dictionary.xml).

Создан обобщенный шаблон для любых тегов с атрибутом const="?" с mode="compare".

2022.04.18 18:38 IMM