import json
import argparse
import requests # type: ignore
import base64
import re
import os
import random
import math
import time
import shutil


start_time = time.time()

class Colors:
    RESET = "\033[0m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    ORANGE = "\033[38;5;208m"

def delete_all_in_directory(directory):
    for filename in os.listdir(directory):
        file_path = os.path.join(directory, filename)
        if os.path.isfile(file_path):
            print(f"{Colors.ORANGE}Deleting {file_path}...{Colors.RESET}")
            os.remove(file_path) 
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)
    print(f"{Colors.GREEN}All files and subdirectories in '{directory}' have been deleted.{Colors.RESET}")


def has_files_or_subdirs(directory):
    if os.path.exists(directory) and os.path.isdir(directory):
        for entry in os.listdir(directory):
            if os.path.isfile(os.path.join(directory, entry)) or os.path.isdir(os.path.join(directory, entry)):
                return True
    return False

def get_directory_size(directory):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(directory):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)

            if os.path.isfile(file_path):
                total_size += os.path.getsize(file_path)
    return total_size

def random_color():
    return f"\033[{random.randint(30, 37)}m"

def sanitize_filename(filename):
    illegal_chars_pattern = r'[<>:"/\\|?*\x00-\x1F]'
    
    sanitized = re.sub(illegal_chars_pattern, '_', filename)
    
    sanitized = sanitized.strip()  
    sanitized = sanitized[:255]  
    
    return sanitized

def filter_id_items(data):
    result = []
    for item in data: 
        result.append(item['id'])
    return result 

def filter_category_items(data):
    result = []
    for item in data: 
        result.append(item['name'])
    return result

errors = []

baseURL = "https://eu.ninjarmm.com/s10/scripting/scripts/"
def main(session_key, input_file, categories_file, destination_dir):
    cookies = {
        'sessionKey': session_key
    }

    if destination_dir.endswith('/') or destination_dir.endswith('\\'):
        destination_dir = destination_dir[:-1]
    
    if has_files_or_subdirs(os.path.abspath(destination_dir)):
        print(f"{Colors.ORANGE}\nDirectory is Not Empty!{Colors.RESET}")
        broke = False
        while(not broke):
            usrin = input(f"{Colors.ORANGE}Enter Y to Delete all Files in Destination Directory {os.path.abspath(destination_dir)}{Colors.RESET}\n")
            if usrin.upper() == "Y":
                print(f"{Colors.GREEN}Deleting all files in {os.path.abspath(destination_dir)}{Colors.RESET}")
                delete_all_in_directory(os.path.abspath(destination_dir))
                broke = True
            elif usrin.upper() == "N":
                print(f"{Colors.GREEN}Continuing without Deleting Files from destination dir{Colors.RESET}")
                broke = True
            else:
                print(f"{Colors.RED}Enter a Valid Option!{Colors.RESET}\n")

    with open(input_file, 'r') as file:
        data = json.load(file)

    with open(categories_file, 'r') as file:
        category_data = json.load(file)

    result = filter_id_items(data)
    category_id_to_name = {category['id']: category['name'] for category in category_data}

    write_count = 0
    for id in result:
        url = f"https://eu.ninjarmm.com/s10/scripting/scripts/{id}"
        response = requests.get(url, cookies=cookies)

        if response.status_code == 200:
            item_data = response.json()

            if 'code' in item_data:
                base64_string = item_data['code']
                decoded_bytes = base64.b64decode(base64_string)
                code = decoded_bytes.decode('utf-8')

                if item_data['language'] == 'sh':
                    extension = 'sh'
                    color = Colors.GREEN
                elif item_data['language'] == 'powershell':
                    extension = 'ps1'
                    color = Colors.BLUE
                elif item_data['language'] == 'batchfile':
                    extension = 'bat'
                    color = Colors.MAGENTA
                else:
                    extension = f".{item_data['language']}"
                    color = Colors.YELLOW

                if item_data['language'] != 'native':
                    name = item_data['name']
                    if name.find('.') != -1:
                        name = name.replace('.', '')

                    if extension.find('.') != -1:
                        extension = extension.replace('.', '')

                    name = sanitize_filename(name)

                    for os_str in item_data['operatingSystems']:
                        os_dir = f"{destination_dir}/{os_str}"
                        if not os.path.exists(os_dir):
                            os.makedirs(os_dir)

                        for category_id in item_data['categoriesIds']:
                            category_name = category_id_to_name.get(category_id)
                            if category_name:  # Check if the category name exists
                                category_dir = f"{os_dir}/{category_name}"
                                if not os.path.exists(category_dir):
                                    os.makedirs(category_dir)
                                    print(f"{Colors.CYAN}Created directory: {category_dir}{Colors.RESET}")

                                file_path = f"{category_dir}/{name}.{extension}"
                                print(f"{color}Writing File: {file_path}{Colors.RESET}")
                                with open(file_path, 'w') as file:
                                    file.write(code)
                                    write_count += 1
                            else:
                                print(f"{Colors.RED}Category ID {category_id} not found in category mapping for script '{name}'!{Colors.RESET}")
                                errors.append(f"{Colors.RED}Category ID {category_id} not found in category mapping for script '{name}'!{Colors.RESET}")
                                errors.append(f"")
            else:
                print(f"{Colors.RED}Cannot find code for {id} - {name}!{Colors.RESET}")
                errors.append(f"{Colors.RED}Cannot find code for {id} - {name}!{Colors.RESET}")
                errors.append(f"")

    total_size = math.ceil(get_directory_size(destination_dir) / (1024 * 1024))
    end_time = time.time()
    print(f"{Colors.CYAN}\nTotal Writes: {write_count}{Colors.RESET}")
    print(f"{Colors.CYAN}Total Scripts in Ninja: {len(result)}{Colors.RESET}")
    print(f"{Colors.CYAN}Total Size: {total_size}MB{Colors.RESET}")
    print(f"{Colors.CYAN}Runtime: {math.ceil(end_time - start_time)}s{Colors.RESET}")
    print(f"{Colors.RED}\nErrors:{Colors.RESET}")
    for error in errors:
        print(f"{Colors.RED}{error}{Colors.RESET}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pulls all of the scripts in Ninja based on a JSON file.")
    parser.add_argument("session_key", help="Session key cookie value to use for the request. Can be obtained by loading the script list in Ninja and checking in devtools at the cors requests", type=str)
    parser.add_argument("input_file", help="Full path to the input JSON file obtained from: Get Ninja Scripts JSON.py")
    parser.add_argument("categories_file", help="Full path to the categories JSON file obtained from: Get Ninja Scripts JSON.py")
    parser.add_argument("destination_dir", help="Full path to the directory to store the scripts, if this is not empty you will be prompted to delete all subdirs and files")
    args = parser.parse_args()
    main(args.session_key, args.input_file, args.categories_file, args.destination_dir)