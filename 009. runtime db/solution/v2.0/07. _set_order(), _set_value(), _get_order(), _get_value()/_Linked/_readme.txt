1. Удаление таблицы synchronization.
2. Замена в таблицах order типа поля entity 
c TEXT на XML.
3. Переименование таблиц entity в таблицы value.
4. Разделение функции _update(xpath TEXT, _entity XML) 
на _set_order(xpath TEXT, _entity XML) и 
_set_value(xpath TEXT, _entity XML).
5. Создание функций _get_order() и _get_value().

2022.08.12 17:56 IMM