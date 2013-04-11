LOCAL_PATH:= $(call my-dir)

#include $(CLEAR_VARS)
#LOCAL_MODULE       := init.sawara.rc
#LOCAL_MODULE_TAGS  := optional eng
#LOCAL_MODULE_CLASS := ETC
#LOCAL_SRC_FILES    := init.sawara.rc
#LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)
#include $(BUILD_PREBUILT)

include $(call all-makefiles-under,$(LOCAL_PATH))
