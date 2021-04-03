#!/bin/bash

# FilmrissCopy is a program for copying and verifying video / audio files for onset backups.
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

## Start (Header Info)
RED='tput setaf 1'
NC='tput sgr0' # no color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

VERSION="FILMRISSCOPY VERSION 0.1.1"

echo "${BOLD}"$VERSION"${NORMAL}"
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
    echo

    for dst in "${allDestinationFoldersFullPath[@]}"; do
        log # Create Log File and Write Header
    done

    logfilePath="$tempFolder"/$projectDate"_"$projectTime"_"$projectName"_"$reelName"_filmrisscopy_log.txt"

    totalFileCount=$(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)
    totalFileSize=$(du -msh "$sourceFolder" | cut -f1)
    copyStartTime=$(date +%s)

    if [[ $runMode == "copySequential" ]]; then
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        cp --recursive --verbose "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1

        sleep 2
        kill $! # Copy then wait for the Status to catch up
    fi

    if [[ $runMode == "copy" ]]; then
        printf "\n## COPY\n" >>"$logfilePath"
        parallel -j0 -N1 --linebuffer --tagstring {} cp --recursive --verbose "$sourceFolder" ::: ${allDestinationFoldersFullPath[*]} >>"$logfilePath" 2>&1
    fi

    if [[ $runMode == "rsync" ]]; then # Needs Root, checks based on checksum Calculations
        printf "\n## COPY\n" >>"$logfilePath"
        sudo parallel -j0 -N1 --linebuffer --tagstring {} rsync --verbose --checksum --archive "$sourceFolder" ::: ${allDestinationFoldersFullPath[*]} >>"$logfilePath" 2>&1
    fi

    checksumFile="$tempFolder"/"$checksumUtility"_"$projectDate"_"$projectTime"_"$projectName"_"$reelName" # Store the checksum file in a temp folder (verifyable with the job number) so it can be refered to when having multiple Destinations

    printf "\n## CHECKSUM CALCULATION\n" >>"$logfilePath"
    checksumSource
    printf "\n## COMPARING CHECKSUM TO COPY\n" >>"$logfilePath"
    checksumComparison

    for dst in ${allDestinationFoldersFullPath[@]}; do
        printf "\n## COPY\n" >>"$dst/$logfile"
        sed -n '/## COPY/,/## CHECKSUM CALCULATION/p' "$logfilePath" | grep -G "$dst*" | cut -f2- >>"$dst/$logfile" # Move the output of copy from the temp LogFile to the real one

        printf "\n## CHECKSUM CALCULATION\n" >>"$dst/$logfile" # Move the output of the hash file to all log files
        cat "$checksumFile" >>"$dst/$logfile"

        printf "\n## COMPARING CHECKSUM TO COPY\n" >>"$dst/$logfile"
        sed -n '/## COMPARING CHECKSUM TO COPY/,//p' "$logfilePath" | grep -G "$dst*" | cut -f2- >>"$dst/$logfile" # Move the output of validate from the temp LogFile to the real one

        checksumPassedFiles=$(grep -c ": OK" "$dst/$logfile") # Checks wether the output to the logfile were all "OK" or not
        if [[ $checksumPassedFiles == $(($totalFileCount)) ]]; then
            #echo "${BOLD}NO CHECKSUM ERRORS!${NORMAL}"
            sed -i "9 a NO CHECKSUM ERRORS!\n" "$dst/$logfile" >/dev/null 2>&1
        else
            #echo "${BOLD}$($RED)ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST${NORMAL}$($NC)"
            sed -i "9 a ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST\n" "$dst/$logfile" >/dev/null 2>&1
        fi

        if [[ ! $runMode == "copy" ]] && [[ ! $runMode == "rsync" ]]; then
            #echo "${BOLD}JOB $currentJobNumber DONE: VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
            sed -i "11 a VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / "$totalByteSpace" )\n" "$dst/$logfile" >/dev/null 2>&1
        else
            #echo "${BOLD}JOB $currentJobNumber DONE: COPIED AND VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
            sed -i "11 a COPIED AND VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / "$totalByteSpace" )\n" "$dst/$logfile" >/dev/null 2>&1
        fi

        sed -i '/THE COPY PROCESS WAS NOT COMPLETED CORRECTLY/d' "$dst/$logfile" >/dev/null 2>&1 # Delete the Notice as the run was completed

        #mkdir -p "$scriptPath"/filmrisscopy_logs/
        #cp "$logfilePath" "$scriptPath"/filmrisscopy_logs/ # Backup logs to a folder in the scriptpath
    done

    currentTime=$(date +%s)
    elapsedTime=$(($currentTime - $copyStartTime))

    timeTemp=$elapsedTime
    elapsedTimeFormatted=$(formatTime)

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
checksumSource() {
    checksumStartTime=$(date +%s)
    cd "$sourceFolder"
    logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1) # Used for the Progress

    # checksumStatus &

    (find -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) -exec $checksumUtility '{}' \; | tee "$checksumFile" >>"$logfilePath" 2>&1)

    cat "$checksumFile" >>"$logfilePath" # Move the output of copy/hash/validate from the temp LogFile to the real one

    #sleep 2
    #kill $!

}

checksumComparison() {
    checksumStartTime=$(date +%s)

    logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1) # Updated for the new Progress
    #checksumComparisonStatus &

    parallel -j0 -N1 --linebuffer --tagstring {} cd {} ';' cd "$(basename "$sourceFolder")" ';' "$checksumUtility" -c "$checksumFile" ::: ${allDestinationFoldersFullPath[*]} >>"$logfilePath" 2>&1 # Go into the copied source folders and verify checksum

    #sleep 2
    #kill $!

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

## Run Status
runStatus() {

    printf '\e[?7l' # Disabling line wrapping
    printf '\e[?25l' # Hide Cursor

    for ((i = 0; i < ${#allSourceFolders[@]}; i = i + 1)); do
        srcfileCount+=("$(find "${allSourceFolders[$i]}" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)")
        srcfileSize+=("$(du -msh "${allSourceFolders[$i]}" | cut -f1)")
    done

    while [[ true ]]; do

        header="\n${BOLD}%-5s %6s %6s %6s %7s %8s    %-35s %-35s ${NORMAL}"
        table="\n${BOLD}%-5s${NORMAL} %6s %6s %6s %7s %8s    %-35s %-5s"

        printf "$header" \
            "" "COPY" "CSUM" "VALD" "FILES" "SIZE" "SOURCE" "DESTINATION"

        JOB=0

        for ((statusX = 0; statusX < ${#allSourceFolders[@]}; statusX = statusX + 1)); do

            tempLogfilePath=""$tempFolder"/"$projectDate"_"$projectTime"_"$projectName"_"${allReelNames[$statusX]}"_filmrisscopy_log.txt"
            tempChecksumFile=""$tempFolder"/"$checksumUtility"_"$projectDate"_"$projectTime"_"$projectName"_"${allReelNames[$statusX]}"" # Store the checksum file in a temp folder (verifyable with the job number) so it can be refered to when having multiple Destinations
            src=${allSourceFolders[$statusX]}

            for ((statusY = 0; statusY < ${#allDestinationFolders[@]}; statusY = statusY + 1)); do
                dst=${allDestinationFoldersFullPath[$JOB]}

                if [[ -f "$tempLogfilePath" ]]; then
                    #copyProgress=$(sed -n '/## COPY/,/## CHECKSUM CALCULATION/p' "$tempLogfilePath" | grep -G "$dst*" | cut -f2- | wc -l | cut --delimiter=" " -f1)
                    copyProgress=$(find "$dst" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)

                    validProgress=$(sed -n '/## COMPARING CHECKSUM TO COPY/,//p' "$tempLogfilePath" | grep -G "$dst*" | cut -f2- | wc -l | cut --delimiter=" " -f1)
                else
                    copyProgress="0"
                    validProgress="0"
                fi

                if [[ -f "$tempChecksumFile" ]]; then
                    checksumProgress=$(wc -l "$tempChecksumFile" | cut --delimiter=" " -f1)
                else
                    checksumProgress="0"
                fi

                printf "$table" \
                    "JOB $(($JOB + 1))" "$copyProgress" "$checksumProgress" "$validProgress" "${srcfileCount[$statusX]}" "${srcfileSize[$statusX]}" "$src" "$dst"
                ((JOB++))

            done
        done
        printf '\e[$((${#allDestinationFoldersFullPath[@]} + 2))A' # Reset lines

        sleep 3

    done
    printf "\n\n\n\n"
}

## Log
log() {

    logfile=$projectDate"_"$projectTime"_""$projectName""_filmrisscopy_log.txt"
    logfilePath="$dst/$logfile"
    echo "$VERSION" >>"$logfilePath"
    echo PROJECT NAME: $projectName >>"$logfilePath"
    echo DATE/TIME: $projectDate"_"$projectTime >>"$logfilePath"
    echo SOURCE: $sourceFolder >>"$logfilePath"
    echo DESTINATION: $dst >>"$logfilePath"
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
    echo "## FOLDER STRUCTURE" >>"$logfilePath"
    find . ! -path . -type d >>"$logfilePath" # Print Folder Structure
    echo >>"$logfilePath"

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
        echo "${BOLD}"$VERSION"${NORMAL}"
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

## Check if there is enought Space Left in all the Destinations
checkIfThereIsEnoughSpaceLeft() {
    totalCopySize=0
    for src in "${allSourceFolders[@]}"; do
        totalCopySize=$(($totalCopySize + $(du --block-size=1 --summarize "$src" | cut -f1))) # Calculate total data size which will be copied
    done

    for dst in "${allDestinationFolders[@]}"; do
        destinationFreeSpace=$(df --block-size=1 --output=avail "$dst" | cut -d$'\n' -f2) # Calculate free space and format the output
        if [[ $(($destinationFreeSpace - $totalCopySize)) -lt 20 ]]; then
            echo "$($RED)ERROR: NOT ENOUGH DISK SPACE LEFT IN "$dst" ($totalCopySize Byte needed)$($NC)"
            baseLoop # Return to the Base Loop to change settings
        fi
    done
}

## Check if Folder already Exists
checkIfFolderExists() {

    if [[ ! -d "$dst" ]]; then # Check if the folder already exists, and creates the structure if needed
        mkdir -p "$dst"
    else
        echo "$($RED)ERROR: DIRECTORY ALREAD EXISTS IN THE DESTINATION FOLDER ("$dst")$($NC)"
        echo
        fileDifference=$(($(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l) - $(find "$dst" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc -l)))

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
baseLoop() {
  printf '\e[?25l' # Hide Cursor
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

                if [ $jobNumber -eq 1 ]; then
                    echo "${BOLD}THERE IS $jobNumber COPY JOB IN QUEUE${NORMAL}"
                else
                    echo "${BOLD}THERE ARE $jobNumber COPY JOBS IN QUEUE${NORMAL}"
                fi

                if [ $verificationMode == "md5" ]; then # Used in commands later (eg. to refer to the correct **sum.txt )
                    checksumUtility="md5sum"
                elif [ $verificationMode == "xxhash" ]; then
                    checksumUtility="xxhsum"
                elif [ $verificationMode == "sha" ]; then
                    checksumUtility="shasum"
                fi

                startTimeAllJobs=$(date +%s)

                checkIfThereIsEnoughSpaceLeft # Check if there is enough Space left in all Destinations

                for ((i = 0; i < ${#allSourceFolders[@]}; i = i + 1)); do
                    runMode=copy # Can be Copy, Checksum or RSync

                    sourceFolder="${allSourceFolders[$i]}"
                    reelName="${allReelNames[$i]}"

                    for ((j = 0; j < ${#allDestinationFolders[@]}; j = j + 1)); do
                        dst="${allDestinationFolders[$j]}""$projectName""/"$projectDate"_""$projectName""_"$reelName"" # Generate Full Path
                        allDestinationFoldersFullPath+=("$dst")
                        checkIfFolderExists
                    done
                    run &
                    ALL_PID+=("$!")

                done
                runStatus &

                for pid in ${ALL_PID[@]} ; do # Wait for all Copy Processes to finish before the last one (runStatus) is killed
                    wait $pid
                done

                sleep 3 # wait for runProgress to finish
                kill $!

                printf '\e[?25h' # Show Cursor Again
                printf '\e[?7h' # Enable Line wrapping again

                echo
                echo
                echo

                endTimeAllJobs=$(date +%s)

                elapsedTime=$(($endTimeAllJobs - $startTimeAllJobs))

                timeTemp=$elapsedTime
                elapsedTimeFormatted=$(formatTime)

                echo
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
}

## MAIN - Actually starts the program

startupSetup
baseLoop

## Add Copied Status
## Option for different Algorithms (XXHASH, SHA-1) + Option for no verification
## MHL Implementation
## Implement Telegram Bot
## Add Option for verifying Checksum using a FilmrissCopyLogFileTM
## Default Preset
## Log Times of individual Tasks
## Change Loop Input Method
## Calculate Source Checksum Once for all Destinations
## Parallel is a Dependency -> CHECK
## On Inputs/Destinations add a trailing / if needed
