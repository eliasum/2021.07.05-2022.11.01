SELECT * FROM order_actual;

SELECT * FROM order_archive;

INSERT INTO order_archive(key, fix, value) SELECT * FROM order_actual WHERE KEY = 1;
