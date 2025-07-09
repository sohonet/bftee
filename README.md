# bftee

Binary FIFO Tee - A high-performance, non-blocking tee implementation for use with named pipes (FIFOs).

## Overview

`bftee` is a specialized version of the standard `tee` command designed to work efficiently with FIFOs (named pipes). Unlike regular `tee`, it won't block when the pipe reader is slow or disconnected. It reads from stdin and writes to both stdout and a named pipe, with internal buffering to handle slow readers gracefully.

Originally developed by racic and enhanced by fabraxias from Stack Overflow.

## Features

- **Non-blocking writes** - Never stalls even if no reader is connected to the FIFO
- **Internal buffering** - Queues data when FIFO reader is slow (default: 4096 buffers × 2KB each)
- **Binary-safe** - Handles all byte values correctly, suitable for any data type
- **Drop counting** - Tracks and reports dropped data when buffer overflows
- **Signal handling**:
  - `SIGUSR1` - Display buffer statistics to stderr
  - `SIGTERM` - Graceful shutdown with buffer flush
  - `SIGINT` - First signal initiates graceful shutdown, second forces exit
- **Automatic reconnection** - Handles reader disconnect/reconnect seamlessly
- **Buffer flush on exit** - Attempts to deliver all buffered data before terminating

## Building

```bash
make
```

To build with debug symbols:
```bash
make CFLAGS="-Wall -g"
```

## Installation

```bash
make
sudo cp bftee /usr/local/bin/
```

## Usage

```bash
someprog 2>&1 | bftee FIFO [BufferSize]
```

Arguments:
- `FIFO` - path to a named pipe (required). Must already exist.
- `BufferSize` - optional number of buffers to allocate (default: 4096)
  - Each buffer is 2048 bytes
  - Total memory = BufferSize × 2KB

## Examples

### Basic Usage

```bash
# Create a named pipe
mkfifo /tmp/mypipe

# Terminal 1: Run a command and tee output to the pipe
ls -la | bftee /tmp/mypipe

# Terminal 2: Read from the pipe
cat /tmp/mypipe
```

### Logging with On-Demand Viewing

```bash
# Create logging pipe
mkfifo /tmp/app.log.pipe

# Start application with bftee logging
./myapp 2>&1 | bftee /tmp/app.log.pipe > /tmp/app.log

# View logs on demand (can connect/disconnect anytime)
tail -f /tmp/app.log.pipe
```

### Network Service Monitoring

```bash
# Monitor a network service
mkfifo /tmp/netstat.pipe
while true; do 
    netstat -an | grep :80
    sleep 1
done | bftee /tmp/netstat.pipe > network.log

# Watch live when needed
cat /tmp/netstat.pipe
```

### Build Output Streaming

```bash
# Stream build output to multiple consumers
mkfifo /tmp/build.pipe
make -j8 2>&1 | bftee /tmp/build.pipe | tee build.log

# Terminal 2: Watch for errors only
grep -E "error|warning" /tmp/build.pipe

# Terminal 3: Full output
cat /tmp/build.pipe
```

### Buffer Statistics Monitoring

```bash
# Generate lots of data
mkfifo /tmp/data.pipe
seq 1 1000000 | bftee /tmp/data.pipe >/dev/null &
BFTEE_PID=$!

# Check buffer statistics
kill -USR1 $BFTEE_PID
# Output: Buffer use: 0 (0/4096), STDOUT: 1000000 PIPE: 1000000:0

# With slow reader
(while read line; do echo $line; sleep 0.01; done < /tmp/data.pipe) &
kill -USR1 $BFTEE_PID
# Shows active buffers and any drops
```

### Using Custom Buffer Size

```bash
# Small buffer for testing drops
mkfifo /tmp/test.pipe
seq 1 10000 | bftee /tmp/test.pipe 10 > /dev/null

# Large buffer for high-throughput scenarios
cat large_file.bin | bftee /tmp/data.pipe 65536

```

## Performance Characteristics

- **Block size**: 2048 bytes per buffer
- **Default capacity**: 4096 buffers (8MB total)
- **Write behavior**: Non-blocking to FIFO, blocking to stdout
- **Overflow handling**: Oldest data dropped when buffer full
- **Platform tested**: Linux (x86_64, ARM64) and macOS

## Buffer Statistics Format

When sending `SIGUSR1`, statistics are printed to stderr:

```
Buffer use: <active> (<maxUsed>/<bufferSize>), STDOUT: <writes> PIPE: <writes>:<drops>
```

- `active`: Currently used buffers
- `maxUsed`: Maximum buffers ever used
- `bufferSize`: Total buffer capacity
- `STDOUT writes`: Number of writes to stdout
- `PIPE writes`: Successful writes to pipe
- `drops`: Buffers dropped due to overflow

## Troubleshooting

### "readfd: open(): No such file or directory"
The FIFO must exist before running bftee. Create it with `mkfifo`.

### No output to pipe reader
- Check if FIFO exists: `ls -la /path/to/fifo`
- Verify it's a FIFO: `file /path/to/fifo` should show "fifo (named pipe)"
- Ensure reader has permissions: `chmod 666 /path/to/fifo`

### High memory usage
Reduce buffer size: `bftee /tmp/pipe 1000` (uses ~2MB instead of 8MB)

### Data loss
Check statistics with `kill -USR1 <pid>`. If drops > 0, increase buffer size or speed up reader.

## License

WTFPL (Do What The F*ck You Want To Public License)