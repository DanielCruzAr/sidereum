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
                    def paramsJson = readFile(PARAMS_FILE)
                    def params = new groovy.json.JsonSlurper().parseText(paramsJson)

                    def updated = params.findAll { it.ParameterKey != 'UserDataScript' } +
                        [ [ParameterKey: 'UserDataScript', ParameterValue: env.ENCODED_USERDATA ] ]

                    writeFile file: 'final-params.json',
                              text: groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(updated))
                }
            }
        }

        stage ('Deploy CloudFormation Stack') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
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