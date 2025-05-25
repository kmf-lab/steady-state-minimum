# Define the output file
$outputFile = "rust_source_summary.md"

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

# Add the Rust Source Summary section
Write-Output "# Rust Source Summary" | Add-Content -Path $outputFile
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

        # Determine the language for syntax highlighting
        $language = switch ($file.Extension.ToLower()) {
            '.rs' { 'rust' }
            '.toml' { 'toml' }
            default { 'text' }
        }

        # Add markdown header for the file
        Add-Content -Path $outputFile -Value "## $relativePath"
        Add-Content -Path $outputFile -Value ""

        # Add the file content in a code block with appropriate language
        Add-Content -Path $outputFile -Value "``````$language"
        Add-Content -Path $outputFile -Value (Get-Content $file.FullName)
        Add-Content -Path $outputFile -Value '```'
        Add-Content -Path $outputFile -Value ""
    }
}
