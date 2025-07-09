#!/bin/bash

# Remote test script for bftee on Linux
echo "=== bftee Linux Testing ==="
echo "Hostname: $(hostname)"
echo "OS: $(uname -a)"
echo "Date: $(date)"
echo

# Build bftee
echo "Building bftee..."
make clean && make
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi
echo "Build successful"

# Create test directory
mkdir -p /tmp/bftee_test
cd /tmp/bftee_test

# Test 1: Basic functionality
echo -e "\n1. Basic functionality test"
mkfifo testpipe
echo "Hello Linux" | ../bftee testpipe > stdout.txt &
cat testpipe > pipe.txt
wait
echo "Stdout: $(cat stdout.txt)"
echo "Pipe: $(cat pipe.txt)"
rm -f testpipe stdout.txt pipe.txt

# Test 2: Buffer flush on exit (Linux)
echo -e "\n2. Testing buffer flush on exit (Linux fcntl behavior)"
mkfifo testpipe
(seq 1 1000 | ../bftee testpipe 20 > stdout.txt) &
BFTEE_PID=$!
sleep 0.5
# Check if process is still running
if kill -0 $BFTEE_PID 2>/dev/null; then
    echo "Process still running, starting reader..."
    cat testpipe > pipe.txt &
    wait $BFTEE_PID
    wait
    echo "Lines to stdout: $(wc -l < stdout.txt)"
    echo "Lines to pipe: $(wc -l < pipe.txt)"
    if [ $(wc -l < stdout.txt) -eq $(wc -l < pipe.txt) ]; then
        echo "✓ Buffer flush works on Linux!"
    else
        echo "✗ Buffer flush failed on Linux"
    fi
else
    echo "Process already exited"
fi
rm -f testpipe stdout.txt pipe.txt

# Test 3: Signal handling
echo -e "\n3. Testing signal handling"
mkfifo testpipe
(yes "data" | head -1000 | ../bftee testpipe > /dev/null) &
BFTEE_PID=$!
sleep 0.2
echo "Sending SIGUSR1..."
kill -USR1 $BFTEE_PID 2>&1
sleep 0.1
kill $BFTEE_PID 2>/dev/null
wait 2>/dev/null
rm -f testpipe

# Test 4: Atomic writes (Linux PIPE_BUF)
echo -e "\n4. Testing atomic writes (PIPE_BUF = $(getconf PIPE_BUF .))"
mkfifo testpipe
# Generate exactly PIPE_BUF bytes
perl -e 'print "A" x 4096' | ../bftee testpipe > stdout_atomic.txt &
cat testpipe > pipe_atomic.txt
wait
echo "Stdout size: $(wc -c < stdout_atomic.txt) bytes"
echo "Pipe size: $(wc -c < pipe_atomic.txt) bytes"
rm -f testpipe stdout_atomic.txt pipe_atomic.txt

# Test 5: Large buffer test with drops
echo -e "\n5. Testing buffer drops"
mkfifo testpipe
(seq 1 10000 | ../bftee testpipe 10 > /dev/null) &
BFTEE_PID=$!
sleep 1
kill -USR1 $BFTEE_PID 2>&1 | grep "Buffer use"
cat testpipe > /dev/null &
wait 2>/dev/null
rm -f testpipe

# Test 6: Binary data
echo -e "\n6. Testing binary data integrity"
mkfifo testpipe
dd if=/dev/urandom bs=1024 count=10 2>/dev/null > binary.in
cat binary.in | ../bftee testpipe > binary.stdout &
cat testpipe > binary.pipe
wait
echo "Input:  $(md5sum binary.in | cut -d' ' -f1)"
echo "Stdout: $(md5sum binary.stdout | cut -d' ' -f1)"
echo "Pipe:   $(md5sum binary.pipe | cut -d' ' -f1)"
rm -f testpipe binary.*

echo -e "\n=== Linux Testing Complete ===\n"

# Cleanup
cd /tmp
rm -rf bftee_test