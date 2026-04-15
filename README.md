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
