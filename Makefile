PWD = $(shell cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

BUILD = $(PWD)/build
SRC   = $(PWD)/src
OBJ   = $(PWD)/obj
PROJECT_NAME = blink

HAL_DIR         = $(PWD)/mik32-hal
SHARED_DIR      = $(PWD)/mik32v2-shared
UPLOADER_DIR    = $(PWD)/mik32-uploader

CROSS_PREFIX    ?= ~/.local/xPacks/riscv-none-elf-gcc/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-
OPENOCD         ?= ~/.local/xPacks/openocd/xpack-openocd-0.12.0-6/bin/openocd

BOOT_MODE       ?= eeprom

CC = $(CROSS_PREFIX)gcc
LD = $(CROSS_PREFIX)ld
STRIP   = $(CROSS_PREFIX)strip
OBJCOPY = $(CROSS_PREFIX)objcopy
OBJDUMP = $(CROSS_PREFIX)objdump

MARCH = rv32i_zicsr
MABI  = ilp32

LDSCRIPT = $(SHARED_DIR)/ldscripts/$(BOOT_MODE).ld
RUNTIME  = $(SHARED_DIR)/runtime/crt0.S

INCLUDE += -I $(SHARED_DIR)/include \
		   -I $(SHARED_DIR)/periphery \
		   -I $(SHARED_DIR)/runtime \
		   -I $(SHARED_DIR)/libs \
		   -I $(HAL_DIR)/core/Include \
		   -I $(HAL_DIR)/peripherals/Include \
		   -I $(HAL_DIR)/utilities/Include

LIBS    += -lc
CFLAGS  += -Os -MD -fstrict-volatile-bitfields -fno-strict-aliasing \
		   -march=$(MARCH) -mabi=$(MABI) -fno-common -fno-builtin-printf
LDFLAGS += -nostdlib -lgcc -mcmodel=medlow -nostartfiles -ffreestanding \
		   -Wl,-Bstatic,-Map,$(OBJ)/$(PROJECT_NAME).map,--print-memory-usage \
		   -march=$(MARCH) -mabi=$(MABI) -specs=nano.specs -lnosys \
		   -L$(SHARED_DIR)/ldscripts -T$(LDSCRIPT)

SOURCES := $(wildcard $(SRC)/*.c) \
		   $(HAL_DIR)/peripherals/Source/mik32_hal.c \
		   $(HAL_DIR)/peripherals/Source/mik32_hal_pcc.c \
		   $(HAL_DIR)/peripherals/Source/mik32_hal_gpio.c \
		   $(SHARED_DIR)/libs/uart_lib.c

OBJECTS := $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SOURCES))
OBJECTS += $(patsubst $(SHARED_DIR)/runtime/%.S, $(OBJ)/%.o, $(RUNTIME))
SOURCES += $(RUNTIME)

OUT = $(BUILD)/$(PROJECT_NAME).hex

all: $(OUT) $(BUILD)/$(PROJECT_NAME)

$(OUT): $(OBJ)/$(PROJECT_NAME).elf | $(BUILD)
	$(OBJCOPY) -O ihex $^ $@

$(OBJ)/$(PROJECT_NAME).elf: $(OBJECTS)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(BUILD)/$(PROJECT_NAME): $(OBJECTS) | $(BUILD)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(OBJ)/%.o: $(SRC)/%.c | $(OBJ)
	$(CC) -c -g $(CFLAGS) $(INCLUDE) -o $@ $^

$(OBJ)/%.o: $(SHARED_DIR)/runtime/%.S | $(OBJ)
	$(CC) -c -g $(CFLAGS) $(INCLUDE) -o $@ $^

$(OBJ):
	mkdir -p $@

$(BUILD):
	mkdir -p $@

upload: $(OUT)
	python3 $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
	        --openocd-scripts $(UPLOADER_DIR)/openocd-scripts --boot-mode $(BOOT_MODE) \
	        --openocd-interface interface/ftdi/mikron-link.cfg $^

clean:
	rm -rf $(OBJ) $(BUILD)

.PHONY: all upload clean
