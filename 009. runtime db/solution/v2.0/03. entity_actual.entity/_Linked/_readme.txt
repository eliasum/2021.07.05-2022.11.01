1. Удаление поля сущности entity из таблицы glossary.
2. Добавление признака существования в таблице entity_actual записи с ключом _Key
в функции _communication(xpath TEXT, valueNew anyelement, _entity TEXT).
3. Добавление логики обновления/вставки данных в таблицу entity_actual вставки
в функции _communication(xpath TEXT, valueNew anyelement, _entity TEXT).
4. Изменение логики функций _refresh(xpath TEXT) и _refresh() вместо поля 
glossary.entity стало поле entity_actual.entity.

2022.08.01 14:22 IMM