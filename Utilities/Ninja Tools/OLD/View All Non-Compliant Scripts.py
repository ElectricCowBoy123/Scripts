# Return all scripts that have 2 categories
# Return all scripts that have any markdown characters in the description that will escape ``

import requests  # type: ignore
import json
import argparse
import os
import base64

def main(input_file):
    with open(input_file, 'r') as file:
        data = json.load(file)

    print("More than one category: ")
    for item in data:
        if len(item['categoriesIds']) > 1:
            print(item['name'])

    print("\nMarkdown chars in the description: ")
    for item in data:
        if 'description' in item and isinstance(item['description'], str):
            if '`' in item['description'] or ' - ' in item['description']:
                print(item['name'])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="awdawdawd")
    parser.add_argument("input_file", help="Full path to the input JSON file", type=str)
    args = parser.parse_args()
    main(args.input_file)