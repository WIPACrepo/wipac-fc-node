# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- for new features
### Changed
- for changes in existing functionality
### Deprecated
- for soon-to-be removed features
### Removed
- for now removed features
### Fixed
- for any bug fixes
### Security
- in case of vulnerabilities

## [0.0.5] - 2018-06-21
### Added
- Method to obtain ETag for a file
- Integration tests for update and replace methods
### Changed
- Update and replace client methods return objects instead of naked JSON
- Existing client tests for object returns
### Fixed
- istanbul dependency changed to bleeding edge to fix coverage report

## [0.0.4] - 2018-06-20
### Added
- Methods to create and query Collections and Snapshots
- Integration tests to ensure client works with file catalog
### Changed
- Many client methods return objects instead of naked JSON
- Existing client tests for object returns

## [0.0.3] - 2018-06-15
### Added
- ClientError class for client side errors
- Implementation for replace() and update()
- Coverage tests for everything except get_files()

## [0.0.2] - 2018-05-15
### Added
- Original Python client client.py in doc/ directory
- client.coffee to implement some of the original Python API

## 0.0.1 - 2018-05-14
### Added
- Project specific directories to .gitignore
- Project build script in Cakefile
- Project dependencies in package.json
- Description of project in README.md

[Unreleased]: https://github.com/WIPACrepo/wipac-fc-node/compare/v0.0.4...HEAD
[0.0.4]: https://github.com/WIPACrepo/wipac-fc-node/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/WIPACrepo/wipac-fc-node/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/WIPACrepo/wipac-fc-node/compare/v0.0.1...v0.0.2
