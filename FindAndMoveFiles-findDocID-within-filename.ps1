<#
.SYNOPSIS
    This script scans a directory for PDF files and checks if their filenames contain any DocIDs listed in a CSV file.
    If a match is found, the script moves the file to a "NewLocation" folder and logs the matched files in a CSV.

.DESCRIPTION
    - Reads a list of DocIDs from "DocIDs.csv".
    - Scans the current directory for PDF files.
    - Checks if any DocID appears anywhere in each filename.
    - Moves matching files to a "NewLocation" folder.
    - Creates a log file ("matched_files.csv") containing the moved filenames.

.PARAMETER
    None (Assumes "DocIDs.csv" exists in the working directory).

.REQUIREMENTS
    - PowerShell 5.0+ recommended.
    - "DocIDs.csv" should be formatted with a single column named "DocID".
    - PDF files should be in the same directory as the script.

.OUTPUTS
    - Matched files are moved to "NewLocation".
    - "matched_files.csv" logs all matched and moved files.

.VERSION
    1.0

.AUTHOR
    Davos DeHoyos
#>

# Define the CSV file containing the list of DocIDs
$docIdCsvPath = ".\DocIDs.csv"

# Load and clean DocIDs (Remove spaces & ensure it's treated as string)
$docIDs = Import-Csv -Path $docIdCsvPath | Select-Object -ExpandProperty DocID | ForEach-Object { $_.Trim() }

Write-Output "📄 Loaded DocIDs from CSV:"
$docIDs | ForEach-Object { Write-Output "🔹 [$($_)]" }

# Set the current working directory
$pdfDirectory = Get-Location
$newLocation = "$pdfDirectory\NewLocation"

# Create the destination folder if it doesn't exist
if (!(Test-Path $newLocation)) {
    New-Item -ItemType Directory -Path $newLocation | Out-Null
}

# Get all files in the current directory
$pdfFiles = Get-ChildItem -Path $pdfDirectory -Filter "*.pdf"

# List to store matched filenames
$matchedFiles = @()

Write-Output "📂 Checking PDF files for matches in filenames:"
foreach ($file in $pdfFiles) {
    $fileName = $file.Name
    Write-Output "🔍 Checking File: $fileName"

    # Check if ANY DocID appears in the filename
    $matchFound = $false
    foreach ($docID in $docIDs) {
        if ($fileName -match [regex]::Escape($docID)) {
            Write-Output "✅ MATCH FOUND: [$fileName] contains [$docID]"
            $matchFound = $true
            break  # Stop checking once a match is found
        }
    }

    if ($matchFound) {
        # Add filename to the matched list
        $matchedFiles += [PSCustomObject]@{ FileName = $fileName }

        # Move the file to NewLocation
        Move-Item -Path "$pdfDirectory\$fileName" -Destination $newLocation -Force
    } else {
        Write-Output "❌ No Match in CSV for: [$fileName]"
    }
}

# Export matched filenames to a CSV list in the current directory
$matchedFiles | Export-Csv -Path "$pdfDirectory\matched_files.csv" -NoTypeInformation

Write-Output "✅ Process Complete! Matched files have been moved to $newLocation."
Write-Output "📄 A record of matched files has been saved in matched_files.csv."
