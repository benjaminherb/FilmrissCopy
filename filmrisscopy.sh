## Start (Header Info)
RED='tput setaf 1'
NC='tput sgr0' # no color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"

scriptPath=${BASH_SOURCE[0]} # Find Scriptpath for the Log File Save Location

echo  "Last Updated:	$( date -r "$scriptPath" )"

cd $( dirname "$scriptPath")
scriptPath=$(pwd)
echo "Location:	"$scriptPath"/"
echo "Logfiles:	"$scriptPath"/filmrisscopy_logs/"

projectDate=$(date +"%Y%m%d")
projectTime=$(date +"%H%M")

## Define Project Settings
setProjectName(){
	echo
	echo Choose Project Name:
	read -e projectName
}

## Choose Ssource Directory
setSource(){
	echo
	echo Choose Source Folder:
	read -e sourceFolder1

	if [[ ! -d "$sourceFolder1" ]]; then
		echo "$($RED)ERROR: $sourceFolder1 is not a valid Source$($NC)"
		setSource
	else
		setReelName1
	fi
	setSource2
}

## Choose Input Reel Name
setReelName1(){
	echo
	echo Source Reel Name:
	read -e reelName1
}

## Add / Edit Source 2
setSource2(){
	echo
	echo "Choose Additional Source Folder (Enter to Skip)"
	read -e sourceFolder2

	if [ ! -d "$sourceFolder2" ] && [ ! "$sourceFolder2" == "" ]; then
		echo "$($RED) ERROR: $sourceFolder2 is not a valid Sorce $($NC)"
		setSource2
	fi

	if [[ "$sourceFolder2" == "$sourceFolder1" ]]; then
		echo "$($RED) ERROR: Source 2 can not be the same as Source 1 $($NC)"
		setSource2
	fi

	if [[ ! "$sourceFolder2" == "" ]]; then setReelName2 ; fi # Only ask for ReelName2 if Sorce 2 isnt empty
}

## Choose Source 2 Reel Name
setReelName2(){
	echo
	echo Source 2 Reel Name:
	read -e reelName2

	if [[ $reelName2 == $reelName1 ]]; then # Error if both Sources have the same Reel Name
		echo
		echo "$($RED)ERROR: Reel Name 2 can not be the same as Reel Name 1 $($NC)"
		setReelName2
	fi
}

## Choose Destination Directory
setDestination(){
	echo
	echo Choose Destination Folder:
	read -e destinationFolder1

	if [[ ! -d "$destinationFolder1" ]]; then
		echo "$($RED)ERROR: $destinationFolder1 is not a valid Destination $($NC)"
		setDestination
	fi

	setDestination2
}

## Add / Edit Destination 2
setDestination2(){
	echo
	echo "Choose Aditional Destination Folder (Enter to Skip)"
	read -e destinationFolder2

	if [ ! -d "$destinationFolder2" ] && [ ! "$destinationFolder2" == "" ] ; then
		echo "$($RED)ERROR: $destinationFolder2 is not a valid Destination $($NC)"
		setDestination2
	fi

	if [[ "$destinationFolder2" == "$destinationFolder1" ]]; then
		echo "$($RED)ERROR: Destination 2 can not be the same as Destination 1 $($NC)"
		setDestination2
	fi
}

## Run the main Copy Process
run(){
	runMode=copy # Can be Copy, Checksum or RSync
	echo

	totalByteSpace=$(du -s "$sourceFolder" | cut -f1) # Check if there is enough Space left
	destinationFreeSpace=$(df --block-size=1 --output=avail "$destinationFolder" | cut -d$'\n' -f2)

	if [[ $(( $destinationFreeSpace-$totalByteSpace)) < 20 ]]; then
		echo "$($RED)ERROR: Not enough Disk Space left in $destinationFolder$($NC)"
		return
	fi

	destinationFolderFullPath="$destinationFolder""$projectName""/"$projectDate"_""$projectName""_"$reelName # Generate Full Path

	if [[ ! -d "$destinationFolderFullPath" ]]; then # Check if the folder already exists, and creates the structure if needed
		mkdir -p "$destinationFolderFullPath"
	else
		echo "$($RED)ERROR: Directory Already Exists in the Destination Folder$($NC)"
		fileDifference=$(( $( find "$sourceFolder" -type f | wc -l ) - $( find "$destinationFolderFullPath" -type f  \( -not -name "md5sum.txt" -not -name "*filmrisscopy_log.txt" \) | wc -l ) ))

		if [[ $fileDifference == 0 ]]; then
			echo
			echo Source and Destination have the same Size

			echo "Run Checksum Calculations? (y/n)"
			read -e rerunChecksum

			while [ ! $rerunChecksum == "y" ] && [ ! $rerunChecksum == "n" ] ; do
				echo "Run Checksum Calculations? (y/n)"
				read -e rerunChecksum
			done

			if [[ $rerunChecksum == "y" ]]; then runMode=checksum ;	fi
			if [[ $rerunChecksum == "n" ]]; then return ;	fi

		else

			echo "There are $fileDifference Files missing compared to the Source Directory"
			echo "Run RSYNC to copy the missing Files? (Needs Sudo Privileges) (y/n)"
			read -e runRsync

			while [ ! $runRsync == "y" ] && [ ! $runRsync == "n" ] ; do
				echo "Run RSYNC to copy the missing Files? (y/n)"
				read -e runRsync
			done
			echo

			if [[ $runRsync == "y" ]]; then runMode=rsync ;	fi
			if [[ $runRsync == "n" ]]; then return ;	fi
		fi
	fi

	log # Create Log File and Write Header

	totalFileCount=$(find "$sourceFolder" -type f | wc -l)
	totalFileSize=$(du -msh "$sourceFolder" | cut -f1)
	copyStartTime=$(date +%s)

	if [[ $runMode == "copy" ]]; then
		echo "${BOLD}RUNNING COPY...${NORMAL}"
		copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
		cp --recursive --verbose "$sourceFolder" "$destinationFolderFullPath" >> "$logfilePath" 2>&1 ; sleep 4 ; kill $! # Copy then wait for the Status to catch up
		echo
	fi

	if [[ $runMode == "rsync" ]]; then
		sudo echo "${BOLD}RUNNING RSYNC...${NORMAL}"
		copyStatus & # copyStatus runs in a loop in the background - when copy is finished the process is killed
		sudo rsync --verbose --checksum --archive  "$sourceFolder" "$destinationFolderFullPath" >> "$logfilePath" 2>&1 ; sleep 4 ; kill $! # Needs Root, checks based on checksum Calculations
		echo
	fi

	checksum

	currentTime=$(date +%s)
	elapsedTime=$(( $currentTime-$copyStartTime ))
	formatElapsedTime

	echo	# End of the Job
	if [ ! $copyMode == "copy" ] && [ ! $copyMode == "rsync" ] ; then
		echo "${BOLD}JOB $currentJobNumber DONE: VERIFIED $totalFileCount Files	(Total Time: $hela:$mela:$sela)${NORMAL}"
	else
		echo "${BOLD}JOB $currentJobNumber DONE: COPIED AND VERIFIED $totalFileCount Files	(Total Time: $hela:$mela:$sela)${NORMAL}"
	fi

	mkdir -p "$scriptPath"/filmrisscopy_logs/
	cp "$logfilePath" "$scriptPath"/filmrisscopy_logs/  # Backup logs to a folder in the scriptpath

}

## Copy progress
copyStatus(){
	while [ true ]; do
		copiedFileCount=$(find "$destinationFolderFullPath" -type f \( -not -name "*filmrisscopy_log.txt" -not -name "md5sum.txt" \) | wc -l)
		currentTime=$(date +%s)

		elapsedTime=$(( $currentTime-$copyStartTime ))
		formatElapsedTime

		echo -ne "($copiedFileCount / $totalFileCount Files - Total Size: $totalFileSize )	(Elapsed Time: $hela:$mela:$sela)"\\r
		sleep 3 # Change if it slows down the process to much / if more accuracy is needed
	done
}

## Checksum
checksum(){
	checksumStartTime=$(date +%s)
	echo "${BOLD}RUNNING CHECKSUM CALCULATIONS ON DESTINATION...${NORMAL}"
	echo >> "$logfilePath"
	echo "CHECKSUM CALCULATIONS ON DESTINATION:" >> "$logfilePath"
	cd "$destinationFolderFullPath"
	checksumStatus &
	( find -type f \( -not -name "md5sum.txt" -not -name "*filmrisscopy_log.txt" \) -exec md5sum '{}' \; | tee md5sum.txt ) >> "$logfilePath" 2>&1 ; sleep 4 ; 	kill $!
	echo

	checksumStartTime=$(date +%s)
	echo "${BOLD}COMPARING TO SOURCE...${NORMAL}"
	echo >> "$logfilePath"
	echo "SOURCE COMPARISON:" >> "$logfilePath"
	logFileLineCount=$(wc -l "$logfilePath" | cut --delimiter=" " -f1)
	cd "$sourceFolder"
	cd ..
	checksumComparisonStatus &
	md5sum -c "$destinationFolderFullPath""/md5sum.txt" >> "$logfilePath" 2>&1 ; sleep 4 ; kill $!
	echo

	checksumPassedFiles=$(grep -c ": OK" "$logfilePath") # Checks wether the output to the logfile were all "OK" or not
	if [[ $checksumPassedFiles == $totalFileCount ]]; then
		echo "${BOLD}NO CHECKSUM ERRORS!${NORMAL}"
		echo >> "$logfilePath"
		echo NO CHECKSUM ERRORS! >> "$logfilePath"
	else
		echo "${BOLD}$($RED)ERROR: $(( $totalFileCount-$checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST${NORMAL}$($NC)"
		echo >> "$logfilePath"
		echo "ERROR: $(( $totalFileCount-$checksumPassedFiles)) / $totalFileCount DID NOT PASS THE CHECKSUM TEST" >> "$logfilePath"
	fi
}

## Checksum Progress
checksumStatus(){
	while [[ true ]]; do
		sleep 3

		checksumFileCount=$(wc -l "$destinationFolderFullPath"/md5sum.txt | cut --delimiter=" " -f1)
		currentTime=$(date +%s)

		elapsedTime=$(( $currentTime-$checksumStartTime ))
		formatElapsedTime

		echo -ne "($checksumFileCount / $totalFileCount Files - Total Size: $totalFileSize )	(Elapsed Time: $hela:$mela:$sela)"\\r
	done
}

## Checksum Comparison progress
checksumComparisonStatus(){
	while [[ true ]]; do
		sleep 3
		checksumFileCount=$(( $(wc -l "$logfilePath" | cut --delimiter=" " -f1)-$logFileLineCount ))
		currentTime=$(date +%s)

		elapsedTime=$(( $currentTime-$checksumStartTime ))
		formatElapsedTime

		echo -ne "($checksumFileCount / $totalFileCount Files - Total Size: $totalFileSize )	(Elapsed Time: $hela:$mela:$sela)"\\r
	done
}

## Log
log(){
	logfile=$projectDate"_"$projectTime"_"$currentJobNumber"_"$jobNumber"_""$projectName""_filmrisscopy_log.txt"
	logfilePath="$destinationFolderFullPath"/$logfile
	echo FILMRISSCOPY VERSION 0.1 >> "$logfilePath"
	echo PROJECT NAME:	$projectName >> "$logfilePath"
	echo DATE/TIME:	$projectDate"_"$projectTime >> "$logfilePath"
	echo SOURCE:		$sourceFolder >> "$logfilePath"
	echo DESTINATION:	$destinationFolderFullPath >> "$logfilePath"
	echo JOB:		$currentJobNumber / $jobNumber >> "$logfilePath"
	echo RUNMODE:	$runMode >> "$logfilePath"
	echo >> "$logfilePath"
}

# Changes seconds to h:m:s, change $elapsedTime to use, and $hela:$mela:$sela to show
formatElapsedTime(){
	((hela=$elapsedTime/3600))
	((mela=$elapsedTime%3600/60))
	((sela=$elapsedTime%60))
}

## Print Current Status
printStatus(){
	echo
	echo "${BOLD}FILMRISSCOPY VERSION 0.1${NORMAL}"
	echo "${BOLD}PROJECT NAME:${NORMAL}	$projectName"
	echo "${BOLD}DATE/TIME:${NORMAL}	$projectDate"_"$projectTime"

	if [[ ! "$sourceFolder2" == "" ]]; then # Only Show the second Source if it is not empty
		echo "${BOLD}SOURCE $reelName1:${NORMAL}	$sourceFolder1"
		echo "${BOLD}SOURCE $reelName2:${NORMAL}	$sourceFolder2"
	else
		echo "${BOLD}SOURCE $reelName1:${NORMAL}	$sourceFolder1"
	fi

	if [[ ! "$destinationFolder2" == "" ]]; then # Only Show the second Destination if it is not empty
		echo "${BOLD}DESTINATION 1:${NORMAL}	$destinationFolder1"
		echo "${BOLD}DESTINATION 2:${NORMAL}	$destinationFolder2"
	else
		echo "${BOLD}DESTINATION:${NORMAL}	$destinationFolder1"
	fi
}

## Write preset_last.config
writePreset(){
echo "## FILMRISSCOPY PRESET"
echo "projectName=$projectName"
echo "sourceFolder1=$sourceFolder1"
echo "reelName1=$reelName1"
echo "destinationFolder1=$destinationFolder1"
}

## Edit Project Loop
editProject(){
	loop=true
 	while [[ $loop == "true" ]]; do

		printStatus

 		echo
 		echo "(0) EDIT PROJECT NAME  (1) EDIT SOURCE  (2) EDIT DESTINATION  (3) EDIT DATE  (4) LOAD PRESET  (5) LOAD PRESET FROM FILE  (6) EXIT SCREEN"
		read -e command

		if [ $command == "0" ]; then setProjectName; 	fi
		if [ $command == "1" ]; then setSource; 		fi
		if [ $command == "2" ]; then setDestination; 	fi
		if [ $command == "3" ]; then
			echo "Input Date (Format: $projectDate)"
			read -e projectDate
		fi
		if [ $command == "4" ]; then source "$scriptPath/filmrisscopy_preset_last.config" ;	 	fi
		if [ $command == "5" ]; then
			echo "Choose Preset Path"
			read -e presetPath
			source $presetPath
		fi
		if [ $command == "6" ]; then loop=false;		fi
	done
}

## Setup at Start
startupSetup(){
echo ; echo "(0) SKIP  (1) RUN SETUP  (2) LOAD LAST PRESET  (3) LOAD PRESET FROM FILE"
read -e usePreset
while [ ! $usePreset == "0" ] && [ ! $usePreset == "1" ] && [ ! $usePreset == "2" ] && [ ! $usePreset == "3" ] ; do
	echo ; echo "(0) SKIP  (1) LOAD LAST PRESET  (2) LOAD PRESET FROM FILE"
	read -e usePreset
done

if [[ $usePreset == "1" ]]; then
	setProjectName
	setSource
	setDestination
fi

if [[ $usePreset == "2" ]]; then
	source "$scriptPath/filmrisscopy_preset_last.config"
fi

if [[ $usePreset == "3" ]]; then
	echo "Choose Preset Path"
	read -e presetPath
	source $presetPath
fi
}


## Base Loop
startupSetup

while [ true ]; do

	printStatus

	echo
	echo "(0) EXIT  (1) RUN  (2) EDIT PROJECT"
	read -e command

	if [ $command == "1" ]  ; then
		if [ ! "$sourceFolder1" == "" ] && [ ! "$destinationFolder1" == "" ] [ ! "$projectName" == "" ]; then # Check if atleast Destination 1 and Source 1 are set

			if [[ ! "$sourceFolder2" == "" ]]; then sourceNumber=2 ; else sourceNumber=1 ; fi
			if [[ ! "$destinationFolder2" == "" ]]; then destinationNumber=2 ; else destinationNumber=1 ; fi

			jobNumber=$(($sourceNumber*$destinationNumber))

			echo ; echo ; echo "${BOLD}THERE ARE $(($sourceNumber*$destinationNumber)) COPY JOBS IN QUEUE${NORMAL}"
			startTimeAllJobs=$(date +%s)

			if [ $sourceNumber == 1 ] ; then # One Source
				sourceFolder="$sourceFolder1" ; reelName=$reelName1

				if [ $destinationNumber == 1 ] ; then # One Source One Destination
					currentJobNumber=1
					destinationFolder="$destinationFolder1"
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/1		$sourceFolder -> $destinationFolder${NORMAL}"
					run
				fi
				if [ $destinationNumber == 2 ] ; then # One Source Two Destinations
					currentJobNumber=1
					destinationFolder="$destinationFolder1"
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/2		$sourceFolder -> $destinationFolder${NORMAL}"
					run

					currentJobNumber=2
					destinationFolder="$destinationFolder2"
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/2		$sourceFolder -> $destinationFolder${NORMAL}"
					run
				fi
			fi

			if [ $sourceNumber == 2 ] ; then  # Two Sources
				if [ $destinationNumber == 1 ] ; then # Two Sources One Destination
					destinationFolder="$destinationFolder1"

					currentJobNumber=1
					sourceFolder="$sourceFolder1" ; reelName=$reelName1
					echo ; echo ;	echo "${BOLD}JOB $currentJobNumber/2		$sourceFolder -> $destinationFolder${NORMAL}"
					run

					currentJobNumber=2
					sourceFolder="$sourceFolder2" ; reelName=$reelName2
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/2		$sourceFolder -> $destinationFolder${NORMAL}"
					run
				fi

				if [ $destinationNumber == 2 ] ; then # Two Sources Two Destinations
					destinationFolder="$destinationFolder1"

					currentJobNumber=1
					sourceFolder="$sourceFolder1" ; reelName=$reelName1
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/4		$sourceFolder -> $destinationFolder${NORMAL}"
					run

					currentJobNumber=2
					sourceFolder="$sourceFolder2" ; reelName=$reelName2
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/4		$sourceFolder -> $destinationFolder${NORMAL}"
					run

					destinationFolder="$destinationFolder2"

					currentJobNumber=3
					sourceFolder="$sourceFolder1" ; reelName=$reelName1
					echo ; echo ; echo "${BOLD}JOB $currentJobNumber/4		$sourceFolder -> $destinationFolder${NORMAL}"
					run

					currentJobNumber=4
					sourceFolder="$sourceFolder2" ; reelName=$reelName2
					echo ; echo ;	echo "${BOLD}JOB $currentJobNumber/4		$sourceFolder -> $destinationFolder${NORMAL}"
					run
				fi
			fi

			endTimeAllJobs=$(date +%s)

			elapsedTime=$(( $endTimeAllJobs-$startTimeAllJobs ))
			formatElapsedTime

			echo
			echo -e "${BOLD}$(($sourceNumber*$destinationNumber)) JOBS FINISHED IN $hela:$mela:$sela${NORMAL}"
			echo


			echo "Do you want to quit the Program? (y/n)" # Quit Program after Finished Jobs or return to the Main Loop
			read -e quitFRC
			while [ ! $quitFRC == "y" ] && [ ! $quitFRC == "n" ] ; do
				echo "Do you want to quit the Program? (y/n)"
				read -e quitFRC
			done
			if [[ $quitFRC == "y" ]]; then command=2	;	fi

		else
			echo
			echo "$($RED)ERROR: SOURCE OR DESTINATION ARE NOT SET YET$($NC)"
		fi
	fi
	if [ $command == "2" ]; then editProject; 	fi
	if [ $command == "0" ]; then
		writePreset >> "$scriptPath/filmrisscopy_preset_last.config" # Write "last" Preset
		exit
 	fi

done

## Cleanup
## Speedtest for Copy / Hash
## Add Copied Status
## Make Checksum Calculations in the Sourcefolder first
## Count Clips / Files and log them / Show Folder Structure = Clips / falls dng
## .ds Ausschließen
## Datum ändern
