# DEMO CI/CD PROJECT - MICROSERVICES APPLICATION

Hey, there! 
Welcome to this demo project description and thank you so much for taking the time to check it out!

---
• Project Goal: take an example microservices application and create a CI/CD pipeline using Jenkins, demonstrating DevOps practices

• Microservices application used: Google Microservice App Demo (https://github.com/GoogleCloudPlatform/microservices-demo)

## • CI/CD Pipeline Design Steps:

1) Create a GitHub repository so we can manage application versioning for all microservices individually, including Jenkins configuration and Terraform code.

2) Terraform an S3 Bucket and an ECR Registry in AWS, so they can be used as artifactory and Docker image registry, respectively (see terraform/main.tf)
```terraform
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "artifactory_bucket" {
  bucket = "artifactory-bucket"
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "ecr-repo"
}
```
3) Build a **Jenkins configuration file** (see jenkins/jenkins.yaml) to document the necessary Jenkins plugins for the Jenkins server. We can then use the Configuration as Code Jenkins plugin for easier setup.

4) Create Jenkinsfiles for each microservice, outlining all CI/CD steps:

• Checkout Branch;

• Increment microservice version;

• Build the application package (4 different programming languages were used, so I used different build and test settings and tools);

• Run a generic test for the resulting artifact;

• Push artifact to S3 bucket;

• Build Docker Image;

• Push the new image to ECR Registry;

• Update the image tag inside the K8s Deployment manifest for the microservice;

• Apply updated manifest using kubectl;

• Commit version bump back to GitHub

## Jenkinsfile specifications:

1) S3 Bucket Artifactory and ECR Registry set as env vars:
```Groovy
pipeline {
    agent any
    environment {
        S3_BUCKET = 'artifactory-s3-bucket'
        ECR_REGISTRY = 'ecr-registry'
    }
```
2) Version incrementation, Build and Test stages specified for the corresponding programming language of each microservice. The example below is for a Java app built using Gradle.
```Groovy
stage('Increment Application Version') {
            steps {
                script {
                    // Defining current version:
                    def gradleFile = 'build.gradle'
                    def currentVersion = readFile(gradleFile).readLines().find { it =~ /version \'.*\'/ }
                    def versionPattern = /version \'(.*?)\'/
                    def currentVersionMatch = currentVersion =~ versionPattern
                    def currentVersionValue = currentVersionMatch[0][1]

                    // Incrementing current version:
                    def versionParts = currentVersionValue.split("\\.")
                    def patchVersion = versionParts[2].toInteger()
                    patchVersion += 1

                    // Building new version
                    def newVersion = "${versionParts[0]}.${versionParts[1]}.${patchVersion}"

                    // Updating the application version in the build.gradle file
                    sh "sed -i 's|version \'${currentVersionValue}\'|version \'${newVersion}\'|' $gradleFile"
                    echo "New version successfully incremented! Current version is now ${newVersion}"
                }
            }
        }

        stage('Build Application Package') {
            steps {
                sh 'gradle clean build'
            }
        }

        stage('Testing') {
            steps {
                // This is a generic test stage.
                sh 'gradle test' 
            }
        }
```
3) The artifact resulted then gets pushed to S3 Bucket:
```Groovy
stage('Push App Artifact to S3 Bucket') {
            steps {
                script {
                    def s3Bucket = env.S3_BUCKET
                    def artifactPath = 'adservice.jar'
                    sh "aws s3 cp ${artifactPath} s3://${s3Bucket}/"
```
4) After the Docker Image is built and pushed to ECR, we update the application version inside the respective K8s Deployment manifest, which is setup with an image tag to be replaced accordingly:
```yaml
containers:
      - name: server
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
          privileged: false
          readOnlyRootFilesystem: true
        image: {{IMAGE_TAG}}
        ports:
        - containerPort: 9555
```
5) We then use Shell commands to update and apply the manifest:
```Groovy
stage('Update K8s Manifest') {
            steps {
                script {
                    def k8sManifestFile = 'k8s-manifests/adservice.yaml'

                    // Replacing K8s manifest placeholder tag with the new image tag
                    sh "sed -i 's|{{IMAGE_TAG}}|${newVersion}|' $k8sManifestFile"
                    echo "Kubernetes manifest updated with the new image tag: ${newVersion}"

stage('Apply updated K8s Manifest') {
            steps {
                script {
                sh "kubectl apply -f k8s-manifests/adservice.yaml"
              }
            }
        }
```
The same structure is used for all microservices, where we edit the stages accordingly, depending on the applications programming language. 

The pipeline is designed to be repeatable and easy to deploy, no matter the OS for the Jenkins server. With that in mind, inside the **EKS** folder, I've included basic Shell Scripts to get eksctl ready in Windows, Mac or Linux. We setup the Jenkins server in the preferred OS using the provided jenkins.yaml configuration file, use one of the Shell scripts to get eksctl available, and off we go!

```shell
# Installing eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64" > eksctl
chmod +x eksctl
sudo mv eksctl /usr/local/bin

# Creating eksctl cluster with pre-configured yaml
eksctl create cluster -f eks-settings.yaml
```


