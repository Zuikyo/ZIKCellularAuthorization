#!/bin/bash
#作用:每次build自动累加Info.plist里的CFBundleDisplayName，CFBundleIdentifier，ZIKCellularAuthorization.h里AppBundleIdentifier参数末尾的数字，目的是使每次运行都是一个新的没有蜂窝权限的app
#PS:当你手动在General/Identity里修改Bundle Ientifier，遇到错误App Installation failed:This application's application-identifier entitilement dose not match that of the installed application···的解决方法：此脚本修改了Info.plist里的CFBundleIdentifier，从$(PRODUCT_BUNDLE_IDENTIFIER)变为绝对值，而当你手动修改时，CFBundleIdentifier会变回$(PRODUCT_BUNDLE_IDENTIFIER)，就会导致和之前运行时的值不一致。把Info.plist里CFBundleIdentifier也改成你想要的值，并且在Build Phases/Run Script里停止使用脚本即可

displayName=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" "$INFOPLIST_FILE")
bundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFOPLIST_FILE")
bundleIdentifier2=${PRODUCT_BUNDLE_IDENTIFIER}
#修改Info.plist里的CFBundleIdentifier会导致Xcode出bug，${PRODUCT_BUNDLE_IDENTIFIER}不准确；当手动在General/Identity里修改Bundle Ientifier时，Info.plist里的CFBundleIdentifier会自动恢复为$(PRODUCT_BUNDLE_IDENTIFIER)，此时使用${PRODUCT_BUNDLE_IDENTIFIER}是准确的
if [ "$bundleIdentifier"x = "\$(PRODUCT_BUNDLE_IDENTIFIER)"x ]
then
bundleIdentifier=$bundleIdentifier2
fi
#更新ZIKCellularAuthorization.h里的bundle id参数
projectDir=${PROJECT_DIR}
headerFilePath=${projectDir/Demo/ZIKCellularAuthorization/ZIKCellularAuthorization.h}
#截取bundle id末尾"-"号后面的数字，并累加
count=${bundleIdentifier##[a-zA-Z\.]*-}
incCount=${count}
let incCount++
#替换数字
bundleIdentifier=${bundleIdentifier/-${count}/-${incCount}}
displayName=${displayName/-${count}/-${incCount}}
#修改ZIKCellularAuthorization.h
sed -i.bak "s/AppBundleIdentifier = @\".*\"/AppBundleIdentifier = @\"${bundleIdentifier}\"/" ${headerFilePath}
tmpFile=${headerFilePath}.bak
rm -rf $tmpFile
#保存到Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $displayName" "${INFOPLIST_FILE}"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundleIdentifier" "${INFOPLIST_FILE}"
