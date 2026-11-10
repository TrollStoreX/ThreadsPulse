export TARGET := iphone:clang:latest:15.0
export ARCHS = arm64
# 無根越獄 (Dopamine/palera1n rootless) 請取消下一行註解：
# export THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = Threads
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ThreadsPulse
ThreadsPulse_FILES = Tweak.x TPLocalization.m TPPrefs.m TPURLCleaner.m TPDownloader.m TPHUD.m TPUI.m TPSettingsViewController.m TPSideloadFix.m
ThreadsPulse_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
ThreadsPulse_FRAMEWORKS = UIKit Photos AVFoundation UniformTypeIdentifiers SafariServices Security
# 用 ObjC runtime 直接 hook，不依賴 CydiaSubstrate（側載注入 IPA 時不必附 Substrate）
ThreadsPulse_LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk
