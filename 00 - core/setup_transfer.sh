#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Transfer - Steps for migrating settings and connections to a new Mac.

_transfer_navicat_settings() {
    print_info "Backing up Navicat settings..."
    mkdir -p ~/settings-backup/navicat
    if [ -d ~/Library/Application\ Support/PremiumSoft\ CyberTech ]; then
        cd ~/Library/Application\ Support/PremiumSoft\ CyberTech && zip -r ~/settings-backup/navicat/settings.zip .
    else
        print_warn "Navicat settings directory not found. Skipping backup."
    fi
}

_transfer_oracle_tns() {
    print_info "Configuring Oracle TNS..."
    # Assumes tnsnames.ora and sqlnet.ora are in ~/Documents
    if [[ -f ~/Documents/tnsnames.ora && -f ~/Documents/sqlnet.ora ]]; then
        ln -sf ~/Documents/tnsnames.ora ~/.tnsnames.ora
        ln -sf ~/Documents/sqlnet.ora ~/.sqlnet.ora
        
        sudo mkdir -p /opt/oracle/instantclient/network/admin/
        sudo ln -sf ~/Documents/tnsnames.ora /opt/oracle/instantclient/network/admin/
        sudo ln -sf ~/Documents/sqlnet.ora /opt/oracle/instantclient/network/admin/
    else
        print_warn "Oracle TNS files not found in ~/Documents. Skipping symlinks."
    fi
}

_setup_ai_stack() {
    print_info "Running AI Stack setup..."
    if [ -f ~/code/isaackehle/settings/config/setup_ai.sh ]; then
        bash ~/code/isaackehle/settings/config/setup_ai.sh
    else
        print_error "AI setup script not found at ~/code/isaackehle/settings/config/setup_ai.sh"
    fi
}

_check_dns() {
    print_info "Checking DNS nameservers..."
    scutil --dns | grep 'nameserver\[[0-9]*\]'
}

setup_transfer() {
    print_info "Starting transfer/migration process..."
    
    print_info "--- Manual Step: Studio 3T ---"
    print_info "1. Open Connect dialog -> Select connections -> Export (Include passwords)"
    print_info "2. On new Mac: Open Connect dialog -> Import"
    
    print_info "--- Navicat Settings ---"
    _transfer_navicat_settings
    
    print_info "--- Oracle TNS ---"
    _transfer_oracle_tns
    print_info "Manual Navicat UI Config: Preferences -> Environments"
    print_info "  - Uncheck 'Use Bundled Instant Client'"
    print_info "  - ORACLE_HOME -> /opt/oracle/instantclient"
    print_info "  - DYLD_LIBRARY_PATH -> /opt/oracle/instantclient"
    print_info "  - TNS_ADMIN -> /opt/oracle/instantclient/network/admin"
    
    print_info "--- AI Stack ---"
    _setup_ai_stack
    
    print_info "--- Network Check ---"
    _check_dns
    
    print_status "Transfer/Migration steps completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_transfer
fi