# Changelog

## Unreleased

### Added

- Environment variable overrides: `CONAN_BASE_PATH`, `STEAMCMD_PATH`, `CONAN_TMUX_SESSION`
- Single SteamCMD session for all workshop mod downloads
- SteamCMD exit code and error output validation for server and mod updates

### Changed

- Workshop mods are downloaded in one batched SteamCMD run instead of one run per mod

## 1.0.0

Initial release.

Features:

- Updates Conan Exiles dedicated server app `443030`
- Downloads Steam Workshop mods for app `440900`
- Reads mod IDs from `ServerModList=`
- Generates `ConanSandbox/Mods/modlist.txt`
- Uses relative `.pak` paths
- Stops and starts the server using `tmux`
- Sends `Ctrl-C` twice before killing the session
- Creates a backup of the existing mod list
- Supports optional `--prune`
- Prevents multiple updater instances with a lock file
- Logs updater output to `conan-mod-updater.log`
