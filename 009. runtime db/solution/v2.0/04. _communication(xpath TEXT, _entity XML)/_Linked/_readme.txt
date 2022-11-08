1. Замена в таблицах entity типа поля entity с
TEXT на XML.
2. Удаление из функции _communication(...) логики обработки 
значений value. Теперь функция работает только со входными параметрами
xpath TEXT и _entity XML.
3. Удаление функции _refresh(xpath TEXT), 
_refreshold(xpath TEXT, st TIMESTAMP, fin TIMESTAMP), 
_refreshold(st TIMESTAMP, fin TIMESTAMP), _order(xpath TEXT, _value TEXT),
_order(), _chart(xpath TEXT), _chart(), _clear(xpath TEXT).
4. Изменение логики функции _refresh(), теперь работает с параметром
entity XML.
5. Изменение логики функции _synchronizer(_xpath TEXT, _status TEXT),
теперь не удаляет актуальные таблицы. 

2022.08.12 14:29 IMM