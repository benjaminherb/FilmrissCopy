![FilmrissCopy_Banner](FilmrissCopy_Banner.jpg)

# Filmriss Copy Version 0.2

## About
FilmrissCopy is a program for copying and verifying video / audio files for onset backups.

You have the option to select multiple sources and destinations and the copied data will be verified via xxHash Checksums (or optionally SHA-1 / MD5 / Size Comparison). In case the copy process was interrupted there is the option to use RSYNC to copy the missing files.

## Logging
Comprehensive Logfiles for the completed process are stored in the destination folder as well as in a "filmrisscopy_logs" folder where the script is located. The log file can also be used to verify copys of the data later.

## Output
The created folder structure looks like this:  
.../PROJECT/DATE_PROJECT_REELNAME/SOURCEFOLDER/DATA...<br/>
.../PROJECT/DATE_PROJECT_REELNAME/DATE_TIME_JOB_PROJECTNAME_filmrisscopy_log.txt<br/>
