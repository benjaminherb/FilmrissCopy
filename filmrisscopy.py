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

import Theme
import npyscreen
import os
from datetime import datetime


VERSION = "FILMRISSCOPY VERSION 0.2"
FILMRISSCOPY_PATH = os.path.dirname(__file__)
FILMRISSCOPY_LOGS_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_logs"
FILMRISSCOPY_TEMP_PATH = FILMRISSCOPY_PATH + "/filmrisscopy_temp"
DATE = datetime.now().date()
TIME = datetime.now().time()


class locationWidget(npyscreen.TitleFilenameCombo):
    def create(self):
        pass

    def when_value_edited(self):
        fcForm.source[1].hidden=False


class fcForm(npyscreen.Form):
    def create(self):

        self.projectWidget = self.add(npyscreen.TitleText, name="PROJECT", begin_entry_at=16)
        self.projectDay = self.add(npyscreen.TitleText, name="PROD. DAY", value="DT01", begin_entry_at=16)

        self.dateWidget = self.add(npyscreen.TitleDateCombo,name="DATE", value=DATE, begin_entry_at=16)
        self.timeWidget = self.add(npyscreen.TitleFixedText,name="TIME", value=TIME, begin_entry_at=16, editable=False)

        self.nextrely +=1

        self.source=[None]*3

        self.source[0] = self.add(npyscreen.TitleFilenameCombo, name="SOURCE 1",  begin_entry_at=16)
        self.source[1] = self.add(npyscreen.TitleFilename, name="SOURCE 2",  begin_entry_at=16)
        self.source[2] = self.add(npyscreen.TitleFilenameCombo, name="SOURCE 3",  begin_entry_at=16)

        self.nextrely +=1

        self.destination=[None]*3
        self.destination[0] = self.add(npyscreen.TitleFilenameCombo, name="DESTINATION 1", begin_entry_at=16)
        self.destination[1] = self.add(npyscreen.TitleFilenameCombo, name="DESTINATION 2", begin_entry_at=16)
        self.destination[2] = self.add(npyscreen.TitleFilenameCombo, name="DESTINATION 3", begin_entry_at=16)

        self.nextrely +=1

        self.checksumWidget = self.add(npyscreen.TitleSelectOne,name="CHECKSUM",values=["xxHash (preferred)", "MD5", "SHA-1", "Size Only"], begin_entry_at=16, scroll_exit=True)




    def afterEditing(self):
        self.parentApp.setNextForm('Source')


class fcApp(npyscreen.NPSAppManaged):
    def onStart(self):
        Theme.filmrissCopyTheme()
        self.addForm('MAIN', fcForm, name=VERSION)
    #    self.addForm('Source', locationForm, name="Choose Source")
    #    self.addForm('Destination', locationForm, name="Choose Destination")




if __name__ == '__main__':
    app = fcApp().run()
