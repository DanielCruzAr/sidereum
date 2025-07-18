pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        STACK_NAME = 'sidereum-reservations'
        TEMPLATE_FILE = 'test_template.yaml'
        PARAMS_FILE = 'params.json'
        EC2_TAG_KEY = 'instance'
        EC2_TAG_VALUE = 'api-instance'
    }

    stages {
        stage('Verify AWS CLI') {
            steps {
                sh 'aws --version'
            }
        }

        stage ('Deploy CloudFormation Stack') {
            steps {
                withAWS(credentials: 'AWS', region: env.AWS_REGION) {
                    sh """
                        aws cloudformation deploy \
                            --template-file ${TEMPLATE_FILE} \
                            --stack-name ${STACK_NAME} \
                            --capabilities CAPABILITY_IAM \
                            --parameter-overrides file://${PARAMS_FILE}
                    """
                }
            }
        }

        stage ('Wait for Stack Completion') {
            steps {
                withAWS(credentials: 'AWS', region: env.AWS_REGION) {
                    sh """
                        aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
                    """
                }
            }
        }

        stage ('Get Instance Public IP') {
            steps {
                withAWS(credentials: 'AWS', region: env.AWS_REGION) {
                    script {
                        def instanceId = sh(
                            script: "aws ec2 describe-instances --filters 'Name=tag:${EC2_TAG_KEY},Values=${EC2_TAG_VALUE}' --query 'Reservations[0].Instances[0].InstanceId' --output text"
                        ).trim()
                        def publicIp = sh(
                            script: "aws ec2 describe-instances --instance-ids ${instanceId} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
                        ).trim()
                        env.INSTANCE_PUBLIC_IP = publicIp
                    }
                }
            }
        }

        stage ('Connect to EC2 Instance') {
            steps {
                sshagent(credentials: ['aws-ssh-key-pair']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.INSTANCE_PUBLIC_IP} << EOF
                            echo "Connected to EC2 Instance"
                            sudo apt-get update
                            sudo apt-get install -y docker.io
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker ubuntu
                            docker --version
                            echo "Docker installed and started"
                            echo "Logging into ECR"
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 912262731597.dkr.ecr.us-east-1.amazonaws.com
                            docker pull 912262731597.dkr.ecr.us-east-1.amazonaws.com/sidereum:latest
                            docker pull 912262731597.dkr.ecr.us-east-1.amazonaws.com/sidereum:redis
                            exit
                        EOF
                    """
                }
            }
        }
    }
}