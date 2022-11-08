--пример использования функции xpath c "чистым xml"
SELECT xpath('*/@*', '<a><b test="1" ></b></a>');

--пример использования функции xpath c xml-данными из столбца entity таблицы entity_actual
SELECT xpath('*/@order', entity)
FROM entity_actual;

--пример использования функции xpath_exists
SELECT xpath_exists('*/@order', entity)
FROM entity_actual;


