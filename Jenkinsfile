pipeline {
    agent any

    environment {
        AZURE_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        AZURE_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
        AZURE_TENANT_ID = credentials('AZURE_TENANT_ID')
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        ACR_NAME = credentials('ACR_NAME')
        APP_NAME = credentials('APP_NAME')
        RESOURCE_GROUP = credentials('RESOURCE_GROUP')
        IMAGE_NAME = credentials('IMAGE_NAME')
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DATABASE_URL = credentials('DATABASE_URL')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Azure Login') {
            steps {
                sh '''
                az login --service-principal \
                    -u $AZURE_CLIENT_ID \
                    -p $AZURE_CLIENT_SECRET \
                    --tenant $AZURE_TENANT_ID
                az account set --subscription $AZURE_SUBSCRIPTION_ID
                '''
            }
        }

        stage('Push to ACR') {
            steps {
                sh '''
                az acr login --name $ACR_NAME
                docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Run Migration') {
            steps {
                sh '''
                    docker run --rm \
                    -e DATABASE_URL=$DATABASE_URL \
                    ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} \
                    flask db upgrade
                '''
            }
        }

        stage('Deploy to App Service') {
            steps {
                sh '''
                az webapp config container set \
                    --name $APP_NAME \
                    --resource-group $RESOURCE_GROUP \
                    --docker-custom-image-name ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} \
                    --docker-registry-server-url https://${ACR_NAME}.azurecr.io \
                az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP 
                '''
            }
        }
    }

    post {
        always {
            sh 'az logout || true'
        }
        success {
            echo "Deployed ${IMAGE_NAME}:${IMAGE_TAG} to Azure App Service successfully!"
        }
        failure {
            echo "Deployment failed. Check the logs for details."
        }
    }
}