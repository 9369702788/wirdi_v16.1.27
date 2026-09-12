import re
from pathlib import Path

path = Path('android/app/src/main/AndroidManifest.xml')
text = path.read_text()

# All permissions needed by Wirdi
# RE-ADDED (was removed earlier as "declared but unused"): now genuinely
# used -- see the ScheduledNotificationBootReceiver registration below.
perms = [
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.VIBRATE',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
    'android.permission.WAKE_LOCK',
    # NEW: required for the Camera Qibla (AR overlay) screen added in v192,
    # which uses CameraController/availableCameras() from the `camera` plugin.
    'android.permission.CAMERA',
]
perm_lines = '\n'.join(
    f'    <uses-permission android:name="{p}" />'
    for p in perms if p not in text
)
if perm_lines:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + perm_lines,
    )

# Add usesCleartextTraffic and networkSecurityConfig to <application>
if 'usesCleartextTraffic' not in text:
    text = re.sub(
        r'<application\b',
        '<application android:usesCleartextTraffic="false" '
        'android:networkSecurityConfig="@xml/network_security_config"',
        text, count=1
    )

# Register audio_service's foreground media-playback service + media
# button receiver, so Radio/Quran audio show a system notification with
# Play/Pause/Stop (lock screen + notification shade controls).
if 'com.ryanheise.audioservice.AudioService' not in text:
    audio_service_block = (
        '\n    <service android:name="com.ryanheise.audioservice.AudioService"\n'
        '        android:foregroundServiceType="mediaPlayback"\n'
        '        android:exported="true">\n'
        '        <intent-filter>\n'
        '            <action android:name="android.media.browse.MediaBrowserService" />\n'
        '        </intent-filter>\n'
        '    </service>\n'
        '    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"\n'
        '        android:exported="true">\n'
        '        <intent-filter>\n'
        '            <action android:name="android.intent.action.MEDIA_BUTTON" />\n'
        '        </intent-filter>\n'
        '    </receiver>\n'
    )
    text = re.sub(r'(</application>)', audio_service_block + r'\1', text, count=1)

# Add <queries> block for URL launcher and radio streams
if '<queries>' not in text:
    queries = (
        '\n    <queries>\n'
        '        <intent>\n'
        '            <action android:name="android.intent.action.VIEW" />\n'
        '            <data android:scheme="https" />\n'
        '        </intent>\n'
        '        <intent>\n'
        '            <action android:name="android.intent.action.VIEW" />\n'
        '            <data android:scheme="http" />\n'
        '        </intent>\n'
        '        <intent>\n'
        '            <action android:name="android.intent.action.VIEW" />\n'
        '            <data android:scheme="geo" />\n'
        '        </intent>\n'
        '    </queries>\n'
    )
    text = text.replace('</manifest>', queries + '</manifest>')

# Register the home-screen widget provider (was previously missing entirely --
# the widget could never appear to the user without this receiver declaration).
# Register flutter_local_notifications' own boot-persistence receivers --
# ScheduledNotificationReceiver fires each scheduled notification at its
# target time; ScheduledNotificationBootReceiver re-reads whatever was
# persisted to disk and re-schedules everything after BOOT_COMPLETED /
# MY_PACKAGE_REPLACED / QUICKBOOT_POWERON. Both classes ship inside the
# plugin's own AAR -- no custom native Kotlin/Java code required.
if 'ScheduledNotificationBootReceiver' not in text:
    boot_receiver_block = (
        '\n    <receiver android:exported="false"\n'
        '        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n'
        '    <receiver android:exported="false"\n'
        '        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n'
        '        <intent-filter>\n'
        '            <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
        '            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n'
        '            <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n'
        '            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n'
        '        </intent-filter>\n'
        '    </receiver>\n'
    )
    text = re.sub(r'(</application>)', boot_receiver_block + r'\1', text, count=1)

if 'WirdiWidgetProvider' not in text:
    widget_block = (
        '\n    <receiver android:name="com.wirdi.wirdi.WirdiWidgetProvider"\n'
        '        android:exported="true">\n'
        '        <intent-filter>\n'
        '            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />\n'
        '        </intent-filter>\n'
        '        <meta-data android:name="android.appwidget.provider"\n'
        '            android:resource="@xml/wirdi_widget_info" />\n'
        '    </receiver>\n'
    )
    text = re.sub(r'(</application>)', widget_block + r'\1', text, count=1)

path.write_text(text)
print('AndroidManifest.xml patched:')
print(text)
