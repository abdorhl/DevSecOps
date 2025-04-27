# PowerShell script to generate security reports locally
param (
    [string]$SonarQubeUrl = "http://localhost:9000",
    [string]$SonarQubeToken = "",
    [string]$ProjectKey = "sample-app",
    [string]$ImageName = "myapp:latest",
    [string]$AppUrl = "http://localhost:8080",
    [switch]$RunZapScan = $false,
    [string]$OutputDir = "./reports/security"
)

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
}

Write-Output "Generating security reports..."
Write-Output "================================="
Write-Output "SonarQube URL: $SonarQubeUrl"
Write-Output "Project Key: $ProjectKey"
Write-Output "Image Name: $ImageName"
Write-Output "Application URL: $AppUrl"
Write-Output "Output Directory: $OutputDir"
Write-Output "Run ZAP Scan: $RunZapScan"
Write-Output "================================="

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Output "Docker is running."
}
catch {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit 1
}

# Generate Trivy report
Write-Output "Generating Trivy security report..."
$trivyResultsPath = Join-Path -Path $OutputDir -ChildPath "trivy-results.json"

try {
    docker run --rm -v ${PWD}:/workdir -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --format json --output /workdir/$trivyResultsPath $ImageName
    Write-Output "Trivy scan completed. Results saved to $trivyResultsPath"
}
catch {
    Write-Error "Failed to run Trivy scan: $_"
    # Create an empty results file for the HTML generation
    Set-Content -Path $trivyResultsPath -Value '{"Results": []}'
}

# Generate SonarQube report if token is provided
if (-not [string]::IsNullOrEmpty($SonarQubeToken)) {
    Write-Output "Generating SonarQube security report..."
    
    # Get vulnerabilities
    $sonarVulnerabilitiesPath = Join-Path -Path $OutputDir -ChildPath "sonarqube-vulnerabilities.json"
    Invoke-RestMethod -Uri "$SonarQubeUrl/api/issues/search?componentKeys=$ProjectKey&types=VULNERABILITY&ps=500" -Headers @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeToken):")))"; "Content-Type" = "application/json"} -Method Get -OutFile $sonarVulnerabilitiesPath
    
    # Get hotspots
    $sonarHotspotsPath = Join-Path -Path $OutputDir -ChildPath "sonarqube-hotspots.json"
    Invoke-RestMethod -Uri "$SonarQubeUrl/api/hotspots/search?projectKey=$ProjectKey&ps=500" -Headers @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeToken):")))"; "Content-Type" = "application/json"} -Method Get -OutFile $sonarHotspotsPath
    
    Write-Output "SonarQube data fetched."
}
else {
    Write-Output "SonarQube token not provided. Skipping SonarQube report generation."
    # Create empty files for the HTML generation
    Set-Content -Path (Join-Path -Path $OutputDir -ChildPath "sonarqube-vulnerabilities.json") -Value '{"issues": []}'
    Set-Content -Path (Join-Path -Path $OutputDir -ChildPath "sonarqube-hotspots.json") -Value '{"hotspots": []}'
}

# Generate ZAP report if requested
$zapResultsPath = Join-Path -Path $OutputDir -ChildPath "zap-results.json"
if ($RunZapScan) {
    Write-Output "Generating ZAP security report..."
    
    try {
        # Run ZAP scan using Docker
        Write-Output "Running ZAP scan against $AppUrl..."
        docker run --rm -v ${PWD}:/zap/wrk owasp/zap2docker-stable zap-baseline.py -t $AppUrl -g gen.conf -r /zap/wrk/$OutputDir/zap-report.html -J /zap/wrk/$zapResultsPath -I
        Move-Item -Path gen.conf -Destination $OutputDir -Force -ErrorAction SilentlyContinue
        Write-Output "ZAP scan completed. Results saved to $zapResultsPath"
    }
    catch {
        Write-Error "Failed to run ZAP scan: $_"
        # Create an empty results file for the HTML generation
        Set-Content -Path $zapResultsPath -Value '{"site": [{"alerts": []}]}'
    }
}
else {
    Write-Output "ZAP scan not requested. Skipping ZAP scan."
    # Create an empty file for the HTML generation if it doesn't exist
    if (-not (Test-Path -Path $zapResultsPath)) {
        Set-Content -Path $zapResultsPath -Value '{"site": [{"alerts": []}]}'
    }
}

# Generate HTML reports using Docker with a lightweight image
Write-Output "Generating HTML reports..."

# Using Docker with a custom HTML generator
$scriptPath = "./jenkins/security-reports.sh"
if (Test-Path -Path $scriptPath) {
    docker run --rm -v ${PWD}:/workdir -w /workdir -e OUTPUT_DIR=/workdir/$OutputDir -e PROJECT_KEY=$ProjectKey -e SONAR_URL=$SonarQubeUrl -e APP_URL=$AppUrl -e IMAGE_NAME=$ImageName -e TRIVY_REPORT=/workdir/$trivyResultsPath -e ZAP_REPORT=zap-results.json curlimages/curl:latest sh -c "chmod +x /workdir/jenkins/security-reports.sh && /workdir/jenkins/security-reports.sh"
    Write-Output "HTML reports generated successfully."
}
else {
    Write-Error "Security reports script not found at $scriptPath"
}

Write-Output "Security reports generation completed!"
Write-Output "Reports are available in the $OutputDir directory."
Write-Output "Open combined-security-report.html to view all reports." 