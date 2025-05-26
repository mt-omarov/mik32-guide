include Makefile.conf

all: check-tools install-deps $(HEX)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF): $(OBJECTS) | $(BUILD)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<

$(OBJ)/%.o: %.S
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<

$(BUILD):
	@mkdir -p $@

upload: check-tools install-deps $(HEX)
	python3 $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
	        --openocd-scripts $(UPLOADER_DIR)/openocd-scripts --boot-mode $(BOOT_MODE) \
	        --openocd-interface interface/ftdi/mikron-link.cfg $(HEX)

start-server: check-tools install-deps $(ELF)
	@$(OPENOCD) \
		-f $(UPLOADER_DIR)/openocd-scripts/interface/ftdi/mikron-link.cfg \
		-f $(UPLOADER_DIR)/openocd-scripts/target/mik32.cfg 2>&1>/dev/tty || \
		{ \
			echo "Failed to start openocd server" && \
			exit 1; \
		}

clean:
	rm -rf $(OBJ) $(BUILD)

purge: clean delete-deps delete-toolchain delete-openocd

.PHONY: all upload clean purge start-server
