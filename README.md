# Being Created
<!--
# Instructions

## Setup

### Virtual Environement

Packages are installed in the virtual environment, please load into the environment before working

```bash
source .venv/bin/activate
```

To see what packages are installed run: 
```bash
pip list
```

To create your requirements.txt file with all dependencies listed run this command:

```bash
pip freeze > requirements.txt
```

If needing guidance to FlaskAlchemy just google it to get instructions.

To retrieve the initial admin password for jenkins, ssh into the instance and run the following command

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

A service principle needs to be created for Jenkins.

Most cloud engineers keep the service principal outside of Terraform for a few reasons:

    - The SP secret ends up in your Terraform state file in plaintext
    - It creates a circular dependency, you need auth to run Terraform, but Terraform is creating your auth
    - Rotating secrets means a Terraform change rather than a quick CLI command

In order to create a SP for this project run the following AZ command in CLI

```bash
az ad sp create-for-rbac \
  --name "jenkins-sp" \
  --role Contributor \
  --scopes /subscriptions/your-subscription-id
```

-->
