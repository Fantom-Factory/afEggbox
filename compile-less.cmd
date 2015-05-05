@echo off

cd C:\Projects\Fantom-Factory\PodRepo

@echo Compiling website.less
call fan afLess4f etc\less\website.less etc\web-static\css\website.min.css

@echo Done.
pause