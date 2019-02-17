Param
(
    [Parameter()]
    [string]$csprojFile
)

function runDevaudit() {
    $auditOutput = (&devaudit.exe netcore -n -f $csprojFile ci)

    Write-Output $auditOutput

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Vulnerabilities found"
    }
}

function Execute() {
    $ErrorActionPreference = "Stop"
 
    try {
        runDevaudit
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