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
                    env.ENCODED_USERDATA = sh(
                        script: "base64 -w 0 ${USERDATA_FILE}",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Inject UserData into Params File') {
            steps {
                def raw = readFile(PARAMS_FILE)
                def updateJson = sh(
                    script: """
                    jq 'map(select(.ParameterKey != "UserDataScript")) + 
                        [{"ParameterKey": "UserDataScript", "ParameterValue": "${env.ENCODED_USERDATA}"}]' <<< '${raw}'
                    """,
                    returnStdout: true
                ).trim()
                writeFile file: 'final-params.json', text: updateJson
            }
        }

        stage ('Deploy CloudFormation Stack') {
            steps {
                withAWS(credentials: 'AWS', region: env.AWS_REGION) {
                    sh """
                        aws cloudformation deploy \
                            --template-file ${TEMPLATE_FILE} \
                            --stack-name ${STACK_NAME} \
                            --parameter-overrides file://final-params.json \
                            --capabilities CAPABILITY_IAM
                    """
                }
            }
        }
    }
}