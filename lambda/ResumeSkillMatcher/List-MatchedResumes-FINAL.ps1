
param(
    [Parameter(Mandatory = $true)]
    [string]$Skill
)

$Bucket = "resume-parser-hardik-2025"
$DownloadFolder = "MatchedResumes"

if (-not (Test-Path $DownloadFolder)) {
    New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

Write-Host "Checking resumes in bucket '$Bucket' for skill '$Skill'..." -ForegroundColor Cyan

try {
    $objects = aws s3api list-objects-v2 --bucket $Bucket --query 'Contents[].Key' --output text

    foreach ($key in $objects) {
        $tagSet = aws s3api get-object-tagging --bucket $Bucket --key $key --query 'TagSet' --output json | ConvertFrom-Json

        $matchTag = $tagSet | Where-Object { $_.Key -eq 'Matched' -and $_.Value -like "*$Skill*" }

        if ($matchTag) {
            Write-Host "✔ $key (matched: $($matchTag.Value))" -ForegroundColor Green

            $localPath = Join-Path -Path $DownloadFolder -ChildPath (Split-Path $key -Leaf)
            aws s3 cp "s3://$Bucket/$key" $localPath | Out-Null
        }
    }
}
catch {
    Write-Host "❌ An error occurred: $_" -ForegroundColor Red
}

Write-Host "Done." -ForegroundColor Cyan
