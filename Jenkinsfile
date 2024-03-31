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
        TARGET_BRANCH_NAME = 'jenkins'
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
                    IMAGE_NAME = "${env.PROJECT_NAME.toLowerCase()}:${env.BUILD_NUMBER}"
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
                    CONTAINER_NAME = "${env.PROJECT_NAME.toLowerCase()}-container"
                    // Attempt to escape the dollar sign correctly for Groovy and shell
                    def command = "docker ps -aq -f name=^${CONTAINER_NAME}\\\$"
                    def containerExists = sh(script: command, returnStdout: true).trim()
                    if (containerExists) {
                        sh """
                        docker stop ${CONTAINER_NAME}
                        sleep 60
                        docker rm ${CONTAINER_NAME}
                        """
                    }
                }
            }
        }
        stage('Run Application') {
            steps {
                script {
                    CONTAINER_NAME = "${env.PROJECT_NAME.toLowerCase()}-container"
                }
                sh "docker run -d -p 5002:80 -p 5003:443 --name ${CONTAINER_NAME} ${IMAGE_NAME}"
            }
        }
    }
    post {
        always {
        script {
            if (fileExists("${env.LOGS_DIR}/build.log")) {
                // Prepare the message
                def message = (currentBuild.result == 'SUCCESS') ? "Build Warnings for ${env.PROJECT_NAME}:${env.BUILD_NUMBER}" : "Build failed Errors for ${env.PROJECT_NAME}:${env.BUILD_NUMBER}"
                // Command to upload the file to Slack
                sh "curl -F file=@${env.LOGS_DIR}/build.log -F 'initial_comment=${message}' -F channels=#egpc-reports -H 'Authorization: Bearer xoxb-eKHiVnprLL0CJL607LNu4gs2' https://slack.com/api/files.upload"
            }
        }
    }
        success {
            slackSend(channel: '#egpc-reports', message: "SUCCESS: The build of ${env.PROJECT_NAME}:${env.BUILD_NUMBER} on branch ${env.BRANCH_NAME} succeeded. http://172.20.21.78:5002/")
            script {
                // Prepare a success message
                def message = "Build SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}  - ${env.BRANCH_NAME} - http://172.20.21.78:5002/"
                // Send the message to Microsoft Teams
                sh "curl -H 'Content-Type: application/json' -d '{\"text\": \"${message}\"}' https://onspecengineeringco.webhook.office.com/webhookb2/03b78d4a-d328-4727-8aad-34f4f0f7ae7a@eb724109-80c2-4d15-a49e-97c78636f620/JenkinsCI/a91a80391a284252935875bbad7e1b41/81c2c87b-b9ec-4978-a6a8-b013d83916fc"
            }
        }
        failure {
            slackSend(channel: '#egpc-reports', message: "FAILURE: The build of ${env.PROJECT_NAME}:${env.BUILD_NUMBER} on branch ${env.BRANCH_NAME} failed.")
            script {
                // Prepare a failure message
                def message = "Build FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL} - ${env.BRANCH_NAME}"
                // Send the message to Microsoft Teams
                sh "curl -H 'Content-Type: application/json' -d '{\"text\": \"${message}\"}' https://onspecengineeringco.webhook.office.com/webhookb2/03b78d4a-d328-4727-8aad-34f4f0f7ae7a@eb724109-80c2-4d15-a49e-97c78636f620/JenkinsCI/a91a80391a284252935875bbad7e1b41/81c2c87b-b9ec-4978-a6a8-b013d83916fc"
            }
        }
    }
}