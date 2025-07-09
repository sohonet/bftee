#!/bin/bash

# Test script for bftee edge cases

echo "=== bftee Edge Case Testing ==="

# Clean up any existing test files
rm -f /tmp/testpipe /tmp/bftee_*.txt

# Create test FIFO
mkfifo /tmp/testpipe

echo -e "\n1. Testing buffer overflow and drop counting"
echo "   Generating data faster than reader can consume..."
# Generate lots of data quickly, with a slow reader
(seq 1 10000 | ./bftee /tmp/testpipe > /tmp/bftee_overflow.txt) &
BFTEE_PID=$!

# Slow reader that reads only every 0.1 seconds
(while read line; do 
    echo "Read: $line" > /dev/null
    sleep 0.1
done < /tmp/testpipe) &
READER_PID=$!

sleep 2
kill -USR1 $BFTEE_PID 2>/dev/null
sleep 0.5
kill $BFTEE_PID 2>/dev/null
kill $READER_PID 2>/dev/null
wait $BFTEE_PID 2>/dev/null
wait $READER_PID 2>/dev/null

echo -e "\n2. Testing reader disconnect and reconnect"
echo "   Starting bftee with no reader..."
(seq 1 1000 | ./bftee /tmp/testpipe > /tmp/bftee_reconnect.txt) &
BFTEE_PID=$!
sleep 0.5
kill -USR1 $BFTEE_PID 2>/dev/null
echo "   Stats with no reader (should show no pipe writes):"

# Now connect a reader
echo "   Connecting reader..."
timeout 1 cat /tmp/testpipe > /tmp/reader_output.txt &
sleep 0.5
kill -USR1 $BFTEE_PID 2>/dev/null
echo "   Stats after reader connected:"

wait $BFTEE_PID 2>/dev/null

echo -e "\n3. Testing graceful shutdown with buffered data"
echo "   Filling buffer then shutting down..."
# Generate data but don't read it immediately
(seq 1 5000 | ./bftee /tmp/testpipe > /tmp/bftee_shutdown.txt) &
BFTEE_PID=$!
sleep 0.5
echo "   Sending SIGTERM for graceful shutdown..."
kill -TERM $BFTEE_PID
# Now read to see if buffered data is flushed
cat /tmp/testpipe > /tmp/shutdown_flush.txt &
wait $BFTEE_PID 2>/dev/null
sleep 0.5
echo "   Lines written to stdout: $(wc -l < /tmp/bftee_shutdown.txt)"
echo "   Lines flushed to pipe: $(wc -l < /tmp/shutdown_flush.txt)"

echo -e "\n4. Testing binary data handling"
echo "   Creating binary test file..."
# Create a binary file with all byte values
python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256)) * 10)" > /tmp/binary_test.bin
echo "   Binary file size: $(wc -c < /tmp/binary_test.bin) bytes"

# Test binary data through bftee
cat /tmp/binary_test.bin | ./bftee /tmp/testpipe > /tmp/bftee_binary_out.bin &
BFTEE_PID=$!
cat /tmp/testpipe > /tmp/pipe_binary_out.bin &
wait $BFTEE_PID 2>/dev/null

# Compare checksums
echo "   Original binary checksum: $(md5sum /tmp/binary_test.bin | cut -d' ' -f1)"
echo "   Stdout binary checksum:   $(md5sum /tmp/bftee_binary_out.bin | cut -d' ' -f1)"
echo "   Pipe binary checksum:     $(md5sum /tmp/pipe_binary_out.bin | cut -d' ' -f1)"

echo -e "\n5. Testing custom buffer size"
echo "   Testing with buffer size of 10..."
(seq 1 100 | ./bftee /tmp/testpipe 10 > /tmp/bftee_small_buffer.txt) &
BFTEE_PID=$!
sleep 0.5
kill -USR1 $BFTEE_PID 2>/dev/null
echo "   Stats should show max buffer size of 10:"
cat /tmp/testpipe > /dev/null &
wait $BFTEE_PID 2>/dev/null

echo -e "\n6. Testing large data transfer"
echo "   Generating 1MB of data..."
# Generate 1MB of data
dd if=/dev/zero bs=1024 count=1024 2>/dev/null | tr '\0' 'A' | ./bftee /tmp/testpipe > /tmp/bftee_large.txt &
BFTEE_PID=$!

# Fast reader
cat /tmp/testpipe > /tmp/pipe_large.txt &

wait $BFTEE_PID 2>/dev/null
echo "   Stdout size: $(wc -c < /tmp/bftee_large.txt) bytes"
echo "   Pipe size:   $(wc -c < /tmp/pipe_large.txt) bytes"

echo -e "\n7. Testing SIGINT handling (double SIGINT for force quit)"
(yes "Testing SIGINT" | ./bftee /tmp/testpipe > /dev/null) &
BFTEE_PID=$!
sleep 0.5
echo "   Sending first SIGINT (should exit gracefully)..."
kill -INT $BFTEE_PID
sleep 0.1
if kill -0 $BFTEE_PID 2>/dev/null; then
    echo "   Process still running, sending second SIGINT (should force exit)..."
    kill -INT $BFTEE_PID
fi
wait $BFTEE_PID 2>/dev/null

echo -e "\n=== Testing Complete ==="
rm -f /tmp/testpipe /tmp/bftee_*.txt /tmp/binary_test.bin /tmp/*binary_out.bin /tmp/*_large.txt /tmp/reader_output.txt /tmp/shutdown_flush.txt