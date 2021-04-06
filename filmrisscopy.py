#!/usr/bin/env python3

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

import npyscreen
import os
from datetime import datetime


VERSION = "FILMRISSCOPY VERSION 0.2"
FILMRISSCOPY_PATH = os.path.dirname(__file__)
FILMRISSCOPY_LOGS_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_logs"
FILMRISSCOPY_TEMP_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_temp"
DATE = datetime.now().date()
TIME = datetime.now().time()


class locationForm(npyscreen.Form):
    def create(self):
        self.newSource = self.add(npyscreen.TitleFilenameCombo, name="Source 1", value="/mnt/", begin_entry_at=12)

        #newSource = self.add(npyscreen.TitleFilenameCombo, name=self.name)
        #newSource = self.add(npyscreen.TitleFilenameCombo, name=self.name)


    def afterEditing(self):
        self.parentApp.setNextForm(None)



class fcForm(npyscreen.Form):
    def create(self):
        self.projectWidget = self.add(npyscreen.TitleText, name="PROJECT", begin_entry_at=12)
        self.dateWidget = self.add(npyscreen.TitleDateCombo,name="DATE", value=DATE, begin_entry_at=12)
        self.timeWidget = self.add(npyscreen.TitleFixedText,name="TIME", value=TIME, begin_entry_at=12)
        self.checksumWidget = self.add(npyscreen.TitleSelectOne,name="CHECKSUM",values=["xxHash (preferred)", "MD5", "SHA-1", "Size Only"], begin_entry_at=12)


    def afterEditing(self):
        self.parentApp.setNextForm('Source')


class fcApp(npyscreen.NPSAppManaged):
    def onStart(self):
        self.addForm('MAIN', fcForm, name=VERSION)
        self.addForm('Source', locationForm, name="Choose Source")
        self.addForm('Destination', locationForm, name="Choose Destination")




if __name__ == '__main__':
    app = fcApp().run()
