import json
import argparse
import os
import time

schema = {"$schema":"https://json-schema.org/draft/2020-12/schema","type":"array","items":{"type":"object","properties":{"uid":{"type":"string"},"name":{"type":"string"},"isActive":{"type":"boolean"},"language":{"type":"string"},"contentId":{"type":"integer"},"architecture":{"type":"array","items":{"type":"string"}},"categoriesIds":{"type":"array","items":{"type":"integer"}},"scriptParameters":{"type":"array"},"operatingSystems":{"type":"array","items":{"type":"string"}},"defaultRunAs":{"type":"string"},"useFirstParametersOptionAsDefault":{"type":"boolean"},"id":{"type":"integer"},"description":{"type":"string"},"scriptVariables":{"type":"array","items":{"type":"object","properties":{"name":{"type":"string"},"calculatedName":{"type":"string"},"description":{"type":"string"},"type":{"type":"string"},"source":{"type":"string"},"defaultValue":{"type":["null","string"]},"required":{"type":"boolean"},"valueList":{"anyOf":[{"type":"array"},{"type":"null"}]}},"required":["calculatedName","defaultValue","description","name","required","source","type","valueList"]}},"binaryInstallSettings":{"type":"object","required":["customIconAttachmentId","helperFilesAttachmentIds","postExecutionScript","preExecutionScript","runAs","runnableAttachmentId"],"properties":{"runnableAttachmentId":{"type":"integer"},"helperFilesAttachmentIds":{"type":"array"},"runAs":{"type":"string"},"preExecutionScript":{"type":"null"},"postExecutionScript":{"type":"null"},"customIconAttachmentId":{"type":"null"}}},"malwareScanStatus":{"type":"string"}},"required":["architecture","categoriesIds","contentId","defaultRunAs","id","isActive","language","name","operatingSystems","scriptParameters","uid","useFirstParametersOptionAsDefault"]}}

def get_non_native_items(data):
    return [item for item in data if item['language'] != 'native' and item['language'] != 'binary_install']

def main(input_file=None, output_file=None):
    if output_file == None:
        output_file = os.path.abspath("./JSON/Result.json")

    if input_file == None:
        input_file = os.path.abspath("./JSON/Ninja.json")

    with open(input_file, 'r') as file:
        data = json.load(file)

    filtered_items = get_non_native_items(data)

    with open(output_file, 'w') as outfile:
        json.dump(filtered_items, outfile, indent=4)
    
    last_modified_time = os.path.getmtime(input_file)
    readable_time = time.ctime(last_modified_time)
    print(f"Source JSON Last Modified at: {readable_time}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Filters the response JSON of the /s10/scripting/scripts request at 'eu.ninjarmm.com'. Response must be obtained from browser dev tools due to CORS policy.")
    parser.add_argument("--input_file", help="Full path to the input JSON file", type=str, required=False)
    parser.add_argument("--output_file", help="Full path to the output JSON file", type=str, required=False)
    args = parser.parse_args()

    main(args.input_file, args.output_file)