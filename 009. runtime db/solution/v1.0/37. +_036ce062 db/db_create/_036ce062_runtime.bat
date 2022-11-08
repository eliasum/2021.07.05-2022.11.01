@echo off 
cmd /c "psql --username=postgres -d postgres -f C:\TEMP\_036ce062_runtime.sql" > C:\TEMP\_036ce062_runtime_cmd.txt
echo %errorlevel% > C:\TEMP\_036ce062_runtime_create_errorlevel.txt
::pause