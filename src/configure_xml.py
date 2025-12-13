#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
import hashlib

if len(sys.argv) != 5:
    print("Usage: configure_xml.py <xml-path> <cpu-list> <emulator-cpu-list> <cpu-vendor>")
    sys.exit(1)

xml_path = sys.argv[1]
cpu_list_str = sys.argv[2]
emulator_list = sys.argv[3]
cpu_vendor = sys.argv[4]

cpus = [c.strip() for c in cpu_list_str.split(",") if c.strip()]
print(cpus)

tree = ET.parse(xml_path)
root = tree.getroot()

# -----------------------------
# Add <memoryBacking><hugepages/>
# -----------------------------
def huge_pages():
    memoryBacking = root.find("memoryBacking")
    if memoryBacking is None:
        memoryBacking = ET.SubElement(root, "memoryBacking")

    # Remove existing children if any
    for child in memoryBacking.findall("*"):
        memoryBacking.remove(child)

    ET.SubElement(memoryBacking, "hugepages")

# -----------------------------
# CPU layout
# -----------------------------
def cpu_layout():
    cpu = root.find("cpu")
    if cpu is None:
        print("Error: your xml is broken there is no cpu defined!")
        sys.exit(1)

    # Remove existing topology (idempotent)
    for topo in cpu.findall("topology"):
        cpu.remove(topo)

    # Remove existing topoext feature (idempotent)
    for feat in cpu.findall("feature"):
        if feat.get("name") == "topoext":
            cpu.remove(feat)

    # Calculate topology
    total_vcpus = len(cpus)
    threads = 2
    cores = total_vcpus // threads

    topology = ET.SubElement(cpu, "topology", {
        "sockets": "1",
        "dies": "1",
        "clusters": "1",
        "cores": str(cores),
        "threads": str(threads),
    })

    # AMD-only topoext
    if cpu_vendor.lower() == "amd":
        ET.SubElement(cpu, "feature", {
            "policy": "require",
            "name": "topoext"
        })

# -----------------------------
# CPU pinning
# -----------------------------
def cpu_pinning():
    cputune = root.find("cputune")
    if cputune is None:
        cputune = ET.SubElement(root, "cputune")

    # Remove previous pins
    for pin in list(cputune.findall("vcpupin")):
        cputune.remove(pin)

    # Remove previous emulator pins
    for pin in list(cputune.findall("emulatorpin")):
        cputune.remove(pin)

    vcpu_elem = root.find("vcpu")

    if vcpu_elem is None or not vcpu_elem.text:
        print("Error: no <vcpu> element found")
        sys.exit(1)

    num_vcpus = int(vcpu_elem.text)

    # Only pin what the user gave
    for v in range(min(num_vcpus, len(cpus))):
        ET.SubElement(cputune, "vcpupin", {"vcpu": str(v), "cpuset": cpus[v]})
    ET.SubElement(cputune, "emulatorpin", {"cpuset": emulator_list})

# -----------------------------
# NVME emulation
# -----------------------------
def nvme_emulation():
    # Find <devices>
    devices = root.find("devices")
    if devices is None:
        print("Error: no <devices> element found")
        sys.exit(1)

    # Remove existing NVMe controllers (so we can re-add cleanly every run)
    for ctrl in list(devices.findall("controller")):
        if ctrl.get("type") == "nvme":
            devices.remove(ctrl)

    # Add NVMe controller (your libvirt expects it)
    ET.SubElement(devices, "controller", {"type": "nvme", "index": "0"})

    # Find the first real disk in the VM (usually the boot disk)
    disk = None
    for d in devices.findall("disk"):
        if d.get("device") == "disk":
            disk = d
            break

    if disk is None:
        print("Error: no <disk device='disk'> found")
        sys.exit(1)

    # Ensure <driver> exists and set performance-friendly options
    driver = disk.find("driver")
    if driver is None:
        driver = ET.SubElement(disk, "driver")

    driver.set("name", "qemu")
    driver.set("type", "qcow2")
    driver.set("cache", "none")
    driver.set("io", "native")
    driver.set("discard", "unmap")

    # Ensure <target> exists and set NVMe target
    target = disk.find("target")
    if target is None:
        target = ET.SubElement(disk, "target")

    target.set("dev", "nvme0n1")
    target.set("bus", "nvme")

    # Remove drive-style address (SATA/SCSI) if present; NVMe is PCIe
    for addr in list(disk.findall("address")):
        if addr.get("type") == "drive":
            disk.remove(addr)

    # Create/update <serial> (libvirt requires serial for NVMe)
    uuid_elem = root.find("uuid")
    if uuid_elem is None or uuid_elem.text is None or uuid_elem.text.strip() == "":
        print("Error: no <uuid> found (virt-install normally creates this)")
        sys.exit(1)

    vm_uuid = uuid_elem.text.strip()
    digest = hashlib.sha256(vm_uuid.encode("utf-8")).hexdigest()
    serial_value = "S5G" + digest[0:17]  # 20 chars total

    serial_elem = disk.find("serial")
    if serial_elem is None:
        serial_elem = ET.SubElement(disk, "serial")
    serial_elem.text = serial_value

cpu_layout()
cpu_pinning()
nvme_emulation()

tree.write(xml_path)
