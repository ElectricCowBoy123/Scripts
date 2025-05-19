old_cookie = ''
old_forgery = ''

new_cookie = ''
new_forgery = ''

only_online_flag = True

from ScreenConnectTools import ScreenConnectTools
from NinjaTools import NinjaTools

def main():
    old_devices_set = set()
    new_devices_set = set()

    old_offline_devices_set = set()
    new_offline_devices_set = set()

    old_macos_devices_set = set()
    new_macos_devices_set = set()

    days_offline = 200

    generation_count = 1 # var to count how many times a list has been generated, sometimes requests dont return full information set
    
    for _ in range(generation_count): # perform request multiple times for accuracy
        obj_ScreenConnectTools = ScreenConnectTools(uri='', cookie=old_cookie, forgery=old_forgery, port='8040') 
        json_old = obj_ScreenConnectTools.perform_request()

        obj_ScreenConnectTools = ScreenConnectTools(json_old, set(), only_online_flag) # Set True here to get only online devices
        old_devices = obj_ScreenConnectTools.filter_devices() 
        old_devices_set.update(old_devices)

        obj_ScreenConnectTools = ScreenConnectTools(json_data=json_old, device_set=set(), days_offline=days_offline) 
        old_offline_devices = obj_ScreenConnectTools.filter_offline_devices()
        old_offline_devices_set.update(old_offline_devices)

        obj_ScreenConnectTools = ScreenConnectTools(json_data=json_old, device_set=set(), return_only_online=only_online_flag) 
        old_macos_devices = obj_ScreenConnectTools.filter_macos_devices()
        old_macos_devices_set.update(old_macos_devices)

    generation_count = 1
    for _ in range(generation_count):
        obj_ScreenConnectTools = ScreenConnectTools(uri='', cookie=new_cookie, forgery=new_forgery) 
        json_new = obj_ScreenConnectTools.perform_request()
        
        obj_ScreenConnectTools = ScreenConnectTools(json_data=json_new, device_set=set(), return_only_online=only_online_flag) # Set True here to get only online devices
        new_devices = obj_ScreenConnectTools.filter_devices() 
        new_devices_set.update(new_devices)

        obj_ScreenConnectTools = ScreenConnectTools(json_data=json_new, device_set=set(), days_offline=days_offline) 
        new_offline_devices = obj_ScreenConnectTools.filter_offline_devices()
        new_offline_devices_set.update(new_offline_devices)

        obj_ScreenConnectTools = ScreenConnectTools(json_data=json_new, device_set=set(), return_only_online=only_online_flag) 
        new_macos_devices = obj_ScreenConnectTools.filter_macos_devices()
        new_macos_devices_set.update(new_macos_devices)

    if only_online_flag:
        print(f"\nThere are {len(old_devices_set)} Number of Online Devices in the Old ScreenConnect")
        print(f"There are {len(new_devices_set)} Number of Online Devices in the New ScreenConnect")
    else:
        print(f"\nThere are {len(old_devices_set)} Number of Devices in the Old ScreenConnect")
        print(f"There are {len(new_devices_set)} Number of Devices in the New ScreenConnect")

    devices_to_migrate = old_devices_set - new_devices_set
    devices_already_migrated = new_devices_set & old_devices_set

    if not only_online_flag:
        print('\nThe Following Devices Need to be Migrated in General:')
    else:
        print('\nThe Following Online Devices Need to be Migrated in General:')

    for device in sorted(devices_to_migrate):
        print(device)

    obj_NinjaTools = NinjaTools(device_set=devices_to_migrate)
    ninja_devices_to_migrate = obj_NinjaTools.check_in_ninja()

    obj_ScreenConnectTools = ScreenConnectTools(device_set=devices_to_migrate)
    devices_to_migrate_santised = obj_ScreenConnectTools.sanitise_names()

    devices_to_migrate_minus_ninja = devices_to_migrate_santised - ninja_devices_to_migrate

    macos_devices_to_migrate = old_macos_devices_set - new_macos_devices_set

    if not only_online_flag:
        print(f'\nThe Following Devices ({len(devices_to_migrate_minus_ninja)}) (Minus Ninja) Need to be Migrated in General:')
    else:
        print(f'\nThe Following Online Devices ({len(devices_to_migrate_minus_ninja)}) (Minus Ninja) Need to be Migrated in General:')

    for device in sorted(devices_to_migrate_minus_ninja):
        print(device)
    
    if not only_online_flag:
        print(f"\nThe Following Devices ({len(ninja_devices_to_migrate)}) are in Ninja to be Migrated: ")
    else:
        print(f"\nThe Following Online Devices ({len(ninja_devices_to_migrate)}) are in Ninja to be Migrated: ")
    for device in sorted(ninja_devices_to_migrate):
        print(f"{device}")

    if not only_online_flag:
        print(f"\nThe Following Devices ({len(devices_already_migrated)}) are Already Migrated: ")
    elif len(devices_already_migrated) > 0:
        print(f"\nThe Following Online Devices ({len(devices_already_migrated)}) are Already Migrated: ")
    for device in sorted(devices_already_migrated):
        print(f"{device}")

    if not only_online_flag:
        print(f'\nThe Following Devices ({len(old_offline_devices_set)}) Have Been Offline for Longer than {days_offline} Days in the Old ScreenConnect:')
        for device in sorted(old_offline_devices_set):
            print(device)
        print(f'\nThe Following Devices ({len(new_offline_devices_set)}) Have Been Offline for Longer than {days_offline} Days in the New ScreenConnect:')
        for device in sorted(new_offline_devices_set):
            print(device)

    if not only_online_flag:
        print(f'\nThe Following MacOS Devices ({len(macos_devices_to_migrate)}) Need to be Migrated in General:')
    else:
        print(f'\nThe Following Online MacOS Devices ({len(macos_devices_to_migrate)}) Need to be Migrated in General:')

    for device in sorted(macos_devices_to_migrate):
        print(device)

    if not only_online_flag:
        confirmed = False
        confirmation = input("\nProceed to Wake On LAN in Old ScreenConnect? (Y/N) ")
        while not confirmed:
            if confirmation.lower() == 'y':
                confirmed = True
            if confirmation.lower() == 'n':
                print('Skipping!')
                break

        if confirmed:
            for device_name in devices_to_migrate: 
                obj_ScreenConnectTools = ScreenConnectTools(uri='', cookie=old_cookie, forgery=old_forgery, port='8040', device_name=device_name)
                obj_ScreenConnectTools.wake_on_lan()

    if len(devices_already_migrated) > 0:
        confirmed = False
        confirmation = input("\nProceed to Delete from Old ScreenConnect? (CONFIRM/N) ")
        while not confirmed:
            if confirmation.lower() == 'confirm':
                confirmed = True
            if confirmation.lower() == 'n':
                confirmed = False
                print('Skipping!')
                break

        if confirmed:
            for device in devices_already_migrated:
                print(f"\nAttempting to Delete {device} from Old ScreenConnect!")
                obj_ScreenConnectTools = ScreenConnectTools(device_name=device, cookie=old_cookie, forgery=old_forgery)
                return_code = obj_ScreenConnectTools.perform_delete_request()
                if return_code != 1:
                    print(f"{device} Deleted!")

if __name__ == "__main__":
    main()