@echo off
title SPIDY DEVIL RESET
echo Daddy is Home... Resetting Full Project 💀🔥
echo.

taskkill /f /im java.exe
taskkill /f /im gradlew.bat

del /s /q .gradle
del /s /q android\.gradle
del /s /q android\build
del /s /q .idea
del /s /q .dart_tool
del /s /q build

flutter clean
flutter pub get

cd android
gradlew.bat --stop
gradlew.bat --no-daemon clean
gradlew.bat build

cd..
flutter run

pause







cd android
gradlew.bat --stop
gradlew.bat --no-daemon clean
gradlew.bat build

cd..
flutter run

pause
cd android
gradlew.bat --stop
gradlew.bat --no-daemon clean
gradlew.bat build

cd..
flutter run

pause

