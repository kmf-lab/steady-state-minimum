# Define the output file
$outputFile = "rust_source_summary.txt"

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

# Write the directory tree to the output file
Write-Output "." | Set-Content -Path $outputFile
Get-DirectoryTree -Path '.' -Prefix '' | Add-Content -Path $outputFile

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
        Add-Content -Path $outputFile -Value "File: $relativePath"
        Add-Content -Path $outputFile -Value (Get-Content $file.FullName)
        Add-Content -Path $outputFile -Value ""
    }
}