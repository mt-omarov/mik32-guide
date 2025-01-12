# Инструкция по кросс-компиляции под mik32 Амур

## Дерево проекта

- `src/` - папка с исходниками проекта (все `*.c`, `*.cpp`, `*.S` файлы),
- `Makefile` - файл правил сборки проекта,
- `configure` - вспомогательный скрипт для установки зависимых проектов.

## Запуск

При запуске нужно указать путь к папке кросс-компилятора и к `openOCD`.
Для macos кросс-компилятор располагается по пути `/opt/homebrew/opt/riscv-gnu-toolchain/`.
В Makefile переменные, отвечающие за это: `CROSS_PREFIX`, `OPENOCD`.

### Запуск кросс-компиляции

```bash
make \
  CROSS_PREFIX='<путь к папке кросс-компилятора>/bin/riscv64-unknown-elf-' \
  OPENOCD='<путь к openOCD>'
```

### Запуск прошивки микроконтроллера

```bash
make upload
```