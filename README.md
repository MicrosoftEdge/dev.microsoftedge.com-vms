# dev.microsoftedge.com - VMs

The code in this repo contains the script files we use to create the free VMs available in https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
The main reason to open source this project is for the community to help with the templates of the different VMs and add features or configurations that might be useful for them.

This script generates VMs for several platforms (VirtualBox and Vagrant, Parallels, Hyper-V, VMWare), notifies via email of the process, uploads the files to an Azure Storage for its distribution and creates a new JSON file to put on the website.
Some of these steps will not make sense for you so feel free to hack around and disable them.

There are some known issues with the scripts so make sure to check the issues section.

Currently this process only works on Windows 8.1 machines.

## Software Requirements
* Windows 8.1 (working on a solution that works for Windows 10)
* [Packer 1.0.2 For Windows and Mac](https://packer.io/downloads.html) 
* [VirtualBox 5.0.2 for Windows hosts](https://www.virtualbox.org/wiki/Downloads)
* [VMware Workstation](http://www.vmware.com/products/workstation)
* Hyper-V
* [Parallels Desktop 11 for Mac](http://www.parallels.com/products/desktop/download/)
* [7-Zip for Windows 64bits](http://www.7-zip.org/download.html)
* [AzCopy](http://aka.ms/downloadazcopy)
* [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)
* [Visual Studio Community](https://www.visualstudio.com/downloads/)

### Automatic installation in Windows computers
For an automatic installation of the required software you can use the script `.\scripts\apps\winappinstaller.ps1` It uses Chocolatey for installing the programs in the previous list. It is not recommended to use the script in machines that have already some of the programs installed manually. The purpose of the script is saving time in the installation in clean machines.

### Automatic installation in Mac computers
Although in Mac only Packer and Parallels are required, you can install them automatically using the script `.\scripts\apps\macappinstaller.sh`. The script uses Homebrew to install the apps. Parallels will require in addition of the installation the registration of a valid key. In case packer is not installing correctly write in the terminal `brew install packer` to retry the installation.

## Preparing the Windows build environment

The following are the instructions to set up an environment almost fully automated. During the VM creation process sometimes the host needs to be rebooted or some permissions are required. If you don't some manual intervention you can skip some steps like AutoLogon, etc.


### Clone this repository
```
git clone https://github.com/MicrosoftEdge/dev.microsoftedge.com-vms/
```

### Install Packer

Unzip Packer files to `C:\packer`.

#### Hyper-V support

Packer doesn't support Hyper-V currently. [PR-2576](https://github.com/mitchellh/packer/pull/2576) adds support to it but hasn't been merged yet.
Although we are working on updating the project to work with that PR, in the meantime you will have to use this [Hyper-V plugin for Packer](https://github.com/pbolduc/packer-hyperv/). Please follow the instructions in the repo to compile it for Windows and place the plugin into `C:\packer`.

#### VirtualBox support

We automatically install the Guest Extensions, but to do that silently the installation needs to add the Oracle certificate to the list of trusted certs in the guest OS. Right now we suggest that you follow the process described in [this guide](http://www.catonrug.net/2013/03/virtualbox-silent-install-store-oracle-certificate.html). You will have to place that `.cer` file in `scripts\floppy\guesttools\oracle-cert.cer`. In the near future we plan to update the process to follow the guidance of the [official manual](https://www.virtualbox.org/manual/ch04.html#additions-windows) in the section **4.2.1.3. Unattended Installation**.

### Set PowerShell Execution Policy
Set the execution policy by typing this into your powershell window:

```
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
```

### Set environment variable

```
setx PATH "%PATH%;C:\Packer;C:\Program Files\7-Zip"
```

### Disable UAC

```
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
```

### Enable AutoLogon
The following registry setting sets the auto logon and also saves the default username and password which will be used to log in at every reboot.

```
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $RegPath "DefaultUsername" -Value "DomainName\Administrator" -type String
Set-ItemProperty $RegPath "DefaultPassword" -Value "Password" -type String
```

### Put all the tools in the right folder
The `bin` folder should have the following folders
* `AzCopy` with all the binaries and no subfolders
* `Putty` with plink.exe and putty.exe
* `PackerMerge` with the output of compiling the project `tools\PackerMerge` with Visual Studio (it should copy the output directly to the right folder when the build is finished)
* `VMSGen\` with the output of compiling the project `tools\VMSGen` with Visual Studio (it should copy the output directly to the right folder when the build is finished)

You will also need to download [BgInfo](https://technet.microsoft.com/en-us/sysinternals/bginfo.aspx), unzip it and put the .exe in `scripts\floppy\bginfo\`

Remember to install also [7-Zip for Windows 64bits](http://www.7-zip.org/download.html)

### Enable Or Disable Hypervisor

To Enable Hypervisor:

```
bcdedit /set hypervisorlaunchtype auto
```

To Disable Hypervisor:

```
bcdedit /set hypervisorlaunchtype off
```

It is recommended that first machine that we generated should not be HyperV. First time we generate a Hyper-V virtual machiche the computer will reboot.

## Preparing the Mac build environment

### Clone this repository

Clone this repo to /Users/admin/dev.microsoftedge.com-vms/

```
git clone https://github.com/MicrosoftEdge/dev.microsoftedge.com-vms/
```

### Share vmgen folder

Turn Apple File Sharing on

```
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
```
Activate SMB

```
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
```

Share Repository folder

```
sudo sharing -a /Users/admin/dev.microsoftedge.com-vms/
```

### Install Packer

Unzip Packer files to /Users/packer

### Set environment variable on OS X

* Open up Terminal.
* Run the following command:

```
sudo nano /etc/paths
```

* Enter your password, when prompted.
* Go to the bottom of the file, and enter the path you wish to add (/Users/admin/packer)
* Hit control-x to quit.
* Enter “Y” to save the modified buffer.

### Enable SSH

The Apple Mac OS X operating system has SSH installed by default but the SSH daemon is not enabled. This means vmgen script can't login remotely or do remote copies until you enable it.

To enable it, go to "System Preferences". Under "Internet & Networking" there is a "Sharing" icon. Run that. In the list that appears, check the "Remote Login" option.

## Download Windows ISOs

This process uses ISOs, and more precisely the Client Enterprise Evaluation. You should legally get a copy of the iso for the guest you want to build and put it directly in the the `scripts\iso` folder.

## Create An Integrated Up To Date Windows ISO

If you want to speed up the process of creating the VMs you can create an Integrated Up To Date Windows ISO. There are online guides such as [this one](https://www.raymond.cc/blog/create-an-integrated-up-to-date-windows-7-install-disc/) that explains the process in detail.

## Start the generation process
In order to run the script, we need to open any Windows PowerShell console with Admin rights and run the script vmgen.ps1 with the -Build parameter.

```
.\vmgen.ps1 -Build
```

This script requires a configuration file called `vmgen.json` located in the same directory. This file is used by the generation tool to know which Virtual Machines must be generated. The content of the configuration file must have this format:

```json
{
  "Build": "20150901",
  "OutputPath": "D:\\vms",
  "AzureUpload": false,
  "GenerateMultipart": true,
  "AzureStorage": {
    "Url" : "https://yourblostorage.blob.core.windows.net/vms",
    "Key" : "xxxxxxxxxxx..."
  },
  "Mac": {
    "IP": "192.168.0.2",
    "SSH_User": "admin",
    "SSH_Password": "password",
    "NetworkPath": "\\\\MAC\\microsoftedge-vms",
    "RepoPath" : "/Users/admin/dev.microsoftedge.com-vms",
    "PackerPath" : "/Users/admin/packer"
  },
  "Mail": {
    "SMTP": "smtp.office365.com",
    "From": "user@domain.com",
    "To": "user@user.com",
    "User": "user@user.com",
    "Password": ""
  },
  "VMS": {
    "Windows": {
      "HyperV": {
        "MSEdge": [
          "Win10"
        ],
        "IE11": [
          "Win81", "Win7"
        ],
        "IE10": [
          "Win7"
        ]
      },
      "VirtualBox": {
        "IE11": [
          "Win81", "Win7"
        ],
        "IE10": [
          "Win7"
        ]
      }
    },
    "Mac": {
      "Parallels": {
        "IE11": [
          "Win81", "Win7"
        ],
        "IE10": [
          "Win7"
        ]
      }
    }
  }
}
```

* Build - Indicates build number. This identifier will be used to generate output folder name.
* OutputPath - Path to store ZIP files.
* AzureUpload - Indicates if output files will be uploaded to an Azure storage account.
* AzureStorage - Contains the Url and the Key of de Azure Storage Account to upload de output files.
* Mac - Contains IP, SSH User & password, and a shared path.
* Mail - SMTP configuration to send emails to the appropriate people
* VMS - Object struct to set the dev.microsoftedge.com Virtual Machines to be generated. The valid values for each level are as follows:

  * **First Level** - Windows, Mac
  * **Second Level** - HyperV, VirtualBox, VMware, Parallels, VPC
  * **Third Level** - IE8, IE9, IE10, IE11, MSEdge
  * **Fourth Level** - Win7, Win81, Win10

## OnlyUpload mode
To upload the generated files after a build without regenerate de VMs, we need to run the script vmgen.ps1 with the -Build and -OnlyUpload parameter.

```
.\vmgen.ps1 -Build -OnlyUpload
```

## Output JSON

A JSON specific version will be generated in OutputPath. If you want your result to be merge with another file, place it in the same folder with the name vms.json.

## Generate a new OS template

To generate a new platform perform the following steps:

1. Make a copy of `floppy_files_OS.json`, `OSx64.json` and `urls_OSx64.json` files from template-parts/templates to template-parts.
2. Change OS by the name of the new platform identifier (i.e. Win10TH2).
3. Edit `url_OSx64.json` and enter the correct `iso_url` and `iso_checksum` properties.
4. Edit `OSx64.json` and change `vm_name` and `output_directory` properties for every builder configuration.
5. It's not mandatory to change `floppy_files_OS.json`. You can leave it without changes.
6. Edit `BuildTemplates.ps1` and and the follow lines to add a new template generation.

`$template = "MSEdge-Win10TH2"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\user.json,.\template-parts\urls_OSx64.json,.\template-parts\OSx64.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_OS.json,.\template-parts\provisioner_common.json,.\template-parts\pp-vagrant.json" -o:".\template-output\$template.json"
Write-Verbose "$template.json created."`

## Valid VMs

|        | Win7  | Win81 | Win10 |
| ------ | ----- | ----- | ----- |
| MSEdge |   -   |   -   |   X   |
| IE11   |   X   |   X   |   -   |
| IE10   |   X   |   -   |   -   |
| IE9    |   X   |   -   |   -   |
| IE8    |   X   |   -   |   -   |
| IE7    |   -   |   -   |   -   |

## Valid Virtualization System by OS

|        | VPC   | HyperV | VBox  | VMware | Parallels |
| ------ | ----- | ------ | ----- | ------ | --------- |
| Win7   |   X   |   X    |   X   |    X   |     X     |
| Win81  |   -   |   X    |   X   |    X   |     X     |
| Win10  |   -   |   X    |   X   |    X   |     X     |


# Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
