#!/bin/bash

# Parse Python dependencies from requirements-old.txt
PYTHON_DEPS=$(awk '/^# Julia dependencies/{exit} /^[^#[:space:]]/ {print $1}' requirements-old.txt | xargs)

# Check for conda (simple version)
if conda --version &> /dev/null; then
    echo "Conda detected. Creating (or overwriting) 'py-rude' environment with the latest Python version..."
    conda remove -y -n py-rude --all &> /dev/null
    conda create -y -n py-rude
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate py-rude
    echo "Installing Python dependencies in 'py-rude' environment using pip..."
    pip install --upgrade pip
    pip install $PYTHON_DEPS
elif command -v pip3 &> /dev/null; then
    echo "Conda not found. Creating Python virtual environment 'py-rude' with the system's default python3..."
    python3 -m venv py-rude
    echo "Activating 'py-rude' virtual environment..."
    # shellcheck disable=SC1091
    source py-rude/bin/activate
    echo "Installing Python dependencies in 'py-rude' virtual environment using pip..."
    pip install --upgrade pip
    pip install $PYTHON_DEPS
else
    echo "Neither conda nor pip3 found. Please install either Miniconda/Anaconda or Python 3 and pip."
    exit 1
fi

echo "\nSetting up Julia environment..."
JULIA_VERSION="1.8.3"
JULIA_ENV_DIR=".julia-rude"
mkdir -p "$JULIA_ENV_DIR"

# Check for juliaup
if command -v juliaup &> /dev/null; then
    echo "Juliaup detected. Checking for Julia $JULIA_VERSION..."
    
    # Try to add Julia 1.8.3 regardless of what juliaup list shows
    echo "Adding Julia $JULIA_VERSION through juliaup..."
    juliaup add "$JULIA_VERSION"
    
    # Verify 1.8.3 is actually available
    if juliaup status | grep -q "$JULIA_VERSION"; then
        echo "Successfully installed Julia $JULIA_VERSION."
        
        echo "Installing Julia dependencies with Julia $JULIA_VERSION..."
        # Parse Julia packages and versions from requirements-old.txt
        awk '/^# Julia dependencies/{flag=1; next} /^#|^$/{next} flag && NF {print $1}' requirements-old.txt | \
        awk -F'==' '{printf "Pkg.add(Pkg.PackageSpec(name=\"%s\", version=\"%s\"))\n", $1, $2}' > "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
    
        # Create the main Julia installation script
        cat > "$JULIA_ENV_DIR/install_julia_deps.jl" <<EOL
import Pkg
Pkg.activate("$JULIA_ENV_DIR")
$(cat "$JULIA_ENV_DIR/install_julia_deps.jl.tmp")
Pkg.resolve()
Pkg.status()
EOL
        rm "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
        
        # Run with the specific Julia version
        julia +$JULIA_VERSION "$JULIA_ENV_DIR/install_julia_deps.jl"
        rm "$JULIA_ENV_DIR/install_julia_deps.jl"
        
        echo "Created Julia $JULIA_VERSION environment at $JULIA_ENV_DIR"
        echo "To use this environment, run: julia +$JULIA_VERSION --project=$JULIA_ENV_DIR"
    else
        echo "Failed to install Julia $JULIA_VERSION using juliaup."
        echo "Available Julia versions:"
        juliaup status
        
        echo "Attempting to use default Julia version instead..."
        # Fall back to using the default Julia version
        JULIA_DEFAULT_CMD="julia"
        if ! command -v $JULIA_DEFAULT_CMD &> /dev/null; then
            echo "No Julia installation found. Please install Julia manually."
            exit 1
        fi
        
        # Use the default Julia installation
        JULIA_CURRENT_VERSION=$($JULIA_DEFAULT_CMD --version | awk '{print $3}')
        echo "Using Julia $JULIA_CURRENT_VERSION (not the recommended $JULIA_VERSION)"
        
        # Parse Julia packages and versions from requirements-old.txt
        awk '/^# Julia dependencies/{flag=1; next} /^#|^$/{next} flag && NF {print $1}' requirements-old.txt | \
        awk -F'==' '{printf "Pkg.add(Pkg.PackageSpec(name=\"%s\", version=\"%s\"))\n", $1, $2}' > "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
        
        # Create the main Julia installation script
        cat > "$JULIA_ENV_DIR/install_julia_deps.jl" <<EOL
import Pkg
Pkg.activate("$JULIA_ENV_DIR")
$(cat "$JULIA_ENV_DIR/install_julia_deps.jl.tmp")
Pkg.resolve()
Pkg.status()
EOL
        rm "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
        
        $JULIA_DEFAULT_CMD "$JULIA_ENV_DIR/install_julia_deps.jl"
        rm "$JULIA_ENV_DIR/install_julia_deps.jl"
    fi
elif command -v julia &> /dev/null; then
    JULIA_CURRENT_VERSION=$(julia --version | awk '{print $3}')
    echo "NOTE: Found Julia $JULIA_CURRENT_VERSION, but project requires Julia $JULIA_VERSION"
    echo "We recommend installing juliaup to manage multiple Julia versions:"
    echo "  - macOS: brew install juliaup"
    echo "  - Linux/Windows: curl -fsSL https://install.julialang.org | sh"
    echo "  - After installing, run this script again"
    echo ""
    echo "Attempting to continue with Julia $JULIA_CURRENT_VERSION, but compatibility issues may occur..."
    
    # Parse Julia packages and versions from requirements-old.txt
    awk '/^# Julia dependencies/{flag=1; next} /^#|^$/{next} flag && NF {print $1}' requirements-old.txt | \
    awk -F'==' '{printf "Pkg.add(Pkg.PackageSpec(name=\"%s\", version=\"%s\"))\n", $1, $2}' > "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
    
    # Create the main Julia installation script
    cat > "$JULIA_ENV_DIR/install_julia_deps.jl" <<EOL
import Pkg
Pkg.activate("$JULIA_ENV_DIR")
$(cat "$JULIA_ENV_DIR/install_julia_deps.jl.tmp")
Pkg.resolve()
Pkg.status()
EOL
    rm "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
    
    # Run with whatever Julia version is available
    julia "$JULIA_ENV_DIR/install_julia_deps.jl"
    rm "$JULIA_ENV_DIR/install_julia_deps.jl"
else
    echo "julia not found. Please install Julia or juliaup:"
    echo "  - macOS: brew install juliaup"
    echo "  - Linux/Windows: curl -fsSL https://install.julialang.org | sh"
    exit 1
fi

echo "\nAll dependencies installed successfully." 