CC = gcc
CFLAGS = -Wall -O2
TARGET = bftee

all: $(TARGET)

$(TARGET): bftee.c
	$(CC) $(CFLAGS) -o $(TARGET) bftee.c

clean:
	rm -f $(TARGET)

.PHONY: all clean