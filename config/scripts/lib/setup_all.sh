. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
. "$(dirname "${BASH_SOURCE[0]}")/setup_continue.sh"
. "$(dirname "${BASH_SOURCE[0]}")/setup_opencode.sh"
. "$(dirname "${BASH_SOURCE[0]}")/setup_crush.sh"
. "$(dirname "${BASH_SOURCE[0]}")/setup_claude.sh"

setup_all() {
    setup_continue
    setup_opencode
    setup_crush
    setup_claude
    print_status "All tool configurations applied"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_all
fi
