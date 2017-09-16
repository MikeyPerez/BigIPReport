
$7zipPath = "C:\Program Files\7-Zip\7z.exe"
$ConfigurationFile = [xml](Get-Content "$PSScriptRoot\bigipreportconfig.xml")

$Version = $ConfigurationFile.Settings.version

$Ps1content = Get-Content "$PSScriptRoot\bigipreport.ps1"

Try {



    $VersionHistory = @()

    Add-Type @'
    public class BigRepVersion {
        public string date;
        public string version;
        public string change;
        public string author;
        public string configupdateneeded;
    }
'@

    Foreach($Line in $Ps1Content){

        $VersionLine = ""
        $VersionDict = @{}

        if($Line -Match "^#\s+[0-9\.]+\s+[0-9\-]+"){


            $VersionObj = New-Object BigRepVersion

            $VersionLine = $Line -Replace "^\s*#\s*", ""
            $VersionArr = $VersionLine -Split "\t+"

            $VersionObj.version = $VersionArr[0]
            $VersionObj.date = $VersionArr[1]
            $VersionObj.change = $VersionArr[2]
            $VersionObj.author = $VersionArr[3]
            $VersionObj.configupdateneeded = $VersionArr[4]

            $VersionHistory += $VersionObj

        } elseif($Line -Match "^\s*This script generates a"){
            Break;
        } elseif($Line -Match "^#\s{4,}") {
            $VersionLine = $Line -Replace "^#\s+", ""
            $VersionHistory[$versionHistory.count-1].change += "`n$VersionLine"
        }

    }
 
    $VersionHistory | Sort-Object -Property Date -Descending |  ConvertTo-Json | Out-File "$PSScriptRoot\versionhistory.json"

} Catch {

    Write-Error "Unable to create version history"
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