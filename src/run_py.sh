#!/bin/bash

set -e

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python 3.7+ and try again."
    exit 1
fi

# Check Python version (must be >= 3.7)
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.7"
if [[ $(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1) != "$REQUIRED_VERSION" ]]; then
    echo "❌ Python version must be >= $REQUIRED_VERSION. Found: $PYTHON_VERSION"
    exit 1
fi

# Check pip installation
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip."
    exit 1
fi

# Show pip version
echo "✅ Python version: $PYTHON_VERSION"
echo "✅ pip version: $(pip3 --version)"

# Create venv if it doesn't exist
if [ ! -d ".env" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv .env
fi

# Activate venv
source .env/bin/activate

# Upgrade pip silently
pip install --upgrade pip -q

# Install dependencies silently
pip install -r requirements.txt -q

# Run your script
python3 flux_snr5.py -i "$1" -o "$2" --plot

# Deactivate
deactivate
