.PHONY: all clean deb

CC = gcc
CFLAGS = -Wall -O2
TARGET = bftee
BUILD_DIR = build

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): bftee.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/$(TARGET) bftee.c

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

deb: clean
	dpkg-buildpackage -us -uc -Zgzip
	# Repack with gzip compression for control.tar
	dpkg-deb -R ../bftee_1.0-1_amd64.deb bftee_tmp
	dpkg-deb -Zgzip -b bftee_tmp ../bftee_1.0-1_amd64.deb
	rm -rf bftee_tmp
