#!/bin/bash

# Installs filmrisscopy in /usr/local/bin and makes it executable
# Also creates a data dir for logs, presets and a config file

installDir="/usr/local/bin"
dataDir="${HOME}/.config/filmrisscopy"
version=0.2

BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "${BOLD}Installing FilmrissCopy V$version${NORMAL}"
echo

## Checking Dependencies

echo "${BOLD}Checking dependencies...${NORMAL}"
dependencyMissing=0

if command -v bash >/dev/null 2>&1; then
    echo "-> $(bash --version | head -1) found"
else
    echo "# bash not found. Please install it to run filmrisscopy"
    exit
fi

if command -v rsync >/dev/null 2>&1; then
    echo "-> $(rsync --version | head -1) found"
else
    echo "# rsync not found. Please install for full functionality"
    ((dependencyMissing += 1))
fi

if command -v xxhsum >/dev/null 2>&1; then
    echo "-> $(xxhsum --version 2>&1 | head -1) found"
else
    echo "# xxhsum not found. Please install for full functionality"
    ((dependencyMissing += 1))
fi

if [ "$dependencyMissing" == 0 ]; then
    echo "${BOLD}All dependencies found!${NORMAL}"
else
    echo "$dependencyMissing dependencies were not found."
fi

## Installation

cd ${installDir}/

if [ -f "${installDir}/filmrisscopy" ]; then
    echo
    echo "${BOLD}A version of FilmrissCopy is already installed!"
    echo "Updating to V${version}${NORMAL}"

fi

echo
echo "${BOLD}Needing Root Privileges to install to ${installDir}${NORMAL}"
echo "----------------------------"
sudo wget --no-verbose -O filmrisscopy https://gitlab.com/Nueffel/filmrisscopy/-/raw/master/filmrisscopy.sh
sudo chmod +x filmrisscopy
echo "----------------------------"

## Config/Data/Log Setup

configFile="${dataDir}/filmrisscopy.config"

mkdir -p "${dataDir}"

if [ ! -f "$configFile" ]; then # Writes default config
    echo " #!/bin/bash" >>"$configFile"
    echo >>"$configFile"
    echo "logfileBackupPath=\${dataDir}/logs" >>"$configFile"
    echo "presetPath=\${dataDir}/presets" >>"$configFile"
    echo "verificationMode=xxhash" >>"$configFile"
fi

echo "${BOLD}FilmrissCopy installed under ${installDir}/filmrisscopy${NORMAL}"

echo
echo "Type ${BOLD}filmrisscopy${NORMAL} to run"
