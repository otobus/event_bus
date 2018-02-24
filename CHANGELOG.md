# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.2.X]

- Removed support for system event tracing for `notify` action (unnecessary)
- Moved internal modules under managers namespace for better documentation
- Add `subscribed?` function to check subscriptions

## [1.1.X] - 2018.02.21

### Added

- Optional system events which notify the `eb_action_called` topic for the actions: `notify`, `register_topic`, `unregister_topic`, `subscribe`, `unsubscribe`, `mark_as_completed`, `mark_as_skipped`
- Add public exist? function to Topic, Watcher, and Store
- Check existence of topic in a blocking manner
- Register/Unregister topic in a blocking manner

## [1.0.0] - 2018.01.23

### Added

- Move build and notify blocks into EventSource
- Add use keyword for Source for developer friendly require and aliases
- Split GenServers and Services
- Move utility functions into its own module
- Add addons section to README
- Switch to microseconds when auto event structuring with `EventSource` to increase compability with Zipkin and Datadog APM
- Error topic introduced for dynamic event builder/notifier with `EventSource`. Now you can pass `:error_topic` key, EvetSource automatically check the result of execution block for `{:error, _}` tuple and create an event structure for the given `:error_topic`.
- Add elixir formatter config to format code

## [0.9.0] - 2018.01.06

### Added

- Add `source` attribute to increase traceability
- Add optional configuration to Subscriber to use the same module/function with different configurations to process the event. The aim of this change is increasing re-useability of the listener with several configurations. For example, this will allow writing an HTTP consumer or an AWS lambda caller function with different configurations.

### TODO

## [0.8.0] - 2018.01.06

### Added

- Register/unregister topics on-demand (`EventBus.register_topic/1` and `EventBus.unregister/1`)
- Add block/yield builder for Event with auto `initialized_at` and `occurred_at` attribute assignments
- Add block/yield notifier for delivering/notifying events creation with same benefits of build block
- Add changelog file

## [0.7.0] - 2018.01.06

### Added

- Add `initialized_at` attribute

