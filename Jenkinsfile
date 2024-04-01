pipeline {
    agent any
    triggers {
        pollSCM('H/2 * * * *')
    }
    environment {
        BUILD_DIR = '/home/sysadmin/Builds/Scheduling-Integration-Solution'
        LOGS_DIR = '/home/sysadmin/Logs'
        PROJECT_NAME = 'Scheduling-Integration-Solution'
        DOTNET_CLI_HOME = '/home/sysadmin'
        TARGET_BRANCH_NAME = 'master-SCADA'
        PORTS_HTTP = '33014'
        PORTS_HTTPS = '33015'
    }
    stages {
        stage('Conditional Execution') {
            steps {
                script {
                    if (env.BRANCH_NAME != TARGET_BRANCH_NAME) {
                        error("This pipeline is not configured to run for ${REPO_NAME}. Stopping execution.")
                    } 
                }
            }
        }
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Restore Dependencies') {
            steps {
                sh "export DOTNET_CLI_HOME=${env.DOTNET_CLI_HOME} && dotnet restore"
            }
        }
        stage('Prepare Directories') {
            steps {
                sh """
                  rm -rf ${env.BUILD_DIR}/*
                  mkdir -p ${env.LOGS_DIR}
                """
            }
        }
        stage('Build') {
            steps {
                sh "dotnet publish -c Release -o ${env.BUILD_DIR} --self-contained --runtime linux-x64 > ${env.LOGS_DIR}/Scheduling-Integration-Solution.log 2>&1"
            }
        }
        stage('Dockerize') {
            steps {
                script {
                    IMAGE_NAME = "${env.PROJECT_NAME.toLowerCase()}_${env.TARGET_BRANCH_NAME.toLowerCase()}:${env.BUILD_NUMBER}"
                }
                sh """
                  docker image prune -a -f
                  cp Dockerfile ${env.BUILD_DIR}/Dockerfile
                  cd ${env.BUILD_DIR}
                  docker build -t ${IMAGE_NAME} .
                """
            }
        }
        stage('Cleanup Containers') {
            steps {
                script {
                    CONTAINER_NAME = "${env.PROJECT_NAME.toLowerCase()}-${env.TARGET_BRANCH_NAME.toLowerCase()}-container"
                    def command = "docker ps -aq -f name=^${CONTAINER_NAME}\\\$"
                    def containerExists = sh(script: command, returnStdout: true).trim()
                    if (containerExists) {
                        sh """
                        docker stop ${CONTAINER_NAME}
                        sleep 10
                        docker rm -f ${CONTAINER_NAME}
                        """
                    }
                }
            }
        }
        stage('Run Application') {
            steps {
                script {
                    CONTAINER_NAME = "${env.PROJECT_NAME.toLowerCase()}-${env.TARGET_BRANCH_NAME.toLowerCase()}-container"
                }
                sh "docker run -d -p ${PORTS_HTTP}:80 -p ${PORTS_HTTPS}:443 --name ${CONTAINER_NAME} ${IMAGE_NAME}"
            }
        }
    }
    post {
        always {
        script {
            if (fileExists("${env.LOGS_DIR}/Scheduling-Integration-Solution.log")) {
                // Prepare the message
                def message = (currentBuild.result == 'SUCCESS') ? "Build Warnings for ${env.PROJECT_NAME}_${env.TARGET_BRANCH_NAME.toLowerCase()}:${env.BUILD_NUMBER}" : "Build failed Errors for ${env.PROJECT_NAME}_${env.TARGET_BRANCH_NAME.toLowerCase()}:${env.BUILD_NUMBER}"
                // Command to upload the file to Slack
                sh "curl -F file=@${env.LOGS_DIR}/Scheduling-Integration-Solution.log -F 'initial_comment=${message}' -F channels=scheduling-integration-solution -H 'Authorization: Bearer xoxb-2103621248087-6831857532868-v1sPfcqA4OwBqoutmvEhOSqd' https://slack.com/api/files.upload"
            }
        }
        }
        success {
            slackSend(channel: '#scheduling-integration-solution', message: "SUCCESS: The build of ${env.PROJECT_NAME}:${env.BUILD_NUMBER} on branch ${env.TARGET_BRANCH_NAME} succeeded. http://172.20.21.78:${PORTS_HTTP}/")
            script {
                // Prepare a success message
                def message = "Build SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}  - ${env.TARGET_BRANCH_NAME} - http://172.20.21.78:${PORTS_HTTP}/"
                // Send the message to Microsoft Teams
                sh "curl -H 'Content-Type: application/json' -d '{\"text\": \"${message}\"}' https://onspecengineeringco.webhook.office.com/webhookb2/0bee4405-6d57-4401-b982-5b0fa13e8355@eb724109-80c2-4d15-a49e-97c78636f620/JenkinsCI/196abfcad7204c71bd93ac0a2c8670a2/81c2c87b-b9ec-4978-a6a8-b013d83916fc"
            }
        }
        failure {
            slackSend(channel: '#scheduling-integration-solution', message: "FAILURE: The build of ${env.PROJECT_NAME}:${env.BUILD_NUMBER} on branch ${env.TARGET_BRANCH_NAME} failed.")
            script {
                // Prepare a failure message
                def message = "Build FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL} - ${env.TARGET_BRANCH_NAME}"
                // Send the message to Microsoft Teams
                sh "curl -H 'Content-Type: application/json' -d '{\"text\": \"${message}\"}' https://onspecengineeringco.webhook.office.com/webhookb2/0bee4405-6d57-4401-b982-5b0fa13e8355@eb724109-80c2-4d15-a49e-97c78636f620/JenkinsCI/196abfcad7204c71bd93ac0a2c8670a2/81c2c87b-b9ec-4978-a6a8-b013d83916fc"
            }
        }
    }
}