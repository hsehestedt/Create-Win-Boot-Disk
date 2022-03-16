@echo off
setlocal enabledelayedexpansion
setlocal enableextensions
cd /d %~dp0

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This batch file will allow you to create a Windows installation disk. This can be a flash drive or a HD.  ::
:: It is designed to create a drive that will boot on either a BIOS or UEFI based system and it is perfectly ::
:: fine for any files in the installation media to be larger than 4 GB.                                      ::
::                                                                                                           ::
:: Note that Windows 11 is only available in 64-bit editions, while Windows 10 is available in both 32-bit   ::
:: and 64-bit editions. Since this batch file is perfectly capable of creating dual architecture media it is ::
:: perfectly suitable for the creation of both Windows 10 and Windows 11 boot media.                         ::
::                                                                                                           ::
:: Originally created December 2020 by HSehestedt and Ztruker                                                ::
:: Last updated March 15, 2022                                                                               ::
::                                                                                                           ::
:: Version 1.22.04                                                                                           ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Explanation of User Customizable Settings ::                                                                   ::
:::::::::::::::::::::::::::::::::::::::::::::::                                                                   ::
:: Set the variables below to customize the behavior of the batch file.                                           ::
::                                                                                                                ::
:: Important: Values are case sensitive.                                                                          ::
::                                                                                                                ::
:: HideDetails - Set to "Y" to hide the details of every file being copied. Set to "N" or anything other than     ::
::    "Y" to show the detailed copy status. May be helpful for troubleshooting.                                   ::
::                                                                                                                ::
:: Partition1Size - This specifies the size in MB to create the first FAT32 partition. Suggestion: 1000 MB        ::
::    (roughly 1GB) should be a good value for most situations. Use a number only (no MB after the number). If    ::
::    use a customized image with many Windows editions, it's possible that you may need to increase the size of  ::
::    this partition.                                                                                             ::
::                                                                                                                ::
:: Part2SizeLimit - Set to either "N" or a numerical value. If you set this to "N", the size of the 2nd           ::
::    partition will be unlimited and will be created with all the remaining space not used by partition 1. If    ::
::    you would like to limit the size of the partition, specify a size in MB to create this partition.           ::
::    Note: 1 GB would be 1000 and 1 TB would be 1000000 (DON'T USE A COMMA IN VALUE!). Limiting the size is      ::
::    useful if you want to add other partitions to the drive. For example, I have a flash drive that I can       ::
::    install Windows from, but it also has another partition that is BitLocker protected with all my software    ::
::    applications, personal documents, etc.                                                                      ::
::                                                                                                                ::
:: Part2FS - This sets the filesystem type to use on the 2nd partition. Either exFAT or NTFS can be specified.    ::
::    Set this value to either "NTFS" or "exFAT". CAUTION: This IS case sensitive.                                ::
::                                                                                                                ::
:: Partition1Name - This is the volume label to give the first partition. Since this is a FAT32 partition, the    ::
::    volume label is limited to 11 characters.                                                                   ::
::                                                                                                                ::
:: Partition2Name - This is the volume label to give the second partition. If you choose to use exFAT you are     ::
::    limited to 11 characters. With NTFS you have up to 32 characters.                                           ::
::                                                                                                                ::
:: PartType - Set to either MBR or GPT. Normally, leave this set to MBR. An MBR partition type will allow for the ::
::    greatest compatibility with both BIOS and UEFI based systems. However, it is limited to disks with up to    ::
::    2TB in size. If you plan to use a disk larger than 2TB you must specify a GPT partition type. Please be     ::
::    aware that doing this will limit compatibility so that it will not work on BIOS based systems.              ::
::                                                                                                                ::
:: AutoDismount - Set this to Y if you want the source ISO image to be automatically dismounted by this batch     ::
::    file when it is done running. If you do NOT want the image dismounted, set this to N. NOTE: Technically,    ::
::    the image will be dismounted when set to anything other than N.                                             ::
::    IMPORTANT: Set this to Y only if the source is an ISO image. If you are pointing to a folder on a drive,    ::
::    then this should be set to N.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set HideDetails=N
set Partition1Size=1000
set Part2SizeLimit=N
set Part2FS=NTFS
set Partition1Name=PAR-1-FAT32
set Partition2Name=PAR-2-%Part2FS%
set PartType=MBR
set AutoDismount=N

:start

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: If the user wants to hide the details of files being copied, we append a "/nfl /ndl" to the end     ::
:: of robocopy commands. By setting a flag to either nothing or to "/nfl /ndl" we can use the same     ::
:: commands and the variable "flag" at the end of each command will determine how the command behaves. ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if %HideDetails%==Y (
set flag=/nfl /ndl
) ELSE (
set flag=
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Check to see if this batch file is being run as Administrator. If it is not, then rerun the batch file ::
:: automatically as admin and terminate the intial instance of the batch file.                            ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

(Fsutil Dirty Query %SystemDrive%>Nul)||(PowerShell start """%~f0""" -verb RunAs & Exit /B)

::::::::::::::::::::::::::::::::::::::::::::::::
:: End Routine to check if being run as Admin ::
::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: We reach this point once the batch file is run as admin ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Change the console mode to 120 columns wide by 25 lines high ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

mode con: cols=120 lines=25

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Ask user for location of mounted ISO image or the directory containing the Windows files ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
echo Introduction
echo ============
echo.
echo This batch file will create a bootable flash drive from a mounted Windows ISO image or an image extracted to disk.
echo If you are using an ISO image, mount it before you continue by double-clicking the ISO image and note the drive
echo letter to which it is mounted.
echo.
echo You will be asked if you want to wipe the destination disk or perform a refresh operation. If this is the first
echo time preparing the disk, use the WIPE option. Be aware that this will destroy ALL data currently on the disk^^!
echo.
echo If you choose the REFRESH option, you will be asked for the drive letter of the two partitions previously
echo created on the disk. We will then replace the files on these partitions with those from the source that you
echo specify. This is especially helpful if you create additional partitions on the disk because it will leave
echo those partitions intact.
echo.
pause
cls
echo Do you want to perform a WIPE operation or a REFRESH operation?
echo.
choice /C WR /N /M "Press W or R to respond:"
if errorlevel 2 set WipeRefresh=REFRESH & goto GetSourcePath
if errorlevel 1 set WipeRefresh=WIPE & goto GetSourcePath

:GetSourcePath

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Get the path to the Windows source files.                           ::
:: Tip: The path can end with or without a backslash (\). For example, ::
:: either D:, D:\, D:\ISO_Files, D:\ISO_Files\ are all valid paths.    ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
echo Enter the path to the SOURCE where your Windows files are located below. Example: E:\
echo.
:GetSourcePath
set /p SourcePath="Enter source path: "

:: Add a trailing backslash (\) if one does not exist

IF NOT "%SourcePath:~-1%"=="\" (
set SourcePath=%SourcePath%\
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Any valid Windows boot media will have a file called "boot\bootfix.bin" on the drive. This is true for both ::
:: single architecture images (x64 or x86) or for images with dual architectures. We will do a simple check to ::
:: see if such a file exists as a basic test for a valid source image location.                                ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if NOT EXIST %SourcePath%boot\bootfix.bin (
cls
echo The location that you specified does not contain a valid Windows image. Please try another location.
echo If you are specifying a location on disk, please be sure to specify the location to the root of the
echo Windows image. If you are using an ISO image, you should double-click the ISO image to mount it and
echo note the drive letter to which it was mounted.
echo.
goto GetSourcePath
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: The directory structure for a dual architecture image (one that has BOTH x64 and x86 images) will include    ::
:: \x64 and \x86 folders. In order for us to properly handle this, we need to determine if the source specified ::
:: is a single of dual architecture image. To do so, we will simply check for the existance on a \x64 folder.   ::
:: The variable Architecture will be set to either SINGLE or DUAL.                                              ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if exist %SourcePath%\x64 (
set Architecture=DUAL
) ELSE (
set Architecture=SINGLE
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: If a refresh operation was selected, then we need to ask the user for the drive letter associated ::
:: with the partitions. Otherwise, we need to identify what disk will be wiped.                      ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

If %WipeRefresh%==WIPE goto GetDiskNum

:GetPar1Letter

cls
echo Please enter the drive letter of the FIRST partition (the FAT32 partition) on the disk that we will refresh. Please
echo enter a drive letter only with no colon (:).
echo.
set /P Partition1="Drive letter of FIRST partition: "

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: As a safety check, verify that the first partition has a file \boot\bootfix.bin ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if exist %Partition1%:\boot\bootfix.bin goto GetPar2Letter
cls
echo ERROR! Either the drive letter you specified does not exist or it does not seem to contain a previously
echo created partition with suitable Windows installation files.
echo.
echo Please verify that you have specified the correct drive letter.
echo.
pause
goto GetPar1Letter

:GetPar2Letter

cls
echo Please enter the drive letter of the SECOND partition (the exFAT or NTFS partition) on the disk that we will
echo refresh. Please enter a drive letter only with no colon (:).
echo.
set /P Partition2="Drive letter of SECOND partition: "

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: As a safety check, verify that the second partition has either a \Sources or a \x64 folder ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if exist %Partition2%:\Sources goto Par2Valid
if exist %Partition2%:\x64 goto Par2Valid

cls
echo ERROR! Either the drive letter you specified does not exist or it does not seem to contain a previously
echo created partition with suitable Windows installation files.
echo.
echo Please verify that you have specified the correct drive letter.
echo.
pause
goto GetPar2Letter

:Par2Valid

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Since we are performing a refresh operation, there is no need for us to get a disk number. We will ::
:: skip that and proceed to the summary screen.                                                       ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

goto Summary

:GetDiskNum

:::::::::::::::::::::::::::::::::::::::::::::::::
:: Display a list of disks seen by the system. ::
:::::::::::::::::::::::::::::::::::::::::::::::::

cls
(echo list disk
echo exit
) | diskpart

echo.
echo Above is a list of disks connected to your system. Scroll up if the list is too long.
echo CAUTION: *MAKE SURE* that you specify the correct disk because it will be erased. Press CTRL-C to abort.
echo.
set /p DiskID="Enter the disk number for the DESTINATION disk (Enter only the number and press ENTER): "

if [%DiskID%] EQU [] Goto GetDiskNum

:Summary

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Display a summary of options that will be used and get confirmation ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
echo Summary of options you have selected:
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: These summary items apply to both WIPE and REFRESH operations ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo Path for the source files: %SourcePath%

if %HideDetails%==Y (
echo File copy status details WILL NOT be displayed
) ELSE (
echo File copy status details WILL be displayed
)

if %AutoDismount%==Y (
echo The ISO image will be automatically dismounted when we are done with it
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: The summary items below apply only to WIPE operations, so if a ::
:: REFRESH is being performed, skip this section                  ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if %WipeRefresh%==REFRESH goto RefreshSummary

echo Drive number to make bootable: %DiskID%
echo Partition type: %PartType%
echo Partition 1 size: %Partition1Size% MB
echo Partition 2 filesystem type: %Part2FS%

if NOT %Part2SizeLimit%==N (
echo Partition 2 size: %Part2SizeLimit% MB
) ELSE (
echo Partition 2 size: Use all remaining space
)

echo Partition 1 volume label: %Partition1Name%
echo Partition 2 volume label: %Partition2Name%

goto GetConfirmation

:RefreshSummary

::::::::::::::::::::::::::::::::::::::::::::::::::::
:: These items apply only to a REFRESH operation. ::
::::::::::::::::::::::::::::::::::::::::::::::::::::

echo Drive letter of FIRST partition to refresh: %Partition1%:
echo Drive letter of SECOND partition to refresh: %Partition2%:

:GetConfirmation

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Time to get final confirmation from user. If the user does not confirm ::
:: that everything is correct, show some possible resolutions.            ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.
choice /C YN /N /M "Is this correct? (Press Y or N to respond):"
if errorlevel 2 (
cls
echo.
echo        Symptom                                            Corrective Action
echo        =======                                            =================
echo Source path is wrong:                 Run the program again and respond with the correct path
echo Wrong drive number for a WIPE:        Run the program again and respond with the correct drive number
echo Wrong drive letters for a REFRESH:    Run the program again and respond with the correct drive letters
echo File copy status display incorrect:   Change the setting of "HideDetails" at start of program
echo Wrong partition sizes:                Change the setting of "Partition1Size" or "Part2SizeLimit" at start of program
echo Wrong volume labels for a WIPE:       Change the setting of "Partition1Name" or "Partition2Name" at start of program
echo Wrong partition type:                 Change the setting of "PartType" at start of program
echo.
pause
exit
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: We are creating 2 partions. A FAT32 partition and an exFAT or NTFS partition. We only need the sources   ::
:: folder on the exFAT or NTFS partition. On the FAT32 partition, we want everything else. We also want the ::
:: single file called BOOT.WIM in the sources folder on the FAT32 partition.                                ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
if %WipeRefresh%==WIPE echo We are performing the initial partitioning the destination drive to free up any used drive letters.
if %WipeRefresh%==REFRESH echo We are formatting drives %Partition1%: and %Partition2%:	and copying files. Other partitions will be left alone.
echo Please be patient^^! This can take a while if your drive is slow.
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: If we are performing a REFRESH, then there are a lot of steps that we can skip. ::
:: As a result, we will skip to the CopyOperations section.                        ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if %WipeRefresh%==REFRESH goto CopyOperations

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: We will first wipe the selected disk. This will free up any drive letters currently used by that disk. ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: NOTE: A problem has been observed recently where the CLEAN command run within DiskPart will fail the first
::       time that it is run. It often succeeds the 2nd time, but not always. However, this problem only
::       happens when the disk is MBR, not GPT. As a result, we try to perform a clean and convert to GPT.
::       Then, we finally set the disk to the correct type (MBR or GPT) based on user preference.

(echo select disk %DiskID%
echo clean
echo convert gpt
echo clean
echo convert gpt
echo clean
echo convert %PartType%
echo rescan
echo exit
) | diskpart > nul

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Ask user for drive letters to assign to the partitions on the destination drive ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:GetPar1DriveLetter

cls
echo Please enter the drive letter to assign to the FIRST partition (the FAT32 partition). Please enter
echo a drive letter only with no colon (:).
echo.
set /p Partition1="Enter the drive letter to assign to Partition #1: "

if exist %Partition1%: (
echo.
echo That drive letter is already in use. Please choose another.
echo.
pause
goto GetPar1DriveLetter
)

:GetPar2DriveLetter

cls
echo Please enter the drive letter to assign to the SECOND partition (the NTFS partition). Please enter
echo a drive letter only with no colon (:).
echo.
set /p Partition2="Enter the drive letter to assign to Partition #2: "

if exist %Partition2%: (
echo.
echo That drive letter is already in use. Please choose another.
echo.
pause
goto GetPar2DriveLetter
)

:::::::::::::::::::::::::::::::::
:: Prepare the first partition ::
:::::::::::::::::::::::::::::::::

cls
echo The first partition will be assigned drive letter %Partition1%: and will be formatted with FAT32.

(echo select disk %DiskID%
echo create partition primary size=%Partition1Size%
echo format fs=fat32 quick
echo assign letter=%Partition1%
echo active
echo rescan
echo exit
) | diskpart > nul

::::::::::::::::::::::::::::::::::
:: Prepare the second partition ::
::::::::::::::::::::::::::::::::::

echo The second partition will be assigned drive letter %Partition2%: and will be formatted with %Part2FS%.
echo.

if %Part2SizeLimit%==N goto NoSizeLimit

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: User has elected to create the second partition with a specific size ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

(echo select disk %DiskID%
echo create partition primary size=%Part2SizeLimit%
echo format fs=%Part2FS% quick
echo assign letter=%Partition2%
echo rescan
echo exit
) | diskpart > nul

goto PartitionsCreated

:NoSizeLimit

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: User has elected create the second partition with all remaining space ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

(echo select disk %DiskID%
echo create partition primary
echo format fs=%Part2FS% quick
echo assign letter=%Partition2%
echo rescan
echo exit
) | diskpart > NUL

:PartitionsCreated

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set volume labels on the two partitions that we just created. ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

label %Partition1%:%Partition1Name%
label %Partition2%:%Partition2Name%

:CopyOperations

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This section is for the copy operations from SOURCE to DESTINATION ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Technical Notes:                                                                                                 ::
::                                                                                                                  ::
:: Some flash drives present themselves as a fixed disk and as a result they my have a recyle bin folder on them.   ::
:: We are excluding the system folders which includes the recycle bin from the following operation. The /njh and    ::
:: /njs switches prevent robocopy from displaying the header and summary information. If you want to stop robocopy  ::
:: from displaying file copy progress just add a /nfl /ndl (No File Listing and No Directory Listing) to each       ::
:: robocopy command. Note that if the user elected to hide details of the copy operation, then the variable "flag"  ::
:: will be set to "/nfl /ndl" which will hide the directory and file listings.                                      ::
::                                                                                                                  ::
:: For reasons unknown to me, sometimes a path enclosed in quotes does not work in robocopy unless you add a        ::
:: trailing space. In the below commands I found this to be true only on the first robocopy command but I've added  ::
:: the space to all commands for consistency. We need the quotes just in case a path with spaces in the name is     ::
:: specified.                                                                                                       ::
::                                                                                                                  ::
:: It was previously necessary to create a file named ei.cfg in the \Sources foler. Technically, this file is only  ::
:: needed if you are NOT using an AUTOUNATTEND.XML answer file, but it won't hurt to have it there anyway. However, ::
:: in my testing, it seems that this file is no longer necessary. As a result, the code to create that file is      ::
:: commented out below but I have not removed it just in case it is needed again.                                   ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if %Architecture%==DUAL goto DualArchitecture

:: Copying files to the FAT32 partition

robocopy "%SourcePath% " %Partition1%:\ /mir /xd sources "system volume information" $recycle.bin /njh /njs %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler1
robocopy "%SourcePath%sources " %Partition1%:\sources boot.wim /njh /njs %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler1

:: Copying files to the exFAT or NTFS partition

robocopy "%SourcePath%sources " %Partition2%:\sources /mir /njh /njs /xf boot.wim %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler2
robocopy %Partition1%:\ %Partition2%:\ /mov autounattend*.xml %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler2

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Technical note: It was previously necessary to create a file named ei.cfg in the \Sources foler. Technically,  ::
:: this file is only needed if you are NOT using an AUTOUNATTEND.XML answer file, but it won't hurt to have it    ::
:: there anyway. However, in my testing, it seems that this file is no longer necessary. As a result, the code to ::
:: create that file is commented out below but I have not removed it just in case it is needed again.             ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: echo [CHANNEL] > %Partition2%:\sources\ei.cfg
:: echo Retail >> %Partition2%:\sources\ei.cfg

goto DoneCopying

:DualArchitecture

:: Copying files to the FAT32 partition

robocopy "%SourcePath% " %Partition1%:\ /mir /xd sources x64 x86 "system volume information" $recycle.bin /njh /njs %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler1
robocopy "%SourcePath%x64\sources " %Partition1%:\x64\sources boot.wim /njh /njs %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler1
robocopy "%SourcePath%x86\sources " %Partition1%:\x86\sources boot.wim /njh /njs %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler1

:: Copying files to the exFAT or NTFS partition

robocopy "%SourcePath%x64\sources " %Partition2%:\x64\sources /mir /njh /njs /xf boot.wim %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler2
robocopy "%SourcePath%x86\sources " %Partition2%:\x86\sources /mir /njh /njs /xf boot.wim %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler2
robocopy %Partition1%:\ %Partition2%:\ /mov autounattend*.xml %flag%
if %ERRORLEVEL% gtr 3 goto ErrorHandler2

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Technical note: It was previously necessary to create a file named ei.cfg in the \Sources foler. Technically,  ::
:: this file is only needed if you are NOT using an AUTOUNATTEND.XML answer file, but it won't hurt to have it    ::
:: there anyway. However, in my testing, it seems that this file is no longer necessary. As a result, the code to ::
:: create that file is commented out below but I have not removed it just in case it is needed again.             ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: echo [CHANNEL] > %Partition2%:\x64\sources\ei.cfg
:: echo Retail >> %Partition2%:\x64\sources\ei.cfg

:: echo [CHANNEL] > %Partition2%:\x86\sources\ei.cfg
:: echo Retail >> %Partition2%:\x86\sources\ei.cfg

:DoneCopying

:::::::::::::::::::::::::::::
:: Dismount the disk image ::
:::::::::::::::::::::::::::::

IF %AutoDismount%==N goto DismountDone

:: Strip the backslash from the path
IF "!SourcePath:~-1!"=="\" SET SourcePath=!SourcePath:~,-1!

:: Dismount the image
powershell.exe -command "Dismount-DiskImage -DevicePath \\.\%SourcePath%" > NUL

:DismountDone

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Inform the user that we are done. Also, as a precaution, check to see if an ::
:: unattended setupanswer file is present and warn the user if it is.          ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
echo All operations have been completed.
echo.

if exist %Partition2%:\autounattend.xml (
echo ^^!CAUTION^^! An unattended setup file ^(autounattend.xml^) is present on the 2nd partition.
echo As a result, if you boot from this disk, an unattended installation will begin. This has
echo the potential to wipe out the contents of disks attached to your system without warning.
echo.
echo It might be a wise idea to carefully label the bootable media to reflect this situation.
echo As an alternative, consider temporarily renaming the autounattend.xml to something else.
echo.
)
pause

:END

exit


:::::::::::::::::::::::::::::
:: Error Handling Routines ::
:::::::::::::::::::::::::::::

:ErrorHandler1
cls
echo There was an error copying files to partition #1. Please verify that partition #1 has sufficient space available.
echo Please correct the situation and run the script again. If you are changing the partition sizes, then you will
echo need to use the WIPE operation to create new partitions with the newly specified sizes.
echo.
pause
goto END

:ErrorHandler2
cls
echo There was an error copying files to partition #2. Please verify that partition #2 has sufficient space available.
echo Please correct the situation and run the script again. If you are changing the partition sizes, then you will
echo need to use the WIPE operation to create new partitions with the newly specified sizes.
echo.
pause
goto END
