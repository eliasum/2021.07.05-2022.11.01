SELECT key, configuration, tstamp
FROM table_Glossary 
INNER JOIN NumberActual ON key = NumberActKey;

SELECT key, configuration, tstamp
FROM table_Glossary 
INNER JOIN FloatActual ON key = FloatActKey;

SELECT key, configuration, tstamp
FROM table_Glossary 
INNER JOIN DecimalActual ON key = DecimalActKey;

SELECT key, configuration, tstamp
FROM table_Glossary 
INNER JOIN StringActual ON key = StringActKey;