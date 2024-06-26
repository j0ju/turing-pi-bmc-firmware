#!/bin/bash

source helpers.sh
BMC_OTG="08de:1234"
RK1_USB="2207:350b"
LTE_MODEM="2c7c:0125"

get_usb_devices() {
    local node="$1"
    result=$(send_command $node "lsusb")
    # dont include the controller on the bus
    echo "$result" | grep -v 'Device 001' | grep -v '2109:3431'
}

get_pci_devices() {
    local n="$1"
    send_command "$n" "lspci | grep -v RK3588 | grep -v 'PCI bridge: Broadcom Inc'"
}

assert_pci_devices() {
    local node="$1"
    local count="$2"
    local devices=$(get_pci_devices "$node")
    local lte_modem=$(send_command $node "lsusb -d ${LTE_MODEM}" | awk '{for(i=3;i<=NF;i++) printf $i" "; print ""}')
    devices=$(echo -e "${devices}\n${lte_modem}" | grep -v '^$')


    if [ -z "$devices" ]; then
        line_count=0
    else
        line_count=$(echo "$devices" | wc -l)
        print_pci_names "$devices"
    fi

    if [ "$line_count" -lt "${count}" ]; then
        echo "Error: The test requires ${count} PCI devices connected to $node, found $line_count." >&2
        echo "Error: Verify the connected NVMe or MPCIe modules" >&2
        exit 1
    fi
}

assert_usb_devices() {
    local node="$1"
    local usb_count="$2"
    local usb_devices=$(get_usb_devices "$node")


    if [ -z "$usb_devices" ]; then
        line_count=0
    else
        line_count=$(echo "$usb_devices" | wc -l)
        print_usb_names "$usb_devices"
    fi

    if [[ "$line_count" -lt "$usb_count" ]]; then
        echo "Error: the test requires ${usb_count} USB devices connected to ${node}, found ${line_count}" >&2
        exit 1
    fi
}

print_usb_names() {
    local usb_devices="$1"
    local counter=1
    echo -e "\tUSB devices:"
    # Loop through each line and print the name of the USB device
    echo "$usb_devices" | while IFS= read -r line; do
    local dev=$(echo "$line" | awk '{for(i=7;i<=NF;i++) printf $i" "; print ""}')
    echo -e "\t\t${counter}. ${dev}"
    ((counter++))
done
}

print_pci_names() {
    local pci_devices="$1"
    local counter=1
    echo -e "\tDevices:"
    echo "$pci_devices" | while IFS= read -r line; do
    local dev=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}')
    echo -e "\t\t${counter}. ${dev}"
    ((counter++))
done
}

#usb_dev_test() {
#    tpi advanced msd --node 2 >/dev/null
#    tpi usb device --node 2 > /dev/null
#    confirm "plug the USB cable from 'BMC_USB_OTG' to the 'USB_DEV' port"
#    devices=$(get_usb_devices "1")
#    if echo "$devices" | grep -q "ID ${RK1_USB}"; then
#        echo -e "\tUSB_DEV => OK"
#    else
#        echo "$devices"
#        echo "Error: Could not detect 'USB_DEV' port"
#        exit 1
#    fi
#}

