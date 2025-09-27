#!/bin/bash

# Создаем app bundle
mkdir -p RemoteControl.app/Contents/MacOS
mkdir -p RemoteControl.app/Contents/Resources

# Копируем исполняемый файл
cp .build/release/remoteControl RemoteControl.app/Contents/MacOS/

# Подписываем исполняемый файл (ad-hoc signing для локального использования)
codesign --force --sign - RemoteControl.app/Contents/MacOS/remoteControl

# Создаем Info.plist
cat > RemoteControl.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>remoteControl</string>
    <key>CFBundleIdentifier</key>
    <string>com.remotecontrol.app</string>
    <key>CFBundleName</key>
    <string>Remote Control</string>
    <key>CFBundleDisplayName</key>
    <string>Remote Control</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Подписываем все приложение
codesign --force --sign - RemoteControl.app

echo "App bundle создан: RemoteControl.app"
echo "Запуск: open RemoteControl.app"
