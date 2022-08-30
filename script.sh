#!/bin/bash

MOUNT_DIR="$(readlink -f $(pwd)/mount)"
TOOL_DIR="$(readlink -f $(pwd))"
user="$LOGNAME"

function Usage() {
cat <<EOT
Usage:
$0 <GSI Image Path> [Other args]
  GSI Image Path: Path of gsi image

  Other args:
    [--help]: View this page
    
    You should use atleast one of these args below.
    [--make_datbr]: Convert img to new.dat.br
    [--debloat]: Debloat gsi
    [--extra_overlays]: Add more wifi and signal icons
    [--bt_fix]: Add bluetooth fix props
    [--umount]: Umount the image after finishing jobs (by default it will not umount)
    [--resize]: Shrink the image file
    [--add_graphenecam]: Add GrapheneOSCamera as a system app
EOT
}

case $1 in
  "-h"|"--help")
    Usage
    exit
    ;;
esac

if [ "$1" = "" ];then
  Usage
  exit
fi

if [ "$2" = "" ];then
  Usage
  exit
fi

gsi=$(readlink -f "$1")
gsi_name=$(echo ${image##*/} | sed 's/\.img//')
make_datbr="false"
debloat="false"
add_extra_overlays="false"
fix_bt="false"
skipmnt="false"
umount="false"
resize="false"
graphene="false"

mkdir -p mount

function mount() {
  if [ "$(mountpoint $MOUNT_DIR)" = "$MOUNT_DIR is not a mountpoint" ];then
    if [ "$skipmnt" = "false" ];then
      sudo rm -rf $MOUNT_DIR/*
      echo "[!] Mounting gsi image to $MOUNT_DIR!"
      sudo mount $gsi $MOUNT_DIR
    elif [ "$skipmnt" = "true" ];then
      echo ""
    fi
  else
    echo "[!] Image is already mounted, skipping mounting..."
  fi
}

function debloat() {
  mount
  echo "[!] Starting debloating..."
  echo "[*] Debloating useless overlays..."
  cd $MOUNT_DIR/system/product/overlay
  GLOBIGNORE=treble-overlay-NightMode.apk:treble-overlay-caf-ims.apk:treble-overlay-highpriomisc.apk:treble-overlay-devinputjack.apk:treble-overlay-hw-ims.apk:treble-overlay-misc-*:treble-overlay-mtk-ims.apk:treble-overlay-sec-ims.apk:treble-overlay-sprd-ims.apk:treble-overlay-tethering-nobpf.apk:treble-overlay-tethering.apk:treble-overlay-wifi5g.apk:treble-overlay-xiaomi-redminote8pro.apk && sudo rm -rf treble-overlay-* && unset GLOBIGNORE
  cd ../../app/
  sudo rm -rf *nokia* *oneplus* *mimix3* *redminote6pro*
  cd ../phh/
  sudo rm -rf bv9500plus-mtk-kpd.kl empty lenovo-synaptics_dsx.kl mimix3-gpio-keys.kl moto-* nokia-soc_gpio_keys.kl nubia-nubia_synaptics_dsx.kl oneplus6-synaptics_s3320.kl oppo-touchpanel.kl samsung-* unihertz-* zf6-goo* umidigi/ teracube2e-mtk-kpd.kl tecno-touchpanel.kl
  cd ../..
  echo "[*] Debloating google bloatware..."
  app_list="BasicDreams PlayAuto* Camera2 CarrierServices Calculator DevicePolicy Bug Bugle Scribe Maestro Micropaper SpeechServices EmergenyInfo Lens TouchAssistant Health MusicPlayerGO TagGoogle Recorder Map acebook YouTube Velvet Duo Videos Gmail Photos Keep Tips arcore ARCORE AndroidAuto Chrome LocationHistory Drive GoogleOne GoogleAssist TurboPrebuilt Telemetry Diagnostics BetaFeedback HelpRtcPrebuilt Hub GoogleCamera TTS"
  for app in $app_list; do
  sudo rm -rf system/*app/*$app*
  sudo rm -rf system/*/*app/*$app*
  done
  cd system/system_ext/apex/
  echo "[*] Debloating useless vndks (will leave only vndk30)..."
  sudo rm -rf com.android.vndk.v2* com.android.vndk.v31*
  echo "[!] Successfully finished debloating!"
  cd $TOOL_DIR
}

function add_extra_overlays() {
  mount
  echo "[!] Starting adding extra wifi and signal icons..."
  cd $MOUNT_DIR/system/product/overlay/
  sudo cp -r $TOOL_DIR/overlays/* . && echo "[!] Successfully finished adding extra icons!" || echo "[!] Failed to add extra icons!" 
  cd $TOOL_DIR
}

function fix_bluetooth() {
  mount
  echo "[!] Fixing bluetooth..."
  sudo chown $user:$user $MOUNT_DIR/system/build.prop
  cd $MOUNT_DIR/system/
  echo "persist.bluetooth.bluetooth_audio_hal.disabled=true" >> build.prop || echo "[!] Failed to add bluetooth fix!"
  echo "ro.bluetooth.library_name=libbluetooth_qti.so" >> build.prop || echo "[!] Failed to add bluetooth fix!"
  cd $TOOL_DIR
}

function addgraphene() {
  mount
  echo "[!] Adding GrapheneOSCamera"
  cd $MOUNT_DIR/system/priv-app/ && sudo mkdir -p GrapheneOSCamera && cd GrapheneOSCamera
  sudo cp -r $TOOL_DIR/graphenecam/GrapheneOSCamera.apk . && echo "[!] Successfully added graphene camera." || echo "[!] An error occurred. Porbably the gsi image doesnt have enough space. First run "$0 $gsi --debloat" then try again."
  cd $TOOL_DIR
}

function img_to_datbr() {
  if [ "$(mountpoint $MOUNT_DIR)" = "$MOUNT_DIR is a mountpoint" ];then
    echo "[!] Unmounting image..."
    sudo umount $MOUNT_DIR
  fi
  echo "[!] Starting converting img to dat.br"
  bash $TOOL_DIR/convertbr/img2datbr.sh $gsi || echo "[!] Something went wrong!"
}

function umount() {
  if [ "$(mountpoint $MOUNT_DIR)" = "$MOUNT_DIR is a mountpoint" ];then
    if [ "$umount" = "false" ];then
      if [ "$(mountpoint $MOUNT_DIR)" = "$MOUNT_DIR is not a mountpoint" ];then
        echo "[!] Image is already not mounted"
      fi
    elif [ "$umount" = "true" ];then
      echo "[!] Unmounting image..."
      sudo umount $MOUNT_DIR
    fi
  fi
}

function resize() {
  umount
  sudo e2fsck -f $gsi
  sudo resize2fs -M $gsi
}

if [ "$2" = "--debloat" ] || [ "$3" = "--debloat" ] || [ "$4" = "--debloat" ] || [ "$5" = "--debloat" ] || [ "$6" = "--debloat" ] || [ "$7" = "--debloat" ] || [ "$8" = "--debloat" ];then
  debloat="true"
else
  debloat="false"
fi

if [ "$debloat" = "true" ];then
  debloat
fi

if [ "$2" = "--extra_overlays" ] || [ "$3" = "--extra_overlays" ] || [ "$4" = "--extra_overlays" ] || [ "$5" = "--extra_overlays" ] || [ "$6" = "--extra_overlays" ] || [ "$7" = "--extra_overlays" ] || [ "$8" = "--extra_overlays" ];then
  add_extra_overlays="true"
else
  add_extra_overlays="false"
fi

if [ "$add_extra_overlays" = "true" ];then
  add_extra_overlays
fi

if [ "$2" = "--bt_fix" ] || [ "$3" = "--bt_fix" ] || [ "$4" = "--bt_fix" ] || [ "$5" = "--bt_fix" ] || [ "$6" = "--bt_fix" ] || [ "$7" = "--bt_fix" ] || [ "$8" = "--bt_fix" ];then
  fix_bt="true"
else
  fix_bt="false"
fi

if [ "$fix_bt" = "true" ];then
  fix_bluetooth
fi

if [ "$2" = "--add_graphenecam" ] || [ "$3" = "--add_graphenecam" ] || [ "$4" = "--add_graphenecam" ] || [ "$5" = "--add_graphenecam" ] || [ "$6" = "--add_graphenecam" ] || [ "$7" = "--add_graphenecam" ] || [ "$8" = "--add_graphenecam" ];then
  graphene="true"
else
  graphene="false"
fi

if [ "$graphene" = "true" ];then
  addgraphene
fi

if [ "$2" = "--umount" ] || [ "$3" = "--umount" ] || [ "$4" = "--umount" ] || [ "$5" = "--umount" ] || [ "$6" = "--umount" ] || [ "$7" = "--umount" ] || [ "$8" = "--umount" ];then
  umount="true"
else
  umount="false"
fi

if [ $umount = "true" ];then
  umount
fi

if [ "$2" = "--make_datbr" ] || [ "$3" = "--make_datbr" ] || [ "$4" = "--make_datbr" ] || [ "$5" = "--make_datbr" ] || [ "$6" = "--make_datbr" ] || [ "$7" = "--make_datbr" ] || [ "$8" = "--make_datbr" ];then
  make_datbr="true"
  skipmnt="true"
  umount="true"
else
  make_datbr="false"
fi

if [ "$make_datbr" = "true" ];then
  img_to_datbr
fi

if [ "$2" = "--resize" ] || [ "$3" = "--resize" ] || [ "$4" = "--resize" ] || [ "$5" = "--resize" ] || [ "$6" = "--resize" ] || [ "$7" = "--resize" ] || [ "$8" = "--resize" ];then
  resize="true"
  umount="true"
else
  resize="false"
fi

if [ "$resize" = "true" ];then
  resize
fi
