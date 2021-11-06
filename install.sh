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

mkdir -p ~/bin/filmrisscopy
cd ~/bin/filmrisscopy

# wget -O filmrisscopy https://gitlab.com/Nueffel/filmrisscopy/-/raw/master/filmrisscopy.sh
# wget -O README.md https://gitlab.com/Nueffel/filmrisscopy/-/raw/master/README.md
chmod +x filmrisscopy

echo "FilmrissCopy installed under ~/bin/filmrisscopy/"
echo "To run in from everywhere you might have to add ~/bin to your \$PATH Variable (you can do that inside your ~/.bashrc)"
echo
echo "Type \"filmrisscopy\" to run"
