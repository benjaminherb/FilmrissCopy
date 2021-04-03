# filmrissCopy Version 0.2

# FilmrissCopy is a program for copying and verifying video / audio files for
# on set backups.
# Copyright (C) <2021>  <Benjamin Herb>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import os
from datetime import datetime

# SETUP
VERSION = "FILMRISSCOPY VERSION 0.2"
FILMRISSCOPY_PATH = os.path.dirname(__file__)
FILMRISSCOPY_LOGS_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_logs"
FILMRISSCOPY_TEMP_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_temp"
DATE = datetime.now().date()
TIME = datetime.now().time()

if not os.path.exists(FILMRISSCOPY_LOGS_PATH):
    os.makedirs(FILMRISSCOPY_LOGS_PATH)

if not os.path.exists(FILMRISSCOPY_TEMP_PATH):
    os.makedirs(FILMRISSCOPY_TEMP_PATH)

print(VERSION)
print("LOCATION:    " + FILMRISSCOPY_PATH)
print("LOGS:        " + FILMRISSCOPY_LOGS_PATH)
print(DATE)
print(TIME)
