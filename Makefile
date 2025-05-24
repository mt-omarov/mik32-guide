include Makefile.conf

all: check-tools install-deps

$(OUT): $(OBJ)/$(PROJECT_NAME).elf
	$(OBJCOPY) -O ihex $^ $@

# Добавьте необходимые для сборки проекта правила
$(OBJ)/$(PROJECT_NAME).elf:
	echo "Not implemented"
	exit 1
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $(LDFLAGS) $(LIBS)

upload: $(OUT)
	python3 $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
	        --openocd-scripts $(UPLOADER_DIR)/openocd-scripts --boot-mode $(BOOT_MODE) \
	        --openocd-interface interface/ftdi/mikron-link.cfg $^

clean:
	rm -rf $(OBJ) $(BUILD)

purge: clean delete-deps delete-toolchain delete-openocd

.PHONY: all upload clean purge
