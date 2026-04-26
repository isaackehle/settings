#!/bin/bash

# setup_core.sh - Interactive installer for 0-core tools
# Allows users to select/deselect tools via spacebar and execute them.

# Load utilities if available
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Define Categories and their associated scripts
declare -A CATEGORIES
CATEGORIES["Base & System"]="setup_homebrew.sh setup_installations.sh setup_bash.sh setup_zsh.sh setup_fonts.sh setup_tweaks.sh"
CATEGORIES["Connectivity"]="setup_internet.sh setup_ssh.sh setup_autossh.sh setup_vpn.sh setup_vnc.sh setup_transfer.sh setup_wget.sh"
CATEGORIES["Terminal"]="setup_ghostty.sh setup_iterm.sh"
CATEGORIES["Browsers"]="setup_arc.sh setup_brave.sh setup_chrome.sh setup_chromium.sh setup_edge.sh setup_firefox.sh"
CATEGORIES["Communication"]="setup_slack.sh setup_teams.sh setup_telegram.sh setup_discord.sh setup_comet.sh"
CATEGORIES["Security & Auth"]="setup_auth.sh setup_1password.sh setup_2fas.sh setup_encryption.sh setup_keepassxc.sh setup_proton_pass.sh"
CATEGORIES["Productivity"]="setup_fantastical.sh setup_itsycal.sh setup_task_managers.sh setup_pdf.sh setup_multimedia.sh setup_deluge.sh setup_folx.sh setup_filezilla.sh setup_kiwi_for_gmail.sh"
CATEGORIES["DevOps & Infra"]="setup_ansible.sh setup_grafana.sh setup_prometheus.sh setup_vm.sh"

# Order of categories to display
ORDER=("Base & System" "Connectivity" "Terminal" "Browsers" "Communication" "Security & Auth" "Productivity" "DevOps & Infra")

# State
SELECTED_SCRIPTS=()
CURSOR=0

# Function to render the menu
render_menu() {
    clear
    echo "========================================================================"
    echo "                  CORE SETUP INTERACTIVE INSTALLER                     "
    echo "========================================================================"
    echo " Use [↑/↓] to navigate, [Space] to select/deselect, [Enter] to install"
    echo "------------------------------------------------------------------------"

    for cat in "${ORDER[@]}"; do
        echo -e "\n\033[1;36m$cat\033[0m"
        read -a scripts <<< "${CATEGORIES[$cat]}"
        for script in "${scripts[@]}"; do
            local marker=" [ ] "
            [[ " ${SELECTED_SCRIPTS[*]} " == *" $script "* ]] && marker=" [x] "

            if [ "$script" == "${CURRENT_SCRIPT}" ]; then
                echo -e "\033[1;33m>$marker $script\033[0m"
            else
                echo -e "$marker $script"
            fi
        done
    done
    echo -e "\n------------------------------------------------------------------------"
}

# Initialize
ALL_SCRIPTS=()
for cat in "${ORDER[@]}"; do
    read -a scripts <<< "${CATEGORIES[$cat]}"
    ALL_SCRIPTS+=("${scripts[@]}")
done

CURRENT_SCRIPT="${ALL_SCRIPTS[0]}"

while true; do
    render_menu

    # Read single character input
    read -rsn1 key
    case "$key" in
        $'\x1b') # Escape sequence
            read -rsn2 -d '' key
            if [[ "$key" == "[A" ]]; then # Up
                ((CURSOR--))
                [ $CURSOR -lt 0 ] && CURSOR=$((${#ALL_SCRIPTS[@]} - 1))
            elif [[ "$key" == "[B" ]]; then # Down
                ((CURSOR++))
                [ $CURSOR -ge ${#ALL_SCRIPTS[@]} ] && CURSOR=0
            fi
            ;;
        " ") # Space
            if [[ " ${SELECTED_SCRIPTS[*]} " == *" ${CURRENT_SCRIPT} "* ]]; then
                # Deselect: remove from array
                new_selected=()
                for s in "${SELECTED_SCRIPTS[@]}"; do
                    [[ "$s" != "$CURRENT_SCRIPT" ]] && new_selected+=("$s")
                done
                SELECTED_SCRIPTS=("${new_selected[@]}")
            else
                # Select: add to array
                SELECTED_SCRIPTS+=("$CURRENT_SCRIPT")
            fi
            ;;
        "") # Enter
            break
            ;;
    esac
    CURRENT_SCRIPT="${ALL_SCRIPTS[$CURSOR]}"
done

# Execution phase
clear
echo "========================================================================"
echo "                      STARTING INSTALLATION                               "
echo "========================================================================"

if [ ${#SELECTED_SCRIPTS[@]} -eq 0 ]; then
    print_warning "No scripts selected. Exiting."
    exit 0
fi

for script in "${SELECTED_SCRIPTS[@]}"; do
    script_path="0-core/$script"
    if [ -f "$script_path" ]; then
        print_info "Running $script..."
        bash "$script_path"
        print_status "Finished $script"
    else
        print_warning "Script $script_path not found, skipping."
    fi
done

print_status "Core setup process complete!"print_status "Corepack setup complete!"
echo "Available setup scripts in 1-dev/:"
for i in "${!SCRIPT_ARRAY[@]}"; do
    # Extract just the filename for the display
    filename=$(basename "${SCRIPT_ARRAY[$i]}")
    echo "$((i+1))) $filename"
done
echo "--------------------------------------------------"
echo "a) Install ALL scripts"
echo "q) Quit"
echo "--------------------------------------------------"
read -p "Selection (number or 'a'/'q'): " choice

if [[ "$choice" == "a" ]]; then
    for script in "${SCRIPT_ARRAY[@]}"; do
        print_info "Executing $(basename "$script")..."
        bash "$script"
    done
elif [[ "$choice" == "q" ]]; then
    print_info "Exiting setup."
    exit 0
elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#SCRIPT_ARRAY[@]}" ]; then
    idx=$((choice-1))
    target_script="${SCRIPT_ARRAY[$idx]}"
    print_info "Executing $(basename "$target_script")..."
    bash "$target_script"
else
    print_warning "Invalid selection."
    exit 1
fi

print_status "Development environment setup process complete!"