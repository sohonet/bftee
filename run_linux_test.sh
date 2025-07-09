#!/bin/bash

# Script to run tests on remote Linux machine
# Usage: ./run_linux_test.sh [username@hostname]

if [ $# -eq 0 ]; then
    echo "Usage: $0 username@hostname"
    echo "Example: $0 user@remote.server.com"
    exit 1
fi

REMOTE_TARGET="$1"
echo "Testing bftee on Linux machine: $REMOTE_TARGET"
echo "=================================================="

# Create tarball with latest code
echo "Creating tarball..."
tar czf bftee_linux_test.tar.gz bftee.c Makefile remote_test.sh

# Copy to remote machine
echo "Copying files to remote machine..."
scp bftee_linux_test.tar.gz $REMOTE_TARGET:/tmp/

# Run tests on remote machine
echo "Running tests on remote machine..."
ssh $REMOTE_TARGET << 'EOF'
cd /tmp
rm -rf bftee_test_dir
mkdir bftee_test_dir
cd bftee_test_dir
tar xzf ../bftee_linux_test.tar.gz
chmod +x remote_test.sh
./remote_test.sh
cd ..
rm -rf bftee_test_dir bftee_linux_test.tar.gz
EOF

# Cleanup local tarball
rm -f bftee_linux_test.tar.gz

echo -e "\nLinux testing complete!"