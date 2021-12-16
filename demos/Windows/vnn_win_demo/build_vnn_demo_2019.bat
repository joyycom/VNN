SET BATPATH=%~dp0
SET BATNAME=%~n0

SET BUILD_DIR=%BATPATH%%BATNAME%
mkdir %BUILD_DIR%
cd %BUILD_DIR%

@echo CMake version must be higher than 3.14.7

cmake ../ ^
      -G "Visual Studio 16 2019" ^
      -A "x64" ^
      --graphviz=graphviz/%BATNAME%.dot

@echo -- CMake Finished --
@dot -Tpng -o %BATNAME%.png graphviz/%BATNAME%.dot &&^
echo Generated graphviz graph for CMake targets in %BATNAME%.png ||^
echo [Warning] Cannot detect dot command. Skip converting graphviz/%BATNAME%.dot to %BATNAME%.png. Install graphviz to use it.

cd ..
