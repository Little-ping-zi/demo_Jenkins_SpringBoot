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
                        mkdir -p ${DEPLOY_PATH}

                        # 复制 JAR 到宿主机挂载目录（由 systemd 在宿主机上启动，避免被 Jenkins 容器杀掉）
                        cp target/${jarFile} ${DEPLOY_PATH}/

                        # 停止 Jenkins 容器内可能残留的旧进程（宿主机由 systemd 负责停服，勿用 pkill）
                        pkill -f "${jarFile}" || true

                        # 触发宿主机 systemd：先停旧应用/孤儿进程，再启动新实例
                        rm -f ${DEPLOY_PATH}/restart.flag
                        touch ${DEPLOY_PATH}/restart.flag

                        echo 'Waiting for application to start on host...'
                        i=1
                        while [ \$i -le 30 ]; do
                            if grep -q "Started DemoApplication" ${DEPLOY_PATH}/app.log 2>/dev/null; then
                                echo "✅ Application started on host"
                                exit 0
                            fi
                            sleep 2
                            i=\$((i + 1))
                        done

                        echo "❌ Application did not start within 60 seconds"
                        echo "Last 30 lines of log:"
                        tail -n 30 ${DEPLOY_PATH}/app.log 2>/dev/null || true
                        echo "Hint: run 'sudo bash deploy/install-systemd.sh' once on the Ubuntu host"
                        exit 1
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