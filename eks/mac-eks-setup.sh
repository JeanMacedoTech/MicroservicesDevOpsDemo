# Installing eksctl
brew tap weaveworks/tap
brew install eksctl

# Creating eksctl cluster with pre-configured yaml
eksctl create cluster -f eks-settings.yaml