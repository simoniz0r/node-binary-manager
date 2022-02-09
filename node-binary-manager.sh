#!/bin/bash

# set default platform if not set
NBM_PLATFORM="${NBM_PLATFORM:-linux-x64}"

# function to handle errors
nbm_error(){
    echo "$1"
    if [[ -n "$file" ]]; then
        rm -f /tmp/"$file"
    fi
    if [[ -n "$input" && -d "/opt/node-binary-manager/${input}_backup" ]]; then
        mv /opt/node-binary-manager/"$input"_backup /opt/node-binary-manager/"$input"
    fi
    exit "$2"
}

# function to get info for given nodejs version
nbm_getversion() {
    # get sha256 sum and file info
    export shafile="$(curl -sL "https://nodejs.org/dist/$1/SHASUMS256.txt" 2>/dev/null | grep "$NBM_PLATFORM\.tar\.xz")"
    if [[ -z "$shafile" ]]; then
        nbm_error "Failed to get info for nodejs version '$1'" "1"
    fi
    export shasum="$(echo "$shafile" | cut -f1 -d' ')"
    export file="$(echo "$shafile" | cut -f3 -d' ')"
    export version="$(echo "$file" | rev | cut -f3- -d'.' | rev)"
}

# function to download and extract given nodejs version
nbm_install() {
    if [[ "$EUID" -ne 0 ]]; then
        nbm_error "This operation requires elevated permissions" "2"
    fi
    if [[ -z "$1" ]]; then
        nbm_error "No version input given" "2"
    fi
    export input="$1"
    # get version info
    nbm_getversion "$1"
    curl -L "https://nodejs.org/dist/$1/$file" -o /tmp/"$file" || nbm_error "Failed to download '$1'" "2"
    shacheck="$(sha256sum /tmp/"$file" | cut -f1 -d' ')"
    if [[ "$shacheck" != "$shasum" ]]; then
        nbm_error "SHA256 sum of downloaded file ($shacheck) does not match expected sum ($shasum)" "2"
    fi
    mkdir -p /opt/node-binary-manager || nbm_error "Failed to create directory '/opt/node-binary-manager'" "2"
    tar -xf /tmp/"$file" -C /opt/node-binary-manager || nbm_error "Failed to extract '/tmp/$file'" "2"
    rm -f /tmp/"$file"
    mv /opt/node-binary-manager/"$version" /opt/node-binary-manager/"$1"
    echo "$version" > /opt/node-binary-manager/"$1"/version.txt
    echo "Installed '$1' to '/opt/node-binary-manager/$1'"
}

# function to check if given nodejs version is up to date
nbm_update() {
    if [[ "$EUID" -ne 0 ]]; then
        nbm_error "This operation requires elevated permissions" "3"
    fi
    if [[ -z "$1" ]]; then
        nbm_error "No version input given" "3"
    fi
    # check if directory exists
    if [[ ! -d "/opt/node-binary-manager/$1" ]]; then
        nbm_error "nodejs version '$1' not found in '/opt/node-binary-manager'" "3"
    fi
    # check if version.txt exists
    if [[ ! -f "/opt/node-binary-manager/$1/version.txt" ]]; then
        nbm_error "version.txt not found in '/opt/node-binary-manager/$1'" "3"
    fi
    # get current_version from version.txt
    current_version="$(cat /opt/node-binary-manager/"$1"/version.txt)"
    # check if current_version is empty
    if [[ -z "$current_version" ]]; then
        nbm_error "Failed getting version info from '/opt/node-binary-manager/$1/version.txt'" "3"
    fi
    # get version info from nodejs.org
    nbm_getversion "$1"
    if [[ "$current_version" == "$version" ]]; then
        echo "nodejs version '$1' is up to date."
    else
        echo "New version of '$1' available"
        echo -e "Current version: $current_version\tNew version: $version"
        echo "Updating '$1' to '$version'..."
        mv /opt/node-binary-manager/"$1" /opt/node-binary-manager/"$1"_backup
        nbm_install "$1"
        rm -rf /opt/node-binary-manager/"$1"_backup
    fi
}

# function to set a given version as default node version using symlinks
nbm_default() {
    if [[ "$EUID" -ne 0 ]]; then
        nbm_error "This operation requires elevated permissions" "3"
    fi
    if [[ -z "$1" ]]; then
        nbm_error "No version input given" "4"
    fi
    # check if directory exists
    if [[ ! -d "/opt/node-binary-manager/$1" ]]; then
        nbm_error "nodejs version '$1' not found in '/opt/node-binary-manager'" "4"
    fi
    mkdir -p /usr/local/bin /usr/local/include /usr/local/lib /usr/local/share/doc/node /usr/local/share/man/man1 /usr/local/share/systemtap/tapset || \
    nbm_error "Failed to create directories in '/usr/local'" "4"
    # test creating symlink for node
    ln -sf /opt/node-binary-manager/"$1"/bin/node /usr/local/bin/node || \
    nbm_error "Failed to create symlink '/usr/local/bin/node'" "4"
    # create symlinks for all files in bin dir
    for lfile in /opt/node-binary-manager/"$1"/bin/*; do
        file_name="$(echo "$lfile" | rev | cut -f1 -d'/' | rev)"
        ln -sf "$lfile" /usr/local/bin/"$file_name"
    done
    # create symlinks for all files in include dir
    for lfile in /opt/node-binary-manager/"$1"/include/*; do
        file_name="$(echo "$lfile" | rev | cut -f1 -d'/' | rev)"
        ln -sf "$lfile" /usr/local/include/"$file_name"
    done
    # create symlinks for all files in lib dir
    for lfile in /opt/node-binary-manager/"$1"/lib/*; do
        file_name="$(echo "$lfile" | rev | cut -f1 -d'/' | rev)"
        ln -sf "$lfile" /usr/local/lib/"$file_name"
    done
    # create symlinks for all files in share dir
    ln -sf /opt/node-binary-manager/"$1"/share/doc/node/gdbinit /usr/local/share/doc/node/gdbinit
    ln -sf /opt/node-binary-manager/"$1"/share/doc/node/lldb_commands.py /usr/local/share/doc/node/lldb_commands.py
    ln -sf /opt/node-binary-manager/"$1"/share/man/man1/node.1 /usr/local/share/man/man1/node.1
    ln -sf /opt/node-binary-manager/"$1"/share/systemtap/tapset/node.stp /usr/local/share/systemtap/tapset/node.stp
    echo "nodejs version '$1' set as default version"
}

# function to remove installed versions
nbm_remove() {
    if [[ "$EUID" -ne 0 ]]; then
        nbm_error "This operation requires elevated permissions" "5"
    fi
    if [[ -z "$1" ]]; then
        nbm_error "No version input given" "5"
    fi
    if [[ ! -d "/opt/node-binary-manager/$1" ]]; then
        nbm_error "nodejs version '$1' not found in '/opt/node-binary-manager'" "5"
    fi
    if [[ -f "/usr/local/bin/node" && "$(readlink -f /usr/local/bin/node | cut -f4 -d'/')" == "$1" ]]; then
        nbm_error "Cannot remove '$1'; '$1' is set as the current default" "5"
    fi
    rm -r /opt/node-binary-manager/"$1" || nbm_error "Failed to remove '/opt/node-binary-manager/$1'" "5"
    echo "Removed nodejs version '$1' from '/opt/local/bin/node'"
}

# function to list installed and available versions
nbm_list() {
    if [[ -d "/opt/node-binary-manager" ]]; then
        echo "Installed versions:"
        ls -Cw1 /opt/node-binary-manager
    fi
    if [[ "$1" == "all" ]]; then
        echo "All versions available from 'https://nodejs.org':"
        curl -sL 'https://nodejs.org/dist' | grep '<a href' | cut -f2 -d'"' | grep '^v\|^latest' | tr -d '/'
    else
        echo "Versions available from 'https://nodejs.org':"
        curl -sL 'https://nodejs.org/dist' | grep '<a href' | cut -f2 -d'"' | grep '^latest' | tr -d '/'
        echo -e "\nUse 'list all' to see all available versions"
    fi
}

# help function
nbm_help() {
    echo "node-binary-manager version 0.0.1"
    echo -e "Usage:\t<install|in|update|up|default|def|remove|rm|list|ls> <version>"
    echo -e "  install|in:\tInstall a given nodejs version to /opt/node-binary-manager"
    echo -e "  update|up:\tUpdate an already installed nodejs version"
    echo -e "  default|def:\tSet a given nodejs version as default by creating symlinks to /usr/local"
    echo -e "  remove|rm:\tRemove an installed nodejs version from /opt/node-binary-manager"
    echo -e "  list|ls:\tList installed and available nodejs versions"
}

# check arguments
case "$1" in
    install|in) nbm_install "$2";;
    update|up) nbm_update "$2";;
    default|def) nbm_default "$2";;
    remove|rm) nbm_remove "$2";;
    list|ls) nbm_list "$2";;
    *) nbm_help;;
esac
