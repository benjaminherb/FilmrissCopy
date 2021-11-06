#!/bin/bash

# Installs filmrisscopy in ~/bin and makes it executable

BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "${BOLD}Installing FilmrissCopy V0.2${NORMAL}"
echo

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
echo

cd /usr/local/bin/

wget -O filmrisscopy https://gitlab.com/Nueffel/filmrisscopy/-/raw/master/filmrisscopy.sh
chmod +x filmrisscopy

configDirectory="${HOME}/.config/filmrisscopy/"
configFile="$configDirectory/filmrisscopy.config"

mkdir -p "$configDirectory"
echo "#!/bin/bash" >>"$configFile"
echo >>"$configFile"
echo "logfileBackupPath=\${HOME}/.config/filmrisscopy/logs" >>"$configFile"
echo "presetPath=\${HOME}/.config/filmrisscopy/presets" >>"$configFile"

echo "${BOLD}FilmrissCopy installed under /usr/local/bin/filmrisscopy${NORMAL}"

echo
echo "Type ${BOLD}filmrisscopy${NORMAL} to run"
