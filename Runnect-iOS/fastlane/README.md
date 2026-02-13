fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios set_version

```sh
[bundle exec] fastlane ios set_version
```

Set Marketing and Build version

### ios release

```sh
[bundle exec] fastlane ios release
```

Build app and release to App Store Review

Usage: fastlane release version:2.3.0

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit existing build for App Store Review

Usage: fastlane submit_review version:2.4.1

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

Usage: fastlane beta version:2.3.0

### ios update_metadata

```sh
[bundle exec] fastlane ios update_metadata
```

Upload metadata only (no binary)

Usage: fastlane update_metadata version:2.3.0

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download current metadata from App Store Connect

### ios register_new_device

```sh
[bundle exec] fastlane ios register_new_device
```

Register Devices

### ios match_read_only

```sh
[bundle exec] fastlane ios match_read_only
```

Match all code signing (read only)

### ios upload_only

```sh
[bundle exec] fastlane ios upload_only
```

Upload IPA to App Store Connect (without review)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
