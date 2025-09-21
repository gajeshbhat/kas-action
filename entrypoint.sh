#!/bin/bash

# Kas Action Entrypoint
# Parses GitHub Action inputs and executes kas commands with proper configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse GitHub Action inputs (GitHub passes inputs as INPUT_* environment variables)
parse_inputs() {
    log_info "Parsing action inputs..."

    # Required inputs
    KAS_FILE="${INPUT_KAS_FILE:?kas_file input is required}"

    # Optional inputs with defaults
    KAS_TAG="${INPUT_KAS_TAG:-latest}"
    KAS_CMD="${INPUT_KAS_CMD:-build}"
    KAS_ARGS="${INPUT_KAS_ARGS:-}"
    BITBAKE_ARGS="${INPUT_BITBAKE_ARGS:-}"

    # Caching configuration
    DL_DIR="${INPUT_DL_DIR:-dl_cache}"
    SSTATE_DIR="${INPUT_SSTATE_DIR:-sstate_cache}"

    # Build optimization
    PARALLELISM="${INPUT_PARALLELISM:-auto}"
    ACCEPT_LICENSES="${INPUT_ACCEPT_LICENSES:-}"

    log_info "Using kas command: ${KAS_CMD}"
    log_info "Using kas files: ${KAS_FILE}"
    log_info "Using kas tag: ${KAS_TAG}"
}

# Set up build environment
setup_environment() {
    log_info "Setting up build environment..."

    # Set up caching directories (relative to GITHUB_WORKSPACE)
    export DL_DIR="${GITHUB_WORKSPACE}/${DL_DIR}"
    export SSTATE_DIR="${GITHUB_WORKSPACE}/${SSTATE_DIR}"

    log_info "DL_DIR: ${DL_DIR}"
    log_info "SSTATE_DIR: ${SSTATE_DIR}"

    # Create cache directories
    mkdir -p "${DL_DIR}" "${SSTATE_DIR}"

    # Ensure builder owns caches when running as root
    if [[ "$(whoami)" == "root" ]]; then
        chown -R builder:builder "${DL_DIR}" "${SSTATE_DIR}" || true
    fi

    # Configure parallelism
    setup_parallelism

    # Set up license acceptance
    if [[ -n "${ACCEPT_LICENSES}" ]]; then
        export ACCEPT_LICENSE="${ACCEPT_LICENSES}"
        log_info "Accepting licenses: ${ACCEPT_LICENSES}"
    fi

}

# Configure build parallelism
setup_parallelism() {
    if [[ "${PARALLELISM}" == "auto" ]]; then
        local nproc_count
        nproc_count=$(nproc)
        export BB_NUMBER_THREADS="${nproc_count}"
        export PARALLEL_MAKE="-j${nproc_count}"
        log_info "Auto parallelism: BB_NUMBER_THREADS=${nproc_count}, PARALLEL_MAKE=-j${nproc_count}"
    elif [[ "${PARALLELISM}" =~ ^[0-9]+$ ]]; then
        export BB_NUMBER_THREADS="${PARALLELISM}"
        export PARALLEL_MAKE="-j${PARALLELISM}"
        log_info "Manual parallelism: BB_NUMBER_THREADS=${PARALLELISM}, PARALLEL_MAKE=-j${PARALLELISM}"
    elif [[ "${PARALLELISM}" =~ ^BB=([0-9]+),MAKE=([0-9]+)$ ]]; then
        export BB_NUMBER_THREADS="${BASH_REMATCH[1]}"
        export PARALLEL_MAKE="-j${BASH_REMATCH[2]}"
        log_info "Custom parallelism: BB_NUMBER_THREADS=${BB_NUMBER_THREADS}, PARALLEL_MAKE=${PARALLEL_MAKE}"
    else
        log_warning "Invalid parallelism format: ${PARALLELISM}. Using auto."
        local nproc_count
        nproc_count=$(nproc)
        export BB_NUMBER_THREADS="${nproc_count}"
        export PARALLEL_MAKE="-j${nproc_count}"
    fi
}


# Build and execute kas command
execute_kas() {
    log_info "Building kas command..."

    # Start with base kas command
    local kas_command="kas ${KAS_CMD}"

    # Add kas arguments if provided
    if [[ -n "${KAS_ARGS}" ]]; then
        kas_command="${kas_command} ${KAS_ARGS}"
    fi

    # Add kas files
    kas_command="${kas_command} ${KAS_FILE}"

    # Add bitbake arguments for build/shell commands
    if [[ "${KAS_CMD}" == "build" || "${KAS_CMD}" == "shell" ]] && [[ -n "${BITBAKE_ARGS}" ]]; then
        kas_command="${kas_command} -- ${BITBAKE_ARGS}"
    fi

    log_info "Executing: ${kas_command}"
    echo "::group::Kas Command Output"

    # Execute kas command with better error capture
    set +e  # Temporarily disable exit on error to capture output
    if [[ "$(id -u)" -eq 0 ]]; then
        gosu builder bash -lc "${kas_command}" 2>&1
    else
        eval "${kas_command}" 2>&1
    fi
    local exit_code=$?
    set -e  # Re-enable exit on error

    echo "::endgroup::"

    if [[ ${exit_code} -eq 0 ]]; then
        log_success "Kas command completed successfully"
    else
        log_error "Kas command failed with exit code: ${exit_code}"
        exit ${exit_code}
    fi
}

# Set GitHub Action outputs
set_outputs() {
    log_info "Setting action outputs..."

    # Find and set image directory output
    if [[ -d "build/tmp/deploy/images" ]]; then
        local image_dir
        image_dir="$(realpath build/tmp/deploy/images)"
        echo "image_dir=${image_dir}" >> "${GITHUB_OUTPUT}"
        log_success "Images available at: ${image_dir}"
    else
        log_warning "No images directory found at build/tmp/deploy/images"
    fi

    # Set build directory output
    if [[ -d "build" ]]; then
        local build_dir
        build_dir="$(realpath build)"
        echo "build_dir=${build_dir}" >> "${GITHUB_OUTPUT}"
        log_info "Build directory: ${build_dir}"
    fi
}

# Main execution
main() {
    log_info "Starting Kas Action..."

    # Fix workspace permissions for GitHub Actions
    # GitHub Actions mounts workspace with different ownership than container user
    if [[ "$(whoami)" == "root" ]]; then
        log_info "Running as root, adjusting workspace permissions..."
        chown -R builder:builder "${GITHUB_WORKSPACE}" || true
    fi

    # Change to workspace directory
    cd "${GITHUB_WORKSPACE}" || {
        log_error "Failed to change to workspace directory: ${GITHUB_WORKSPACE}"
        exit 1
    }

    parse_inputs
    setup_environment
    execute_kas
    set_outputs

    log_success "Kas Action completed successfully!"
}

# Execute main function
main "$@"
