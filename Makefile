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

.PHONY: all clean