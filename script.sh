#!/bin/bash

MainPath="$(readlink -f -- $(pwd))"
MOUNT_DIR="$(readlink -f -- $MainPath/mount)"
TOOL_DIR="$(pwd)/tools"
RANPATH="0"

usage() {
cat <<EOT
Usage:
$0 -path "gsi image path" [Other args]
GSI Image Path: Path of gsi image
Other args:
  [-help]: View this page

  You should use atleast two of these flags below.
  [-path]: Path to the gsi image (The script will automatically mount the image)
  [-make_datbr]: Convert img to new.dat.br
  [-debloat]: Debloat gsi
  [-add_extra_overlays]: Add more wifi and signal icons
  [-bt_fix]: Add bluetooth fix props
  [-umount]: Umount the image after finishing jobs (by default it will not umount for future changes etc)
  [-resize]: Shrink the image file
  [-add_aperturecam]: Add Aperture Camera as a system app [Currently not available]
EOT
exit 0
}

add_extra_overlays() {
  echo "[!] Starting adding extra wifi and signal icons..."
  cd $MOUNT_DIR/system/product/overlay/ || exit 1
  sudo cp -r $TOOL_DIR/overlays/* . && echo "[*] Sucessfully added extra wifi and signal icons" || echo "[!] An error occured while adding extra wifi and signal icons"
  cd $MainPath
}

debloat() {
  if [ "$RANPATH" -eq 0 ]; then
    echo "[!] Please add -path flag and the gsi image path first. Exiting with code 1."
    exit 1
  fi
  if [ "$(findmnt $MOUNT_DIR)" = "" ]; then
    echo "[!] An error occured, the image is not mounted!"
    exit 1
  fi
  echo "[!] Starting debloating..."
  echo "[*] Debloating useless overlays..."
  cd $MOUNT_DIR/system/product/overlay
  GLOBIGNORE=treble-overlay-NightMode.apk:treble-overlay-caf-ims.apk:treble-overlay-highpriomisc.apk:treble-overlay-devinputjack.apk:treble-overlay-hw-ims.apk:treble-overlay-misc-*:treble-overlay-mtk-ims.apk:treble-overlay-sec-ims.apk:treble-overlay-sprd-ims.apk:treble-overlay-tethering-nobpf.apk:treble-overlay-tethering.apk:treble-overlay-wifi5g.apk:treble-overlay-xiaomi-redminote8pro.apk && sudo rm -rf treble-overlay-* && unset GLOBIGNORE
  cd ../../app/
  sudo rm -rf *nokia* *oneplus* *mimix3* *redminote6pro* empty || exit 1
  cd ../phh/
  sudo rm -rf bv9500plus-mtk-kpd.kl empty lenovo-synaptics_dsx.kl mimix3-gpio-keys.kl moto-* nokia-soc_gpio_keys.kl nubia-nubia_synaptics_dsx.kl oneplus6-synaptics_s3320.kl oppo-touchpanel.kl samsung-* unihertz-* zf6-goo* umidigi/ teracube2e-mtk-kpd.kl tecno-touchpanel.kl || exit 1
  cd ../..
  echo "[*] Debloating google bloatware..."
  app_list="BasicDreams PlayAuto* Camera2 CarrierServices Calculator DevicePolicy Bug Scribe Maestro SpeechServices EmergenyInfo Lens TouchAssistant Health MusicPlayerGO TagGoogle Recorder Map acebook YouTube Velvet Duo Videos Gmail Photos Keep Tips arcore ARCORE AndroidAuto Chrome LocationHistory Drive GoogleOne GoogleAssist TurboPrebuilt Telemetry Diagnostics BetaFeedback HelpRtcPrebuilt GoogleCamera TTS"
  for app in $app_list; do
  sudo rm -rf system/*app/*$app* || echo "[!] An error occured while debloating apps."
  sudo rm -rf system/*/*app/*$app* || echo "[!] An error occured while debloating apps."
  done
  cd system/system_ext/apex/
  echo "[*] Debloating useless vndks (will leave only vndk30)..."
  sudo rm -rf com.android.vndk.v2* com.android.vndk.v31* com.android.vndk.v32* com.android.vndk.v33* || echo "[!] An error occured while debloating vndks. Exiting with code 1."
  echo "[!] Successfully finished debloating!"
  cd $MainPath
}

fix_bluetooth() {
  echo "[*] Fixing bluetooth..."
  sudo chown $USER:$USER $MOUNT_DIR/system/build.prop || echo "[!] An error occured while adding bluetooth fix. Exiting with code 1."
  cd $MOUNT_DIR/system/
  if [ "$(grep 'persist.bluetooth.bluetooth_audio_hal.disabled=true' build.prop)" != "" ] && [ "$(grep 'ro.bluetooth.library_name=libbluetooth_qti.so' build.prop)" != "" ] ; then
    echo "[!] An error occured while adding bluetooth fix. The gsi already has the fix applied."
  else
    echo "persist.bluetooth.bluetooth_audio_hal.disabled=true" >> build.prop || echo "[!] An error occured while adding bluetooth fix."
    echo "ro.bluetooth.library_name=libbluetooth_qti.so" >> build.prop || echo "[!] An error occured while adding bluetooth fix."
    echo "[!] Successfully added bluetooth fix props"
  fi
  cd $MainPath
}

makedatbr() {
  if [ "$RANPATH" -eq 0 ]; then
    echo "[!] Please add -path flag and the gsi image path first. Exiting with code 1."
    exit 1
  fi
  umount
  echo "[!] Starting converting img to dat.br"
  bash $TOOL_DIR/convertbr/img2datbr.sh $GsiPath || echo "[!] An error occured while converting to dat.br."
}

mount() {
  if [ "$dont_mount" = "1" ]; then
    echo "[!] Don't mount is set. Skipping mounting."
  elif [ "$(findmnt $MOUNT_DIR)" = "" ]; then
    sudo umount $MOUNT_DIR &>/dev/null
    mkdir -p mount
    echo "[!] Mounting gsi image to $MOUNT_DIR!"
    sudo mount $GsiPath $MOUNT_DIR ||  echo "[!] An error occured while mounting image."
  else
    echo "[!] Image is already mounted, skipping mounting..."
  fi
}

path() {
  if [ ! -f "${GsiPath}" ];then
    echo "[!] Error: The file doesnt exist"
    exit 1
  else
    mount
  fi
}

resize() {
  if [ "$RANPATH" -eq 0 ]; then
    echo "[!] Please add -path flag and the gsi image path first. Exiting with code 1."
    exit 1
  fi
  umount &>/dev/null
  sudo e2fsck -f $GsiPath || exit 1
  sudo resize2fs -M $GsiPath || exit 1
}

umount() {
  if [ "$RANPATH" -eq 0 ]; then
    echo "[!] Please add -path flag and the gsi image path first. Exiting with code 1."
    exit 1
  fi
  if [ "$(findmnt $MOUNT_DIR)" = "" ]; then
    echo "[!] Image is already not mounted"
  else
    echo "[!] Unmounting image..."
    sudo umount $MOUNT_DIR || exit 1
  fi
}

if [ "$1" = "" ];then
  usage
  exit 1
fi

if [ "$(echo $@ | grep -o -e '\<debloat\>' -e '\<umount\>' -e '\<resize\>' -e '\<make_datbr\>' -e '\<add_extra_overlay\>' -e '\<add_extra_overlays\>' -e '\<bluetooth_fix\>' -e '\<bt_fix\>' -e '\<path\>' | wc -l)" -eq 0 ];then
  echo "[!] Unknwon flag is used.
  "
  sleep 1
  usage
  exit 1
fi

if [ "$(grep -o -E "path" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -path flag more than once."
  exit 1
elif [ "$(grep -o -E "make_datbr" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -make_datbr flag more than once."
  exit 1
elif [ "$(grep -o -E "debloat" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -debloat flag more than once."
  exit 1
elif [ "$(grep -o -E "add_extra_overlays" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -add_extra_overlay flag more than once. "
  exit 1
  exit 1
elif [ "$(grep -o -E "bt_fix" <<< "$@" | wc -l)" -ge 2 ] || [ "$(grep -o -E "bluetooth_fix" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -bt_fix flag more than once."
  exit 1
elif [ "$(grep -o -E "bt_fix" <<< "$@" | wc -l)" -eq 1 ] && [ "$(grep -o -E "bluetooth_fix" <<< "$@" | wc -l)" -eq 1 ];then
  echo "[!] You can not use the -bt_fix flag more than once."
  exit 1
elif [ "$(grep -o -E "umount" <<< "$@" | wc -l)" -ge 2 ] || [ "$(grep -o -E "unmount" <<< "$@" | wc -l)" -ge 2 ] ;then
  echo "[!] You can not use the -umount flag more than once."
  exit 1
elif [ "$(grep -o -E "umount" <<< "$@" | wc -l)" -eq 1 ] && [ "$(grep -o -E "unmount" <<< "$@" | wc -l)" -eq 1 ] ;then
  echo "[!] You can not use the -umount flag more than once."
  exit 1
elif [ "$(grep -o -E "resize" <<< "$@" | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -resize flag more than once."
  exit 1
fi

if [ "$(echo $1 | grep "path")" = "" ] ; then
  echo "[!] You should use -path as first flag.
Example: $0 -path 'gsi image path'"
  exit 1
fi

if [ "$(echo $1 | grep "path")" != "" ] && [ "$(echo $2)" = "" ] ; then
  echo "Option $1 requires an argument." >&2
  exit 1
fi

if [ "$(echo $@ | grep -o -e '\<path\>' | wc -l)" -ge 2 ];then
  echo "[!] You can not use the -path flag twice."
  exit 1
fi

if [ "$(echo $3)" = "" ] ; then
  echo "[!] You should use another flag after $1.
Example: $0 $1 "$2" -debloat
"
  sleep 1
  usage
  exit 1
fi

if [ "$(echo $3 | grep "umount")" != "" ] ; then
  echo "[!] You can not use $3 here. It should be on end of the command.
Example: $0 $1 "$2" -debloat $3"
  exit 1
fi

if [ "$(echo $@ | grep "debloat")" = "" ] && [ "$(echo $@ | grep "bt_fix")" = "" ] && [ "$(echo $@ | grep "add_extra_overlay")" = "" ] ; then
  dont_mount="1"
fi

while test $# -gt 0; do
  case "$1" in
     -h|--help)
       usage
      ;;
     -p|-path|--path)
       if [ "$2" != "" ];then
         GsiPath="$(readlink -f -- $2)"; GsiName=$(echo ${GsiPath##*/} | sed 's/\.img//'); RANPATH="1"; path
       else
         echo "Option $1 requires an argument." >&2
         exit 1
       fi
       shift 2
      ;;
     -make_datbr|--make_datbr)
       makedatbr
       shift
      ;;
     -debloat|--debloat)
       debloat
       shift
      ;;
     -add_extra_overlays|--add_extra_overlays)
       add_extra_overlays
       shift
      ;;
     -bt_fix|-bluetooth_fix|--bt_fix|--bluetooth_fix)
       fix_bluetooth
       shift
      ;;
     -umount|-unmount|--umount|--unmount)
       umount
       shift
      ;;
     -resize|--resize)
       resize
       exit 0
      ;;
     *)
       usage
       exit 0
      ;;
  esac
done
