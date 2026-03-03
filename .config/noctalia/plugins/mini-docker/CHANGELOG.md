# Changelog

All notable changes to the Mini Docker plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-12-17

### Added
- **Expandable Details**: Click on any Container, Image, Volume, or Network to view detailed output
- **Advanced Run Dialog**: Container name, Environment Variables support, and Network selection dropdown

### Changed
- **Refactor**: Major refactoring of delegate components to fix QML layout warnings and improve stability
- **Run Dialog**: Improved UI layout and error handling

## [2.0.0] - 2025-12-16

### Added
- **Images Management**: New tab to view, pull, and run Docker images
- **Networks Management**: New tab to view and manage Docker networks
- **Run Image Dialog**: Interactive dialog to run images with port selection and configuration
- **Smart Port Selection**: Automatically suggests available ports when running containers
- **Network Configuration**: Option to specify network when running containers

### Changed
- **UI Improvements**: Enhanced sidebar icons and overall interface design
- **Code Cleanup**: Removed unused comments and cleaned up internationalization files
- **Performance**: Optimized loading times and improved responsiveness

### Fixed
- **Volumes Tab Loading**: Fixed performance issues when opening the volumes tab

## [1.0.0] - 2025-12-13

### Added
- **Initial Release**: Complete Docker container management plugin for Noctalia
- **Bar Widget**: Shows running container count in the status bar
- **Container Management**: List, start, stop, and remove containers
- **Volume Management**: View and manage Docker volumes
- **Settings Panel**: Configurable refresh intervals (1-30 seconds)
- **Internationalization**: Support for multiple languages (English, German, Spanish, French, Italian, Japanese, Dutch, Portuguese, Russian, Turkish, Ukrainian, Chinese)
- **Auto Refresh**: Live updates of container and volume status

### Features
- **Container Status**: Visual indicators for running/stopped containers
- **Volume Cleanup**: Remove unused Docker volumes
- **Responsive Design**: Adapts to different panel sizes
- **Error Handling**: Graceful handling of Docker daemon issues

### Technical
- **QtQuick/QML**: Modern UI framework integration
- **Quickshell**: Native Noctalia plugin architecture
- **Docker CLI Integration**: Direct command execution for reliability