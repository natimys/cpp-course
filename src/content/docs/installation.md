---
title: "Что устанавливаем"
---
Для работы нам потребуется редактор кода (VSCode, или любой по вашему вкусу) и компилятор (GCC)

Вся установка будет на винде, если у вас линукс или другая ОС то вы уже явно разбираетесь
## Все автоматически (скрипт)
Вводим в Powershell это:
```powershell
$p="$env:TEMP\install-vscode.ps1"; irm https://raw.githubusercontent.com/natimys/cpp-course/main/scripts/install-vscode.ps1 -OutFile $p; if ($?) { powershell -NoProfile -ExecutionPolicy Bypass -File $p }
```
Скрипт сам проверит установлен ли у вас MinGW, есть ли VSCode и даже если все есть, сам настроит расширение в VSCode для C++ (выберет компилятор)

## Вручную
### Компилятор
Для установки компилятора GCC введите следующую команду в powershell
```powershell
$p="$env:TEMP\install-mingw.ps1"; irm https://raw.githubusercontent.com/natimys/cpp-course/main/scripts/install-mingw.ps1 -OutFile $p; if ($?) { powershell -NoProfile -ExecutionPolicy Bypass -File $p }
```

После установки откройте новый Powershell, введите `g++ --version` для проверки установки


### Редактор
Устанавливаем VSCode по ссылке: https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user

После установки VSCode установите расширение C++

<img width="279" height="72" alt="image" src="https://github.com/user-attachments/assets/e3e9a373-a63b-4fba-8e33-711c7b766f69" />

Выбираем компилятор по пути `C:\Users\<ваш юзер>\AppData\Local\Programs\WinLibs\mingw64\bin\g++.exe`

## Готово!
После этого можете приступать к написанию кода
