# Container Manager Plugin for Noctalia

A plugin to manage Docker containers and volumes directly from your Noctalia bar.

## Features

- **Bar Widget**: Shows the number of running containers
- **Container Management**: List all containers with status, start/stop/remove options
- **Volume Management**: List volumes and remove them
- **Auto Refresh**: Configurable refresh interval for live updates

## Installation

This plugin is part of the `noctalia-plugins` repository.

## Configuration

Access the plugin settings in Noctalia to configure:

- **Refresh Interval**: How often to update the container and volume lists (1-30 seconds)

## Usage

- The Docker icon with running container count appears on your bar
- Click to open the management panel
- Switch between Containers and Volumes tabs
- Use buttons to manage individual items

## Requirements

- Noctalia 3.6.0 or later
- Docker installed and running

## Todos

- Allow user to delete the volumes and containers
- Allow users for full system clean (clean all volumes)
- Add panel for most used volumes or some popular images that they can pull directly and use without searching it on web first for example n8n, redis, mongodb, postgres etc
