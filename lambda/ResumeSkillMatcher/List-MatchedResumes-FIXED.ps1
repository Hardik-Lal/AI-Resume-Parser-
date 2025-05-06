param(
    [Parameter(Mandatory = $true)]
    [string]$Skill
)

$Bucket = "resume-parser-hardik-2025"
$DownloadPath = "C:\lambda\SortedResumes"

# Create the folder if it doesn't exist
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath | Out-Null
}

Write-Host "Checking resumes in bucket '$Bucket' for skill '$Skill'..." -ForegroundColor Cyan

# Get the list of all resume keys
$keys = aws s3api list-objects-v2 --bucket $Bucket --query 'Contents[].Key' --output text

$found = $false

foreach ($key in $keys) {
    $tagSet = aws s3api get-object-tagging --bucket $Bucket --key $key --query 'TagSet' --output json | ConvertFrom-Json
    $matchTag = $tagSet | Where-Object { $_.Key -eq 'Matched' -and $_.Value -like "*$Skill*" }

    if ($matchTag) {
        Write-Host "✔ $key (matched: $($matchTag.Value))" -ForegroundColor Green
        $destination = Join-Path -Path $DownloadPath -ChildPath $key
        aws s3 cp "s3://$Bucket/$key" "$destination" | Out-Null
        $found = $true
    }
}
    
if (-not $found) {
    Write-Host "No resumes found with skill '$Skill'." -ForegroundColor Yellow
}

Write-Host "Done." -ForegroundColor Cyan