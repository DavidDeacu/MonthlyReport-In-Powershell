$directory = "D:\CSV files" #$directory is the place where all the .CSV files should be.
cd $directory

New-Item -Path $directory -Name "OtherFiles" -ItemType "directory" -Force #Creates a new folder named "OtherFiles". In this folder the script will move all the items which extension is not .CSV from the $directory.
New-Item -Path $directory -Name "MonthlyReport" -ItemType "directory" -Force #Creates a new folder named "MonthlyReport". In this folder the script will create a .CSV file, which is a monthly report.

#Next sequence will verify if there exist any other files than .CSV in $directory.

$extensions = (Get-ChildItem -Path $directory | where { ! $_.PSIsContainer } | Select-Object PSParentPath,Extension).extension
ForEach ($fileextension in $extensions)
{
    $file = get-childitem "$directory\*$fileextension" | where { ! $_.PSIsContainer }
    if(-Not($fileextension -eq ".csv"))
    {
    Move-Item -Path $file -Destination "$directory\OtherFiles"
    }
}

$mainpath = (Get-childItem -Path "$directory"| where { ! $_.PSIsContainer }) #$mainpath will store all files in $directory, except of folders.

$firstCSV = $mainpath | Select-Object -First 1 #Selects the first .CSV file
$firstCSVcontent = Import-Csv -path .\$firstCSV

#Next sequence will add in $firstCSVcontent all company names from all .CSV files (even if during the month, in a certain day it was added or deleted any company) and will check for the biggest number of licenses, for each company and will replace the current number of licenses from $firstCSVcontent. 

ForEach ( $csvfile1 in $mainpath )
{  
    $csv = Import-Csv -path .\$csvfile1

    ForEach ($CompanyName1 in $csv.CustomerNameCode)
    {
        $j= $csv.CustomerNameCode.indexof($CompanyName1)

        if ($firstCSVcontent.CustomerNameCode -notcontains $CompanyName1)
        {
            $firstCSVcontent += new-object psobject -property @{'CustomerNameCode' = $CompanyName1; 'LicenseCount' = $csv.LicenseCount[$j];} # Will add in $firstCSVcontent all company names from all .CSV files.
        }
        :Main ForEach($CompanyName2 in $firstCSVcontent.CustomerNameCode)
        {
            $i= $firstCSVcontent.CustomerNameCode.indexof($CompanyName2)
            if ($CompanyName2 -contains $CompanyName1)
            {
                
                if([int]$firstCSVcontent.LicenseCount[$i] -lt [int]$csv.LicenseCount[$j]) #will check for the biggest number of licenses.
                {
                    
                   $firstCSVcontent[$i].LicenseCount = $csv.LicenseCount[$j] #will replace the current number of licenses.
                }
                break Main
            }
        }
    }
}

$ExportLocation = "$directory\MonthlyReport\MonthlyReport$(get-date -f yyyy-MM-dd).csv" #$ExportLocation is the place where the MonthlyReport.csv file will be created. Moreover it will add in its name the current date.

$firstCSVcontent | Export-Csv -path $ExportLocation -Delimiter ',' -NoTypeInformation #Creates the .CSV file.