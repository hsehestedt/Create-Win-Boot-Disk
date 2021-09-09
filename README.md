# Create-Win-Boot-Disk
This batch file will create a Windows setup disk for you and adds some advanced features.

NOTE: For a more full featured program that includes the ability to create a Windows boot disk as does this batch file but with more features, please see my WIM-Tools project (www.github.com/hsehestedt/WIM-Tools). This batch file duplicates a small portion of the functionality of one routine in that program and is especially useful for those who may want to dissect the batch file to see how it works under the hood.

This batch file will allow you you to create a Windows boot disk using nothing but native Microsoft tools. Some of the features:

- Can create a Windows boot disk that is bootable on x64 and x86 systems, as well as BIOS and UEFI based systems.
- Works around the limitation of a 4GB file size even on systems that don't like to boot from NTFS formatted removable media.
- Fully supports the creation of dual architecture media (media with both x64 and x86 editions of Windows in the same image).
- Features a number of user definable parameters that are set by modifying settings in the batch file.
- Allows the user to leave free space available on the media so that additional partitions can be created for other purposes.
- If user wishes to update the bootable, there is a REFRESH option available to allow recreation of the Windows boot media WITHOUT impacting other partitions. As a result, you can store additional data on other partitions and still retain the ability to update your boot image.

******
 Usage
******

After you download the batch file, open it in a program such as Notepad. NOTE: Avoid using programs such as Word which insert special formatting characters into the the document.

At the start of the batch file you will see comments and settings that can be altered by you to customize the behavior of the batch file. Read the description of each setting and make any adjustments that you wish to change the behavior of the batch file.
