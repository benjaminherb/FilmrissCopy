# FilmrissCopy is a program for copying and verifying video / audio files for onset backups.
# Copyright (C) <2021>  <Benjamin Herb>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Start (Header Info)
RED='tput setaf 1'
NC='tput sgr0' # no color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"
echo
scriptPath=${BASH_SOURCE[0]} # Find Scriptpath for the Log File Save Location
echo "LAST UPDATED:	$(date -r "$scriptPath")"

cd $(dirname "$scriptPath")
scriptPath=$(pwd)
echo "LOCATION:	"$scriptPath"/"
echo "LOGFILES:	"$scriptPath"/filmrisscopy_logs/"
echo "PRESETS: 	"$scriptPath"/filmrisscopy_presets/"

tempFolder=""$scriptPath"/filmrisscopy_temp"
mkdir -p $tempFolder #Temp folder for storing Hashfiles during a process (to be used again)

projectDate=$(date +"%Y%m%d")
projectTime=$(date +"%H%M")
verificationMode="xxhash"

## Define Project Settings
setProjectName() {
    echo
    echo Choose Project Name:
    read -e projectName
}

## Choose Ssource Directoryot -name
setSource() {
    echo
    echo Choose Source Folder:
    read -e sourceFolderTemp

    if [[ ! -d "$sourceFolderTemp" ]]; then
        echo "$($RED)ERROR: $sourceFolderTemp IS NOT A VALID SOURCE$($NC)"
        setSource
    else
        setReelName
    fi

    allSourceFolders=("$sourceFolderTemp")
    allReelNames=("$reelNameTemp")

    loop="true"
    while [[ $loop == "true" ]]; do
        echo
        echo "Choose Additional Source Folder (Enter to Skip)"
        read -e sourceFolderTemp

        duplicateSource="false"
        for src in "${allSourceFolders[@]}"; do # Loops over source array to check if the new source is a douplicate
            if [ "${src}" == "$sourceFolderTemp" ]; then
                duplicateSource="true"
                break
            fi
        done

        if [[ $sourceFolderTemp == "" ]]; then
            loop=false
        elif [ ! -d "$sourceFolderTemp" ]; then
            echo "$($RED)ERROR: "$sourceFolderTemp" IS NOT A VALID SOURCE$($NC)"
        elif [[ $duplicateSource == "true" ]]; then
            echo "$($RED)ERROR: YOU CAN NOT SET THE SAME SOURCE TWICE IN A PROJECT$($NC)"
        else
            setReelName
            allSourceFolders+=("$sourceFolderTemp")
            allReelNames+=("$reelNameTemp")
        fi
    done
}

## Choose Reel Name
setReelName() {
    echo
    echo Source Reel Name:
    read -e reelNameTemp
}

## Choose Destination Directory
setDestination() {
    echo
    echo Choose Destination Folder:
    read -e destinationFolderTemp

    if [[ ! -d "$destinationFolderTemp" ]]; then
        echo "$($RED)ERROR: $destinationFolderTemp IS NOT A VALID DESTINATION $($NC)"
        setDestination
    fi

    allDestinationFolders=("$destinationFolderTemp")

    duplicateDestination="false"
    for dst in "${allDestinationFolders[@]}"; do # Loops over source array to check if the new source is a douplicate
        if [ "${dst}" == "$destinationFolderTemp" ]; then
            duplicateDestination="true"
            break
        fi
    done

    loop="true"
    while [[ $loop == "true" ]]; do
        echo
        echo "Choose Additional Destination Folder (Enter to Skip)"
        read -e destinationFolderTemp

        if [[ $destinationFolderTemp == "" ]]; then
            loop=false
        elif [ ! -d "$destinationFolderTemp" ]; then
            echo "$($RED)ERROR: "$destinationFolderTemp" IS NOT A VALID DESTINATION$($NC)"
        elif [[ duplicateDestination == "true" ]]; then
            echo "$($RED)ERROR: YOU CAN NOT SET THE SAME DESTINATION TWICE IN A PROJECT$($NC)"
        else
            allDestinationFolders+=("$destinationFolderTemp")
        fi
    done

}

## Choose Verification Method
setVerificationMethod() {
    echo
    echo "Choose your preferred Verification Method (xxHash is recommended)"
    echo
    echo "(0) EXIT  (1) XXHASH  (2) MD5  (3) SHA-1  (4) SIZE COMPARISON ONLY"
    read -e verifCommand

    if [[ ! $verifCommand == "0" ]] && [[ $verifCommand == "1" ]] && [[ $verifCommand == "2" ]] && [[ $verifCommand == "3" ]] && [[ $verifCommand == "4" ]]; then
        setVerificationMethod
    fi

    if [ $verifCommand == "1" ]; then
        verificationMode="xxhash"
    elif [ $verifCommand == "2" ]; then
        verificationMode="md5"
    elif [ $verifCommand == "3" ]; then
        verificationMode="sha"
    elif [ $verifCommand == "4" ]; then
        verificationMode="size"
    fi
}

loadPreset() {
    echo
    echo "(0) BACK  (1) LOAD LAST PRESET  (2) LOAD PRESET FROM FILE"
    read -e presetCommand

    if [ ! $presetCommand == "0" ] && [ ! $presetCommand == "1" ] && [ ! $presetCommand == "2" ]; then loadPreset; fi

    if [ $presetCommand == "1" ]; then
        source "$scriptPath/filmrisscopy_preset_last.config"
    elif [ $presetCommand == "2" ]; then
        echo "Choose Preset Path"
        read -e presetPath
        source "$presetPath"
    fi
}

## Run the main Copy Process
run() {
    runMode=copy # Can be Copy, Checksum or RSync
    echo

    totalByteSpace=$(du -s "$sourceFolder" | cut -f1) # Check if there is enough Space left
    destinationFreeSpace=$(df --block-size=1 --output=avail "$destinationFolder" | cut -d$'\n' -f2)

    if [[ $(($destinationFreeSpace - $totalByteSpace)) -lt 20 ]]; then
        echo "$($RED)ERROR: NOT ENOUGH DISK SPACE LEFT IN $destinationFolder$($NC)"
        return
    fi

    destinationFolderFullPath="$destinationFolder""$projectName""/"$projectDate"_""$projectName""_"$reelName # Generate Full Path

    if [[ ! -d "$destinationFolderFullPath" ]]; then # Check if the folder already exists, and creates the structure if needed
        mkdir -p "$destinationFolderFullPath"
    else
        echo "$($RED)ERROR: DIRECTORY ALREAD EXISTS IN THE DESTINATION FOLDER$($NC)"
        echo
        fileDifference=$(($(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l) - $(find "$destinationFolderFullPath" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)))

        if [[ $fileDifference == 0 ]]; then
            echo Source and Destination have the same Size

            echo "Run Checksum Calculations? (y/n)"
            read -e rerunChecksum

            while [ ! "$rerunChecksum" == "y" ] && [ ! "$rerunChecksum" == "n" ] && [ -z "$rerunChecksum" ]; do
                echo "Run Checksum Calculations? (y/n)"
                read -e rerunChecksum
            done

            if [[ $rerunChecksum == "y" ]]; then
                runMode=checksum
                echo
            fi
            if [[ $rerunChecksum == "n" ]]; then return; fi

        else

            if [ $fileDifference -gt 0 ]; then
                echo "There are $fileDifference Files missing compared to the Source Directory"
            else
                fileDifference=$(($fileDifference * -1))
                echo "There are $fileDifference Files more in the Destination than in the Source Directory. The Folder is probably already in use for something different!"
            fi
            echo "Run RSYNC to copy the missing Files? (Needs Sudo Privileges) (y/n)"
            read -e runRsync

            while [ ! $runRsync == "y" ] && [ ! $runRsync == "n" ]; do
                echo "Run RSYNC to copy the missing Files? (y/n)"
                read -e runRsync
            done
            echo

            if [[ $runRsync == "y" ]]; then runMode=rsync; fi
            if [[ $runRsync == "n" ]]; then return; fi
        fi
    fi

    log # Create Log File and Write Header

    totalFileCount=$(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)
    totalFileSize=$(du -msh "$sourceFolder" | cut -f1)
    copyStartTime=$(date +%s)

    if [[ $runMode == "copy" ]]; then
        echo "${BOLD}RUNNING COPY...${NORMAL}"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        cp --recursive --verbose "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1
        sleep 2
        kill $! # Copy then wait for the Status to catch up
        echo
    fi

    if [[ $runMode == "rsync" ]]; then
        sudo echo "${BOLD}RUNNING RSYNC...${NORMAL}"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        sudo rsync --verbose --checksum --archive "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1
        sleep 2
        kill $! # Needs Root, checks based on checksum Calculations
        echo
    fi

    if [ $verificationMode == "md5" ]; then # Used in commands later (eg. to refer to the correct **sum.txt )
        checksumUtility="md5sum"
    elif [ $verificationMode == "xxhash" ]; then
        checksumUtility="xxhsum"
    elif [ $verificationMode == "sha" ]; then
        checksumUtility="shasum"
    fi

    checksumFile=""$tempFolder"/"$checksumUtility"_"$reelName"" # Store the checksum file in a temp folder (verifyable with the job number) so it can be refered to when having multiple Destinations

    checksum

    currentTime=$(date +%s)
    elapsedTime=$(($currentTime - $copyStartTime))

    timeTemp=$elapsedTime
    elapsedTimeFormatted=$(formatTime)

    echo # End of the Job
    if [[ ! $runMode == "copy" ]] && [[ ! $runMode == "rsync" ]]; then
        echo "${BOLD}JOB $currentJobNumber DONE: VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
        sed -i "11 a VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / "$totalByteSpace" )\n" "$logfilePath" >/dev/null 2>&1
    else
        echo "${BOLD}JOB $currentJobNumber DONE: COPIED AND VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
        sed -i "11 a COPIED AND VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / "$totalByteSpace" )\n" "$logfilePath" >/dev/null 2>&1
    fi

    sed -i '/THE COPY PROCESS WAS NOT COMPLETED CORRECTLY/d' "$logfilePath" >/dev/null 2>&1 # Delete the Notice as the run was completed

    mkdir -p "$scriptPath"/filmrisscopy_logs/
    cp "$logfilePath" "$scriptPath"/filmrisscopy_logs/ # Backup logs to a folder in the scriptpath
}

## Copy progress
copyStatus() {
    while [ true ]; do
        sleep 1 # Change if it slows down the process to much / if more accuracy is needed

        copiedFileCount=$(find "$destinationFolderFullPath" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $copyStartTime))

        if [[ ! $copiedFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($copiedFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut -d. -f1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        timeTemp=$elapsedTime
        elapsedTimeFormatted=$(formatTime)
        timeTemp=$aproxTime
        aproxTimeFormatted=$(formatTime)

        echo -ne "$copiedFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted"\\r
    done
}

## Checksum
checksum() {
    checksumStartTime=$(date +%s)
    echo "${BOLD}RUNNING CHECKSUM CALCULATIONS ON SOURCE...${NORMAL}"
    echo >>"$logfilePath"
    echo "CHECKSUM CALCULATIONS ON SOURCE:" >>"$logfilePath"
    cd "$sourceFolder"
    logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1) # Used for the Progress

    checksumStatus &

    (find -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) -exec $checksumUtility '{}' \; | tee "$checksumFile" >>"$logfilePath" 2>&1)

    sleep 2
    kill $!
    echo

    checksumStartTime=$(date +%s)
    echo "${BOLD}COMPARING CHECKSUM TO COPY...${NORMAL}"
    echo >>"$logfilePath"
    echo "COMPARING CHECKSUM TO COPY:" >>"$logfilePath"

    logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1) # Updated for the new Progress
    cd "$destinationFolderFullPath"
    cd "$(basename "$sourceFolder")" # Go into the copied source folder to get the same relative path for the checksum verification

    checksumComparisonStatus &

    "$checksumUtility" -c "$checksumFile" >>"$logfilePath" 2>&1 # Command to verify using the checksumFile

    sleep 2
    kill $!
    echo

    checksumPassedFiles=$(grep -c ": OK" "$logfilePath") # Checks wether the output to the logfile were all "OK" or not
    if [[ $checksumPassedFiles == $totalFileCount ]]; then
        echo "${BOLD}NO CHECKSUM ERRORS!${NORMAL}"
        sed -i "9 a NO CHECKSUM ERRORS!\n" "$logfilePath" >/dev/null 2>&1
    else
        echo "${BOLD}$($RED)ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST${NORMAL}$($NC)"
        sed -i "9 a ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST\n" "$logfilePath" >/dev/null 2>&1
    fi
}

## Checksum Progress
checksumStatus() {
    while [[ true ]]; do
        sleep 1

        checksumFileCount=$(($(wc -l "$logfilePath" | cut --delimiter=" " -f1) - $logFileLineCount))
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $checksumStartTime))

        if [[ ! $checksumFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($checksumFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut -d. -f1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        timeTemp=$elapsedTime
        elapsedTimeFormatted=$(formatTime)
        timeTemp=$aproxTime
        aproxTimeFormatted=$(formatTime)
        echo -ne "$checksumFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted\\r"
    done
}

## Checksum Comparison progress
checksumComparisonStatus() {
    while [[ true ]]; do
        sleep 1

        checksumFileCount=$(($(wc -l "$logfilePath" | cut --delimiter=" " -f1) - $logFileLineCount))
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $checksumStartTime))

        if [[ ! $checksumFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($checksumFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut -d. -f1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        timeTemp=$elapsedTime
        elapsedTimeFormatted=$(formatTime)
        timeTemp=$aproxTime
        aproxTimeFormatted=$(formatTime)

        echo -ne "$checksumFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted\r"
    done
}

## Log
log() {
    logfile=$projectDate"_"$projectTime"_"$currentJobNumber"_"$jobNumber"_""$projectName""_filmrisscopy_log.txt"
    logfilePath="$destinationFolderFullPath"/$logfile
    echo FILMRISSCOPY VERSION 0.1 >>"$logfilePath"
    echo PROJECT NAME: $projectName >>"$logfilePath"
    echo DATE/TIME: $projectDate"_"$projectTime >>"$logfilePath"
    echo SOURCE: $sourceFolder >>"$logfilePath"
    echo DESTINATION: $destinationFolderFullPath >>"$logfilePath"
    echo JOB: $currentJobNumber / $jobNumber >>"$logfilePath"
    echo RUNMODE: $runMode >>"$logfilePath"

    if [ $verificationMode == "md5" ]; then
        echo VERIFICATION: MD5 >>"$logfilePath"
    elif [ $verificationMode == "xxhash" ]; then
        echo VERIFICATION: xxHash >>"$logfilePath"
    elif [ $verificationMode == "sha" ]; then
        echo VERIFICATION: SHA-1 >>"$logfilePath"
    fi

    echo >>"$logfilePath"
    echo THE COPY PROCESS WAS NOT COMPLETED CORRECTLY >>"$logfilePath" # Will be Deleted after the Job is finished
    echo >>"$logfilePath"
    cd "$sourceFolder"
    echo FOLDER STRUCTURE: >>"$logfilePath"
    find . ! -path . -type d >>"$logfilePath" # Print Folder Structure
}

## Changes seconds to h:m:s, change $tempTime to use, and save the output in a variable
formatTime() {
    h=$(($timeTemp / 3600))
    m=$(($timeTemp % 3600 / 60))
    s=$(($timeTemp % 60))
    printf "%02d:%02d:%02d" $h $m $s
}

## Print Current Status
printStatus() {
    echo
    if [[ $statusMode == "normal" ]]; then
        echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"
    fi

    if [[ $statusMode == "edit" ]]; then
        echo "${BOLD}EDIT PROJECT SETTINGS${NORMAL}"
    fi

    echo "${BOLD}PROJECT NAME:${NORMAL}	$projectName"
    echo "${BOLD}DATE:	${NORMAL}	$projectDate"
    echo "${BOLD}TIME:	${NORMAL}	$projectTime"

    x=0
    for src in "${allSourceFolders[@]}"; do # Loops over source array prints all entrys
        echo "${BOLD}SOURCE ${allReelNames[x]}:${NORMAL}	$src"
        ((x++))
    done

    x=1
    for dst in "${allDestinationFolders[@]}"; do # Loops over destination array prints all entrys
        echo "${BOLD}DESTINATION $x:${NORMAL}	$dst"
        ((x++))
    done

    case $verificationMode in
    xxhash)
        echo "${BOLD}VERIFICATION:${NORMAL}   xxHash"
        ;;
    md5)
        echo "${BOLD}VERIFICATION:${NORMAL}   MD5"
        ;;
    sha)
        echo "${BOLD}VERIFICATION:${NORMAL}   SHA-1"
        ;;
    size)
        echo "${BOLD}VERIFICATION:${NORMAL}   size comparison only"
        ;;
    esac

}

## Write preset_last.config
writePreset() {

    echo "## FILMRISSCOPY PRESET"
    echo "projectName=$projectName"
    echo "allSourceFolders=()"
    echo "allReelNames=()"
    echo "allDestinationFolders=()"

    x=0
    for src in "${allSourceFolders[@]}"; do # Loops over source array prints all entrys
        echo "allSourceFolders+=(\""$src"\")"
        echo "allReelNames+=("${allReelNames[x]}")"
        ((x++))
    done

    for dst in "${allDestinationFolders[@]}"; do # Loops over destination array prints all entrys
        echo "allDestinationFolders+=(\""$dst"\")"
    done

    echo "verificationMode=$verificationMode"
}

## Setup at Start
startupSetup() {

    echo
    echo "(0) SKIP  (1) RUN SETUP  (2) LOAD LAST PRESET  (3) LOAD PRESET FROM FILE"
    read -e usePreset
    if [ ! $usePreset == "0" ] && [ ! $usePreset == "1" ] && [ ! $usePreset == "2" ] && [ ! $usePreset == "3" ]; then
        startupSetup
    fi

    if [[ $usePreset == "1" ]]; then
        setProjectName
        setSource
        setDestination
    elif [[ $usePreset == "2" ]]; then
        source "$scriptPath/filmrisscopy_preset_last.config"
    elif [[ $usePreset == "3" ]]; then
        echo
        echo "Choose Preset Path"
        read -e presetPath
        source $presetPath
    fi
}

## Edit Project Loop
editProject() {
    loop=true
    while [[ $loop == "true" ]]; do

        statusMode="edit"
        printStatus
        statusMode="normal"

        echo
        echo "(0) BACK  (1) EDIT PROJECT NAME  (2) EDIT SOURCE  (3) EDIT DESTINATION  (4) EDIT DATE  (5) CHANGE VERIFICATION METHOD (6) LOAD PRESET"
        read -e editCommand

        if [ $editCommand == "1" ]; then setProjectName; fi
        if [ $editCommand == "2" ]; then setSource; fi
        if [ $editCommand == "3" ]; then setDestination; fi
        if [ $editCommand == "4" ]; then
            echo "Input Date (Format: $projectDate)"
            read -e projectDate
        fi
        if [ $editCommand == "5" ]; then setVerificationMethod; fi
        if [ $editCommand == "6" ]; then loadPreset; fi
        if [ $editCommand == "0" ]; then loop="false"; fi
    done
}

## Base Loop
startupSetup

while [ true ]; do

    statusMode="normal" # choose how the Status will be shown (normal or edit)
    printStatus

    echo
    echo "(0) EXIT  (1) RUN  (2) EDIT PROJECT  (3) RUN SETUP"
    read -e command

    if [ $command == "1" ]; then
        if [ ! ${#allSourceFolders[@]} -eq 0 ] && [ ! ${#allDestinationFolders[@]} -eq 0 ] && [ ! "$projectName" == "" ]; then # Check if atleast one Destination, one Source and a Project Name are set

            jobNumber=$((${#allSourceFolders[@]} * ${#allDestinationFolders[@]}))

            echo
            echo

            if [ $jobNumber -eq 1 ]; then
                echo "${BOLD}THERE IS $jobNumber COPY JOB IN QUEUE${NORMAL}"
            else
                echo "${BOLD}THERE ARE $jobNumber COPY JOBS IN QUEUE${NORMAL}"
            fi

            startTimeAllJobs=$(date +%s)

            currentJobNumber=0
            reelNumber=0
            for sourceFolder in "${allSourceFolders[@]}"; do # Loops over Source array for the Job Queue

                reelName=${allReelNames[$reelNumber]}
                ((reelNumber++))

                for destinationFolder in "${allDestinationFolders[@]}"; do # Loops over Destination array for the Job Que
                    ((currentJobNumber++))
                    echo
                    echo
                    echo "${BOLD}JOB $currentJobNumber / $jobNumber   $sourceFolder -> $destinationFolder${NORMAL}"
                    run
                done
            done

            endTimeAllJobs=$(date +%s)

            elapsedTime=$(($endTimeAllJobs - $startTimeAllJobs))

            timeTemp=$elapsedTime
            elapsedTimeFormatted=$(formatTime)

            echo
            if [ $jobNumber -eq 1 ]; then
                echo -e "${BOLD}$jobNumber JOB FINISHED IN $elapsedTimeFormatted${NORMAL}"
            else
                echo -e "${BOLD}$jobNumber JOBS FINISHED IN $elapsedTimeFormatted${NORMAL}"
            fi
            echo

            echo "Do you want to quit the Program? (y/n)" # Quit Program after Finished Jobs or return to the Main Loop
            read -e quitFRC
            while [ ! $quitFRC == "y" ] && [ ! $quitFRC == "n" ]; do
                echo "Do you want to quit the Program? (y/n)"
                read -e quitFRC
            done
            if [[ $quitFRC == "y" ]]; then command=0; fi

        else

            echo
            echo "$($RED)ERROR: PROJECT NAME, SOURCE OR DESTINATION ARE NOT SET YET$($NC)"
        fi

    fi

    if [ $command == "2" ]; then
        editProject
    fi

    if [ $command == "3" ]; then
        setProjectName
        setSource
        setDestination
    fi

    if [ $command == "0" ]; then
        echo
        echo "Overwrite last preset with the current Setup? (y/n)" # filmrisscopy_preset_last.config will be overwritten with the current parameters
        read -e overWriteLastPreset
        while [ ! $overWriteLastPreset == "y" ] && [ ! $overWriteLastPreset == "n" ]; do
            echo "Update last preset with the current Setup? (y/n)"
            read -e overWriteLastPreset
        done
        if [[ $overWriteLastPreset == "y" ]]; then
            writePreset >"$scriptPath/filmrisscopy_preset_last.config" # Write "last" Preset
            echo
            echo "Preset Updated"
        fi
        echo
        exit
    fi
done

## Add Copied Status
## Make Checksum Calculations in the Source folder first
## Option for different Algorithms (XXHASH, SHA-1) + Option for no verification
## MHL Implementation
## Implement Telegram Bot
## Add Option for verifying Checksum using a FilmrissCopyLogFileTM
## Default Preset
## Log Times of individual Tasks
## Change Loop Input Method
## Calculate Source Checksum Once for all Destinations
