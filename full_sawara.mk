$(call inherit-product, device/qcom/common/common.mk)

PRODUCT_COPY_FILES := \
  device/qcom/sawara/init.sawara.rc:root/init.sawara.rc
  device/qcom/sawara/ueventd.sawara.rc:root/ueventd.sawara.rc

$(call inherit-product-if-exists, vendor/qcom/sawara/sawara-vendor-blobs.mk)
$(call inherit-product-if-exists, vendor/qcom/common/vendor-blobs.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full.mk)

PRODUCT_PROPERTY_OVERRIDES += \
  rild.libpath=/system/lib/libril-qc-qmi-1.so \
  rild.libargs=-d/dev/smd0 \
  ro.moz.cam.0.sensor_offset=180 \
  ro.use_data_netmgrd=true \
  ro.moz.ril.simstate_extra_field=true \
  ro.moz.ril.emergency_by_default=true \
  ro.moz.omx.hw.max_width=640 \
  ro.moz.omx.hw.max_height=480 \
  ro.moz.fm.noAnalog=true

# Discard inherited values and use our own instead.
PRODUCT_NAME := full_sawara
PRODUCT_DEVICE := sawara
PRODUCT_BRAND := toro
PRODUCT_MANUFACTURER := toro
PRODUCT_MODEL := sawara1

PRODUCT_DEFAULT_PROPERTY_OVERRIDES := \
  persist.usb.serialno=$(PRODUCT_NAME)
