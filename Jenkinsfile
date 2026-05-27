pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
        jdk 'JDK 17'
    }

    environment {
        MAVEN_OPTS = '-Xmx1024m'
        APP_NAME = 'demo'
        APP_VERSION = '0.0.1-SNAPSHOT'
        // 部署目录：宿主机上的绝对路径（Jenkins 容器通过挂载卷访问）
        DEPLOY_PATH = '/opt/deployments'
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
                    url: 'https://github.com/Little-ping-zi/demo_Jenkins_SpringBoot.git',
                    credentialsId: 'Github-token'

                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                }
                echo "Commit: ${env.GIT_COMMIT_MSG} by ${env.GIT_COMMIT_AUTHOR}"
            }
        }

        stage('Build') {
            steps {
                echo '🔨 Building application...'
                sh '''
                    chmod +x mvnw
                    ./mvnw clean package -DskipTests
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
                sh './mvnw test'
            }
            post {
                always {
                    // 发布测试报告
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
                sh './mvnw verify'
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application to Ubuntu server...'

                script {
                    def jarFile = "${APP_NAME}-${APP_VERSION}.jar"
                    
                    sh """
                        echo 'Deploying ${jarFile} to ${DEPLOY_PATH}'

                        # 创建部署目录（如果不存在）
                        sudo mkdir -p ${DEPLOY_PATH}
                        sudo chown -R 1000:1000 ${DEPLOY_PATH}

                        # 复制 JAR 文件到部署目录
                        cp target/${jarFile} ${DEPLOY_PATH}/

                        cd ${DEPLOY_PATH}

                        # 停止旧应用
                        echo "Stopping old application..."
                        sudo pkill -f "${jarFile}" || true
                        sleep 2

                        # 再次确认进程已停止
                        sudo pkill -9 -f "${jarFile}" || true
                        sleep 1

                        # 启动新应用
                        echo "Starting application..."
                        sudo nohup java -jar ${jarFile} > app.log 2>&1 &
                        APP_PID=\$!

                        echo "Application started with PID: \${APP_PID}"
                        sleep 5

                        # 验证进程是否在运行
                        if ps -p \${APP_PID} > /dev/null 2>&1; then
                            echo "✅ Application process is running (PID: \${APP_PID})"

                            # 检查日志中是否有错误
                            if grep -i "error\\|exception\\|failed" app.log | tail -5; then
                                echo "⚠️ Found errors in logs, but application is running"
                            fi

                            echo "✅ Application deployed successfully on Ubuntu server"
                            exit 0
                        else
                            echo "❌ Application process is not running"
                            echo "Last 30 lines of log:"
                            tail -n 30 app.log || true
                            exit 1
                        fi
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