@echo off 
cmd /c "pg_dump -U postgres -h localhost runtime" > C:\TEMP\sqlfile.sql
echo %errorlevel% > C:\TEMP\db_export_errorlevel.txt
::pause