
$7zipPath = "C:\Program Files\7-Zip\7z.exe"
$ConfigurationFile = [xml](Get-Content "$PSScriptRoot\bigipreportconfig.xml")

$Version = $ConfigurationFile.Settings.version

$Ps1content = Get-Content "$PSScriptRoot\bigipreport.ps1"

Try {

    $VersionHistory = @()

    Foreach($Line in $Ps1Content){

        $VersionData = ""
        $VersionDict = @{}

        if($Line -Match "^#\s+[0-9\.]+\s+[0-9\-]+"){
            $VersionData = $Line -Replace "^\s*#\s*", ""
            $VersionArr = $VersionData -Split "\t+"

            $VersionDict["Version"] = $VersionArr[0]
            $VersionDict["Date"] = $VersionArr[1]
            $VersionDict["Change"] = $VersionArr[2]
            $VersionDict["Author"] = $VersionArr[3]
            $VersionDict["ConfigUpdateNeeded"] = $VersionArr[4]

            $VersionHistory += $VersionDict

        } elseif($Line -Match "^\s*This script generates a"){
            Break;
        } elseif($Line -Match "^#\s{4,}") {
            $VersionData = $Line -Replace "^#\s+", ""
            $VersionHistory[$versionHistory.count-1]["Change"] += "`n$Version"
        }

    }

    $VersionJson = $VersionHistory | ConvertTo-Json

} Catch {
    Write-Error "Corrupt version history JSON"
    Break;
}

#Make sure the Zip file does not exist
if(-not (Test-Path "$PSScriptRoot\Releases\BigipReport-$Version.zip")){

    #Get the content of the current bigipreport.ps1 file 
    $Ps1Content = Get-Content "$PSScriptRoot\bigipreport.ps1"

    $VersionFound = $false

    #Verify that version history has been populated for this release
    Foreach($Line in $Ps1Content){
        
        if($Line.contains($version)){
            $VersionFound = $true
            Break       
        }

        #Break at the start of the script code
        if(-not ($Line.startswith("#"))){
            Break
        }
    }

    #Add version to the file in order to allow users to store multiple versions without overwriting them
    Move-Item "$PSScriptRoot\bigipreport.ps1" "$PSScriptRoot\bigipreport-$version.ps1"
    
    #Zip the release and put it in .\Releases
    & $7ZipPath a -tzip $PSScriptRoot\Releases\BigipReport-$Version.zip "$PSScriptRoot\bigipreport-$Version.ps1" "$PSScriptRoot\bigipreportconfig.xml" "`"$PSScriptRoot\Move the content of this folder to the configured report root`""
    
    #Restore the file name
    Move-Item "$PSScriptRoot\bigipreport-$version.ps1" "$PSScriptRoot\bigipreport.ps1"
} else {
    "A release with that name already exist. Forgot to update the XML version?"
}

$VersionJson -split "`n" | select -last 22 | ForEach-Object { Write-Host -Foregroundcolor "Yellow" $_ }

#Halt before exit to show that everything has gone OK
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")