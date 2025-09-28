#!/bin/bash
# Build Lambda layer with psycopg2 following AWS best practices

echo "🔧 Building Lambda layer with psycopg2..."

# Clean up any existing files
rm -rf python/
rm -f psycopg2-layer.zip

# Create the proper directory structure for Lambda layers
mkdir -p python
cd python

# Install psycopg2-binary with the correct platform flags for AWS Lambda x86_64
echo "📦 Installing psycopg2-binary for AWS Lambda (x86_64)..."
pip3 install \
    --platform manylinux2014_x86_64 \
    --target . \
    --python-version 3.9 \
    --only-binary=:all: \
    psycopg2-binary

# Go back to the layers directory
cd ..

# Create zip file for the layer
echo "📦 Creating layer zip file..."
if command -v powershell.exe &> /dev/null; then
    # Windows - use PowerShell
    powershell.exe -Command "Compress-Archive -Path 'python' -DestinationPath 'psycopg2-layer.zip' -Force"
else
    # Linux/Mac - use zip
    zip -r psycopg2-layer.zip python/
fi

echo "✅ Layer built successfully: psycopg2-layer.zip"

# Show the contents to verify
echo "📋 Layer contents:"
if command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Get-ChildItem -Recurse python/ | Select-Object Name, Length"
else
    find python/ -type f -name "*.py" -o -name "*.so" | head -10
fi