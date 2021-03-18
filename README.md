![FilmrissCopy_Banner](FilmrissCopy_Banner.jpg)

# Filmriss Copy Version 0.1

## About
FilmrissCopy is a program for copying and verifying video / audio files for onset backups.

You have the option for up to two sources and two destinations and the copied data will be verified via MD5Checksum Calculations. In case the copy process was interrupted there is the option to use RSYNC to copy the missing files.

## Logging
Logfiles for the completed process are stored in the destination folder as well as in a "filmrisscopy_logs" folder where the script is located.

## Output
The created folder structure looks like this:  
.../PROJECT/DATE_PROJECT_REELNAME/SOURCEFOLDER/DATA...<br/>
.../PROJECT/DATE_PROJECT_REELNAME/DATE_TIME_JOB_PROJECTNAME_filmrisscopy_log.txt<br/>
.../PROJECT/DATE_PROJECT_REELNAME/md5sum.txt<br/>

## Checksum
Currently the Script only supports MD5 Checksum, Implementations of XXHash and SHA-1 are planned.
