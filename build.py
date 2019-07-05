import os
import shutil

addon_name = "WCCCAddOn"
addon_root_folder = "WCCCAddOn"
builds_folder = "Builds"

version_num = 0

with open(os.path.join(addon_root_folder, "WCCCAddOn.toc"), 'r') as toc_file:
    for line in toc_file:
        if "## Version:" in line:
            version_num = line.split()[2]

print("Building version " + version_num)

release_folder = os.path.join(builds_folder, version_num)
release_zip_path = os.path.join(release_folder, addon_name + "_" + version_num)

if not os.path.exists("Builds"):
    os.mkdir("Builds")

if os.path.isfile(release_zip_path):
    os.rm(release_zip_path)
    
shutil.make_archive(release_zip_path, "zip", os.path.join(addon_root_folder, os.pardir), addon_root_folder)