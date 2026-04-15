# Script to install Jenkins on Azure VM

!/bin/bash
# Update package lists
sudo apt update
# Install Java (required for Jenkins)
sudo apt install fontconfig openjdk-21-jre

# Download Jenkins Longterm Support (LTS) version
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins

# Enable Jenkins service
sudo systemctl enable jenkins

# Start Jenkins service
sudo systemctl start jenkins

# Print Jenkins initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword 

# echo admin password to console
echo "Jenkins initial admin password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"


