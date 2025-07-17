pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        STACK_NAME = 'sidereum-reservations'
        TEMPLATE_FILE = 'test_template.yaml'
        PARAMS_FILE = 'params.json'
        USERDATA_FILE = 'reservations-api.sh'
    }

    stages {
        stage('Verify AWS CLI') {
            steps {
                sh 'aws --version'
            }
        }

        stage ('Read and Encode User Data') {
            steps {
                script {
                    def userData = sh(
                        script: "base64 -w 0 ${USERDATA_FILE}",
                        returnStdout: true
                    ).trim()

                    env.ENCODED_USERDATA = userData
                }
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
                            --parameter-overrides UserDataScript=${ENCODED_USERDATA}
                    """
                }
            }
        }
    }
}