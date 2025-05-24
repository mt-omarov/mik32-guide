include Makefile.conf

all: check-tools install-deps $(OUT)

$(OUT): $(OBJ)/$(PROJECT_NAME).elf | $(BUILD)
	$(OBJCOPY) -O ihex $^ $@

$(OBJ)/$(PROJECT_NAME).elf: $(OBJECTS)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c -g $(CFLAGS) $(INCLUDE) -o $@ $^

$(OBJ)/%.o: %.S
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $^

$(BUILD):
	@mkdir -p $@

upload: $(OUT)
	python3 $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
	        --openocd-scripts $(UPLOADER_DIR)/openocd-scripts --boot-mode $(BOOT_MODE) \
	        --openocd-interface interface/ftdi/mikron-link.cfg $^

clean:
	rm -rf $(OBJ) $(BUILD)

purge: clean delete-deps delete-toolchain delete-openocd

.PHONY: all upload clean purge
