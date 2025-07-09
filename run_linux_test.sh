#!/bin/bash

# Script to run tests on Linux machine
REMOTE_HOST="10.110.10.172"
REMOTE_USER="${1:-$USER}"  # Use provided username or current user

echo "Testing bftee on Linux machine: $REMOTE_USER@$REMOTE_HOST"
echo "=================================================="

# Create tarball with latest code
echo "Creating tarball..."
tar czf bftee_linux_test.tar.gz bftee.c Makefile remote_test.sh

# Copy to remote machine
echo "Copying files to remote machine..."
scp bftee_linux_test.tar.gz $REMOTE_USER@$REMOTE_HOST:/tmp/

# Run tests on remote machine
echo "Running tests on remote machine..."
ssh $REMOTE_USER@$REMOTE_HOST << 'EOF'
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