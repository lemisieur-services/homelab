# Homelab

This repository contains the configurations I use to manage my personal homelab. It is shared publicly for reference and inspiration — feel free to browse, but please read the disclaimer below before using anything here.

## Table of Contents

- [Homelab](#homelab)
  - [Table of Contents](#table-of-contents)
  - [Disclaimer](#disclaimer)
  - [Overview](#overview)
  - [Directory Structure](#directory-structure)
  - [License](#license)

## Disclaimer

> **This repository is provided as-is, without any warranty or guarantee of any kind.**
>
> The configurations and scripts here are what I personally use to manage my own homelab. They are shared for reference only. I make no claims that they will work in your environment, and I am not responsible for any issues that may arise from using them. Use at your own risk.

## Overview

This is my personal homelab repository. It houses all the Kubernetes manifests, network configurations, and tooling I use to run and automate my homelab environment. The setup is built around ArgoCD for GitOps-style deployments and Traefik as the ingress controller.

## Directory Structure

- **k8s/**: Kubernetes manifests for all services deployed in the homelab.
  - **argocd/**: ArgoCD Application definitions for GitOps deployments.
  - **homepage/**: Configuration for the homelab dashboard.
  - **traefik/**: Traefik ingress controller configuration and TLS certificates.
  - **eso/**: External Secrets Operator configuration (secrets sourced from Azure Key Vault).
  - **longhorn/**: Longhorn distributed storage configuration.
  - **oauth2-proxy/**: OAuth2 Proxy for authentication.
  - **uptimekuma/**: Uptime Kuma monitoring configuration.
  - **seerr/**: Overseerr/Jellyseerr configuration.
  - **portainer/**: Portainer container management configuration.
  - **renovate/**: Renovate bot configuration for automated dependency updates.
  - **gh-arc/**: GitHub Actions Runner Controller configuration.
- **network/**: Network-related configurations.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.