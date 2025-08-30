#!/usr/bin/env groovy

/**
 * Jenkins Shared Library Functions
 * Common functions for use across Jenkins pipelines
 */

def buildDockerImage(String imageName, String version, String dockerfilePath = ".") {
    echo "🏗️ Building Docker image: ${imageName}:${version}"
    
    try {
        def image = docker.build("${imageName}:${version}", dockerfilePath)
        echo "✅ Successfully built ${imageName}:${version}"
        return image
    } catch (Exception e) {
        echo "❌ Failed to build ${imageName}:${version}"
        throw e
    }
}

def pushToDockerHub(String imageName, String version, String repository) {
    echo "📤 Pushing to Docker Hub: ${repository}/${imageName}:${version}"
    
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
        def image = docker.image("${imageName}:${version}")
        image.push(version)
        image.push("latest")
        echo "✅ Successfully pushed to Docker Hub"
    }
}

def pushToGHCR(String imageName, String version, String owner) {
    echo "📤 Pushing to GHCR: ghcr.io/${owner}/${imageName}:${version}"
    
    docker.withRegistry('https://ghcr.io', 'github-token') {
        def image = docker.image("${imageName}:${version}")
        image.push("ghcr.io/${owner}/${imageName}:${version}")
        image.push("ghcr.io/${owner}/${imageName}:latest")
        echo "✅ Successfully pushed to GHCR"
    }
}

def runTests(String testCommand = 'pytest tests/ -v') {
    echo "🧪 Running tests..."
    
    try {
        sh testCommand
        echo "✅ Tests passed"
        return true
    } catch (Exception e) {
        echo "❌ Tests failed"
        return false
    }
}

def deployWithAnsible(String playbook, String environment, String version) {
    echo "🚀 Deploying with Ansible..."
    echo "📋 Playbook: ${playbook}"
    echo "🎯 Environment: ${environment}"
    echo "📦 Version: ${version}"
    
    dir('ansible') {
        sh """
            ansible-playbook -i inventory.ini ${playbook} \\
                --extra-vars "environment=${environment} image_version=${version}"
        """
    }
    
    echo "✅ Ansible deployment completed"
}

def deployToKubernetes(String namespace, String imageName, String version) {
    echo "☸️ Deploying to Kubernetes..."
    echo "🏷️ Namespace: ${namespace}"
    echo "🖼️ Image: ${imageName}:${version}"
    
    sh """
        # Update deployment with new image
        kubectl set image deployment/${imageName} ${imageName}=${imageName}:${version} -n ${namespace}
        
        # Wait for rollout to complete
        kubectl rollout status deployment/${imageName} -n ${namespace} --timeout=300s
        
        # Verify deployment
        kubectl get pods -l app=${imageName} -n ${namespace}
    """
    
    echo "✅ Kubernetes deployment completed"
}

def runHealthCheck(String url, int retries = 5, int delay = 10) {
    echo "🏥 Running health check on ${url}"
    
    for (int i = 0; i < retries; i++) {
        try {
            def response = sh(
                script: "curl -f -s -o /dev/null -w '%{http_code}' ${url}",
                returnStdout: true
            ).trim()
            
            if (response == '200') {
                echo "✅ Health check passed (${response})"
                return true
            } else {
                echo "⚠️ Health check returned ${response}, retrying..."
            }
        } catch (Exception e) {
            echo "⚠️ Health check failed, retrying in ${delay} seconds..."
        }
        
        if (i < retries - 1) {
            sleep(delay)
        }
    }
    
    echo "❌ Health check failed after ${retries} attempts"
    return false
}

def notifySlack(String message, String color = 'good') {
    try {
        slackSend(
            channel: '#deployments',
            color: color,
            message: message
        )
    } catch (Exception e) {
        echo "⚠️ Failed to send Slack notification: ${e.message}"
    }
}

def notifyEmail(String subject, String body, String recipients) {
    try {
        emailext(
            subject: subject,
            body: body,
            to: recipients
        )
    } catch (Exception e) {
        echo "⚠️ Failed to send email notification: ${e.message}"
    }
}

def generateVersionNumber(String versionType = 'patch') {
    echo "🏷️ Generating version number (${versionType})"
    
    def currentVersion = sh(
        script: "git describe --tags --abbrev=0 2>/dev/null || echo 'v0.0.0'",
        returnStdout: true
    ).trim().replaceFirst('^v', '')
    
    def versionParts = currentVersion.split('\\.')
    def major = versionParts[0] as Integer
    def minor = versionParts[1] as Integer
    def patch = versionParts[2] as Integer
    
    switch (versionType) {
        case 'major':
            major++
            minor = 0
            patch = 0
            break
        case 'minor':
            minor++
            patch = 0
            break
        case 'patch':
        default:
            patch++
            break
    }
    
    def newVersion = "v${major}.${minor}.${patch}"
    echo "🆕 New version: ${newVersion}"
    return newVersion
}

def createGitTag(String version) {
    echo "🏷️ Creating Git tag: ${version}"
    
    sh """
        git tag ${version}
        git push origin ${version}
    """
    
    echo "✅ Git tag created successfully"
}

def cleanupDockerImages(String imageName, int keepCount = 5) {
    echo "🧹 Cleaning up old Docker images for ${imageName}"
    
    try {
        // Get list of images and remove old ones
        sh """
            # Get all tags for the image, sort by creation date, and remove old ones
            docker images --format "table {{.Repository}}:{{.Tag}}\\t{{.CreatedAt}}" \\
                | grep ${imageName} \\
                | tail -n +${keepCount + 1} \\
                | awk '{print \$1}' \\
                | xargs -r docker rmi
        """
        echo "✅ Docker cleanup completed"
    } catch (Exception e) {
        echo "⚠️ Docker cleanup failed: ${e.message}"
    }
}

def backupDatabase(String environment, String dbName) {
    echo "💾 Creating database backup for ${dbName} in ${environment}"
    
    def timestamp = new Date().format('yyyyMMdd_HHmmss')
    def backupFile = "backup_${dbName}_${environment}_${timestamp}.sql"
    
    switch (environment) {
        case 'local':
            sh "docker-compose exec -T mysql mysqldump -u adminuser -padminpass ${dbName} > ${backupFile}"
            break
        case ~/k8s-.+/:
            def namespace = environment.replace('k8s-', '') + '-microservice-admin-app'
            sh """
                kubectl exec -n ${namespace} deployment/mysql-database -- \\
                    mysqldump -u adminuser -padminpass ${dbName} > ${backupFile}
            """
            break
        default:
            throw new Exception("Unknown environment: ${environment}")
    }
    
    archiveArtifacts artifacts: backupFile
    echo "✅ Database backup created: ${backupFile}"
    return backupFile
}

def rollbackDeployment(String environment, String service, String previousVersion) {
    echo "🔄 Rolling back ${service} to ${previousVersion} in ${environment}"
    
    switch (environment) {
        case ~/k8s-.+/:
            def namespace = environment.replace('k8s-', '') + '-microservice-admin-app'
            sh """
                kubectl rollout undo deployment/${service} -n ${namespace}
                kubectl rollout status deployment/${service} -n ${namespace} --timeout=300s
            """
            break
        default:
            // For other environments, redeploy with previous version
            deployWithAnsible('deploy.yml', environment, previousVersion)
    }
    
    echo "✅ Rollback completed"
}

def runSecurityScan(String imageName, String version) {
    echo "🔒 Running security scan on ${imageName}:${version}"
    
    try {
        // Using Trivy for vulnerability scanning
        sh """
            # Install trivy if not present
            if ! command -v trivy &> /dev/null; then
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
            fi
            
            # Run security scan
            trivy image --format json --output scan-results.json ${imageName}:${version}
            trivy image --format table ${imageName}:${version}
        """
        
        archiveArtifacts artifacts: 'scan-results.json'
        echo "✅ Security scan completed"
        return true
    } catch (Exception e) {
        echo "❌ Security scan failed: ${e.message}"
        return false
    }
}

def performanceTest(String url, int duration = 60, int users = 10) {
    echo "⚡ Running performance test on ${url}"
    echo "👥 Users: ${users}, Duration: ${duration}s"
    
    try {
        sh """
            # Install artillery if not present
            if ! command -v artillery &> /dev/null; then
                npm install -g artillery
            fi
            
            # Create test configuration
            cat > perf-test.yml << EOF
config:
  target: '${url}'
  phases:
    - duration: ${duration}
      arrivalRate: ${users}
scenarios:
  - name: "Load test"
    requests:
      - get:
          url: "/"
      - get:
          url: "/api/health"
EOF
            
            # Run performance test
            artillery run perf-test.yml --output perf-results.json
        """
        
        archiveArtifacts artifacts: 'perf-results.json,perf-test.yml'
        echo "✅ Performance test completed"
        return true
    } catch (Exception e) {
        echo "❌ Performance test failed: ${e.message}"
        return false
    }
}

def generateDeploymentReport(Map deploymentInfo) {
    echo "📊 Generating deployment report"
    
    def timestamp = new Date().format('yyyy-MM-dd HH:mm:ss')
    def report = """
# Deployment Report

## Summary
- **Application**: ${deploymentInfo.appName ?: 'N/A'}
- **Version**: ${deploymentInfo.version ?: 'N/A'}
- **Environment**: ${deploymentInfo.environment ?: 'N/A'}
- **Deployed by**: ${env.BUILD_USER ?: 'Jenkins'}
- **Deployment time**: ${timestamp}
- **Build number**: ${env.BUILD_NUMBER}
- **Git commit**: ${env.GIT_COMMIT ?: 'N/A'}

## Components Deployed
${deploymentInfo.components?.collect { "- ${it}" }?.join('\n') ?: 'N/A'}

## Registry Information
- **Docker Hub**: ${deploymentInfo.dockerHubImages?.join(', ') ?: 'N/A'}
- **GHCR**: ${deploymentInfo.ghcrImages?.join(', ') ?: 'N/A'}

## Health Checks
${deploymentInfo.healthChecks?.collect { check -> 
    "- ${check.name}: ${check.status ? '✅ PASS' : '❌ FAIL'}"
}?.join('\n') ?: 'N/A'}

## Performance Metrics
${deploymentInfo.performanceMetrics ? deploymentInfo.performanceMetrics.collect { metric ->
    "- ${metric.name}: ${metric.value}"
}.join('\n') : 'N/A'}

## Notes
${deploymentInfo.notes ?: 'None'}

---
Generated by Jenkins Pipeline at ${timestamp}
"""
    
    writeFile file: 'deployment-report.md', text: report
    archiveArtifacts artifacts: 'deployment-report.md'
    
    echo "✅ Deployment report generated"
    return report
}

// Return this script for use in other pipelines
return this
