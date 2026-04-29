# Python Flask App Using Jenkins CI/CD Pipeline

Welcome to my repository to deploy a Python Flask application using Jenkins pipelines.  Here you will find everything needed in order to deploy this web application to Azure cloud using IaC.  This project deploys a Flask API + PostgreSQL database for tracking a "To Do" list, (I know, very basic).  Some key services this project uses in Azure are VNET, private endpoints, ACR, PostgreSQL Flexible Server, Key Vault, secrets, VM (Jenkins), and App Services. Please remember to study, apply, and learn but most importantly have fun!

Thanks!

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Cloud Deployment](#cloud-deployment)
  - [Create Azure Infrastructure](#create-azure-infrastructure)
  - [Unlock Jenkins Pipeline](#unlock-jenkins-pipeline)
- [License](#license)

## Overview

This project is a Python Flask API deployed through Jenkins CI/CD pipeline that creates, reads, updates, and deletes "To Do" tasks into an Azure cloud PostgreSQL database.

## Architecture

**Components:**
| Component | Description |
|-----------|-------------|
| ACR | Container registry storing the Docker image |
| Azure PostgreSQL | Managed database for "To Do" entries |
| Key Vault | Secure storage for secrets and credentials |
| VM (Jenkins) | Virtual machine server running Jenkins CI/CD pipeline |
| App Service | Azure App Service hosting web application |
| VNET | Virtual network isolating Azure resources |
| Private Endpoints | Private connectivity between App Service/Jenkins and backend services |

## Prerequisites

### Local Development
- Git
- Docker Desktop
- VS Code with Dev Containers extension
- Python3.14
- Azure Account

### Cloud Deployment
- Azure CLI (`az`)
- Terraform
- GitHub CLI (`gh` and/or `git`)

## Local Development

**Quick Start**
```bash
# Clone the repository
git clone https://github.com/JordanSum/flask-jenkins-pipeline.git
cd flask-jenkins-pipeline

# Copy environment template
cp .env-sample .env

# Open in VS Code
code .
```

**Environment Variables**
| .env variable | value |
|---------------|-------|
| databaseurl | sqlite:///project.db (development purpose) |

**Create venv**
```bash
python3 -m venv <venv-name>

# macOS/Linux
source venv/bin/activate

# Windows
venv/Scripts/activate

# Install packages
pip install <package-name>

# Save dependencies
pip freeze > requirements.txt

# Recreate from requirements
pip install -r requirements.txt
```

## Cloud Deployment

### Create Azure Infrastructure

```bash
cd infra

terraform validate

terraform plan

terraform apply --auto-approve

# Wait for your azure infrastructure to finish deploying and then move on to the next steps
```

A service principal needs to be created for Jenkins. This is going to allow Jenkins to push the Docker container in the GitHub repository to Azure Container Registry (ACR) without login credentials.

In order to create an SP for this project, run the following `az` command in the CLI

```bash
az ad sp create-for-rbac \
  --name "jenkins-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RG-NAME
```

> [!IMPORTANT]
> Replace both YOUR-SUBSCRIPTION-ID and YOUR-RG-NAME with their actual values.
> Output will be used later in the project.

### Unlock Jenkins Pipeline

When your Azure infrastructure has finished deploying, go into your Azure account and open your Resource Group that was just created. Inside that resource group you will locate your Jenkins Virtual Machine (VM).  Click on your Jenkins VM and locate the public IP (PIP) address, open a separate internet tab and paste the PIP in the address bar with port 8080. (http://ip-address:8080).  You should be introduced to an 'Unlock Jenkins' page.  On this page you will see a file path that is holding the Jenkins server password. Use this file path in the next step to locate the password to paste into this page.

<img src="docs/images/Screenshot 2026-04-24 at 13.24.42.png" alt="Jenkins Unlock Jenkins splash page displaying the initial admin password file path" width="900">
<br><br>

Back in your Azure account, on your Jenkins VM page, locate the "Connect" hyperlink and click on it.

<img src="docs/images/Screenshot 2026-04-24 at 13.26.34.png" alt="Azure portal Jenkins VM overview page with the Connect hyperlink highlighted" width="900">
<br><br>

On the connect page you will see a "Native SSH" page.  At the bottom of the page it will show the ssh command to connect to this VM.  Copy the ssh link and paste this into your terminal of choice.

<img src="docs/images/Screenshot 2026-04-24 at 13.26.44.png" alt="Azure portal Native SSH connection page showing the SSH command to connect to the Jenkins VM" width="900">
<br><br>

Once pasted, replace "private-key-file-path" with your private key used when creating the VM.

<img src="docs/images/Screenshot 2026-04-24 at 13.27.13.png" alt="Terminal SSH command with private-key-file-path placeholder to be replaced with your actual private key path" width="900">
<br><br>

You should now be logged into your Jenkins VM.  Run the `cat` command to reveal your password with the file path that was given from the "Unlock Jenkins" splash page.

<img src="docs/images/Screenshot 2026-04-24 at 13.28.03.png" alt="Terminal running the cat command to reveal the Jenkins initial admin password" width="900">
<br><br>

Once logged into your Jenkins VM click the "Install suggested plugins". This will install the necessary plugins needed to run and configure this Jenkins server.

<img src="docs/images/Screenshot 2026-04-24 at 13.28.20.png" alt="Jenkins setup page prompting to Install Suggested Plugins" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.28.47.png" alt="Jenkins plugin installation progress screen showing suggested plugins being installed" width="900">
<br><br>

On the next page fill out the fields to create your first user.  This is going to be used to log into the Jenkins server.

<img src="docs/images/Screenshot 2026-04-24 at 13.29.19.png" alt="Jenkins Create First Admin User form with fields for username, password, and email" width="900">
<br><br>

On the "Instance Configuration" page keep the current settings and click "Save and Finish"

<img src="docs/images/Screenshot 2026-04-24 at 13.29.42.png" alt="Jenkins Instance Configuration page showing the Jenkins URL with the Save and Finish button" width="900">
<br><br>

On your "Welcome to Jenkins" page, click on "New Item" in the top left corner.

<img src="docs/images/Screenshot 2026-04-24 at 13.30.17.png" alt="Jenkins Welcome page with New Item option in the left-hand navigation menu" width="900">
<br><br>

In your "New Item" page, enter your item name, select "Pipeline," and click on "Ok".

<img src="docs/images/Screenshot 2026-04-24 at 13.31.00.png" alt="Jenkins New Item page with a name entered and the Pipeline type selected" width="900">
<br><br>

On your "General" page, give a brief description, and under "Triggers" select "GitHub hook trigger for GITScm polling". In "Pipeline" select "Pipeline Script from SCM" under "Definition". Git needs to be selected under SCM, use the GitHub repo URL in the "Repository URL" input box, the "Branch Specifier" should read "*/main", and set the "Script Path" to "Jenkinsfile".

<img src="docs/images/Screenshot 2026-04-24 at 13.39.22.png" alt="Jenkins pipeline General configuration page with GitHub hook trigger for GITScm polling selected under Build Triggers" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.39.31.png" alt="Jenkins pipeline Pipeline section with Definition set to Pipeline Script from SCM and SCM set to Git" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.39.34.png" alt="Jenkins pipeline SCM settings showing the GitHub repository URL, branch specifier set to main, and Script Path set to Jenkinsfile" width="900">
<br><br>

Set up a webhook in your GitHub repository so when a push trigger is activated in GitHub it runs the build in Jenkins of the updated code. GitHub Repository/Settings/Webhook

<img src="docs/images/Screenshot 2026-04-24 at 13.42.26.png" alt="GitHub repository Webhooks settings page for configuring a webhook to trigger Jenkins builds on push" width="900">
<br><br>

Back in your Jenkins server application, make your way to the settings page, and click on "Credentials" --> "System" --> "Global" --> "+ Add Credentials". Make sure to click on "Secret Text". Here you will be putting in your variables to allow your Jenkins Server to push your GitHub code to your Azure Container Registry (ACR).

<img src="docs/images/Screenshot 2026-04-24 at 13.43.13.png" alt="Jenkins Add Credentials page with Secret Text kind selected for storing Azure and ACR credentials" width="900">
<br><br>

> [!NOTE]
> Your output for the SP will be put into some of these variables. 

| Name | Secret |
|------|--------|
| AZURE_CLIENT_ID | Service principal app ID |
| AZURE_CLIENT_SECRET | Service principal password |
| AZURE_TENANT_ID | Your tenant ID |
| AZURE_SUBSCRIPTION_ID | Your subscription ID |
| ACR_NAME | Found in terraform.tfvars |
| APP_NAME | Found in terraform.tfvars |
| RESOURCE_GROUP | Found in terraform.tfvars |
| IMAGE_NAME | Whatever you want to input |

<img src="docs/images/Screenshot 2026-04-24 at 13.51.13.png" alt="Jenkins Global Credentials page listing all added secret text credentials including Azure and ACR variables" width="900">
<br><br>

Now go to your Jenkins home page and click on the pipeline you just created and click "Build Now". You should see your build spinning up below the left hand menu bar.

<img src="docs/images/Screenshot 2026-04-24 at 13.52.55.png" alt="Jenkins pipeline page with Build Now option and the build running in the build history" width="900">
<br><br>

Once your build has completed successfully, navigate back to your Azure Web App that is hosting the application. Give it a few minutes, and click on the "Default Domain" in the "Overview" page of the Web App.  You should be seeing your web application deployed and ready for use.

<img src="docs/images/Screenshot 2026-04-24 at 13.59.11.png" alt="Azure App Service Overview page showing the Default Domain link to open the deployed web application" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.59.26.png" alt="Deployed Flask To Do web application running live in the browser via Azure App Service" width="900">
<br><br>

Make several entries into this web application.  To make sure that your entries are actually being put into your PostgreSQL database make your way to your network settings in the database in your PostgreSQL Flexible Server in Azure.  Since this database was created to not allow any outside connections we will temporarily allow access to only your client PIP.

<img src="docs/images/Screenshot 2026-04-24 at 14.01.32.png" alt="Azure PostgreSQL Flexible Server networking settings page for managing public access and firewall rules" width="900">
<br><br>

Check off "Allow public access to this resource through the internet using a public IP address" and add your public IP address to the allow list and click save

<img src="docs/images/Screenshot 2026-04-24 at 14.01.59.png" alt="Azure PostgreSQL network settings with public access enabled and a client IP address added to the firewall allowlist" width="900">
<br><br>

Back in your IDE, (I use VS Code, and PostgreSQL explorer as an extension) log into your database and check that your actual entries are being created in the database.

<img src="docs/images/Screenshot 2026-04-24 at 14.17.42.png" alt="VS Code PostgreSQL Explorer extension showing To Do entries successfully stored in the Azure PostgreSQL database" width="900">
<br><br>

Once you have confirmed that entries are going into your database, go back to your database network settings and remove your public IP address from the list and uncheck "allow public access".

Once completed, navigate to the infra folder in your IDE or CLI in this project and run the following to destroy your cloud infrastructure.  You don't want to build up any charges.

```bash
terraform destroy --auto-approve
```

Also, so you don't have any dangling credentials in your Azure account run the following command to delete your SP.

```bash
az ad sp delete --id <appId-from-create-output>
```

## License

MIT License

Copyright (c) 2026 Jordan Sumner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
