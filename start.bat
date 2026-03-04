@echo off
setlocal
set FLUTTER_ROOT=C:\flutter
set PATH=%FLUTTER_ROOT%\bin;%PATH%
flutter pub get
flutter run
endlocal
