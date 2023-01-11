Param
(
    [Parameter()]
    [string]$WorkingDirectory,

    [ValidateSet("low", "moderate", "high", "critical")]
    [Parameter()]
    [string]$Level = "high"
)

function runDotnetListPackage() {
    if ($WorkingDirectory) {
        Set-Location $WorkingDirectory
    }

    $auditOutput = (&dotnet list package --vulnerable)

    Write-Output $auditOutput

    $foundVulns = findVulnerablePackagesString $auditOutput

    $shouldBreak = checkLevel $foundVulns

    if ($shouldBreak -eq $true) {
        Write-Error "Vulnerabilities found"
    }
}

function checkLevel([string]$foundVulns) {
    if ($Level -eq "low") {
        return $foundVulns.Contains("Low") -or $foundVulns.Contains("Moderate") -or $foundVulns.Contains("High") -or $foundVulns.Contains("Critical")
    }
    if ($Level -eq "moderate") {
        return $foundVulns.Contains("Moderate") -or $foundVulns.Contains("High") -or $foundVulns.Contains("Critical")
    }
    if ($Level -eq "high") {
        return $foundVulns.Contains("High") -or $foundVulns.Contains("Critical")
    }
    if ($Level -eq "critical") {
        return $foundVulns.Contains("Critical")
    }
}

function findVulnerablePackagesString([string[]]$output) {
    $regex = ".*(Low|Moderate|High|Critical)+"
    return $output -match $regex
}

function Execute() {
    $ErrorActionPreference = "Stop"

    try {
        runDotnetListPackage
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
