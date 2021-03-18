![FilmrissCopy_Banner](FilmrissCopy_Banner.jpg)

# Filmriss Copy Version 0.1

## About
FilmrissCopy is a small program for copying and checking video/audio files for onset backups. You have the option for up to two sources and two destinations and the copied data will be verified via MD5Checksum Calculations. In case the copy process was interrupted there is the option to use RSYNC to copy the missing files. Log files for the complete process are stored in the destinations as well as in a "filmrisscopy_logs" folder where the script is located.  

## Output
The created folder structure looks like this:  
.../Project/Date_Projekt_ReelName/Source

## Checksum 
Currently the Script only supports MD5sum, but I am planning to implement xXHash and SHA-1 aswell.
