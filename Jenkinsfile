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
                script {
                    def rawParams = readFile(PARAMS_FILE)
                    def paramsList = new groovy.json.JsonSlurper().parseText(rawParams) as List

                    // Remove existing UserDataScript param if it exists
                    def filtered = paramsList.findAll { it.ParameterKey != 'UserDataScript' }

                    // Add updated UserDataScript param
                    filtered << [
                        ParameterKey  : 'UserDataScript',
                        ParameterValue: env.ENCODED_USERDATA
                    ]

                    // Serialize immediately to avoid LazyMap issues
                    def serialized = groovy.json.JsonOutput.prettyPrint(
                        groovy.json.JsonOutput.toJson(filtered)
                    )

                    writeFile file: 'final-params.json', text: serialized
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
                            --parameter-overrides file://final-params.json \
                            --capabilities CAPABILITY_IAM
                    """
                }
            }
        }
    }
}