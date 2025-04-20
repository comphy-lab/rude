#!/bin/bash

# Parse Python dependencies from requirements.txt
PYTHON_DEPS=$(awk '/^# Julia dependencies/{exit} /^[^#[:space:]]/ {print $1}' requirements.txt | xargs)

# Parse Julia packages from requirements.txt
parse_julia_deps() {
    awk '/^# Julia dependencies/{flag=1; next} /^#|^$/{next} flag && NF {print $1}' requirements.txt | \
    awk '{printf "Pkg.add(\"%s\")\n", $1}' > "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
    
    # Create the main Julia installation script
    cat > "$JULIA_ENV_DIR/install_julia_deps.jl" <<EOL
import Pkg
Pkg.activate("$JULIA_ENV_DIR")
$(cat "$JULIA_ENV_DIR/install_julia_deps.jl.tmp")
Pkg.resolve()
Pkg.status()
EOL
    rm "$JULIA_ENV_DIR/install_julia_deps.jl.tmp"
}

# Install Julia packages using a specific Julia command
install_julia_packages() {
    local julia_cmd="$1"
    $julia_cmd "$JULIA_ENV_DIR/install_julia_deps.jl"
    rm "$JULIA_ENV_DIR/install_julia_deps.jl"
}

# Install Python environment and dependencies
install_python_deps() {
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
}

# Main execution starts here
echo "Setting up Python environment..."
install_python_deps

echo "\nChecking for Julia installation..."
JULIA_ENV_DIR=".julia-rude"
mkdir -p "$JULIA_ENV_DIR"

# Check for juliaup or julia
if command -v julia &> /dev/null; then
    JULIA_CURRENT_VERSION=$(julia --version | awk '{print $3}')
    echo "Using Julia $JULIA_CURRENT_VERSION"
    echo "Installing Julia dependencies with Julia $JULIA_CURRENT_VERSION..."
    
    parse_julia_deps
    install_julia_packages "julia"
    
    echo "Created Julia $JULIA_CURRENT_VERSION environment at $JULIA_ENV_DIR"
    echo "To use this environment, run: julia --project=$JULIA_ENV_DIR"
else
    echo "Julia not found. Please install Julia using juliaup:"
    echo ""
    echo "To install Julia, run the following command:"
    echo "  curl -fsSL https://install.julialang.org | sh"
    echo ""
    echo "Important: We strongly recommend installing Julia via the command above"
    echo "rather than through OS-specific software repositories, as the latter"
    echo "currently have some drawbacks."
    echo ""
    echo "After installing Julia, run this script again to install the required Julia packages."
    echo "For more information, visit: https://github.com/JuliaLang/juliaup"
    exit 1
fi

echo "\nAll dependencies installed successfully." 

# Create project configuration file for easy activation
echo "Creating .project_config file for easy environment activation..."
ABSOLUTE_PATH_TO_JULIA="$PWD/$JULIA_ENV_DIR"

cat > .project_config <<EOL
#!/bin/bash

# Activate the appropriate Python environment
if command -v conda &> /dev/null; then
    # Conda environment
    source "\$(conda info --base)/etc/profile.d/conda.sh"
    conda activate py-rude
    echo "Activated conda environment 'py-rude'"
else
    # Python virtual environment
    if [ -d "py-rude" ]; then
        source "py-rude/bin/activate"
        echo "Activated Python virtual environment 'py-rude'"
    else
        echo "Python environment 'py-rude' not found"
    fi
fi

# Set up Julia alias
alias julia="julia --project=$ABSOLUTE_PATH_TO_JULIA"
echo "Julia alias set to use project at $ABSOLUTE_PATH_TO_JULIA"

echo "RUDE development environment activated"
EOL

chmod +x .project_config
echo "Configuration file created. To activate the environment, run: source .project_config" 