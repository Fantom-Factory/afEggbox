@echo off

cd C:\Projects\Fantom-Factory\Eggbox

@echo Compiling website.less
call fan afLess4f -x etc\less\website.less etc\web-static\css\website.min.css
rem call fpm run afLess4f -x etc\less\website.less etc\web-static\css\website.min.css

@echo Done.
@rem pause