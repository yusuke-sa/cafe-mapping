FROM mcr.microsoft.com/devcontainers/javascript-node:20

ARG DEBIAN_FRONTEND=noninteractive

# Azure CLI + Functions Core Tools + global npm tooling
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y azure-functions-core-tools-4 \
  && npm install -g npm@11.6.2 turbo@2.6.1 \
  && rm -rf /var/lib/apt/lists/* /tmp/packages-microsoft-prod.deb

ENV AZURE_FUNCTIONS_ENVIRONMENT=Development
