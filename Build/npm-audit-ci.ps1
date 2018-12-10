Param
(
    [Parameter()]
    [string]$WorkingDirectory,
    
    [ValidateSet("low", "moderate", "high", "critical")]
    [Parameter()]
    [string]$Level = "high"
)

function runNpmAudit() {
    if ($WorkingDirectory) {
        Set-Location $WorkingDirectory
    }

    $auditOutput = (&npm audit)

    Write-Output $auditOutput

    if ($LASTEXITCODE -ne 0) {
        $foundVulns = findVulnerablePackagesString $auditOutput

        if (!$foundVulns) {
            Write-Error "Error in npm audit"
        }

        $shouldBreak = checkLevel $foundVulns
        
        if ($shouldBreak -eq $true) {
            Write-Error "Vulnerabilities found"
        }
    }
}

function checkLevel([string]$foundVulns) {
    if ($Level -eq "low") {
        return $foundVulns.Contains("low") -or $foundVulns.Contains("moderate") -or $foundVulns.Contains("high") -or $foundVulns.Contains("critical")
    }
    if ($Level -eq "moderate") {
        return $foundVulns.Contains("moderate") -or $foundVulns.Contains("high") -or $foundVulns.Contains("critical")
    }
    if ($Level -eq "high") {
        return $foundVulns.Contains("high") -or $foundVulns.Contains("critical")
    }
    if ($Level -eq "critical") {
        return $foundVulns.Contains("critical")
    }
}

function findVulnerablePackagesString([string[]]$output) {
    $regex = "(\d+) (low|moderate|high|critical)+"
    return $output -match $regex
}

function Execute() {
    $ErrorActionPreference = "Stop"
 
    try {
        runNpmAudit
    }
    catch {
        Write-Output "$Error"
 
        # Signal failure to MSRM:
        $ErrorActionPreference = "Continue"
        Write-Error "Error: $Error"
        Exit 1
    }
}

$Error.Clear()
Execute