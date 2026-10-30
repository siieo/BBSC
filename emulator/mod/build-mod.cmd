@echo off
rem Builds the BBSC mod: bbsc.dll (injected into shadPS4 or BBport's bb-probe.exe) and
rem bbsc-launch.exe (the injector).
rem bbsc.dll = bbsc_mod.cpp + bbsc_hooks.cpp + bbsc_relay.cpp + the emulator build's own
rem src\core\bloodborne_re.cpp (BBSC_MOD), with mod\shim\ answering its emulator includes.
rem
rem Needs: Visual Studio 2022 (any edition, or Build Tools) with "Desktop development with C++"
rem and "C++ Clang tools for Windows" (clang-cl), plus the fmt and xbyak submodules:
rem   git submodule update --init --depth 1 emulator/externals/fmt emulator/externals/xbyak
rem
rem Output: %BBSC_OUT% if set; else D:\BBSC\build\mod when D:\BBSC exists (the maintainer's
rem layout); else <repository>\build\mod. The log is mod-build.log one folder above the output
rem (ends with exit=N).
setlocal
set "SRC=%~dp0"
set "EXT=%SRC%..\externals"

rem Visual Studio: the newest install with the C++ tools, found by vswhere; else Community.
set "VSDIR="
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR set "VSDIR=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" (
    echo Visual Studio with the C++ tools was not found.
    echo Install Visual Studio 2022 with "Desktop development with C++" and "C++ Clang tools for Windows".
    exit /b 1
)
call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set "PATH=%VSDIR%\VC\Tools\Llvm\x64\bin;%PATH%"
where clang-cl >nul 2>&1 || (
    echo clang-cl was not found. In the Visual Studio Installer, add "C++ Clang tools for Windows".
    exit /b 1
)
if not exist "%EXT%\fmt\include\fmt\format.h" goto nosub
if not exist "%EXT%\xbyak\xbyak\xbyak.h" goto nosub

if defined BBSC_OUT (
    set "OUT=%BBSC_OUT%"
) else if exist "D:\BBSC\" (
    set "OUT=D:\BBSC\build\mod"
) else (
    set "OUT=%SRC%..\..\build\mod"
)
set "OBJ=%OUT%\obj"
set "LOG=%OUT%\..\mod-build.log"
if not exist "%OBJ%" mkdir "%OBJ%"
set FLAGS=/nologo /std:c++latest /O2 /MT /EHsc /W3 /DNOMINMAX /DWIN32_LEAN_AND_MEAN /D_CRT_SECURE_NO_WARNINGS /DBBSC_MOD /DFMT_HEADER_ONLY /I "%SRC%shim" /I "%SRC%..\src" /I "%EXT%\fmt\include" /I "%EXT%\xbyak"
echo building > "%LOG%"
echo Building bbsc.dll (a few minutes: bloodborne_re.cpp is large)...
clang-cl %FLAGS% /LD "%SRC%bbsc_mod.cpp" "%SRC%bbsc_hooks.cpp" "%SRC%bbsc_relay.cpp" "%SRC%bbsc_channel.cpp" "%SRC%bbsc_http.cpp" "%SRC%bbsc_discord.cpp" "%SRC%..\src\core\bbsc_memscan.cpp" "%SRC%..\src\core\bloodborne_re.cpp" /Fo"%OBJ%\\" /Fe"%OUT%\bbsc.dll" /link ws2_32.lib winhttp.lib user32.lib >> "%LOG%" 2>&1 || goto fail
echo Building bbsc-launch.exe...
clang-cl %FLAGS% "%SRC%bbsc_launch.cpp" /Fo"%OBJ%\\" /Fe"%OUT%\bbsc-launch.exe" /link user32.lib comdlg32.lib /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup >> "%LOG%" 2>&1 || goto fail
echo exit=0 >> "%LOG%"
echo Done: "%OUT%\bbsc.dll" and "%OUT%\bbsc-launch.exe"
exit /b 0
:nosub
echo The fmt / xbyak sources are missing under "%EXT%". From the repository folder run:
echo   git submodule update --init --depth 1 emulator/externals/fmt emulator/externals/xbyak
exit /b 1
:fail
echo exit=1 >> "%LOG%"
echo Build FAILED - see "%LOG%"
exit /b 1
