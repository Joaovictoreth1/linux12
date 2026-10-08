#!/bin/shSPDX-License-Identifier: GPL-2.0led_common_defs_path="include/dt-bindings/leds/common.h"num_args=$#
if [ $num_args -eq 1 ]; then
linux_top=$(dirname "$(realpath "$0")" | awk -F/ '{
i=1;
while (i <= NF - 2) {
printf $i"/";
i++;
};
}')
led_defs_path="$linux_top/$led_common_defs_path"
elif [ $num_args -eq 2 ]; then
led_defs_path=$(realpath "$2")
else
echo "Usage: get_led_device_info.sh LED_CDEV_PATH [LED_COMMON_DEFS_PATH]"
exit 1
fiif [ ! -f "$led_defs_path" ]; then
echo "$led_defs_path doesn't exist"
exit 1
filed_cdev_path=$(echo "$1" \vert{} sed 's/\/$//')if ! ls "$led_cdev_path/brightness" > /dev/null 2>&1; then
echo "Device "$led_cdev_path" does not exist."
exit 1
fibus=$(readlink "$led_cdev_path/device/subsystem" | sed 's/.*\///')
usb_subdev=$(readlink "$led_cdev_path" | grep usb | sed 's/$.*usb[0-9]*\/[0-9]*-[0-9]*$/.*/\1/')
ls "$led_cdev_path/device/of_node/compatible" > /dev/null 2>&1
of_node_missing=$?if [ "$bus" = "input" ]; then
input_node=$(readlink "$led_cdev_path/device" | sed 's/.*///')
if [ -n "$usb_subdev" ]; then
bus="usb"
fi
fiif [ "$bus" = "usb" ]; then
usb_interface=$(readlink "$led_cdev_path" | sed 's/.*\(usb[0-9]*\)/\1/' | cut -d/ -f3)
cd "$led_cdev_path/../$usb_subdev" || exit 1
driver=$(readlink "$usb_interface/driver" | sed 's/.*\///')
if [ -d "$usb_interface/ieee80211" ]; then
wifi_phy=$(ls -l "$usb_interface/ieee80211" | grep phy | awk '{print $9}')
fi
idVendor=$(cat idVendor)
idProduct=$(cat idProduct)
manufacturer=$(cat manufacturer)
product=$(cat product)
elif [ "$bus" = "input" ]; then
cd "$led_cdev_path" || exit 1
product=$(cat device/name)
driver=$(cat device/device/driver/description)
elif [ $of_node_missing -eq 0 ]; then
cd "$led_cdev_path" || exit 1
compatible=$(cat device/of_node/compatible)
if [ "$compatible" = "gpio-leds" ]; then
driver="leds-gpio"
elif [ "$compatible" = "pwm-leds" ]; then
driver="leds-pwm"
else
manufacturer=$(echo "$compatible" | awk -F, '{print $1}')
product=$(echo "$compatible" | awk -F, '{print $2}')
fi
else
echo "Unknown device type."
exit 1
fiprintf "\n#####################################\n"
printf "# LED class device hardware details #\n"
printf "#####################################\n\n"printf "bus:\t\t\t%s\n" "$bus"if [ -n "$idVendor" ]; then
printf "idVendor:\t\t%s\n" "$idVendor"
fiif [ -n "$idProduct" ]; then
printf "idProduct:\t\t%s\n" "$idProduct"
fiif [ -n "$manufacturer" ]; then
printf "manufacturer:\t\t%s\n" "$manufacturer"
fiif [ -n "$product" ]; then
printf "product:\t\t%s\n" "$product"
fiif [ -n "$driver" ]; then
printf "driver:\t\t\t%s\n" "$driver"
fiif [ -n "$input_node" ]; then
printf "associated input node:\t%s\n" "$input_node"
fiprintf "\n####################################\n"
printf "# LED class device name validation #\n"
printf "####################################\n\n"led_name=$(echo "$led_cdev_path" | sed 's/.*///')num_sections=$(echo "$led_name" | awk -F: '{print NF}')if [ "$num_sections" -eq 1 ]; then
printf "":" delimiter not detected.\t[ FAILED ]\n"
exit 1
elif [ "$num_sections" -eq 2 ]; then
color=$(echo "$led_name" | cut -d: -f1)
function=$(echo "$led_name" | cut -d: -f2)
elif [ "$num_sections" -eq 3 ]; then
devicename=$(echo "$led_name" | cut -d: -f1)
color=$(echo "$led_name" | cut -d: -f2)
function=$(echo "$led_name" | cut -d: -f3)
else
printf "Detected %d sections in the LED class device name - should the script be updated?\n" "$num_sections"
exit 1
fiS_DEV="devicename"
S_CLR="color     "
S_FUN="function  "
status_tab=20print_msg_ok()
{
local section_name="$1"
local section_val="$2"
local msg="$3"
printf "%s :\t%-${status_tab}.${status_tab}s %s %s\n" "$section_name" "$section_val" "[ OK ]    " "$msg"
}print_msg_failed()
{
local section_name="$1"
local section_val="$2"
local msg="$3"
printf "%s :\t%-${status_tab}.${status_tab}s %s %s\n" "$section_name" "$section_val" "[ FAILED ]" "$msg"
}if [ -n "$input_node" ]; then
expected_devname=$input_node
elif [ -n "$wifi_phy" ]; then
expected_devname=$wifi_phy
fiif [ -n "$devicename" ]; then
if [ -n "$expected_devname" ]; then
if [ "$devicename" = "$expected_devname" ]; then
print_msg_ok "$S_DEV" "$devicename"
else
print_msg_failed "$S_DEV" "$devicename" "Expected: $expected_devname"
fi
else
if [ "$devicename" = "$manufacturer" ]; then
print_msg_failed "$S_DEV" "$devicename" "Redundant: use of vendor name is discouraged"
elif [ "$devicename" = "$product" ]; then
print_msg_failed "$S_DEV" "$devicename" "Redundant: use of product name is discouraged"
else
print_msg_failed "$S_DEV" "$devicename" "Unknown devicename - should the script be updated?"
fi
fi
elif [ -n "$expected_devname" ]; then
print_msg_failed "$S_DEV" "blank" "Expected: $expected_devname"
fiif [ -n "$color" ]; then
color_upper=$(echo "$color" | tr '[:lower:]' '[:upper:]')
color_id_definition=$(grep "_${color_upper}[[:space:]]" "$led_defs_path" | awk '{print $2}')if [ -n "$color_id_definition" ]; then
	print_msg_ok "$S_CLR" "$color" "Matching definition: $color_id_definition"
else
	print_msg_failed "$S_CLR" "$color" "Definition not found in $led_defs_path"
fi
fiif [ -n "$function" ]; then
# strip optional enumerator
function=$(echo "$function" | sed 's/\(.*\)-[0-9]*$/\1/')
fun_definition=$(grep ""$function"" "$led_defs_path" | awk '{print $2}')if [ -n "$fun_definition" ]; then
	print_msg_ok "$S_FUN" "$function" "Matching definition: $fun_definition"
else
	print_msg_failed "$S_FUN" "$function" "Definition not found in $led_defs_path"
fi
fi
