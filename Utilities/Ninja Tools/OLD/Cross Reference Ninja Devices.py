import os
from NinjaTools import NinjaTools
from ScreenConnectTools import ScreenConnectTools

session_key_file_path = os.path.abspath('./active_sessionkey.txt')
obj_NinjaTools = NinjaTools(session_key_file_path=session_key_file_path)
ninja_device_set = obj_NinjaTools.get_all_ninja_devices()

device_list_file_path = os.path.abspath('./Utilities/DeviceList.txt')

device_list_set = set()

with open(device_list_file_path, 'r') as file:
    for line in file:
        device_list_set.add(line.strip())

obj_ScreenConnectTools = ScreenConnectTools(device_set=device_list_set)
device_list_set_sanitised = obj_ScreenConnectTools.sanitise_names()

devices_in_ninja = device_list_set_sanitised & ninja_device_set

for device in devices_in_ninja:
    print(device)
