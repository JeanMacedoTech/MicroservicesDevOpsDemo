# Installing eksctl
choco install eksctl -y

# Creating eksctl cluster with pre-configured yaml
eksctl create cluster -f eks-settings.yaml