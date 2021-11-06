![FilmrissCopy_Banner](FilmrissCopy_Banner.jpg)

# Filmriss Copy Version 0.2

## About
FilmrissCopy is a program for copying and verifying video / audio files for onset backups.

You have the option to select multiple sources and destinations and the copied data will be verified via xxHash Checksums (or optionally SHA-1 / MD5 / Size Comparison). In case the copy process was interrupted there is the option to use RSYNC to copy the missing files as well as an option to verify your copy again using the log files.

## Installation

The script uses xxHash as default verification method and rsync for resuming a copy process so it is recommended to install both of them.

# Arch Based Distro
```
sudo pacman -S xxhash rsync
```

Then Download the latest script from the release page and make it executable
```
chmod +x ./filmrisscopy.sh
```

Then just run it with
```
./filmrisscopy.sh
```

## Logging
Comprehensive logfiles for the completed process are stored in the destination folder as well as in a "filmrisscopy_logs" folder where the script is located. The log file can also be used to verify copys of the data later. A log files looks like this:

```
FILMRISSCOPY VERSION 0.2
PROJECT NAME: TEST
SHOOT DAY: SD01
PROJECT DATE: 19500101
SOURCE: /mnt/SRC
DESTINATION: /mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001
JOB: 1 / 1
RUNMODE: copy
DATE/TIME: 20211106_1551
VERIFICATION: xxHash

NO CHECKSUM ERRORS!

COPIED AND VERIFIED 33 FILES IN 00:00:06 ( TOTAL SIZE: 128M / 130376 )

FOLDER STRUCTURE:
./SRC/
./SRC/A001_01011200_C001
./SRC/A001_01011202_C002
./SRC/A001_01011204_C003
[...]

COPY PROCESS:
'/mnt/SRC' -> '/mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001/SRC'
'/mnt/SRC/A001_01011200_C001' -> '/mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001/SRC/A001_01011200_C001'
'/mnt/SRC/A001_01011200_C001/A001_01011200_C001.wav' -> '/mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001/SRC/A001_01011200_C001/A001_01011200_C001.wav'
'/mnt/SRC/A001_01011200_C001/A001_01011200_C001_000000.dng' -> '/mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001/SRC/A001_01011200_C001/A001_01011200_C001_000000.dng'
'/mnt/SRC/A001_01011200_C001/A001_01011200_C001_000001.dng' -> '/mnt/DST/TEST/SD01_19500101/SD01_19500101_TEST_A001/SRC/A001_01011200_C001/A001_01011200_C001_000001.dng'
[...]

CHECKSUM CALCULATIONS ON SOURCE:
b7f652ee8013c1a9  ./A001_01011200_C001/A001_01011200_C001.wav
03774b332dbbbee1  ./A001_01011200_C001/A001_01011200_C001_000000.dng
dd6ba91ff2be5c08  ./A001_01011200_C001/A001_01011200_C001_000001.dng
[...]

COMPARING CHECKSUM TO COPY:
./A001_01011200_C001/A001_01011200_C001.wav: OK
./A001_01011200_C001/A001_01011200_C001_000000.dng: OK
./A001_01011200_C001/A001_01011200_C001_000001.dng: OK
[...]
```

## Verify
There are two ways to verify using a filmrisscopy log file.
The first option is to choose a logfile and the corresponding directory to verify.
The second option is "Batch Verify". Here you choose a top level directory and filmrisscopy will recursivly search for all log files and verify based on the oldest log file (granted it has completed checksums).
The Output will be stored in a filmrisscopy_verification_log.txt file.

## V0.2 Changelog
Added Option to verify using FilmrissCopy Log Files<br/>
Fixed RSYNC Behaviour & Speed Improvements<br/>
Added Way to differentiate between Current Date/Time and Project Date<br/>
Fixed Log File Formatting Issues<br/>
Updated Folder / Log File Naming Scheme<br/>
Added Option to save preset when something is interrupted<br/>
Fixed Checksum Progress Bar<br/>
Added Source Serial Number to the log file<br/>
Stability Improvements<br/>
