param(
    [string]$Upstream = "https://github.com/openai/plugins.git",
    [string]$Branch = "main",
    [string]$OldValue = "codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-openai-curated",
    [string]$NewValue = "codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-codexplusplus-openai-curated",
    [switch]$Push
)

$ErrorActionPreference = "Stop"

$dirty = git status --porcelain
if ($dirty) {
    throw "Working tree is not clean. Commit or stash changes before syncing."
}

git remote remove upstream 2>$null
git remote add upstream $Upstream
git fetch origin $Branch --prune
git fetch upstream $Branch --prune
git checkout $Branch
git merge --no-edit -X theirs "upstream/$Branch"

$skipDirs = @(".git", ".github")
Get-ChildItem -Recurse -File | Where-Object {
    $parts = $_.FullName.Split([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    foreach ($skip in $skipDirs) {
        if ($parts -contains $skip) {
            return $false
        }
    }
    return $true
} | ForEach-Object {
    $bytes = [IO.File]::ReadAllBytes($_.FullName)
    if ([Array]::IndexOf($bytes, [byte]0) -lt 0) {
        try {
            $text = [Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            $text = $null
        }

        if ($null -ne $text) {
            $updated = $text.Replace($OldValue, $NewValue)
            if ($updated -ne $text) {
                [IO.File]::WriteAllText($_.FullName, $updated, [Text.Encoding]::UTF8)
            }
        }
    }
}

git diff --quiet
if ($LASTEXITCODE -ne 0) {
    git add -A
    git commit -m "Sync upstream and rename curated channel"
}

if ($Push) {
    $ahead = [int](git rev-list --count "origin/$Branch..HEAD")
    if ($ahead -gt 0) {
        git push origin $Branch
    } else {
        Write-Host "No changes to push."
    }
}
