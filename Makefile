ARCHS = armv7 arm64
TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iTunesStoreX7 StoreFrontInterceptor

iTunesStoreX7_FILES = Tweak.xm
iTunesStoreX7_CFLAGS = -fobjc-arc
iTunesStoreX7_BUNDLE_FILTER = com.apple.AppStore com.apple.itunesstored com.apple.mobilesafari com.apple.MobileStore
iTunesStoreX7_FRAMEWORKS = Foundation

StoreFrontInterceptor_FILES = StoreFrontInterceptor/Storefront.xm
StoreFrontInterceptor_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk