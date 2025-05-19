 #!/usr/bin/env bash
APP="connectwisecontrol-1a5d6cc5d5f07e3e"
APP_TO_UNINSTALL=$(system_profiler SPApplicationsDataType 2>/dev/null | sed -n 's/^ *Location: \(.*\)/\1/p' | grep -E '^\/Applications.*|\/Users\/.+\/Applications.*' | grep "${APP}" | head -n 1)

if [[ -z "${APP_TO_UNINSTALL}" ]]; then
    echo "Could not find application: $APP"
    exit 1
fi

launchctl bootout system/connectwisecontrol-1a5d6cc5d5f07e3e
rm /Library/LaunchAgents/connectwisecontrol-1a5d6cc5d5f07e3e*.plist 
rm -r /Applications/connectwisecontrol-1a5d6cc5d5f07e3e.app
status=$?

if [ $status -eq 0 ]; then
    echo "Removed ${APP_TO_UNINSTALL}"
else
    echo "Failed to remove ${APP_TO_UNINSTALL}"
fi

exit $status