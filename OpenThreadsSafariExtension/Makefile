# 「在 Threads 開啟」Safari 延伸功能（只放進 sideload 版 IPA）
# 編譯：make -C OpenThreadsSafariExtension FINALPACKAGE=1
# 產出：OpenThreadsSafariExtension/.theos/obj/OpenThreadsSafariExtension.appex
TARGET ?= iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPEX_NAME = OpenThreadsSafariExtension
OpenThreadsSafariExtension_FILES = OpenInThreadsHandler.m
OpenThreadsSafariExtension_CFLAGS = -fobjc-arc
OpenThreadsSafariExtension_FRAMEWORKS = Foundation SafariServices

include $(THEOS_MAKE_PATH)/appex.mk
