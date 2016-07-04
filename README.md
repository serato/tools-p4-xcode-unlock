# tools-p4-xcode-unlock
Unlock script for Xcode to checkout readonly files with Perforce.

==== Setup ====

On your XCode behaviour settings, set the unlock script to point to this one.

On the top of the script, set the user name, workspace and port to the correct values. You can also add a Perforce password in your keychain to automatically login.

If it doesn't work check the log file generated in /tmp/xcode_unlock.log to see the errors