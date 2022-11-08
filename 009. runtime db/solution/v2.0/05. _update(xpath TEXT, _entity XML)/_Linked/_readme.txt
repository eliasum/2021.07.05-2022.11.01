1. Переименование функции _communication(xpath TEXT, _entity XML) 
в _update(xpath TEXT, _entity XML).
2. Добавление в функцию _update(xpath TEXT, _entity XML) логики
обновления данных в таблице entity_actual в зависимости
от атрибута @order узла, который поступает в качестве аргумента 
_entity XML.
3. Удаление функции _synchronizer(_xpath TEXT, _status TEXT).

2022.08.12 14:40 IMM