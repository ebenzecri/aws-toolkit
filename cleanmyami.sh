#!/bin/bash

# Base functions
check_user() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: please run this script as root" >&2
        exit
    fi
}

print_banner() {
    clear
    echo -e '   ___ _    ___   _   _  _   __  ____   __    _   __  __ ___ ' 
    echo -e '  / __| |  | __| /_\ | \| | |  \/  \ \ / /   /_\ |  \/  |_ _|'
    echo -e ' | (__| |__| _| / _ \| .` | | |\/| |\ V /   / _ \| |\/| || | '
    echo -e '  \___|____|___/_/ \_\_|\_| |_|  |_| |_|   /_/ \_\_|  |_|___|'
}

print_section() {
    echo -e "\n\e[93m[+]\e[39m $1\e[0m"
}

print_section_done() {
    echo -e "   \e[93m Tasks completed!\e[0m"
}

print_section_error() {
    echo -e "   \e[91m Error: $1\e[0m" >&2
}

print_subsection_item() {
    echo -e "    \e[36m>\e[39m $1\e[0m"
}

print_subsection_item_done() {
    echo -e "    \e[92m> Done!\e[0m"
}

print_subsection_item_error() {
    echo -e "    \e[91m> Error: $1\e[0m" >&2
}

read_section() {
    read -p "    $1 " $2
}

read_subsection() {
    read -p "    > $1 " $2
}


# Specific functions
clean_bash_history() {
    print_section "Bash history"

    print_subsection_item "Cleaning bash history of root..."
    set +o history 
    history -c
    history_file="/root/.bash_history"
    if [ -f $history_file ]; then
        rm -f $history_file 2>/dev/null
        if [ $? -eq 0 ]; then
            print_subsection_item_done
        else
            print_subsection_item_error "Error deleting bash history of root."
        fi
    fi

    homes=`ls /home`
    if [ ! -z "$homes" ]; then
        for user_home in $homes; do
            history_file="/home/$user_home/.bash_history"
            if [ -f $history_file ]; then
                print_subsection_item "Cleaning bash history of $user_home..."
                rm -f $history_file 2>/dev/null
                if [ $? -eq 0 ]; then
                    print_subsection_item_done
                else
                    print_subsection_item_error "Error deleting bash history of $user_home."
                fi
            fi
        done
    fi

    print_section_done
}

clean_custom_files() {
    print_section "Files and directories"
    
    while true; do
        read_section "Do you want to delete specific files or directories? [y/n]" confirmation
        case $confirmation in
            [Yy]*)
                read_subsection "File or directory absolute path:" path_target
                if [ -z "$path_target" ]; then
                    print_subsection_item_error "Empty path."
                    continue
                fi
                if [ -f $path_target ]; then
                    rm -f $path_target 2>/dev/null
                    if [ $? -eq 0 ]; then
                        print_subsection_item_done
                    else
                        print_subsection_item_error "Error deleting file."
                    fi
                elif [ -d $path_target ]; then
                    rm -rf $path_target 2>/dev/null
                    if [ $? -eq 0 ]; then
                        print_subsection_item_done
                    else
                        print_subsection_item_error "Error deleting directory."
                    fi
                else
                    print_subsection_item_error "File/directory does not exist."
                fi
                ;;
            [Nn]*)
                break
                ;;
        esac
    done
    
    print_section_done
}

clean_logs() {
    print_section "Logs"
    path_target="/var/log"
    
    print_subsection_item "Cleaning .old files..."
    find $path_target -name "*.old" -type f -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more '.old' files can't be deleted."
    fi

    print_subsection_item "Cleaning .gz files..."
    find $path_target -name "*.gz" -type f -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more '.gz' files can't be deleted."
    fi

    print_subsection_item "Cleaning .(number) files..."
    find $path_target -name '*.[[:digit:]]' -type f -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more '.(number)' files can't be deleted."
    fi

    print_subsection_item "Cleaning -(yyyymmdd date) files..."
    find $path_target -regextype posix-extended -regex '.*-[0-9]{8}$' -type f -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more -(yyyymmdd date) files can't be deleted."
    fi

    print_subsection_item "Cleaning .log files..."
    find $path_target -name "*.log" -type f -exec truncate -s 0 {} \; 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more '.log' files can't be emptied."
    fi

    print_subsection_item "Cleaning files without extension..."
    find $path_target ! -name "*.*" -type f -exec truncate -s 0 {} \; 2>/dev/null
    if [ $? -eq 0 ]; then
        print_subsection_item_done
    else
        print_subsection_item_error "One or more files without extension can't be emptied."
    fi

    print_section_done
}

clean_package_manager() {
    print_section "Cached software packages"

    if [ -x "$(command -v yum)" ]; then pm="yum"
    elif [ -x "$(command -v apt-get)" ]; then pm="apt"
    elif [ -x "$(command -v dnf)" ]; then pm="dnf"
    elif [ -x "$(command -v zypper)" ]; then pm="zypper"
    else
        print_section_item_error "Unknown package manager. Skipping..."
        return 1
    fi

    print_subsection_item "Package manager detected: $pm"
    print_subsection_item "Cleaning $pm packages..."
    case "$pm" in
        yum)
            yum clean all 2>/dev/null
            ;;
        apt)
            apt-get clean 2>/dev/null
            ;;
        dnf)
            dnf clean all 2>/dev/null
            ;;
        zypper)
            zypper clean --all 2>/dev/null
            ;;
    esac
    if [ $? -eq 0 ]; then
        print_section_done
    else
        print_section_error "Something failed. Skipping..."
    fi
}

clean_ssh_keys() {
    print_section "SSH keys"

    print_subsection_item "Searching for SSH keys"
    ssh_key_file="/root/.ssh/authorized_keys"
    if [ -f $ssh_key_file ]; then
        print_subsection_item "Cleaning SSH keys belonging to root..."
        rm -f $ssh_key_file 2>/dev/null
        if [ $? -eq 0 ]; then
            print_subsection_item_done
        else
            print_subsection_item_error "Error deleting SSH keys of root."
        fi
    fi

    homes=`ls /home`
    if [ ! -z "$homes" ]; then
        for user_home in $homes; do
            ssh_key_file="/home/$user_home/.ssh/authorized_keys"
            if [ -f $ssh_key_file ]; then
                print_subsection_item "Cleaning SSH keys belonging to $user_home..."
                rm -f $ssh_key_file 2>/dev/null
                if [ $? -eq 0 ]; then
                    print_subsection_item_done
                else
                    print_subsection_item_error "Error deleting SSH keys of $user_home."
                fi
            fi
        done
    fi

    print_section_done
}

poweroff() {
    print_section "Shutting down the system"

    while true; do
        read_section "Do you want to shutdown the system? [y/n]" confirmation
        case $confirmation in
            [Yy]*)
                if [ -x "$(command -v systemctl)" ]; then
                    systemctl poweroff
                elif [ -x "$(command -v shutdown)" ]; then
                    shutdown -h now
                else
                    print_subsection_item_error "EC2 instance can't be powered off."
                fi
                break
                ;;
            [Nn]*)
                break
                ;;
        esac
    done

    print_section_done
}


# Main
print_banner
check_user
clean_custom_files
clean_ssh_keys
clean_package_manager
clean_logs
clean_bash_history
poweroff
