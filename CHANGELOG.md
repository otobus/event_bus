# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2018-01-06

### Added

- Add `source` attribute to increase traceability
- Add optional configuration to Subscriber to use the same module/function with different configurations to process the event. The aim of this change is increasing re-useability of the listener with several configurations. For example, this will allow writing an HTTP consumer or an AWS lambda caller function with different configurations.

### TODO

## [0.8.0] - 2018-01-06

### Added

- Register/unregister topics on-demand (`EventBus.register_topic/1` and `EventBus.unregister/1`)
- Add block/yield builder for Event with auto `initialized_at` and `occurred_at` attribute assignments
- Add block/yield notifier for delivering/notifying events creation with same benefits of build block
- Add changelog file

## [0.7.0] - 2018-01-06

### Added

- Add `initialized_at` attribute

