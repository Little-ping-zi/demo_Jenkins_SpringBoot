pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
        jdk 'JDK 17'
    }

    environment {
        HOME = 'C:\\Windows\\System32\\config\\systemprofile'
        MAVEN_OPTS = '-Xmx1024m'
        APP_NAME = 'demo'
        APP_VERSION = '0.0.1-SNAPSHOT'
    }

    options {
        // 保留最近10次构建
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // 添加时间戳到控制台输出
        timestamps()
        // 设置超时时间
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                echo '🔍 Checking out code...'
                git branch: 'main',
                    url: 'git@github.com:Little-ping-zi/demo_Jenkins_SpringBoot.git',
                    credentialsId: 'Github-token'

                script {
                    // Windows 下使用 bat 获取 Git 信息
                    env.GIT_COMMIT_MSG = bat(
                        script: 'git log -1 --pretty=%%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_AUTHOR = bat(
                        script: 'git log -1 --pretty=%%an',
                        returnStdout: true
                    ).trim()
                }
                echo "Commit: ${env.GIT_COMMIT_MSG} by ${env.GIT_COMMIT_AUTHOR}"
            }
        }

        stage('Build') {
            steps {
                echo '🔨 Building application...'
                // Windows 下使用 bat 执行 mvnw.cmd
                bat '''
                    mvnw.cmd clean package -DskipTests
                '''
            }
            post {
                success {
                    echo '✅ Build completed successfully!'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
                failure {
                    echo '❌ Build failed!'
                }
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                bat 'mvnw.cmd test'
            }
            post {
                always {
                    // 发布测试报告（Windows 路径同样适用）
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
                success {
                    echo '✅ All tests passed!'
                }
                failure {
                    echo '❌ Tests failed!'
                }
            }
        }

        stage('Code Quality') {
            steps {
                echo '📊 Analyzing code quality...'
                bat 'mvnw.cmd verify'
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application...'

                script {
                    def remoteHost = 'ubuntu@111.230.13.53'
                    def deployPath = '/home/ubuntu/deployments'
                    def jarFile = "${APP_NAME}-${APP_VERSION}.jar"

                    // Windows 下使用 bat，但 scp/ssh 需要 Windows 支持（如 OpenSSH 或 WSL）
                    // 以下示例假设已安装 OpenSSH for Windows 并加入 PATH
                    bat """
                        echo Deploying ${jarFile} to ${remoteHost}
                        
                        REM 上传 JAR 文件
                        scp target\\${jarFile} ${remoteHost}:${deployPath}/
                        
                        REM 远程部署（ssh 命令在 Windows 下同样可用）
                        ssh -T ${remoteHost} "
                            cd ${deployPath} && 
                            echo 'Stopping old application...' && 
                            pkill -f '${jarFile}' || true && 
                            sleep 2 && 
                            pkill -9 -f '${jarFile}' || true && 
                            echo 'Starting application...' &&
                            nohup java -jar ${jarFile} > app.log 2>&\1 &
                            APP_PID=\$! &&
                            echo \"Application started with PID: \$APP_PID\" &&
                            sleep 5 &&
                            if ps -p \$APP_PID > /dev/null 2>&\1; then
                            echo \"✅ Application process is running (PID: \$APP_PID)\" && 
                            if grep -i 'error\\|exception\\|failed' app.log | tail -5; then 
                                echo '⚠️ Found errors in logs, but application is running' 
                            fi && 
                            exit 0;
                            else
                            echo '❌ Application process is not running' &&
                            tail -n 30 app.log || true && 
                            exit 1; 
                            fi
                        "
                        
                        echo '✅ Deployment completed'
                    """
                }
            }
            post {
                success {
                    echo '✅ Deployment completed successfully!'
                }
                failure {
                    echo '❌ Deployment failed!'
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline completed successfully!'
            // 可以添加通知，例如邮件或 Slack
            // emailext subject: "✅ Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //          body: "The build was successful.",
            //          to: "team@example.com"
        }
        failure {
            echo '💥 Pipeline failed!'
            // emailext subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //          body: "The build failed. Please check the logs.",
            //          to: "team@example.com"
        }
        unstable {
            echo '⚠️ Pipeline is unstable!'
        }
    }
}