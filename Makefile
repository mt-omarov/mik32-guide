include Makefile.conf

all: deps $(OUT)

$(OUT): $(OBJ)/$(PROJECT_NAME).elf | $(BUILD)
	$(OBJCOPY) -O ihex $^ $@

$(OBJ)/$(PROJECT_NAME).elf: $(OBJECTS)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LDFLAGS) $(LIBS)

$(OBJ)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) -c -g $(CFLAGS) $(INCLUDE) -o $@ $^

$(OBJ)/%.o: %.S
	mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $^

$(BUILD):
	mkdir -p $@

upload: $(OUT)
	python3 $(UPLOADER_DIR)/mik32_upload.py --run-openocd --openocd-exec=$(OPENOCD) \
	        --openocd-scripts $(UPLOADER_DIR)/openocd-scripts --boot-mode $(BOOT_MODE) \
	        --openocd-interface interface/ftdi/mikron-link.cfg $^

deps: $(HAL_DIR) $(SHARED_DIR) $(UPLOADER_DIR)

$(HAL_DIR):
	git clone $(HAL_GIT)

$(SHARED_DIR):
	git clone $(SHARED_GIT)
	cd $@ && git checkout tags/v0.1.3 &>/dev/null

$(UPLOADER_DIR):
	git clone $(UPLOADER_GIT)

clean:
	rm -rf $(OBJ) $(BUILD)

.PHONY: all upload clean deps
