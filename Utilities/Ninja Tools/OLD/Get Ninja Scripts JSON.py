import requests # type: ignore
import json
import argparse
import os

url = 'https://eu.ninjarmm.com/swb/s10/scripting/scripts'
categoriesUrl = 'https://eu.ninjarmm.com/swb/s10/scripting/categories'
policiesUrl = 'https://eu.ninjarmm.com/swb/s10/policy/list?nodeClassGroup=RMM'

def filter_items(categoryData, mainData):
    categoryDict = {category['id']: category['name'] for category in categoryData}
    for item in mainData:
        new_categories = []
        if 'scriptVariables' in item:
            script_variable_names = [var['name'] for var in item['scriptVariables']]
            if item['name'] not in script_variable_names:
                for catId in item['categoriesIds']:
                    if catId in categoryDict:
                        new_categories.append(categoryDict[catId])
        elif 'scriptVariables' not in item:
            for catId in item['categoriesIds']:
                    if catId in categoryDict:
                        new_categories.append(categoryDict[catId])
        item['categoriesIds'] = new_categories
    return mainData

def get_session_key(session_key_file_path):
    try:
        with open(session_key_file_path, 'r') as file:
            session_key = file.read().strip()
        return session_key
    except FileNotFoundError:
        print(f"Error: The file '{session_key_file_path}' was not found!")
        return None
    except IOError:
        print(f"Error: An I/O error occurred while reading the file '{session_key_file_path}'")
        return None

def main(session_key=None, output_file=None, output_categories_file=None, output_policies_file=None):

    if session_key == None:
        session_key_file_path = os.path.abspath('./Deployment/active_sessionkey.txt')
        session_key = get_session_key(session_key_file_path)

    if output_file == None:
        output_file = os.path.abspath("./JSON/Ninja.json")

    if output_categories_file == None:
        output_categories_file = os.path.abspath("./JSON/Categories.json")
    
    if output_policies_file == None:
        output_policies_file = os.path.abspath("./JSON/Policies.json")
    
    cookies = {
        'sessionKey': session_key
    }
    
    response = requests.get(url, cookies=cookies)
    if response.status_code == 200:
        print("Main Request was Successful!")
        mainData = response.json()
    else:
        print(f"Main Request Failed with Status Code: {response.status_code}")

    categoriesResponse = requests.get(categoriesUrl, cookies=cookies)
    if categoriesResponse.status_code == 200:
        print("Categories Request was Successful!")
        categoriesData = categoriesResponse.json()
        with open(output_categories_file, 'w') as categories_outfile:
            json.dump(categoriesData, categories_outfile, indent=4)
    else:
        print(f"Categories Request Failed with Status Code: {response.status_code}")

    policiesResponse = requests.get(policiesUrl, cookies=cookies)
    if policiesResponse.status_code == 200:
        print("Policies Request was Successful!")
        policiesData = policiesResponse.json()
        with open(output_policies_file, 'w') as policies_outfile:
            json.dump(policiesData, policies_outfile, indent=4)
    else:
        print(f"Policies Request Failed with Status Code: {response.status_code}")

    if categoriesResponse.status_code == 200 and response.status_code == 200:
        mainData = filter_items(categoriesData, mainData)
        with open(output_file, 'w') as outfile:
            json.dump(mainData, outfile, indent=4)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Performs GET Request at /s10/scripting/scripts and at /s10/scripting/categories on 'eu.ninjarmm.com'. Stores Output in File. Requests the sessionKey")
    parser.add_argument("--session_key", help="Session key cookie value to use for the request", type=str, required=False)
    parser.add_argument("--output_file", help="Full path to the output JSON file for the main request", type=str, required=False)
    parser.add_argument("--output_categories_file", help="Full path to the output JSON file for the categories request", type=str, required=False)
    parser.add_argument("--output_policies_file", help="Full path to the output JSON file for the policies request", type=str, required=False)
    args = parser.parse_args()
    main(args.session_key, args.output_file, args.output_categories_file, args.output_policies_file)
