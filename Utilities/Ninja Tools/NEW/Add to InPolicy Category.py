""" 
- Adds scripts into an 'In Policy' category if they are used in a policy 
- Determines what ID belongs to the 'In Policy' category before sending the request
- Ensures the code is present before sending the request 
"""

import json
import argparse
import os
from NinjaTools import add_category

def main(script_input_json=None):
    # Load the script JSON data
    if script_input_json is None:
        script_input_json_path = os.path.abspath("./JSON/Ninja.json")
        with open(script_input_json_path, 'r') as file:
            script_input_json = json.load(file)  # Load the JSON data into a Python object

    # Load the policy JSON data
    policy_file_path = os.path.abspath("./JSON/Policy_Script_Report.json")
    with open(policy_file_path, 'r') as file:
        policy_content = file.read()

    # Load the categories JSON data
    category_file_path = os.path.abspath("./JSON/Categories.json")
    with open(category_file_path, 'r') as file:
        category_content = json.load(file)

    # Get the category ID for the "In Policy" category
    for category in category_content:
        if category["name"] == "In Policy":
            categoryId = category["id"]
            break
    
    # Iterate through the scripts and add them to the "In Policy" category if they are used in a policy
    for script in script_input_json:
        if script["language"] != "native":
            if(script["name"] in policy_content):
                    print(f"Name: '{script["name"]}' ID({script["id"]}) - Attempting to Add In Policy Category")
                    add_category(script, categoryId)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Iterates through all scripts, if a script is used in a policy it is added to the 'In Policy' category")
    parser.add_argument("--script_input_json", help="Full path to the input JSON file for the scripts", type=str, required=False)
    args = parser.parse_args()
    main(args.script_input_json)
