@echo off 
cmd /c "psql --username=postgres -d postgres -f database.sql" > database_cmd.txt
echo %errorlevel% > database_create_errorlevel.txt
::pause