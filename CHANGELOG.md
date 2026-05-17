# Changelog

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
