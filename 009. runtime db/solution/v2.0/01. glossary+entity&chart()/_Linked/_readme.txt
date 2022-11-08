1. Добавление в таблицу glossary столбца сущности entity.
2. Добавление в функцию _communication(xpath TEXT, valueNew anyelement, _entity TEXT) третьего
аргумента entity.
3. Функция _communication(xpath TEXT, valueNew anyelement, _entity TEXT) обновляет значение 
entity в таблице glossary по ключу, получаемому из входного параметра xpath TEXT.
4. Функции _refresh(xpath TEXT) и _refresh() продублированы. Первые две копии не изменились и
переименованы в функции _chart(xpath TEXT) и _chart() соответственно.
5. Во вторые две копии добавлена сущность entity.

2022.07.28 18:21 IMM