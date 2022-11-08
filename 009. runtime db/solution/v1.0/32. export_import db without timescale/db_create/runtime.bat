@echo off 
cmd /c "psql --username=postgres -d postgres -f C:\TEMP\runtime.sql" > C:\TEMP\cmd.txt
echo %errorlevel% > C:\TEMP\db_create_errorlevel.txt
::pause