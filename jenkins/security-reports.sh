#!/bin/bash
set -e

# Script to generate security reports from SonarQube and Trivy

# Parameters
SONAR_URL=${SONAR_URL:-"http://sonarqube:9000"}
SONAR_TOKEN=${SONAR_TOKEN:-""}
PROJECT_KEY=${PROJECT_KEY:-"sample-app"}
TRIVY_REPORT=${TRIVY_REPORT:-"trivy-results.json"}
ZAP_REPORT=${ZAP_REPORT:-"zap-results.json"}
OUTPUT_DIR=${OUTPUT_DIR:-"/reports/security"}
IMAGE_NAME=${IMAGE_NAME:-"myapp:latest"}
APP_URL=${APP_URL:-"http://sample-app:8080"}

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

echo "Generating security reports..."
echo "================================="
echo "SonarQube URL: ${SONAR_URL}"
echo "Project Key: ${PROJECT_KEY}"
echo "Output Directory: ${OUTPUT_DIR}"
echo "================================="

# Generate SonarQube security report
echo "Generating SonarQube security report..."
if [ -z "${SONAR_TOKEN}" ]; then
  echo "SONAR_TOKEN is not set. SonarQube report generation will be skipped."
else
  # Get issues
  curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/issues/search?componentKeys=${PROJECT_KEY}&types=VULNERABILITY&ps=500" > ${OUTPUT_DIR}/sonarqube-vulnerabilities.json
  
  # Get hotspots
  curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/hotspots/search?projectKey=${PROJECT_KEY}&ps=500" > ${OUTPUT_DIR}/sonarqube-hotspots.json
  
  # Generate HTML report
  cat > ${OUTPUT_DIR}/sonarqube-security-report.html << EOF
  <!DOCTYPE html>
  <html>
  <head>
    <title>SonarQube Security Report - ${PROJECT_KEY}</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; }
      h1 { color: #333; }
      h2 { color: #666; margin-top: 30px; }
      table { border-collapse: collapse; width: 100%; margin-top: 20px; }
      th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
      th { background-color: #f2f2f2; }
      tr:nth-child(even) { background-color: #f9f9f9; }
      .critical { background-color: #ffdddd; }
      .high { background-color: #ffffcc; }
      .medium { background-color: #e6f3ff; }
      .summary { margin: 20px 0; padding: 15px; background-color: #f2f2f2; border-radius: 5px; }
    </style>
  </head>
  <body>
    <h1>SonarQube Security Report</h1>
    <div class="summary">
      <p><strong>Project:</strong> ${PROJECT_KEY}</p>
      <p><strong>Date:</strong> $(date)</p>
      <p><strong>SonarQube URL:</strong> <a href="${SONAR_URL}/dashboard?id=${PROJECT_KEY}" target="_blank">${SONAR_URL}/dashboard?id=${PROJECT_KEY}</a></p>
    </div>
    
    <h2>Security Vulnerabilities</h2>
    <p>This section shows security vulnerabilities detected by SonarQube.</p>
    <div id="vulnerabilities">Loading vulnerabilities...</div>
    
    <h2>Security Hotspots</h2>
    <p>This section shows security hotspots that need review.</p>
    <div id="hotspots">Loading hotspots...</div>
    
    <script>
      // Parse vulnerabilities
      fetch('sonarqube-vulnerabilities.json')
        .then(response => response.json())
        .then(data => {
          const vulnDiv = document.getElementById('vulnerabilities');
          if (data.issues && data.issues.length > 0) {
            let html = '<table>';
            html += '<tr><th>Severity</th><th>Component</th><th>Description</th><th>Status</th></tr>';
            
            data.issues.forEach(issue => {
              html += '<tr class="' + issue.severity.toLowerCase() + '">';
              html += '<td>' + issue.severity + '</td>';
              html += '<td>' + issue.component + '</td>';
              html += '<td>' + issue.message + '</td>';
              html += '<td>' + issue.status + '</td>';
              html += '</tr>';
            });
            
            html += '</table>';
            vulnDiv.innerHTML = html;
          } else {
            vulnDiv.innerHTML = '<p>No vulnerabilities found.</p>';
          }
        })
        .catch(error => {
          document.getElementById('vulnerabilities').innerHTML = '<p>Error loading vulnerabilities: ' + error + '</p>';
        });
      
      // Parse hotspots
      fetch('sonarqube-hotspots.json')
        .then(response => response.json())
        .then(data => {
          const hotspotsDiv = document.getElementById('hotspots');
          if (data.hotspots && data.hotspots.length > 0) {
            let html = '<table>';
            html += '<tr><th>Risk</th><th>Component</th><th>Description</th><th>Status</th></tr>';
            
            data.hotspots.forEach(hotspot => {
              html += '<tr class="' + hotspot.vulnerabilityProbability.toLowerCase() + '">';
              html += '<td>' + hotspot.vulnerabilityProbability + '</td>';
              html += '<td>' + hotspot.component + '</td>';
              html += '<td>' + hotspot.message + '</td>';
              html += '<td>' + hotspot.status + '</td>';
              html += '</tr>';
            });
            
            html += '</table>';
            hotspotsDiv.innerHTML = html;
          } else {
            hotspotsDiv.innerHTML = '<p>No hotspots found.</p>';
          }
        })
        .catch(error => {
          document.getElementById('hotspots').innerHTML = '<p>Error loading hotspots: ' + error + '</p>';
        });
    </script>
  </body>
  </html>
EOF

  echo "SonarQube security report generated at ${OUTPUT_DIR}/sonarqube-security-report.html"
fi

# Generate Trivy security report
echo "Generating Trivy security report..."
if [ -f "${TRIVY_REPORT}" ]; then
  echo "Using existing Trivy report at ${TRIVY_REPORT}"
else
  echo "Running Trivy scan on ${IMAGE_NAME}..."
  trivy image --format json --output ${OUTPUT_DIR}/trivy-results.json ${IMAGE_NAME}
  TRIVY_REPORT="${OUTPUT_DIR}/trivy-results.json"
fi

# Generate HTML report for Trivy
cat > ${OUTPUT_DIR}/trivy-security-report.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Trivy Vulnerability Report - ${IMAGE_NAME}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    h2 { color: #666; margin-top: 30px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .CRITICAL { background-color: #ffdddd; }
    .HIGH { background-color: #ffffcc; }
    .MEDIUM { background-color: #e6f3ff; }
    .LOW { background-color: #e8f5e9; }
    .summary { margin: 20px 0; padding: 15px; background-color: #f2f2f2; border-radius: 5px; }
    .stats { display: flex; justify-content: space-around; margin: 20px 0; }
    .stat-box { padding: 15px; border-radius: 5px; width: 18%; text-align: center; }
    .critical-box { background-color: #ffdddd; }
    .high-box { background-color: #ffffcc; }
    .medium-box { background-color: #e6f3ff; }
    .low-box { background-color: #e8f5e9; }
    .unknown-box { background-color: #f2f2f2; }
  </style>
</head>
<body>
  <h1>Trivy Vulnerability Report</h1>
  <div class="summary">
    <p><strong>Image:</strong> ${IMAGE_NAME}</p>
    <p><strong>Date:</strong> $(date)</p>
  </div>
  
  <div id="statistics" class="stats">
    <div class="stat-box critical-box">
      <h3>CRITICAL</h3>
      <p id="critical-count">0</p>
    </div>
    <div class="stat-box high-box">
      <h3>HIGH</h3>
      <p id="high-count">0</p>
    </div>
    <div class="stat-box medium-box">
      <h3>MEDIUM</h3>
      <p id="medium-count">0</p>
    </div>
    <div class="stat-box low-box">
      <h3>LOW</h3>
      <p id="low-count">0</p>
    </div>
    <div class="stat-box unknown-box">
      <h3>UNKNOWN</h3>
      <p id="unknown-count">0</p>
    </div>
  </div>
  
  <h2>Vulnerabilities</h2>
  <div id="vulnerabilities">Loading vulnerabilities...</div>
  
  <script>
    // Parse Trivy results
    fetch('trivy-results.json')
      .then(response => response.json())
      .then(data => {
        const vulnDiv = document.getElementById('vulnerabilities');
        let criticalCount = 0;
        let highCount = 0;
        let mediumCount = 0;
        let lowCount = 0;
        let unknownCount = 0;
        
        if (data.Results) {
          let html = '';
          
          data.Results.forEach(result => {
            if (result.Vulnerabilities && result.Vulnerabilities.length > 0) {
              html += '<h3>Target: ' + result.Target + '</h3>';
              html += '<table>';
              html += '<tr><th>Severity</th><th>VulnerabilityID</th><th>Package</th><th>Installed Version</th><th>Fixed Version</th><th>Description</th></tr>';
              
              result.Vulnerabilities.forEach(vuln => {
                html += '<tr class="' + vuln.Severity + '">';
                html += '<td>' + vuln.Severity + '</td>';
                html += '<td>' + vuln.VulnerabilityID + '</td>';
                html += '<td>' + vuln.PkgName + '</td>';
                html += '<td>' + vuln.InstalledVersion + '</td>';
                html += '<td>' + (vuln.FixedVersion || 'N/A') + '</td>';
                html += '<td>' + vuln.Title + '</td>';
                html += '</tr>';
                
                // Count by severity
                if (vuln.Severity === 'CRITICAL') criticalCount++;
                else if (vuln.Severity === 'HIGH') highCount++;
                else if (vuln.Severity === 'MEDIUM') mediumCount++;
                else if (vuln.Severity === 'LOW') lowCount++;
                else unknownCount++;
              });
              
              html += '</table>';
            }
          });
          
          if (html) {
            vulnDiv.innerHTML = html;
          } else {
            vulnDiv.innerHTML = '<p>No vulnerabilities found.</p>';
          }
          
          // Update statistics
          document.getElementById('critical-count').textContent = criticalCount;
          document.getElementById('high-count').textContent = highCount;
          document.getElementById('medium-count').textContent = mediumCount;
          document.getElementById('low-count').textContent = lowCount;
          document.getElementById('unknown-count').textContent = unknownCount;
        } else {
          vulnDiv.innerHTML = '<p>No vulnerability data found.</p>';
        }
      })
      .catch(error => {
        document.getElementById('vulnerabilities').innerHTML = '<p>Error loading vulnerabilities: ' + error + '</p>';
      });
  </script>
</body>
</html>
EOF

echo "Trivy security report generated at ${OUTPUT_DIR}/trivy-security-report.html"

# Generate ZAP security report
echo "Generating ZAP security report..."
if [ -f "${OUTPUT_DIR}/${ZAP_REPORT}" ]; then
  echo "Using existing ZAP report at ${OUTPUT_DIR}/${ZAP_REPORT}"
  
  # Generate HTML report for ZAP
  cat > ${OUTPUT_DIR}/zap-security-report.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>OWASP ZAP Security Report - ${APP_URL}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    h2 { color: #666; margin-top: 30px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .High { background-color: #ffdddd; }
    .Medium { background-color: #ffffcc; }
    .Low { background-color: #e6f3ff; }
    .Informational { background-color: #e8f5e9; }
    .summary { margin: 20px 0; padding: 15px; background-color: #f2f2f2; border-radius: 5px; }
    .stats { display: flex; justify-content: space-around; margin: 20px 0; }
    .stat-box { padding: 15px; border-radius: 5px; width: 18%; text-align: center; }
    .high-box { background-color: #ffdddd; }
    .medium-box { background-color: #ffffcc; }
    .low-box { background-color: #e6f3ff; }
    .info-box { background-color: #e8f5e9; }
  </style>
</head>
<body>
  <h1>OWASP ZAP Security Report</h1>
  <div class="summary">
    <p><strong>Target:</strong> ${APP_URL}</p>
    <p><strong>Date:</strong> $(date)</p>
  </div>
  
  <div id="statistics" class="stats">
    <div class="stat-box high-box">
      <h3>HIGH</h3>
      <p id="high-count">0</p>
    </div>
    <div class="stat-box medium-box">
      <h3>MEDIUM</h3>
      <p id="medium-count">0</p>
    </div>
    <div class="stat-box low-box">
      <h3>LOW</h3>
      <p id="low-count">0</p>
    </div>
    <div class="stat-box info-box">
      <h3>INFO</h3>
      <p id="info-count">0</p>
    </div>
  </div>
  
  <h2>Alerts</h2>
  <div id="alerts">Loading alerts...</div>
  
  <script>
    // Parse ZAP results
    fetch('${ZAP_REPORT}')
      .then(response => response.json())
      .then(data => {
        const alertsDiv = document.getElementById('alerts');
        let highCount = 0;
        let mediumCount = 0;
        let lowCount = 0;
        let infoCount = 0;
        
        if (data.site && data.site.length > 0 && data.site[0].alerts) {
          const alerts = data.site[0].alerts;
          let html = '<table>';
          html += '<tr><th>Risk Level</th><th>Alert</th><th>CWE ID</th><th>URL</th><th>Description</th><th>Solution</th></tr>';
          
          alerts.forEach(alert => {
            // Count by risk level
            if (alert.riskdesc.startsWith('High')) highCount++;
            else if (alert.riskdesc.startsWith('Medium')) mediumCount++;
            else if (alert.riskdesc.startsWith('Low')) lowCount++;
            else infoCount++;
            
            // Get the risk class for styling
            let riskClass = 'Informational';
            if (alert.riskdesc.startsWith('High')) riskClass = 'High';
            else if (alert.riskdesc.startsWith('Medium')) riskClass = 'Medium';
            else if (alert.riskdesc.startsWith('Low')) riskClass = 'Low';
            
            html += '<tr class="' + riskClass + '">';
            html += '<td>' + alert.riskdesc + '</td>';
            html += '<td>' + alert.name + '</td>';
            html += '<td>' + (alert.cweid || 'N/A') + '</td>';
            
            // Get first instance URL or 'N/A'
            const firstInstanceUrl = alert.instances && alert.instances.length > 0 ? 
                                     alert.instances[0].uri : 'N/A';
            html += '<td>' + firstInstanceUrl + '</td>';
            
            html += '<td>' + alert.desc + '</td>';
            html += '<td>' + alert.solution + '</td>';
            html += '</tr>';
          });
          
          html += '</table>';
          alertsDiv.innerHTML = html;
          
          // Update statistics
          document.getElementById('high-count').textContent = highCount;
          document.getElementById('medium-count').textContent = mediumCount;
          document.getElementById('low-count').textContent = lowCount;
          document.getElementById('info-count').textContent = infoCount;
        } else {
          alertsDiv.innerHTML = '<p>No alerts found or unable to parse ZAP results.</p>';
        }
      })
      .catch(error => {
        document.getElementById('alerts').innerHTML = '<p>Error loading ZAP results: ' + error + '</p>';
      });
  </script>
</body>
</html>
EOF

  echo "ZAP security report generated at ${OUTPUT_DIR}/zap-security-report.html"
else
  echo "ZAP report not found at ${OUTPUT_DIR}/${ZAP_REPORT}. Skipping ZAP report generation."
fi

# Generate combined report
cat > ${OUTPUT_DIR}/combined-security-report.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Combined Security Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    .tabs { display: flex; margin-bottom: 20px; }
    .tab {
      padding: 10px 20px;
      background-color: #f2f2f2;
      cursor: pointer;
      margin-right: 5px;
      border-radius: 5px 5px 0 0;
    }
    .tab.active {
      background-color: #333;
      color: white;
    }
    .tab-content {
      display: none;
      border: 1px solid #ddd;
      padding: 20px;
    }
    .tab-content.active {
      display: block;
    }
    iframe {
      width: 100%;
      height: 800px;
      border: none;
    }
  </style>
</head>
<body>
  <h1>Combined Security Report</h1>
  
  <div class="tabs">
    <div class="tab active" onclick="openTab('sonarqube')">SonarQube Security Report</div>
    <div class="tab" onclick="openTab('trivy')">Trivy Vulnerability Report</div>
    <div class="tab" onclick="openTab('zap')">ZAP Security Report</div>
  </div>
  
  <div id="sonarqube" class="tab-content active">
    <iframe src="sonarqube-security-report.html"></iframe>
  </div>
  
  <div id="trivy" class="tab-content">
    <iframe src="trivy-security-report.html"></iframe>
  </div>
  
  <div id="zap" class="tab-content">
    <iframe src="zap-security-report.html"></iframe>
  </div>
  
  <script>
    function openTab(tabName) {
      const tabs = document.getElementsByClassName('tab');
      const tabContents = document.getElementsByClassName('tab-content');
      
      // Hide all tab contents
      for (let i = 0; i < tabContents.length; i++) {
        tabContents[i].classList.remove('active');
      }
      
      // Remove active class from all tabs
      for (let i = 0; i < tabs.length; i++) {
        tabs[i].classList.remove('active');
      }
      
      // Show the selected tab content
      document.getElementById(tabName).classList.add('active');
      
      // Add active class to the clicked tab
      event.currentTarget.classList.add('active');
    }
  </script>
</body>
</html>
EOF

echo "Combined security report generated at ${OUTPUT_DIR}/combined-security-report.html"
echo "Security reports generation completed!" 