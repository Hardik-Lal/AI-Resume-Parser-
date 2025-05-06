param(
    [Parameter(Mandatory = $true)]
    [string]$Skill
)

$Bucket = "resume-parser-hardik-2025"
$DownloadFolder = "MatchedResumes"

Write-Host "Searching for resumes with skill: '$Skill'" -ForegroundColor Cyan

# Create the folder if it doesn't exist
if (!(Test-Path -Path $DownloadFolder)) {
    New-Item -ItemType Directory -Path $DownloadFolder | Out-Null
}

# Get list of object keys
$keysRaw = aws s3api list-objects-v2 --bucket $Bucket --query "Contents[].Key" --output text

if (-not $keysRaw) {
    Write-Host "No resumes found in bucket." -ForegroundColor Red
    return
}

$keys = $keysRaw -split "\s+"
$found = $false

foreach ($key in $keys) {
    try {
    $json = aws s3api get-object-tagging --bucket $Bucket --key "$key" --output json
    $tagSet = $json | Out-String | ConvertFrom-Json | Select-Object -ExpandProperty TagSet

    foreach ($tag in $tagSet) {
        if ($tag.Key -eq "Matched" -and $tag.Value -match $Skill) {
            Write-Host "Match found: $key" -ForegroundColor Green
            aws s3 cp "s3://$Bucket/$key" "$DownloadFolder\$key" | Out-Null
            $found = $true
            break
        }
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Host ("Error processing file: " + $key + " - " + $errorMessage) -ForegroundColor Yellow
}

}

if (-not $found) {
    Write-Host "No resumes matched for skill: '$Skill'" -ForegroundColor Red
} else {
    Write-Host "Matching resumes downloaded to folder: $DownloadFolder" -ForegroundColor Cyan
}

Write-Host "Done." -ForegroundColor Cyan