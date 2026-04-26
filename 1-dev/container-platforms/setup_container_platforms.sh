. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_docker_desktop() {
    print_info "Installing Docker Desktop..."
    brew install --cask docker && return 0
    return 1
}

_install_orbstack() {
    print_info "Installing OrbStack..."
    brew install --cask orbstack && return 0
    return 1
}

verify_docker() {
    check_tool_with_version "Docker" "docker"
}

setup_container_platforms() {
    print_info "Setting up container platforms..."

    if ! verify_docker; then
        print_info "Choose a container runtime:"
        print_info "  Docker Desktop: brew install --cask docker"
        print_info "  OrbStack (recommended, faster): brew install --cask orbstack"
        print_info "  Colima (lightweight): brew install colima docker docker-compose"
        print_info "  Rancher Desktop: brew install --cask rancher"
    fi

    print_info ""
    print_info "=== Container Platforms ==="
    print_info "Run container: docker run -it ubuntu bash"
    print_info "List running:  docker ps"
    print_info "Build image:   docker build -t my-image ."
    print_info "Docs:          https://docs.docker.com/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_container_platforms
fi
