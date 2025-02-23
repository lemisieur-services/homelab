# Homelab

This repository contains the configurations and scripts used in my home lab. Feel free to use them where you see fit. Contributions are welcome!

## Table of Contents

- [Homelab](#homelab)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Directory Structure](#directory-structure)
  - [Usage](#usage)
    - [Deploying Mac Scripts](#deploying-mac-scripts)
    - [Deploying Homepage](#deploying-homepage)
    - [Running Media Services](#running-media-services)
    - [Contributing](#contributing)
    - [License](#license)

## Overview

This repository is meant to be the home of all my home lab configurations and scripts. It includes various services and tools that I use to manage and automate my home lab environment.

## Directory Structure

- **.github/workflows/**: GitHub Actions workflows for deploying configurations.
- **services/homepage/**: Configuration files and Docker setup for the homepage service.
- **services/mac-scripts/**: Shell scripts for managing Mac-specific tasks.
- **services/media-services/**: Docker setup for media-related services, like downloads and streaming.

## Usage

### Deploying Mac Scripts

The `macscripts-deploy.yml` workflow deploys Mac scripts to a remote server. It triggers on pushes to the `main` branch affecting files in the `services/mac-scripts/` directory.

### Deploying Homepage

The `homepage-deploy.yml` workflow deploys the homepage configuration to a NAS drive. It triggers on pushes to the `main` branch affecting files in the `services/homepage/` directory or the workflow file itself.

### Running Media Services

The `docker-compose.yml` file in the `services/media-services/` directory sets up various media services using Docker. To start the services, navigate to the directory and run:
```sh
docker-compose up -d
```

### Contributing
Contributions are welcome! Please open an issue or submit a pull request with your changes. Make sure to follow the existing code style and include relevant tests.

### License
This project is licensed under the MIT License. See the LICENSE file for details.