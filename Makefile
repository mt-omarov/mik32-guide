PWD = $(shell cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

BUILD = $(PWD)/build
SRC	  = $(PWD)/src
OBJ	  = $(PWD)/obj
PROJECT_NAME = blink

HAL_DIR 		= $(PWD)/mik32-hal
SHARED_DIR		= $(PWD)/mik32v2-shared
UPLOADER_DIR	= $(PWD)/mik32-uploader
CROSS_PREFIX	= /opt/homebrew/opt/riscv-gnu-toolchain/bin/riscv64-unknown-elf-
OPENOCD			= /opt/homebrew/opt/riscv-openocd/bin/openocd

CC = $(CROSS_PREFIX)gcc
LD = $(CROSS_PREFIX)ld
STRIP 	= $(CROSS_PREFIX)strip
OBJCOPY = $(CROSS_PREFIX)objcopy
OBJDUMP = $(CROSS_PREFIX)objdump

MARCH = rv32imc
MABI  = ilp32

LDSCRIPT = $(SHARED_DIR)/ldscripts/eeprom.ld
RUNTIME  = $(SHARED_DIR)/runtime/crt0.S

INCLUDE += -I $(SHARED_DIR)/include \
		   -I $(SHARED_DIR)/periphery \
		   -I $(SHARED_DIR)/runtime \
		   -I $(SHARED_DIR)/libs \
		   -I $(HAL_DIR)/core/Include \
		   -I $(HAL_DIR)/peripherals/Include \
		   -I $(HAL_DIR)/utilities/Include

LIBS	+= -lc
CFLAGS 	+= -Os -MD -fstrict-volatile-bitfields -fno-strict-aliasing \
		   -march=$(MARCH) -mabi=$(MABI) -fno-common -fno-builtin-printf
LDFLAGS += -nostdlib -lgcc -mcmodel=medlow -nostartfiles -ffreestanding \
		   -Wl,-Bstatic,-T,$(LDSCRIPT),-Map,$(OBJ)/$(PROJECT_NAME).map,--print-memory-usage \
		   -march=$(MARCH) -mabi=$(MABI) -specs=nano.specs -lnosys \
		   -L$(SHARED_DIR)/ldscripts

SOURCES := $(wildcard $(SRC)/*.c) \
		   $(HAL_DIR)/peripherals/Source/mik32_hal_pcc.c \
		   $(HAL_DIR)/peripherals/Source/mik32_hal_gpio.c \
		   $(HAL_DIR)/peripherals/Source/mik32_hal_adc.c \
		   $(SHARED_DIR)/libs/xprintf.c \
		   $(SHARED_DIR)/libs/uart_lib.c \

OBJECTS := $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SOURCES))
OBJECTS += $(patsubst $(SHARED_DIR)/runtime/%.S, $(OBJ)/%.o, $(RUNTIME))
SOURCES += $(RUNTIME)

OUT = $(BUILD)/$(PROJECT_NAME).hex

all: $(OBJ) $(BUILD) $(OUT)

$(OBJ):
	mkdir -p $@

$(BUILD):
	mkdir -p $@

$(OUT): $(OBJ)/$(PROJECT_NAME).elf
	$(OBJCOPY) -O ihex $^ $@

$(OBJ)/$(PROJECT_NAME).elf: $(OBJECTS)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(OBJ)/%.o: $(SRC)/%.c
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $^

$(OBJ)/%.o: $(SHARED_DIR)/runtime/%.S
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $^

upload: $(OUT)
	python $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
		--openocd-scripts $(UPLOADER_DIR)/openocd-scripts \
		--openocd-interface interface/ftdi/mikron-link.cfg $^

clean:
	rm -rf $(OBJ) $(BUILD)

.PHONY: all upload clean
