# This script generates a summary of a Rust project, including the project structure
# and the contents of all .rs and .toml files, excluding 'target' and hidden directories.
# The output is written to lesson-00-minimum.md, with a .txt copy created if needed.
# Run this script from the root of the Rust project using PowerShell.

# Define the output file
$outputFile = "lesson-00-minimum.md"

# Function to generate a directory tree
function Get-DirectoryTree {
    param (
        [string]$Path = '.',
        [string]$Prefix = ''
    )
    # Get all items (files and directories) excluding 'target' and hidden items
    $items = Get-ChildItem -Path $Path | Where-Object { $_.Name -ne 'target' -and $_.Name -notlike '.*' }
    $count = $items.Count
    for ($i = 0; $i -lt $count; $i++) {
        $item = $items[$i]
        $last = $i -eq ($count - 1)
        # Use ASCII characters for tree structure
        $itemPrefix = if ($last) { '\-- ' } else { '+-- ' }
        Write-Output ($Prefix + $itemPrefix + $item.Name)
        if ($item.PSIsContainer) {
            if ($last) {
                $newPrefix = $Prefix + '    '
            } else {
                $newPrefix = $Prefix + '|   '
            }
            Get-DirectoryTree -Path $item.FullName -Prefix $newPrefix
        }
    }
}

# Check if README.md exists and initialize the file with its content
$readmePath = "README.md"
if (Test-Path $readmePath) {
    # Start with README.md content
    Get-Content $readmePath | Set-Content -Path $outputFile
    Write-Output "" | Add-Content -Path $outputFile
    Write-Output "---" | Add-Content -Path $outputFile
    Write-Output "" | Add-Content -Path $outputFile
} else {
    # Initialize empty file if no README
    "" | Set-Content -Path $outputFile
}

# Add the Lesson 00: Minimum section
Write-Output "# Lesson 00: Minimum" | Add-Content -Path $outputFile
Write-Output "" | Add-Content -Path $outputFile
Write-Output "## Project Structure" | Add-Content -Path $outputFile
Write-Output "" | Add-Content -Path $outputFile
Write-Output '```' | Add-Content -Path $outputFile
Write-Output "." | Add-Content -Path $outputFile
Get-DirectoryTree -Path '.' -Prefix '' | Add-Content -Path $outputFile
Write-Output '```' | Add-Content -Path $outputFile
Write-Output "" | Add-Content -Path $outputFile

# Find all Cargo.toml files to identify Rust project directories
$cargoTomls = Get-ChildItem -Recurse -Filter Cargo.toml -File

# Process each Rust project
foreach ($cargoToml in $cargoTomls) {
    $projectDir = $cargoToml.Directory.FullName
    # Find all *.toml and *.rs files, excluding those in 'target' or hidden directories
    $files = Get-ChildItem -Path $projectDir -Recurse -File -Include *.toml,*.rs | Where-Object {
        $_.FullName -notmatch '\\target\\' -and $_.FullName -notmatch '\\\.[^\\]+\\'
    }

    foreach ($file in $files) {
        # Get the relative path for consistency with typical script outputs
        $relativePath = Resolve-Path -Path $file.FullName -Relative


        # Read the file content as a single string
        $fileContent = Get-Content $file.FullName -Raw
        # Ensure the content ends with a newline
        if (-not $fileContent.EndsWith("`n")) {
            $fileContent += "`n"
        }
        # Create the code block
        $codeBlockOpen = switch ($file.Extension.ToLower()) {
            '.rs' {  '```rust' }
            '.toml' { '```toml' }
            default {  '```text' }
        }

        # Add markdown header and code block to the file
        Add-Content -Path $outputFile -Value "## $relativePath"
        Add-Content -Path $outputFile -Value ""
        Add-Content -Path $outputFile -Value $codeBlockOpen
        Add-Content -Path $outputFile -Value "`n"
        Add-Content -Path $outputFile -Value $fileContent
        Add-Content -Path $outputFile -Value '```'
        Add-Content -Path $outputFile -Value ""
    }
}

# If the output file does not end with .txt, create a copy with .txt appended
if (-not $outputFile.EndsWith('.txt')) {
    $txtFile = "$outputFile.txt"
    Copy-Item -Path $outputFile -Destination $txtFile
}