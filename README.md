# bftee

Binary FIFO Tee - A high-performance tee implementation for use with named pipes (FIFOs).

## Overview

`bftee` is a specialized version of the standard `tee` command designed to work efficiently with FIFOs. It reads from stdin and writes to both stdout and a named pipe, with buffering and non-blocking writes to handle slow or disconnected readers gracefully.

## Features

- Non-blocking writes to FIFO to prevent stalling
- Internal buffering when FIFO reader is slow
- Binary-safe data handling
- Signal handling for graceful shutdown
- Statistics output on SIGUSR1
- Automatic reconnection when FIFO reader disconnects

## Building

```bash
make
```

## Usage

```bash
someprog 2>&1 | bftee FIFO [BufferSize]
```

Arguments:
- `FIFO` - path to a named pipe (required)
- `BufferSize` - optional internal buffer size in case write to FIFO fails (default: 4096)

## Example

```bash
# Create a named pipe
mkfifo /tmp/mypipe

# In terminal 1: Run a command and tee output to the pipe
ls -la | bftee /tmp/mypipe

# In terminal 2: Read from the pipe
cat /tmp/mypipe
```

## Signals

- `SIGUSR1` - Print buffer statistics to stderr
- `SIGTERM/SIGINT` - Graceful shutdown

## License

WTFPL