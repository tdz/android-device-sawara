#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE=${DEVICE:-sawara}
COMMON=common
MANUFACTURER=${MANUFACTURER:-qcom}

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.id | sed -e 's/ro.build.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.id | sed -e 's/ro.build.id=//' | tr -d '\n\r'`
fi

case "$DEVICE_BUILD_ID" in
7.0.A.1.307*)
  FIRMWARE=ICS
  echo Found ICS firmware with build ID $DEVICE_BUILD_ID >&2
  ;;
*)
  FIRMWARE=unknown
  echo Found unknown firmware with build ID $DEVICE_BUILD_ID >&2
  echo Please download a compatible backup-${DEVICE} directory.
  echo Check the ${DEVICE} intranet page for information on how to get one.
  exit -1
  ;;
esac

if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
fi

BASE_PROPRIETARY_COMMON_DIR=vendor/$MANUFACTURER/$COMMON/proprietary
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/$DEVICE/proprietary
PROPRIETARY_COMMON_DIR=../../../$BASE_PROPRIETARY_COMMON_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR

for NAME in audio hw wifi etc
do
    mkdir -p $PROPRIETARY_COMMON_DIR/$NAME
done


COMMON_BLOBS_LIST=../../../vendor/$MANUFACTURER/$COMMON/vendor-blobs.mk

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $COMMON_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_COMMON_DIR
copy_file()
{
    echo Pulling \"$1\"
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        adb pull /$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    fi

    if [[ -f $PROPRIETARY_COMMON_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_COMMON_DIR/$4/$2:$3/$2 \\ >> $COMMON_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_COMMON_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo device/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\ >> $COMMON_BLOBS_LIST
    done
}

# amix
# aplay
#  arec
#  battery_logging
# btwlancoex
#  corecatcher
#  db-debug
#  dcfparser-test
#  diag_klog
#  diag_mdlog
#  drmmanager
#  EGLUtils_test
#  fmftmtest

FILES_SYSTEM_BIN="
  acdbtest
  anrprocdep
  ATFWD-daemon
  battery_monitor
  battery_shutdown
  bluetoothd
  bridgemgrd
  btnvtool
  cal_data_manager
  ccid_daemon
  chargemon
  clearpad_fwloader
  cnd
  crashmonitorns
  crda
  ctrlaltdel
  curl
  diag_uart_log
  drmdiagapp
  drmserver
  ds_fmc_appd
  fmconfig
  fm_qsoc_patches
  fota-snoop
  fsck_msdos
  ftmdaemon
  fwdlock-converter
  fwdlock-decoder
  gatord
  gatttool
  grabramdump
  hciattach
  hci_qcomm_init
  iddc
  iddd
  idd-logreader
  illumination_service
  ip
  isdbtmmtest
  iw
  klogrouter
  lcatp
  lsusb
  mm-adec-omxaac-test
  mm-adec-omxwma-test
  mm-aenc-omxaac-test
  mm-aenc-omxamr-test
  mm-aenc-omxevrc-test
  mm-aenc-omxqcelp13-test
  mm-audio-alsa-test
  mm-audio-ftm
  mm-jpeg-dec-test
  mm-jpeg-dec-test-client
  mm-jpeg-enc-test
  mm-jpeg-enc-test-client
  mm-jps-enc-test
  mm-mpo-dec-test
  mm-mpo-enc-test
  mm-pp-daemon
  mm-qcamera-daemon
  mm-qcamera-test
  mm-qcamera-testsuite-client
  mm-vdec-omx-test
  mm-venc-omx-test720p
  mm-video-driver-test
  mm-video-encdrv-test
  mpdecision
  mtpd
  netmgrd
  nl_listener
  omav1dcf-decoder-test
  pand
  ping
  ping6
  PktRspTest
  port-bridge
  powertop
  pppd
  profiler_daemon
  ptt_socket_app
  qcci_adc_test
  qmiproxy
  qmuxd
  qseecomd
  qseecom_sample_client
  qseecom_security_test
  quipc_igsn
  quipc_main
  racoon
  radish
  rb_repart
  ric
  rmt_storage
  rtspclient
  rtspserver
  sapd
  sdptool
  secchand
  sns_cm_conc_test
  sns_cm_test
  sns_smr_loopback_test
  startupflag
  stop_mdlog
  StoreKeybox
  suntrold
  system_monitor
  tad
  taimport
  ta_param_loader
  ta_qmi_service
  tc
  test_diag
  test_gemini
  thermald
  time_daemon
  touchd
  updatemiscta
  usbeng
  usbhub
  usbhub_init
  v4l2-qcamera-app
  wait4tad
  wiperiface
  wiperiface_v02
  wlanftmtest"

#copy_files "$FILES_SYSTEM_BIN" "system/bin" ""

COMMON_BINS="
  rmt_storage"

copy_files "$COMMON_BINS" "system/bin" ""

FILES_SYSTEM_ETC="
  apns-conf.xml
  be_movie
  clearpad_fwloader.sh
  fallback_fonts.xml
  flashled_calc_parameters.cfg
  gps.conf
  hw_config.sh
  iddd.conf
  init.netconfig.sh
  nfcee_access.xml
  OperatorPolicy.xml
  pre_hw_config.sh
  sensors.conf
  sysmon.cfg
  system_fonts.xml
  thermald.conf
  UserPolicy.xml
  vosfPlay.cfg
  voVidDec.dat
  wfdconfig.xml"

#copy_files "$FILES_SYSTEM_ETC" "system/etc" ""

FILES_SYSTEM_ETC_FIRMWARE="
  cyttsp_8960_cdp.hex
  dsps.b00
  dsps.b01
  dsps.b02
  dsps.b03
  dsps.b04
  dsps.b05
  dsps.flist
  dsps.mdt
  modem.b00
  modem.b01
  modem.b02
  modem.b03
  modem.b04
  modem.b05
  modem.b06
  modem_f1.b00
  modem_f1.b01
  modem_f1.b02
  modem_f1.b03
  modem_f1.b04
  modem_f1.b05
  modem_f1.b06
  modem_f1.b07
  modem_f1.b08
  modem_f1.b09
  modem_f1.b10
  modem_f1.b13
  modem_f1.b14
  modem_f1.b21
  modem_f1.b22
  modem_f1.b23
  modem_f1.b25
  modem_f1.b26
  modem_f1.b29
  modem_f1.flist
  modem_f1.mdt
  modem_f2.b00
  modem_f2.b01
  modem_f2.b02
  modem_f2.b03
  modem_f2.b04
  modem_f2.b05
  modem_f2.b06
  modem_f2.b07
  modem_f2.b08
  modem_f2.b09
  modem_f2.b10
  modem_f2.b13
  modem_f2.b14
  modem_f2.b21
  modem_f2.b22
  modem_f2.b23
  modem_f2.b25
  modem_f2.b26
  modem_f2.b29
  modem_f2.flist
  modem_f2.mdt
  modem.flist
  modem_fw.b00
  modem_fw.b01
  modem_fw.b02
  modem_fw.b03
  modem_fw.b04
  modem_fw.b05
  modem_fw.b06
  modem_fw.b07
  modem_fw.b08
  modem_fw.b09
  modem_fw.b10
  modem_fw.b13
  modem_fw.b14
  modem_fw.b21
  modem_fw.b22
  modem_fw.b23
  modem_fw.b25
  modem_fw.b26
  modem_fw.b29
  modem_fw.flist
  modem_fw.mdt
  modem.mdt
  q6.b00
  q6.b01
  q6.b03
  q6.b04
  q6.b05
  q6.b06
  q6.mdt
  touch_module_id_0x14.img
  touch_module_id_0x19.img
  touch_module_id_0x1a.img
  touch_module_id_0xff.img
  tzlibasb.b00
  tzlibasb.b01
  tzlibasb.b02
  tzlibasb.b03
  tzlibasb.flist
  tzlibasb.mdt
  tzs1sl.b00
  tzs1sl.b01
  tzs1sl.b02
  tzs1sl.b03
  tzs1sl.flist
  tzs1sl.mdt
  tzsuntory.b00
  tzsuntory.b01
  tzsuntory.b02
  tzsuntory.b03
  tzsuntory.flist
  tzsuntory.mdt
  vidc_1080p.fw
  vidc.b00
  vidc.b01
  vidc.b02
  vidc.b03
  vidcfw.elf
  vidc.mdt
  wcnss.b00
  wcnss.b01
  wcnss.b02
  wcnss.b04
  wcnss.flist
  wcnss.mdt"

#copy_files "$FILES_SYSTEM_ETC_FIRMWARE" "system/etc/firmware" ""

FILES_SYSTEM_ETC_FIRMWARE_WCD9310="
  wcd9310_anc.bin
  wcd9310_mbhc.bin"

#copy_files "$FILES_SYSTEM_ETC_FIRMWARE_WCD9310" "system/etc/firmware/wcd9310" ""

FILES_SYSTEM_ETC_FORMWARE_WLAN="
  macaddr0"

#copy_files "$FILES_SYSTEM_ETC_FIRMWARE_WLAN" "system/etc/firmware/wlan" ""

FILES_SYSTEM_ETC_FIRMWARE_WLAN_PRIMA="
  WCNSS_cfg.dat
  WCNSS_qcom_cfg.ini
  WCNSS_qcom_wlan_nv.bin"

#copy_files "$FILES_SYSTEM_ETC_FIRMWARE_WLAN_PRIMA" "system/etc/firmware/wlan/prima" ""

FILES_SYSTEM_ETC_PERMISSIONS="
  android.hardware.camera.flash-autofocus.xml
  android.hardware.camera.front.xml
  android.hardware.location.gps.xml
  android.hardware.nfc.xml
  android.hardware.sensor.accelerometer.xml
  android.hardware.sensor.compass.xml
  android.hardware.sensor.gyroscope.xml
  android.hardware.sensor.proximity.xml
  android.hardware.telephony.gsm.xml
  android.hardware.touchscreen.multitouch.jazzhand.xml
  android.hardware.usb.accessory.xml
  android.hardware.usb.host.xml
  android.hardware.wifi.direct.xml
  android.hardware.wifi.xml
  android.software.sip.voip.xml
  com.google.android.nfc_extras.xml
  com.google.protobuf-2.3.0.xml
  com.nxp.mifare.xml
  handheld_core_hardware.xml
  qcnvitems.xml
  qcrilhook.xml"

#copy_files "$FILES_SYSTEM_ETC_PERMISSIONS" "system/etc/permissions" ""

FILES_SYSTEM_ETC_SND_SOC_MSM="
  DL_REC_blue
  FM_REC_blue
  HiFi_blue
  HiFi_Low_Power_blue
  HiFi_Rec_blue
  snd_soc_msm_blue
  UL_DL_REC_blue
  Voice_Call_blue
  Voice_Call_IP_blue"

#copy_files "$FILES_SYSTEM_ETC_SND_SOC_MSM" "system/etc/snd_soc_msm" ""

FILES_SYSTEM_ETC_WIFI="
  gsm_domains.conf
  wpa_supplicant.conf"

#copy_files "$FILES_SYSTEM_ETC_WIFI" "system/etc/wifi" ""

FILES_SYSTEM_FONTS="
  AndroidClock_Highlight.ttf
  AndroidClock_Solid.ttf
  AndroidClock.ttf
  Clockopia.ttf
  DroidSansMono.ttf
  Lohit-Bengali.ttf
  Lohit-Devanagari.ttf
  Lohit-Tamil.ttf
  MozTT-Bold.ttf
  MozTT-Light.ttf
  MozTT-Medium.ttf
  MozTT-Regular.ttf
  SoMABold.ttf
  SoMADigitLight.ttf
  SoMARegular.ttf
  SoMC-HKSCS-Fallback.ttf
  SoMCSans-Regular.ttf
  thaidict.wtd"

#copy_files "$FILES_SYSTEM_FONTS" "system/fonts" ""

FILES_SYSTEM_LIB="
  drmclientlib.so
  libacdbloader.so
  libandroid_runtime.so
  libalarmservice_jni.so
  liballjoyn.so
  libalsa-intf.so
  libals.so
  libaudioflinger.so
  lib_asb_tee.so
  libaudcal.so
  libaudioalsa.so
  libbluedroid.so
  libbluetoothd.so
  libbluetooth.so
  libbson.so
  libbtio.so
  libcald_client.so
  libcald_hal.so
  libcald_imageutil.so
  libcald_pal.so
  libcald_server.so
  libcald_util.so
  libcamera_clientsemc.so
  libcameraextensionclient.so
  libcameraextensionjni.so
  libcameraextensionservice.so
  libcameralight.so
  libcneapiclient.so
  libcneqmiutils.so
  libcneutils.so
  libCommandSvc.so
  libconfigdb.so
  libcurl.so
  libcutils.so
  libDiagService.so
  libdiag.so
  libdivxdrmdecrypt.so
  libDivxDrm.so
  libdnshostprio.so
  libdrmdiag.so
  libdrmfs.so
  libdrmtime.so
  libdrmframework.so
  libdsi_netctrl.so
  libdsprofile.so
  libdss.so
  libdsucsd.so
  libdsutils.so
  libEffectOmxCore.so
  libEGL.so
  libexif.so
  libface.so
  libfastcvopt.so
  libFFTEm.so
  libFileMux.so
  libfmradio.so
  libgemini.so
  libgenlock.so
  libgeofence.so
  lib_get_rooting_status.so
  lib_get_secure_mode.so
  libGLESv1_CM.so
  libGLESv1_enc.so
  libGLESv2_dbg.so
  libGLESv2_enc.so
  libGLESv2.so
  libglib.so
  libgps.utils.so
  libhdminativecontrol.so
  libhdmi.so
  libhwui.so
  libI420colorconvert.so
  libiddjni.so
  libidd.so
  libidl.so
  libimage-jpeg-dec-omx-comp.so
  libimage-jpeg-enc-omx-comp.so
  libimage-omx-common.so
  libiprouteutil.so
  libiwiOmx.so
  libiwiOmxUtil.so
  libiwi.so
  libJNISecureClock.so
  libkeyctrl.so
  liblights-core.so
  libllvm-a3xx.so
  libloc_adapter.so
  libloc_api_v02.so
  libloc_eng.so
  libmedia.so
  libmedia_jni.so
  libmediaplayerservice.so
  libMiscTaAccessor.so
  libmiscta.so
  libmllite.so
  libmlplatform.so
  libmm-abl-oem.so
  libmm-abl.so
  libmm-audio-resampler.so
  libmmcamera_faceproc.so
  libmmcamera_frameproc.so
  libmmcamera_statsproc30.so
  libmm-color-convertor.so
  libmmipl.so
  libmmjpeg.so
  libmmjps.so
  libmmmpod.so
  libmmmpo.so
  libmmosal.so
  libmmparser.so
  libmmQSM.so
  libmmrtpencoder.so
  libmmstereo.so
  libmmstillomx.so
  libmmwfdinterface.so
  libmmwfdsinkinterface.so
  libmmwfdsrcinterface.so
  libmonkeyprocess.so
  libmpl.so
  libMPU3050.so
  libmtpip.so
  libnetlink.so
  libnetmgr.so
  libnetmonitor.so
  libnetutils.so
  libnfc.so
  libNimsWrap.so
  libnl.so
  liboemcamera.so
  libOmxAacDec.so
  libOmxAacEnc.so
  libOmxAmrEnc.so
  libOmxEvrcDec.so
  libOmxEvrcEnc.so
  libOmxMux.so
  libOmxQcelp13Dec.so
  libOmxQcelp13Enc.so
  libOmxVdec.so
  libOmxVenc.so
  libOmxWmaDec.so
  libOpenCL.so
  libOpenglSystemCommon.so
  libpin-cache.so
  libprofiler_msmadc.so
  libprotobuf-c.so
  libqcci_adc.so
  libqc-opt.so
  libqdi.so
  libqdp.so
  libqmi_cci.so
  libqmi_common_so.so
  libqmi_csi.so
  libqmi_encdec.so
  libqmiservices.so
  libqmi.so
  libqsap_sdk.so
  libQSEEComAPI.so
  libquipc_os_api.so
  libquipc_ulp_adapter.so
  libQWiFiSoftApCfg.so
  lib_renderControl_enc.so
  libril-qc-qmi-1.so
  libroparsertest.so
  libs1sl.so
  lib_s1_verification.so
  libsensor1.so
  libsensor_reg.so
  libsensor_test.so
  libsensor_user_cal.so
  libSHIMDivxDrm.so
  libskia.so
  libsnpvideometadataretrieverjni.so
  libsolsengine.so
  libsolsextensionjni.so
  libsolsmetadataretriever.so
  libsqlite_jni.so
  libSR_AudioIn.so
  libsrec_jni.so
  libsrsprocessing.so
  libsurfaceflinger.so
  libSwiqiController.so
  libsysmon_jni.so
  libsysmon.so
  libsystem_server.so
  libsys-utils.so
  libstagefright.so
  libTamperDetect.so
  libta.so
  libtcpfinaggr.so
  libtextrendering.so
  libtilerenderer.so
  libtime_genoff.so
  libttscompat.so
  libttspico.so
  libtzplayready.so
  libulp2.so
  libulp.so
  libutils.so
  libv8.so
  libvideoeditor_jni.so
  libvideoeditorplayer.so
  libvoAVIFR.so
  libvoMKVFR.so
  libvosfEngn.so
  libvoVidDec.so
  libvptwrapper.so
  libwebkitaccel.so
  libwfdcommonutils.so
  libwfdhdcpcp.so
  libwfdmmsrc.so
  libwfdmmutils.so
  libwfdnative.so
  libwfdrtsp.so
  libwfdsm.so
  libwfduibcinterface.so
  libwfduibcsrcinterface.so
  libwfduibcsrc.so
  libwifiscanner.so
  libwiperjni.so
  libwiperjni_v02.so
  libwtle.so
  libxml.so
  libxt_native.so
  libxt_v02.so
  pp_proc_plugin.so
  qnet-plugin.so
  tcp-connections.so"

#copy_files "$FILES_SYSTEM_LIB" "system/lib" ""

FILES_SYSTEM_LIB_BLUEZ_PLUGIN="
  audio.so
  bluetooth-health.so
  input.so
  network.so"

#copy_files "$FILES_SYSTEM_LIB_BLUEZ_PLUGIN" "system/lib/bluez-plugin" ""

FILES_SYSTEM_LIB_CRDA="
  regulatory.bin"

#copy_files "$FILES_SYSTEM_LIB_CRDA" "system/lib/crda" ""

FILES_SYSTEM_LIB_DRM="
  libfwdlockengine.so
  libfwdlockengine-semc.so
  libomasdengine.so"

#copy_files "$FILES_SYSTEM_LIB_DRM" "system/lib/drm" ""

FILES_SYSTEM_LIB_HW="
  alsa.msm8960.so
  audio.a2dp.default.so
  audio_policy.msm8960.so
  audio.primary.msm8960.so
  camera.msm8960.so
  copybit.msm8960.so
  gralloc.goldfish.so
  lights.default.so
  nfc.msm8960.so
  sensors.default.so"

#copy_files "$FILES_SYSTEM_LIB_HW" "system/lib/hw" ""

FILES_SYSTEM_LIB_MODULES="
  ansi_cprng.ko
  bluetooth-power.ko
  cfg80211.ko
  dma_test.ko
  gator.ko
  ksapi.ko
  mmc_test.ko
  msm-buspm-dev.ko
  oprofile.ko
  qce40.ko
  qcedev.ko
  qcrypto.ko
  radio-iris-transport.ko
  reset_modem.ko
  scsi_wait_scan.ko
  wlan.ko"

#copy_files "$FILES_SYSTEM_LIB_MODULES" "system/lib/modules" ""

FILES_SYSTEM_LIB_MODULES_PRIMA="
  prima_wlan.ko"

#copy_files "$FILES_SYSTEM_LIB_MODULES_PRIMA" "system/lib/modules/prima" ""

FILES_SYSTEM_LIB_SOUNDFX="
  libclearaudiowrapper.so
  libhearingprotection.so
  libsoundaurawrapper.so
  libvptwrapper.so
  libxloudwrapper.so"

#copy_files "$FILES_SYSTEM_LIB_SOUNDFX" "system/lib/soundfx" ""

FILES_SYSTEM_LIB_SYSMON="
  sysmon_batt_therm.so
  sysmon_charge_current_limit_level0.so
  sysmon_charge_current_limit_level1.so
  sysmon_charge_current_limit_level2.so
  sysmon_charge_current_limit_level3.so
  sysmon_corelimit.so
  sysmon_disable_charging1.so
  sysmon_disable_charging2.so
  sysmon_enable_charging.so
  sysmon_lcd_brightness_level.so
  sysmon_modem_level0.so
  sysmon_modem_level1.so
  sysmon_modem_level2.so
  sysmon_modem_level3.so
  sysmon_msm_thermal_disable.so
  sysmon_pa_therm0.so
  sysmon_pa_therm1.so
  sysmon_perflevel.so
  sysmon_pm8921_tz.so
  sysmon_test_sensor.so
  sysmon_tsens_tz_sensor0.so
  sysmon_tsens_tz_sensor1.so
  sysmon_tsens_tz_sensor2.so
  sysmon_tsens_tz_sensor3.so
  sysmon_tsens_tz_sensor4.so
  sysmon_usb_current_limit_level0.so
  sysmon_usb_current_limit_level1.so
  sysmon_usb_current_limit_level2.so
  sysmon_usb_current_limit_level3.so
  sysmon_usb_current_limit_level4.so
  sysmon_xo_therm.so"

#copy_files "$FILES_SYSTEM_LIB_SYSMON" "system/lib/sysmon" ""

FILES_SYSTEM_MEDIA="
  bootanimation.zip"

#copy_files "$FILES_SYSTEM_MEDIA" "system/media" ""

FILES_SYSTEM_SEMC_CHARGEMON_DATA="
  charging_animation_01.png
  charging_animation_02.png
  charging_animation_03.png
  charging_animation_04.png
  charging_animation_05.png
  charging_animation_06.png
  charging_animation_07.png
  non-charging_animation_01.png
  non-charging_animation_02.png
  non-charging_animation_03.png
  non-charging_animation_04.png
  non-charging_animation_05.png
  non-charging_animation_06.png
  non-charging_animation_07.png"

#copy_files "$FILES_SYSTEM_SEMC_CHARGEMON_DATA" "system/semc/chargemon/data" ""

FILES_SYSTEM_TTS_LANG_PICO="
  de-DE_gl0_sg.bin
  de-DE_ta.bin
  en-GB_kh0_sg.bin
  en-GB_ta.bin
  en-US_lh0_sg.bin
  en-US_ta.bin
  es-ES_ta.bin
  es-ES_zl0_sg.bin
  fr-FR_nk0_sg.bin
  fr-FR_ta.bin
  it-IT_cm0_sg.bin
  it-IT_ta.bin"

#copy_files "$FILES_SYSTEM_TTS_LANG_PICO" "system/tts/lang_pico" ""

FILES_SYSTEM_USR_IDC="
  Atmel_maXTouch_Touchscreen_controller.idc
  atmel_mxt_ts.idc
  atmel-touchscreen.idc
  clearpad.idc
  ft5x06_ts.idc
  ft5x0x_ts.idc
  msg2133.idc
  sensor00fn11.idc"

#copy_files "$FILES_SYSTEM_USR_IDC" "system/usr/idc" ""

FILES_SYSTEM_USR_KEYLAYOUT="
  pmic8xxx_pwrkey.kl
  simple_remote_appkey.kl
  simple_remote.kl
  Vendor_045e_Product_0719.kl
  Vendor_046d_Product_c21a.kl
  Vendor_046d_Product_c21d.kl
  Vendor_0810_Product_0002.kl"

#copy_files "$FILES_SYSTEM_USR_KEYLAYOUT" "system/usr/keylayout" ""

FILES_SYSTEM_USR_SHARE_BMD="
  RFFspeed_501.bmd
  RFFstd_501.bmd"

#copy_files "$FILES_SYSTEM_USR_SHARE_BMD" "system/usr/share/bmd" ""

FILES_SYSTEM_USR_SREC_CONFIG_EN_US="
  baseline11k.par
  baseline8k.par
  baseline.par"

#copy_files "$FILES_SYSTEM_USR_SREC_CONFIG_EN_US" "system/usr/srec/config/en.us" ""

FILES_SYSTEM_USR_SREC_CONFIG_EN_US_DICTIONARY="
  basic.ok
  cmu6plus.ok.zip
  enroll.ok"

#copy_files "$FILES_SYSTEM_USR_SREC_CONFIG_EN_US_DICTIONARY" "system/usr/srec/config/en.us/dictionary" ""

FILES_SYSTEM_USR_SREC_CONFIG_EN_US_G2P="
  en-US-ttp.data"

#copy_files "$FILES_SYSTEM_USR_SREC_CONFIG_EN_US_G2P" "system/usr/srec/config/en.us/g2p" ""

FILES_SYSTEM_USR_SREC_CONFIG_EN_US_GRAMMARS="
  boolean.g2g
  phone_type_choice.g2g
  VoiceDialer.g2g"

#copy_files "$FILES_SYSTEM_USR_SREC_CONFIG_EN_US_GRAMMARS" "system/usr/srec/config/en.us/grammars" ""

FILES_SYSTEM_USR_SREC_CONFIG_EN_US_MODELS="
  generic11_f.swimdl
  generic11.lda
  generic11_m.swimdl
  generic8_f.swimdl
  generic8.lda
  generic8_m.swimdl
  generic.swiarb"

#copy_files "$FILES_SYSTEM_USR_SREC_CONFIG_EN_US_MODELS" "system/usr/srec/config/en.us/models" ""

FILES_SYSTEM_VENDOR_CAMERA="
  APT01BM0.dat
  flash.dat
  KMO13BS0_BU6456.dat
  KMO13BS0.dat
  KMO13BS0_IMX091.dat
  product.dat
  SOI13BS0_BU6456.dat
  SOI13BS0.dat
  SOI13BS0_IMX091.dat
  STW01BM0.dat"

#copy_files "$FILES_SYSTEM_VENDOR_CAMERA" "system/vendor/camera" ""

FILES_SYSTEM_VENTOR_ETC="
  audio_effects.conf
  fallback_fonts.xml
  system_fonts.xml"

#copy_files "$FILES_SYSTEM_VENDOR_ETC" "system/vendor/etc" ""

FILES_SYSTEM_VENDOR_FIRMWARE="
  libpn544_fw_c2.so
  libpn544_fw_c3.so"

#copy_files "$FILES_SYSTEM_VENDOR_FIRMWARE" "system/vendor/firmware" ""

FILES_SYSTEM_XBIN="
  agent
  attest
  avinfo
  avtest
  bdaddr
  bttest
  gtest_fwdlock
  gtest_fwdlockengine
  gtest_integration_getrootingstatus
  gtest_integration_getsecuremode
  gtest-integration-libasb
  gtest_integration_ric
  gtest_integration_s1verification
  gtest_integration_s1verification_static
  gtest_keyctrl
  gtest_omasdengine
  gtest_ro-db
  gtest-s1sl
  gtest-s1sl-public
  gtest_tee
  gtest_wbxml-parser
  hciconfig
  hcidump
  hcitool
  hstest
  l2ping
  l2test
  lmptest
  nc
  netperf
  netserver
  opcontrol
  oprofiled
  rctest
  rfcomm
  scotest
  scp
  sdptest
  ssh
  tcpdump"

#copy_files "$FILES_SYSTEM_XBIN" "system/xbin" ""

#if [ ! -f "../../../Adreno200-sawara.zip" ]; then
#	echo Adreno driver not found. Please download the "Adreno 2xx User-mode Android ICS Graphics Driver (ARMv7)" driver from
#  echo https://developer.qualcomm.com/mobile-development/mobile-technologies/gaming-graphics-optimization-adreno/tools-and-resources
#	echo and put the zip file in the top level B2G directory.
#  exit -1
#fi
#unzip -o -d ../../../vendor/$MANUFACTURER/$DEVICE ../../../Adreno200-sawara.zip

#(cat << EOF) | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > ../../../vendor/$MANUFACTURER/$DEVICE/$DEVICE-vendor-blobs.mk
## Copyright (C) 2010 The Android Open Source Project
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#
#LOCAL_PATH := vendor/$MANUFACTURER/$DEVICE
#
#PRODUCT_COPY_FILES := \
#    \$(LOCAL_PATH)/system/etc/firmware/a225p5_pm4.fw:system/etc/firmware/a225p5_pm4.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/a225_pfp.fw:system/etc/firmware/a225_pfp.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/a225_pm4.fw:system/etc/firmware/a225_pm4.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/a300_pfp.fw:system/etc/firmware/a300_pfp.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/a300_pm4.fw:system/etc/firmware/a300_pm4.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/leia_pfp_470.fw:system/etc/firmware/leia_pfp_470.fw \\
#    \$(LOCAL_PATH)/system/etc/firmware/leia_pm4_470.fw:system/etc/firmware/leia_pm4_470.fw \\
#    \$(LOCAL_PATH)/system/lib/libC2D2.so:system/lib/libC2D2.so \\
#    \$(LOCAL_PATH)/system/lib/libsc-a2xx.so:system/lib/libsc-a2xx.so \\
#    \$(LOCAL_PATH)/system/lib/libgsl.so:system/lib/libgsl.so \\
#    \$(LOCAL_PATH)/system/lib/libOpenVG.so:system/lib/libOpenVG.so \\
#    \$(LOCAL_PATH)/system/lib/egl/egl.cfg:system/lib/egl.cfg \\
#    \$(LOCAL_PATH)/system/lib/egl/libGLESv1_CM_adreno200.so:system/lib/egl/libGLESv1_CM_adreno200.so \\
#    \$(LOCAL_PATH)/system/lib/egl/libEGL_adreno200.so:system/lib/egl/libEGL_adreno200.so \\
#    \$(LOCAL_PATH)/system/lib/egl/eglsubAndroid.so:system/lib/egl/eglsubAndroid.so \\
#    \$(LOCAL_PATH)/system/lib/egl/libGLESv2_adreno200.so:system/lib/egl/libGLESv2_adreno200.so \\
#    \$(LOCAL_PATH)/system/lib/egl/libGLESv2S3D_adreno200.so:system/lib/egl/libGLESv2S3D_adreno200.so \\
#    \$(LOCAL_PATH)/system/lib/egl/libq3dtools_adreno200.so:system/lib/egl/libq3dtools_adreno200.so \\
#    \$(LOCAL_PATH)/system/lib/egl/libGLES_android.so:system/lib/egl/libGLES_android.so
#EOF

BOOTIMG=boot-sawara.img
if [ -f ../../../${BOOTIMG} ]; then
    (cd ../../.. && ./build.sh unbootimg)
    . ../../../build/envsetup.sh
    HOST_OUT=$(get_build_var HOST_OUT_$(get_build_var HOST_BUILD_TYPE))
    KERNEL_DIR=../../../vendor/${MANUFACTURER}/${DEVICE}
    cp ../../../${BOOTIMG} ${KERNEL_DIR}
    ../../../${HOST_OUT}/bin/unbootimg ${KERNEL_DIR}/${BOOTIMG}
    mv ${KERNEL_DIR}/${BOOTIMG}-kernel ${KERNEL_DIR}/kernel
    rm -f ${KERNEL_DIR}/${BOOTIMG}-ramdisk.cpio.gz ${KERNEL_DIR}/${BOOTIMG}-second ${KERNEL_DIR}/${BOOTIMG}-mk ${KERNEL_DIR}/${BOOTIMG}
fi
