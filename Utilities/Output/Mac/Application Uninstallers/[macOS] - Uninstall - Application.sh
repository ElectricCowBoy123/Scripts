#!/usr/bin/env bash

if [[ -n $application ]]; then
    APP=$application
else
    APP=$1
fi

mdfind kMDItemContentTypeTree=com.apple.application-bundle -onlyin >/dev/null
APP_TO_UNINSTALL=$(system_profiler SPApplicationsDataType 2>/dev/null | sed -n 's/^ *Location: \(.*\)/\1/p' | grep -E '^\/Applications.*|\/Users\/.+\/Applications.*' | grep "${APP}" | head -n 1)

if [[ -z "${APP_TO_UNINSTALL}" ]]; then
    echo "Could not find application: $APP"
    exit 1
fi

echo "Found ${APP_TO_UNINSTALL}"
echo "Removing ${APP_TO_UNINSTALL}"

rm -rf "${APP_TO_UNINSTALL}"
status=$?

if [ $status -eq 0 ]; then
    echo "Removed ${APP_TO_UNINSTALL}"
else
    echo "Failed to remove ${APP_TO_UNINSTALL}"
fi

exit $status