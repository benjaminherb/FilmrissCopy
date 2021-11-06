#!/bin/bash

# Installs filmrisscopy in ~/bin and makes it executable

echo "Installing FilmrissCopy V0.2"
echo

echo "Checking dependencies..."
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
    echo "All dependencies found!"
else
    echo "$dependencyMissing dependencies were not found."
fi
echo

mkdir -p ~/bin/
cd ~/bin/

wget -O filmrisscopy https://gitlab.com/Nueffel/filmrisscopy/-/raw/master/filmrisscopy.sh
chmod +x filmrisscopy

configDirectory="${HOME}/.config/filmrisscopy/"
configFile="$configDirectory/filmrisscopy.config"

mkdir -p "$configDirectory"
echo "#!/bin/bash" >>"$configFile"
echo >>"$configFile"
echo "logfileBackupPath=\${HOME}/.config/filmrisscopy/logs" >>"$configFile"
echo "presetPath=\${HOME}/.config/filmrisscopy/presets" >>"$configFile"

echo "FilmrissCopy installed under ~/bin/filmrisscopy"
echo "To run in from everywhere you might have to add ~/bin to your \$PATH Variable (you can do that inside your ~/.bashrc)"
echo
echo "Type \"filmrisscopy\" to run"
