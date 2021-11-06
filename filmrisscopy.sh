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

<<<<<<< HEAD
echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"
=======
version="0.2"

echo "${BOLD}FILMRISSCOPY VERSION $version${NORMAL}"
>>>>>>> testing
echo
scriptPath=${BASH_SOURCE[0]} # Find Scriptpath for the Log File Save Location
echo "LAST UPDATED:	$(date -r "$scriptPath")"

cd "$(dirname "$scriptPath")"
scriptPath=$(pwd)
echo "LOCATION:	$scriptPath/"
echo "LOGFILES:	$scriptPath/filmrisscopy_logs/"
echo "PRESETS: 	$scriptPath/filmrisscopy_presets/"

tempFolder="$scriptPath/filmrisscopy_temp"
mkdir -p "$tempFolder" #Temp folder for storing Hashfiles during a process (to be used again)

dateNow=$(date +"%Y%m%d")
timeNow=$(date +"%H%M")
verificationMode="xxhash"

## Define Project Settings
function setProjectInfo() {
    echo
    echo "Choose Project Name"
    read -er projectName

    echo
    echo "Choose Shoot Date [Default: $dateNow]"
    read -er projectDate

    if [ -z "$projectDate" ]; then
        projectDate=$dateNow
        echo "$dateNow"
    fi

    echo
    echo "Name Shoot Day [eg. DT01]"
    read -er projectShootDay
}

<<<<<<< HEAD
## Choose Ssource Directoryot -name
setSource() {
=======
## Choose Source Directory
function setSource() {
>>>>>>> testing
    echo
    echo Choose Source Folder:
    read -er sourceFolderTemp
    [[ "${sourceFolderTemp}" == */ ]] && sourceFolderTemp="${sourceFolderTemp::-1}" # Remove trailing /

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
        read -er sourceFolderTemp
        [[ "${sourceFolderTemp}" == */ ]] && sourceFolderTemp="${sourceFolderTemp::-1}" # Remove trailing /

        duplicateSource="false"
        for src in "${allSourceFolders[@]}"; do # Loops over source array to check if the new source is a douplicate
            if [ "${src}" == "$sourceFolderTemp" ]; then
                duplicateSource="true"
                break
            fi
        done

        if [[ $sourceFolderTemp == "" ]]; then
            loop=false
            echo "-"
        elif [ ! -d "$sourceFolderTemp" ]; then
            echo "$($RED)ERROR: $sourceFolderTemp IS NOT A VALID SOURCE$($NC)"
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
function setReelName() {
    echo
    echo Source Reel Name:
    read -er reelNameTemp
}

## @TODO
function setReelSpecifier() {
    true
    # TODO
}

## Choose Destination Directory
function setDestination() {
    echo
    echo Choose Destination Folder:
    read -er destinationFolderTemp
    [[ "${destinationFolderTemp}" == */ ]] && destinationFolderTemp="${destinationFolderTemp::-1}" # Remove trailing /

    if [[ ! -d "$destinationFolderTemp" ]]; then
        echo "$($RED)ERROR: $destinationFolderTemp IS NOT A VALID DESTINATION $($NC)"
        setDestination
    fi

    allDestinationFolders=("$destinationFolderTemp")

    loop="true"
    while [[ $loop == "true" ]]; do
        echo
        echo "Choose Additional Destination Folder (Enter to Skip)"
        read -er destinationFolderTemp
        [[ "${destinationFolderTemp}" == */ ]] && destinationFolderTemp="${destinationFolderTemp::-1}" # Remove trailing /

        duplicateDestination="false"
        for dst in "${allDestinationFolders[@]}"; do # Loops over dst array to check if the new source is a duplicate
            if [ "${dst}" == "$destinationFolderTemp" ]; then
                duplicateDestination="true"
                break
            fi
        done

        if [[ $destinationFolderTemp == "" ]]; then
            loop=false
            echo "-"
        elif [ ! -d "$destinationFolderTemp" ]; then
            echo "$($RED)ERROR: $destinationFolderTemp IS NOT A VALID DESTINATION$($NC)"
        elif [[ $duplicateDestination == "true" ]]; then
            echo "$($RED)ERROR: YOU CAN NOT SET THE SAME DESTINATION TWICE IN A PROJECT$($NC)"
        else
            allDestinationFolders+=("$destinationFolderTemp")
        fi
    done

}

## Choose Verification Method
function setVerificationMethod() {
    echo
    echo "Choose your preferred Verification Method (xxHash is recommended)"
    echo
    echo "(0) EXIT  (1) XXHASH  (2) MD5  (3) SHA-1  (4) SIZE COMPARISON ONLY"
    read -er verifCommand

    if [[ ! $verifCommand == "0" ]] && [[ $verifCommand == "1" ]] && [[ $verifCommand == "2" ]] && [[ $verifCommand == "3" ]] && [[ $verifCommand == "4" ]]; then
        setVerificationMethod
    fi

    if [ "$verifCommand" == "1" ]; then
        verificationMode="xxhash"
    elif [ "$verifCommand" == "2" ]; then
        verificationMode="md5"
    elif [ "$verifCommand" == "3" ]; then
        verificationMode="sha"
    elif [ "$verifCommand" == "4" ]; then
        verificationMode="size"
    fi
}

## Loads preset from text file
function loadPreset() {
    echo
    echo "(0) BACK  (1) LOAD LAST PRESET  (2) LOAD PRESET FROM FILE"
    read -er presetCommand

    if [ ! "$presetCommand" == "0" ] && [ ! "$presetCommand" == "1" ] && [ ! "$presetCommand" == "2" ]; then loadPreset; fi

    if [ "$presetCommand" == "1" ]; then
        source "${scriptPath}/filmrisscopy_preset_last.config"
    elif [ "$presetCommand" == "2" ]; then
        echo
        echo "Choose Preset Path"
        read -er presetPath

        while [[ ! -f "$presetPath" ]] || [[ ! "$presetPath" == *".config" ]]; do
            echo "$($RED)ERROR: \"$presetPath\" IS NOT A VALID PRESET FILE $($NC)"
            echo
            echo "Choose Preset Path"
            read -er presetPath
        done

        source "$presetPath"
    fi
}

<<<<<<< HEAD
## Run the main Copy Process
run() {
    runMode=copy # Can be Copy, Checksum or RSync
=======
## Find all logfiles in a given directory and verify the data
function batchVerify() {
>>>>>>> testing
    echo
    echo "Choose root directory for the batch verify:"
    read -er batchVerifyDirectory

<<<<<<< HEAD
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
=======
    while [ ! -d "$batchVerifyDirectory" ]; do
        echo "$($RED)ERROR: $batchVerifyDirectory IS NOT A VALID DIRECTORY$($NC)"
        echo
        echo "Choose root directory for the batch verify:"
        read -er batchVerifyDirectory
    done

    allLogFileDirectorysTemp=($(find "$batchVerifyDirectory" -type f -name "*filmrisscopy_log.txt" -exec dirname {} \;))
>>>>>>> testing

    for lTemp in "${allLogFileDirectorysTemp[@]}"; do # Sorts out duplicate directorys
        dup="false"
        for l in "${allLogFileDirectorys[@]}"; do
            if [ "${lTemp}" == "$l" ]; then
                dup="true"
                break
            fi
        done
        if [ $dup == "false" ]; then allLogFileDirectorys+=("$lTemp"); fi
    done

<<<<<<< HEAD
    if [[ $runMode == "copy" ]]; then
        echo "${BOLD}RUNNING COPY...${NORMAL}"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        cp --archive --recursive --verbose "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1

        sleep 2
        kill $! # Copy then wait for the Status to catch up
        echo
    fi

    if [[ $runMode == "copyParallel" ]]; then
        echo "${BOLD}RUNNING PARALLEL COPY...${NORMAL}"

        tempDest=""
        for dest in "${allDestinationFolders[@]}"; do #create String with all Destinations
            tempDest="$tempDest ""$dest"
        done

        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed

        for src in "${allSourceFolders[@]}"; do
            parallel -j0 -N1 cp --archive --recursive --verbose "$src" ::: "$tempDest" >>"$logfilePath" 2>&1
        done

        sleep 2
        kill $! # Copy then wait for the Status to catch up
        echo
    fi

    if [[ $runMode == "rsync" ]]; then # Needs Root, checks based on checksum Calculations
        sudo echo "${BOLD}RUNNING RSYNC...${NORMAL}"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        sudo rsync --verbose --checksum --archive "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1
        sleep 2
        kill $!
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
=======
    for copyDirectoryVerification in "${allLogFileDirectorys[@]}"; do
        echo
        echo "FOUND DIRECTORY: $copyDirectoryVerification"

        local logFiles=($(find "$copyDirectoryVerification"/*filmrisscopy_log.txt))

        for logFileVerification in "${logFiles[@]}"; do
            if grep -q "COMPARING CHECKSUM TO COPY" "$logFileVerification"; then
                echo "USING $logFileVerification"
                verify # verifys with the current logFileVerification
            fi
            break
        done
    done
    endScreen
}

## Verifys Copy using the checksums from a filmrisscopy_log file
function singleVerify() {

    echo
    echo "Choose a Filmrisscopy Log File"
    read -er logFileVerification

    while [[ ! -f "$logFileVerification" ]] || [[ ! "$logFileVerification" == *"filmrisscopy_log.txt" ]]; do
        echo "$($RED)ERROR: \"$logFileVerification\" IS NOT A VALID FILMRISSCOPY LOG FILE $($NC)"
        echo
        echo "Choose filmrisscopy_log.txt File"
        read -er logFileVerification
    done

    echo
    echo "Choose Copy to verify [Default: $(dirname "$logFileVerification")]"
    read -er copyDirectoryVerification

    while [ ! "$copyDirectoryVerification" == "" ] && [ ! -d "$copyDirectoryVerification" ]; do
        echo "$($RED)ERROR: $copyDirectoryVerification IS NOT A VALID DIRECTORY$($NC)"
        copyDirectoryVerification="" # Resets so you can use the default again
        echo
        echo "Choose Copy to verify [Default: $(dirname "$logFileVerification")]"
        read -er logFileVerification
    done

    if [[ "$copyDirectoryVerification" == "" ]]; then
        copyDirectoryVerification=$(dirname "$logFileVerification")
        echo "$copyDirectoryVerification"
    fi

    verify
    endScreen

}

function verify() {

    projectName=$(grep "PROJECT NAME" "$logFileVerification" | cut --delimiter=' ' --field=3)

    logfilePath="${copyDirectoryVerification}/${dateNow}_${timeNow}_${projectName}_filmrisscopy_verification_log.txt"
    echo "FILMRISSCOPY VERSION $version" >>"$logfilePath"
    echo "LOGFILE: $logFileVerification" >>"$logfilePath"
    echo "COPY DIRECTORY: $copyDirectoryVerification" >>"$logfilePath"

    verificationModeName=$(grep "VERIFICATION" "$logFileVerification" | cut --delimiter=' ' --field=2)

    if [ "$verificationModeName" == "xxHash" ]; then
        checksumUtility="xxhsum"
    elif [ "$verificationModeName" == "SHA-1" ]; then
        checksumUtility="shasum"
    elif [ "$verificationModeName" == "MD5" ]; then
        checksumUtility="md5sum"
    else
        echo "$($RED)ERROR: LOG FILE [$logfilePath] CONTAINS NO CHECKSUMS$($NC)"
        return
    fi

    echo "VERIFICATION: $verificationModeName" >>"$logfilePath"
    echo >>"$logfilePath"
    echo "CHECKSUM CALCULATIONS ON SOURCE:" >>"$logfilePath"

    getChecksums "$logFileVerification" >>"$logfilePath" # Returns $checksums Variable

    headerLength=$(grep -n "VERIFICATION: " "$logfilePath" | cut --delimiter=: --field=1)

    destinationFolderFullPath=$copyDirectoryVerification
    sourceFolder=$(grep "SOURCE: " "$logFileVerification" | cut --delimiter=' ' --field=2)

    logFileLineCount=$(wc --lines "$logfilePath" | cut --delimiter=" " --field=1) # Used for the Progress
    checksumStartTime=$(date +%s)
    totalFileCount=$(find "$copyDirectoryVerification" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name "*_filmrisscopy_verification_log.txt" -not -name ".DS_Store" \) | wc --lines)
    totalFileSize=$(du --block-size=1M --summarize --human-readable "$copyDirectoryVerification" | cut --field=1)

    checksumComparison

    backupLogFile

}

## Copies current LogFile to the filmrisscopy_logs dir
function backupLogFile() {
    if [ -f "$logfilePath" ]; then
        logfileBackupPath="$scriptPath/filmrisscopy_logs"

        mkdir -p "$logfileBackupPath"
        logfileName=$(basename "$logfilePath" | sed "s/_filmrisscopy/_1_filmrisscopy/g")

        i=2

        while [[ -f "$logfileBackupPath/$logfileName" ]]; do
            logfileName=$(echo "$logfileName" | sed "s/_[0-9]*_filmrisscopy/_${i}_filmrisscopy/g")
            ((i++))
            echo $logfileName
        done

        cp -i "$logfilePath" "$logfileBackupPath/$logfileName" # Backup logs to a folder in the scriptpath
    fi
}

## Run the main Copy Process
function run() {
    runMode=copy # Can be Copy, Checksum or RSync
    echo

    totalByteSpace=$(du --summarize "$sourceFolder" | cut --field=1) # Check if there is enough Space left
    destinationFreeSpace=$(df --block-size=1 --output=avail "$destinationFolder" | cut --delimiter=$'\n' --field=2)

    if [[ $(($destinationFreeSpace - $totalByteSpace)) -lt 20 ]]; then
        echo "$($RED)ERROR: NOT ENOUGH DISK SPACE LEFT IN $destinationFolder$($NC)"
        return
    fi

    destinationFolderFullPath="${destinationFolder}/${projectName}/${projectShootDay}_${projectDate}/${projectShootDay}_${projectDate}_${projectName}_${reelName}" # Generate Full Path
    sourceBaseName=$(basename "$sourceFolder")

    if [[ ! -d "$destinationFolderFullPath" ]]; then # Check if the folder already exists, and creates the structure if needed
        mkdir -p "$destinationFolderFullPath"
    else
        echo "$($RED)ERROR: DIRECTORY ALREAD EXISTS IN THE DESTINATION FOLDER$($NC)"
        echo
        fileDifference=$(($(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc --lines) - $(find "$destinationFolderFullPath" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc --lines)))

        if [[ $fileDifference == 0 ]]; then
            echo Source and Destination have the same Size

            echo "Run Checksum Calculations? (y/n)"
            read -er rerunChecksum

            while [ ! "$rerunChecksum" == "y" ] && [ ! "$rerunChecksum" == "n" ] && [ -z "$rerunChecksum" ]; do
                echo "Run Checksum Calculations? (y/n)"
                read -er rerunChecksum
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
            read -er runRsync

            while [ ! "$runRsync" == "y" ] && [ ! "$runRsync" == "n" ]; do
                echo "Run RSYNC to copy the missing Files? (y/n)"
                read -er runRsync
            done
            echo

            if [[ $runRsync == "y" ]]; then runMode=rsync; fi
            if [[ $runRsync == "n" ]]; then return; fi
        fi
    fi

    log # Create Log File and Write Header

    # Used to position lines in the log file
    headerLength=$(grep -n "VERIFICATION: " "$logfilePath" | cut --delimiter=: --field=1)

    totalFileCount=$(find "$sourceFolder" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc --lines)
    totalFileSize=$(du -msh "$sourceFolder" | cut --field=1)
    copyStartTime=$(date +%s)

    if [[ $runMode == "copy" ]]; then
        echo "${BOLD}RUNNING COPY...${NORMAL}"
        echo >>"$logfilePath"
        echo "COPY PROCESS:" >>"$logfilePath"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        cp --archive --recursive --verbose "$sourceFolder" "$destinationFolderFullPath" >>"$logfilePath" 2>&1

        sleep 2
        kill $! # Copy then wait for the Status to catch up
        echo
    fi

    if [[ $runMode == "rsync" ]]; then # Needs Root, checks based on checksum Calculations
        sudo echo "${BOLD}RUNNING RSYNC...${NORMAL}"
        echo >>"$logfilePath"
        echo "RSYNC PROCESS:" >>"$logfilePath"
        copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
        sudo rsync --archive --size-only --info=NAME "$sourceFolder" "${destinationFolderFullPath}/${sourceBaseName}" >>"$logfilePath" 2>&1
        sleep 2
        kill $!
        echo

    fi

    if [ $verificationMode == "md5" ]; then # Used in commands later (eg. to refer to the correct **sum.txt )
        checksumUtility="md5sum"
    elif [ $verificationMode == "xxhash" ]; then
        checksumUtility="xxhsum"
    elif [ $verificationMode == "sha" ]; then
        checksumUtility="shasum"
    fi

    if [ $verificationMode == "size" ]; then
        fileSizeComparison
    else
        checksum
    fi
>>>>>>> testing

    currentTime=$(date +%s)
    elapsedTime=$(($currentTime - $copyStartTime))

    elapsedTimeFormatted=$(formatTime $elapsedTime)

    echo # End of the Job
    if [[ ! $runMode == "copy" ]] && [[ ! $runMode == "rsync" ]]; then
        echo "${BOLD}JOB $currentJobNumber DONE: VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
        sed -i "$(($headerLength + 3)) a VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / $totalByteSpace )\n" "$logfilePath" >/dev/null 2>&1
    elif [ $verificationMode == "size" ]; then
        echo "${BOLD}JOB $currentJobNumber DONE: COPIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
        sed -i "$(($headerLength + 3)) a COPIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / $totalByteSpace )\n" "$logfilePath" >/dev/null 2>&1
    else
        echo "${BOLD}JOB $currentJobNumber DONE: COPIED AND VERIFIED $totalFileCount Files	(Total Time: $elapsedTimeFormatted)${NORMAL}"
        sed -i "$(($headerLength + 3)) a COPIED AND VERIFIED $totalFileCount FILES IN $elapsedTimeFormatted ( TOTAL SIZE: $totalFileSize / $totalByteSpace )\n" "$logfilePath" >/dev/null 2>&1
    fi

    sed -i '/THE COPY PROCESS WAS NOT COMPLETED CORRECTLY/I,+1d' "$logfilePath" >/dev/null 2>&1 # Delete the Notice as the run was completed

    backupLogFile

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
function copyStatus() {
    while true; do
        sleep 1 # Change if it slows down the process to much / if more accuracy is needed

        copiedFileCount=$(find "$destinationFolderFullPath" -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) | wc --lines)
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $copyStartTime))

        if [[ ! $copiedFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($copiedFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut --delimiter=. --field=1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        elapsedTimeFormatted=$(formatTime $elapsedTime)
        aproxTimeFormatted=$(formatTime $aproxTime)

        echo -ne "$copiedFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted"\\r
    done
}

## Verify Copy by comparing Byte Size and file count
function fileSizeComparison() {
    local sourceSize=$(du --summarize "${sourceFolder}" | cut --field=1)
    local copySize=$(du --summarize "${destinationFolderFullPath}/${sourceBaseName}" | cut --field=1)

    local sourceFileCount=$(find "$sourceFolder" -type f | wc --lines)
    local copyFileCount=$(find "${destinationFolderFullPath}/${sourceBaseName}" -type f | wc --lines)

    if [ "$copySize" == "$sourceSize" ] && [ "$sourceFileCount" == "$copyFileCount" ]; then
        echo "${BOLD}FILE SIZE ( $copySize / $sourceSize ) AND FILE COUNT ( $copyFileCount / $sourceFileCount ) MATCH! ${NORMAL}"
        sed -i "$(($headerLength + 1)) a FILE SIZE ( $copySize / $sourceSize ) AND FILE COUNT ( $copyFileCount / $sourceFileCount ) MATCH!\n" "$logfilePath" >/dev/null 2>&1
    else
        echo $(du --summarize "${destinationFolderFullPath}/${sourceBaseName}" | cut --field=1)
        echo "${BOLD}$($RED)ERROR: FILE SIZE ( $copySize / $sourceSize ) AND FILE COUNT ( $copyFileCount / $sourceFileCount ) DONT MATCH!${NORMAL}$($NC)"
        sed -i "$(($headerLength + 1)) a ERROR: FILE SIZE ( $copySize / $sourceSize ) AND FILE COUNT ( $copyFileCount / $sourceFileCount ) DONT MATCH!\n" "$logfilePath" >/dev/null 2>&1
    fi
}

## Checksum
<<<<<<< HEAD
checksum() {
=======
function checksum() {
>>>>>>> testing
    checksumStartTime=$(date +%s)
    echo "${BOLD}RUNNING CHECKSUM CALCULATIONS ON SOURCE...${NORMAL}"
    echo >>"$logfilePath"
    echo "CHECKSUM CALCULATIONS ON SOURCE:" >>"$logfilePath"
    cd "$sourceFolder"
    logFileLineCount=$(wc --lines "$logfilePath" | cut --delimiter=" " --field=1) # Used for the Progress

    checksumStatus &

    find . -type f \( -not -name "*sum.txt" -not -name "*filmrisscopy_log.txt" -not -name ".DS_Store" \) -exec $checksumUtility '{}' + 2>>/dev/null 1>>"$logfilePath"

    sleep 2
    kill $!
<<<<<<< HEAD
    echo

=======

    checksumComparison

}

## Compare Checksums to Copy
function checksumComparison() {

    echo

>>>>>>> testing
    checksumStartTime=$(date +%s)
    echo "${BOLD}COMPARING CHECKSUM TO COPY...${NORMAL}"
    echo >>"$logfilePath"
    echo "COMPARING CHECKSUM TO COPY:" >>"$logfilePath"
<<<<<<< HEAD

    logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1) # Updated for the new Progress
    cd "$destinationFolderFullPath"
    cd "$(basename "$sourceFolder")" # Go into the copied source folder to get the same relative path for the checksum verification

    checksumComparisonStatus &

    "$checksumUtility" -c "$checksumFile" >>"$logfilePath" 2>&1 # Command to verify using the checksumFile

    sleep 2
    kill $!
    echo
=======
    checksums=$(getChecksums "$logfilePath")

    logFileLineCount=$(wc --lines "$logfilePath" | cut --delimiter=" " --field=1) # Updated for the new Progress
    cd "$destinationFolderFullPath"
    cd "$(basename "$sourceFolder")" # Go into the copied source folder to get the same relative path for the checksum verification

    checksumComparisonStatus &

    # Command to verify using the checksumFile, takes the output of the checksums variable
    #(from the log file) and pipes the result to the checksum Utility
    echo "$checksums" | "$checksumUtility" -c >>"$logfilePath" 2>&1

    sleep 2
    kill $!
    echo

    checksumPassedFiles=$(grep -c ": OK" "$logfilePath") # Checks wether the output to the logfile were all "OK" or not
    if [[ $checksumPassedFiles == "$totalFileCount" ]]; then
        echo "${BOLD}NO CHECKSUM ERRORS!${NORMAL}"
        sed -i "$(($headerLength + 1)) a NO CHECKSUM ERRORS!\n" "$logfilePath" >/dev/null 2>&1
    else
        echo "${BOLD}$($RED)ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST${NORMAL}$($NC)"
        sed -i "$(($headerLength + 1)) a ERROR: $(($totalFileCount - $checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST\n" "$logfilePath" >/dev/null 2>&1
    fi
>>>>>>> testing

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
function checksumStatus() {
    while true; do
        sleep 1

        checksumFileCount=$(($(wc --lines "$logfilePath" | cut --delimiter=" " --field=1) - $logFileLineCount))
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $checksumStartTime))

        if [[ ! $checksumFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($checksumFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut --delimiter=. --field=1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        elapsedTimeFormatted=$(formatTime $elapsedTime)
        aproxTimeFormatted=$(formatTime $aproxTime)
        echo -ne "$checksumFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted\\r"
    done
}

## Checksum Comparison progress
function checksumComparisonStatus() {
    while true; do
        sleep 1

        checksumFileCount=$(($(wc --lines "$logfilePath" | cut --delimiter=" " --field=1) - $logFileLineCount))
        currentTime=$(date +%s)
        elapsedTime=$(($currentTime - $checksumStartTime))

        if [[ ! $checksumFileCount == "0" ]] && [[ ! $totalFileCount == "0" ]]; then                                                     # Make sure the calc doesnt divide through 0
            aproxTime=$(echo "(($elapsedTime/($checksumFileCount/$totalFileCount)))-$elapsedTime" | bc -l | cut --delimiter=. --field=1) # Calculate aproxTime with bc -l and cut the decimals
        fi
        if [[ $aproxTime == "" ]]; then aproxTime="0"; fi

        elapsedTimeFormatted=$(formatTime $elapsedTime)
        aproxTimeFormatted=$(formatTime $aproxTime)

        echo -ne "$checksumFileCount / $totalFileCount Files | Total Size: $totalFileSize | Elapsed Time: $elapsedTimeFormatted | Aprox. Time Left: $aproxTimeFormatted\r"
    done
}

<<<<<<< HEAD
## Run Status

runStatus() {
    header="\n${BOLD}%-5s %6s %6s %6s %7s %8s    %-35s %-35s ${NORMAL}"
    table="\n${BOLD}%-5s${NORMAL} %6s %6s %6s %7s %8s    %-35s %-5s"

    printf "$header" \
        "" "COPY" "CSUM" "VALD" "SIZE" "FILES" "SOURCE" "DESTINATION"

    printf "$table" \
        "JOB 1" "DONE" "DONE" "85%" "15G" "1304" "/home/benny/Video/TEST" "/mnt/Projekt/SSD/" \
        "JOB 2" "DONE" "DONE" "DONE" "15G" "1304" "/home/benny/Video" "/mnt/Projekt/HDD/" \
        "JOB 3" "15%" "" "" "15G" "1304" "/mnt/Projekt/TEST2" "/mnt/Projekt/SSD/" \
        "JOB 4" "DONE" "06%" "" "15G" "1304" "/mnt/Projekt/TEST2" "/mnt/Projekt/HDD/"

    echo
    echo
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
=======
## Get Checksums from Filmrisscopy Log and prints them
function getChecksums() {
    # Get start and end of the checksums from the given logfile
    local logfile="$1"
    local startLineChecksum=$(($(grep -n "CHECKSUM CALCULATIONS ON SOURCE:" "$logfile" | cut --delimiter=: --field=1) + 1))
    local endLineChecksum=$(($(grep -n "COMPARING CHECKSUM TO COPY:" "$logfile" | cut --delimiter=: --field=1) - 2))

    sed -n $startLineChecksum','$endLineChecksum'p' "$logfile"
}

## Get SNR by finding the partition of the sourcedir, comparing it to available disks and then runnign lsblk
function getSerial() {

    local availableDisks=($(lsblk | grep disk | cut --delimiter=" " --field=1))           # Get all available disks
    local sourcePartition=$(df "$sourceFolder" | tail -1 | cut --delimiter=' ' --field=1) # Get Partition
    local sourceDevice

    for d in "${availableDisks[@]}"; do
        if [[ "*$sourcePartition*" == *"$d"* ]]; then
            sourceDevice="/dev/$d"
            break
        fi
    done

    echo $sourceDevice
    local sourceSerial=$(lsblk -n -o SERIAL "$sourceDevice" | head -1)

    if [ ! "$sourceSerial" == "" ]; then
        echo "SOURCE SERIAL: $sourceSerial" >>"$logfilePath"
    fi
}

## Log
function log() {

    if [ "${#allDestinationFolders[@]}" -gt 1 ]; then # if there are more than one copys made, adds an identifier
        local current_copy_num=$((($currentJobNumber - 1) % "${#allDestinationFolders[@]}" + 1))
        logfile="${dateNow}_${timeNow}_${projectName}_${reelName}_${current_copy_num}_filmrisscopy_log.txt"
    else
        logfile="${dateNow}_${timeNow}_${projectName}_${reelName}_filmrisscopy_log.txt"
    fi

    logfilePath="$destinationFolderFullPath/$logfile"
    echo "FILMRISSCOPY VERSION $version" >>"$logfilePath"
    echo "PROJECT NAME: $projectName" >>"$logfilePath"
    echo "SHOOT DAY: $projectShootDay" >>"$logfilePath"
    echo "PROJECT DATE: $projectDate" >>"$logfilePath"
    echo "SOURCE: $sourceFolder" >>"$logfilePath"

    getSerial >/dev/null 2>&1 # Gets the serial number of the source drive if possible

    echo "DESTINATION: $destinationFolderFullPath" >>"$logfilePath"
    echo "JOB: $currentJobNumber / $jobNumber" >>"$logfilePath"
    echo "RUNMODE: $runMode" >>"$logfilePath"
    echo "DATE/TIME: ${dateNow}_${timeNow}" >>"$logfilePath"
>>>>>>> testing

    if [ $verificationMode == "md5" ]; then
        echo "VERIFICATION: MD5" >>"$logfilePath"
    elif [ $verificationMode == "xxhash" ]; then
        echo "VERIFICATION: xxHash" >>"$logfilePath"
    elif [ $verificationMode == "sha" ]; then
        echo "VERIFICATION: SHA-1" >>"$logfilePath"
    elif [ $verificationMode == "size" ]; then
        echo "VERIFICATION: Size Comparison" >>"$logfilePath"
    fi

    echo >>"$logfilePath"
    echo "THE COPY PROCESS WAS NOT COMPLETED CORRECTLY" >>"$logfilePath" # Will be Deleted after the Job is finished
    echo >>"$logfilePath"
    cd "$sourceFolder"
<<<<<<< HEAD
    echo FOLDER STRUCTURE: >>"$logfilePath"
    find . ! -path . -type d >>"$logfilePath" # Print Folder Structure
=======
    cd ..
    echo "FOLDER STRUCTURE:" >>"$logfilePath"
    find "./${sourceBaseName}/" ! -path . -type d >>"$logfilePath" # Print Folder Structure
>>>>>>> testing
}

## Changes seconds to h:m:s, change $temp to use, and save the output in a variable
function formatTime() {
    local time="$1"
    # Sets default value if time is done
    if ! [[ "$time" =~ ^[0-9]+$ ]]; then
        local time=0
    fi
    h=$(($time / 3600))
    m=$(($time % 3600 / 60))
    s=$(($time % 60))
    printf "%02d:%02d:%02d" $h $m $s
}

## Print Current Status
function printStatus() {
    echo
    if [[ $statusMode == "normal" ]]; then
<<<<<<< HEAD
        echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"
=======
        echo "${BOLD}FILMRISSCOPY VERSION $version${NORMAL}"
>>>>>>> testing
    fi

    if [[ $statusMode == "edit" ]]; then
        echo "${BOLD}EDIT PROJECT SETTINGS${NORMAL}"
    fi

    echo "${BOLD}PROJECT NAME:${NORMAL}	$projectName"
    echo "${BOLD}SHOOT DAY:${NORMAL}	$projectShootDay"
    echo "${BOLD}PROJECT DATE:${NORMAL}	$projectDate"

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
        echo "${BOLD}VERIFICATION:${NORMAL}   Size Comparison"
        ;;
    esac

}

## Write preset_last.config
function writePreset() {

    echo "## FILMRISSCOPY PRESET"
    echo "projectName=$projectName"
    echo "projectShootDay=$projectShootDay"
    echo "projectDate=$projectDate"
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
function startupSetup() {

    echo
    echo "(0) SKIP  (1) RUN SETUP  (2) LOAD LAST PRESET  (3) LOAD PRESET FROM FILE"
    read -er usePreset
    if [ ! "$usePreset" == "0" ] && [ ! "$usePreset" == "1" ] && [ ! "$usePreset" == "2" ] && [ ! "$usePreset" == "3" ]; then
        startupSetup
    fi

    if [[ $usePreset == "1" ]]; then
        setProjectInfo
        setSource
        setDestination
    elif [[ $usePreset == "2" ]]; then

        presetLast="$scriptPath/filmrisscopy_preset_last.config"

        if [ -f "$presetLast" ]; then
            source "$scriptPath/filmrisscopy_preset_last.config"
        else
            echo "$($RED)ERROR: LAST PRESET NOT FOUND$($NC)"
            startupSetup
        fi

    elif

        [[ $usePreset == "3" ]]
    then
        echo
        echo "Choose Preset Path"
        read -er presetPath
        source "$presetPath"
    fi
}

## Edit Project Loop
function editProject() {
    loop=true
    while [[ $loop == "true" ]]; do

        statusMode="edit"
        printStatus
        statusMode="normal"

        echo
        echo "(0) BACK  (1) EDIT PROJECT INFO  (2) EDIT SOURCE  (3) EDIT DESTINATION  (4) CHANGE VERIFICATION METHOD (5) LOAD PRESET"
        read -er editCommand

        if [ "$editCommand" == "1" ]; then setProjectInfo; fi
        if [ "$editCommand" == "2" ]; then setSource; fi
        if [ "$editCommand" == "3" ]; then setDestination; fi
        if [ "$editCommand" == "4" ]; then setVerificationMethod; fi
        if [ "$editCommand" == "5" ]; then loadPreset; fi
        if [ "$editCommand" == "0" ]; then loop="false"; fi
    done
}

<<<<<<< HEAD
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
=======
function runJobs() {

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

        elapsedTimeFormatted=$(formatTime $elapsedTime)

        echo
        if [ $jobNumber -eq 1 ]; then
            echo -e "${BOLD}$jobNumber JOB FINISHED IN $elapsedTimeFormatted${NORMAL}"
        else
            echo -e "${BOLD}$jobNumber JOBS FINISHED IN $elapsedTimeFormatted${NORMAL}"
        fi

        endScreen

    else

        echo
        echo "$($RED)ERROR: PROJECT NAME, SOURCE OR DESTINATION ARE NOT SET YET$($NC)"
    fi
}

function endScreen() {
    echo
    echo
    echo "Exiting FilmrissCopy"
    echo
    echo "Update last preset with the current Setup? (y/n)" # filmrisscopy_preset_last.config will be overwritten with the current parameters
    read -er overWriteLastPreset
    while [ ! "$overWriteLastPreset" == "y" ] && [ ! "$overWriteLastPreset" == "n" ]; do
        echo "Update last preset with the current Setup? (y/n)"
        read -er overWriteLastPreset
    done
    if [[ $overWriteLastPreset == "y" ]]; then
        writePreset >"$scriptPath/filmrisscopy_preset_last.config" # Write "last" Preset
        echo
        echo "Preset Updated"
    fi
    echo

    exit

}

function baseLoop() {
    while true; do

        statusMode="normal" # choose how the Status will be shown (normal or edit)
        printStatus

        echo
        echo "(0) EXIT  (1) RUN  (2) EDIT PROJECT  (3) RUN SETUP  (4) VERIFY  (5) BATCH VERIFY"
        read -er command

        if [ "$command" == "1" ]; then
            runJobs
        fi

        if [ "$command" == "2" ]; then
            editProject
        fi

        if [ "$command" == "3" ]; then
            setProjectInfo
            setSource
            setDestination
        fi

        if [ "$command" == "4" ]; then
            singleVerify
        fi

        if [ "$command" == "5" ]; then
            batchVerify
        fi

        if [ "$command" == "0" ]; then
            endScreen
        fi
    done
}

## Base Loop
startupSetup

# Trap ctrl-c and call endScreen; Dont apply before setup
trap endScreen INT

baseLoop

## PRIO 1
## @TODO Capture STDERR of checksum calculation
## @TODO Add function for better output to logfile / screen

## PRIO 2
## @TODO MHL Implementation
## @TODO Implement Telegram Bot
## @TODO Default Preset
## @TODO Log Times of individual Tasks
## @TODO Calculate Source Checksum Once for all Destinations
>>>>>>> testing
