from NinjaTools import generate_policies_json, generate_categories_json, generate_main_json, add_category
import os
import json
import argparse

def add_to_inPolicy_category():
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

def main(pull_data=None, apply_inPolicyCategory=None):
    if(pull_data):
        generate_categories_json()
        generate_policies_json()
        generate_main_json()
    elif(apply_inPolicyCategory):
        add_to_inPolicy_category()
    else:
        print("No Params Provided")
        exit(0)
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Main")
    parser.add_argument("--pull_data", help="Supply this parameter to grab latest data from Ninja", action='store_true')
    parser.add_argument("--apply-inPolicyCategory", help="Supply this parameter to apply in Policy Category", action='store_true')
    args = parser.parse_args()
    main(args.pull_data, args.apply_inPolicyCategory)