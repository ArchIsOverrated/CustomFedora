import xml.etree.ElementTree as ET

SOURCE_VM="Windows10VMTutorialBackup.xml"
TARGET_VM="Windows10PerformanceVM.xml"

tree = ET.parse(TARGET_VM)
root = tree.getroot()

memory_backing = root.find("memoryBacking")
if memory_backing is None:
    memory_backing = ET.SubElement(root, "memoryBacking")
    ET.SubElement(memory_backing, "hugepages")
elif memory_backing is not None:
    print("It's here!")

cpu_tune = root.find("cputune")
if cpu_tune is None:
    cpu_tune = ET.SubElement(root,"cputune")

tree.write(SOURCE_VM)
