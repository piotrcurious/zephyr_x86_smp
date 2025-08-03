#!/bin/bash

# ==============================================================================
# Zephyr DTS Data Extraction Script for Legacy x86 Hardware (e.g., Intel 440BX)
# ==============================================================================
#
# This script is designed to assist in creating a Zephyr device tree source (.dts)
# file for a running system by extracting key hardware information. It gathers
# data from a live Linux environment and provides search commands to find relevant
# C code within a Linux kernel source tree.
#
# NOTE: This script is a data-gathering tool, not a complete DTS generator.
# The output must be manually interpreted and cross-referenced with your
# motherboard's documentation and the Linux kernel source to accurately
# create a functional Zephyr DTS file.
#
# Prerequisites:
# - Run this script on the physical machine you are targeting.
# - The following packages must be installed: dmidecode, lshw, lspci, pciutils.
# - A Linux kernel source tree (e.g., from kernel.org) should be available
#   for manual searching.
#
# ==============================================================================

echo "======================================================================="
echo "  Zephyr DTS Data Extraction Script"
echo "======================================================================="
echo ""

# Check for required tools
for cmd in dmidecode lshw lspci grep; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: Required command '$cmd' not found. Please install it."
    exit 1
  fi
done

# ==============================================================================
# 1. System Information (DMI)
# ==============================================================================
echo "[1] DMI (BIOS/Motherboard) Information:"
echo "---------------------------------------"
sudo dmidecode -t 2 | grep -E 'Manufacturer|Product Name|Version'
echo ""

# ==============================================================================
# 2. CPU and Memory Information
# ==============================================================================
echo "[2] CPU Information (/proc/cpuinfo):"
echo "------------------------------------"
grep 'processor' /proc/cpuinfo | wc -l | xargs echo "Number of CPUs:"
grep 'model name' /proc/cpuinfo | head -n 1
echo ""
echo "[3] Memory Information (free):"
echo "---------------------------------"
free -h | head -n 2
echo ""

# ==============================================================================
# 3. PCI Bus and Device Information
# ==============================================================================
echo "[4] PCI Bus Information (lspci):"
echo "-----------------------------------"
echo "This section is CRITICAL for the PCI host bridge and interrupt map."
echo "Look for the vendor:device IDs and IRQ lines."
echo ""
lspci -tvv | grep -E --color=always "Intel|440BX|PIIX4|IRQ"
echo ""
echo "Full PCI device list (vendor:device IDs are key):"
lspci -n
echo ""

# ==============================================================================
# 4. Interrupts (APIC and PIC)
# ==============================================================================
echo "[5] Interrupt Information (/proc/interrupts):"
echo "-----------------------------------------------"
echo "This shows the current IRQ usage, which helps validate device assignments."
cat /proc/interrupts
echo ""
echo "Finding APIC/PIC info from dmesg:"
dmesg | grep -E --color=always "APIC|PIC|IRQ|Interrupt"
echo ""

# ==============================================================================
# 5. Linux Kernel Source Search Guide
# ==============================================================================
echo "======================================================================="
echo "  GUIDE TO SEARCHING LINUX KERNEL SOURCE FOR DTS INFORMATION"
echo "======================================================================="
echo ""
echo "The Linux kernel source is the canonical source for hardware initialization."
echo "Use 'grep' to find the C code that configures your hardware."
echo ""

# Assuming a Linux kernel source tree is at /usr/src/linux
LINUX_SRC_DIR="/usr/src/linux"
if [ ! -d "$LINUX_SRC_DIR" ]; then
  echo "Kernel source directory '$LINUX_SRC_DIR' not found. Please specify the path."
  echo "Example: export LINUX_SRC_DIR=/path/to/your/kernel/source"
else
  echo "Searching in kernel source at: $LINUX_SRC_DIR"
  echo "-----------------------------------------------------------------------"
  echo "To find the 440BX chipset driver (look for the PCI device ID):"
  echo "  grep -r 'INTEL_440BX_DEVICE_ID' $LINUX_SRC_DIR/drivers/pci/ | grep h"
  echo "  (or similar search for the PIIX4 Southbridge, device: 8086:7113)"
  echo ""
  echo "To find the APIC and SMP initialization code for x86:"
  echo "  grep -r 'intel_smp' $LINUX_SRC_DIR/arch/x86/kernel/smpboot.c"
  echo "  grep -r 'io_apic' $LINUX_SRC_DIR/arch/x86/kernel/apic/io_apic.c"
  echo ""
  echo "To find PCI IRQ routing for the 440BX (this is very complex):"
  echo "  grep -r 'intel_440bx_router' $LINUX_SRC_DIR/drivers/pci/quirks.c"
  echo "  (This code maps PCI interrupts to APIC vectors.)"
fi

echo ""
echo "======================================================================="
echo "  SCRIPT COMPLETE"
echo "======================================================================="
echo "Data has been collected. You now have the raw information to begin crafting"
echo "your Zephyr DTS file. The next step is manual research and coding."
echo ""
