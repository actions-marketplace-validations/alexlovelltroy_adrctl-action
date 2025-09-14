#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect platform and architecture for download
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            case "$(uname -m)" in
                x86_64) echo "Linux_x86_64" ;;
                aarch64|arm64) echo "Linux_arm64" ;;
                *) log_error "Unsupported architecture: $(uname -m)" && exit 1 ;;
            esac
            ;;
        Darwin*)
            case "$(uname -m)" in
                x86_64) echo "Darwin_x86_64" ;;
                arm64) echo "Darwin_arm64" ;;
                *) log_error "Unsupported architecture: $(uname -m)" && exit 1 ;;
            esac
            ;;
        *) log_error "Unsupported OS: $(uname -s)" && exit 1 ;;
    esac
}

# Download and install adrctl
install_adrctl() {
    local platform
    platform=$(detect_platform)

    # Get the latest version tag
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/alexlovelltroy/adrctl/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    # Remove 'v' prefix from version for filename
    local version_no_v="${latest_version#v}"
    local download_url="https://github.com/alexlovelltroy/adrctl/releases/download/${latest_version}/adrctl_${version_no_v}_${platform}.tar.gz"
    local temp_dir
    temp_dir=$(mktemp -d)

    log_info "Downloading adrctl..."

    if ! curl -sL "$download_url" | tar -xz -C "$temp_dir"; then
        log_error "Failed to download adrctl"
        exit 1
    fi

    chmod +x "$temp_dir/adrctl"

    # For local testing, install to current directory; in CI, try /usr/local/bin
    if [[ -n "$GITHUB_ACTIONS" ]]; then
        sudo mv "$temp_dir/adrctl" /usr/local/bin/adrctl
    else
        mv "$temp_dir/adrctl" ./adrctl
        export PATH="$PWD:$PATH"
    fi

    rm -rf "$temp_dir"

    log_info "adrctl installed successfully"
    adrctl --version
}

# Main execution
main() {
    log_info "Starting ADR Index Generation"

    # Install adrctl
    install_adrctl

    # Build command arguments
    local args=("index")

    if [[ -n "$INPUT_DIRECTORY" ]]; then
        args+=("--dir" "$INPUT_DIRECTORY")
    fi

    if [[ -n "$INPUT_OUT" ]]; then
        args+=("--out" "$INPUT_OUT")
    fi

    if [[ -n "$INPUT_PROJECT_NAME" ]]; then
        args+=("--project-name" "$INPUT_PROJECT_NAME")
    fi

    if [[ -n "$INPUT_PROJECT_URL" ]]; then
        args+=("--project-url" "$INPUT_PROJECT_URL")
    fi

    log_info "Executing: adrctl ${args[*]}"

    # Execute and capture output (the index file path)
    if index_path=$(adrctl "${args[@]}" 2>&1); then
        log_info "Index generated successfully at: $index_path"
        echo "index-path=$index_path" >> "$GITHUB_OUTPUT"
    else
        log_error "Failed to generate index: $index_path"
        exit 1
    fi
}

main "$@"