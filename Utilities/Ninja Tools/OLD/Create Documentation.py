import json
import argparse
import re 
import os

schema = {"$schema":"https://json-schema.org/draft/2020-12/schema","type":"array","items":{"type":"object","properties":{"uid":{"type":"string"},"name":{"type":"string"},"isActive":{"type":"boolean"},"language":{"type":"string"},"contentId":{"type":"integer"},"architecture":{"type":"array","items":{"type":"string"}},"categoriesIds":{"type":"array","items":{"type":"integer"}},"scriptParameters":{"type":"array"},"operatingSystems":{"type":"array","items":{"type":"string"}},"defaultRunAs":{"type":"string"},"useFirstParametersOptionAsDefault":{"type":"boolean"},"id":{"type":"integer"},"description":{"type":"string"},"scriptVariables":{"type":"array","items":{"type":"object","properties":{"name":{"type":"string"},"calculatedName":{"type":"string"},"description":{"type":"string"},"type":{"type":"string"},"source":{"type":"string"},"defaultValue":{"type":["null","string"]},"required":{"type":"boolean"},"valueList":{"anyOf":[{"type":"array"},{"type":"null"}]}},"required":["calculatedName","defaultValue","description","name","required","source","type","valueList"]}},"binaryInstallSettings":{"type":"object","required":["customIconAttachmentId","helperFilesAttachmentIds","postExecutionScript","preExecutionScript","runAs","runnableAttachmentId"],"properties":{"runnableAttachmentId":{"type":"integer"},"helperFilesAttachmentIds":{"type":"array"},"runAs":{"type":"string"},"preExecutionScript":{"type":"null"},"postExecutionScript":{"type":"null"},"customIconAttachmentId":{"type":"null"}}},"malwareScanStatus":{"type":"string"}},"required":["architecture","categoriesIds","contentId","defaultRunAs","id","isActive","language","name","operatingSystems","scriptParameters","uid","useFirstParametersOptionAsDefault"]}}
def filter_items(data):
    regex = r'[\r\n]+'
    result = []
    result.append("# Ninja RMM Scripts")
    for item in data: 
        if 'scriptVariables' in item and item['name'] not in item['scriptVariables']:
            result.append(f"## {item['name']}")
            if len(str(item['description'])) != 0:
                result.append(f"- **Description**: `{re.sub(regex, '', item['description'])}`")
            else:
                result.append(f"- **Description**: `None`")
            result.append(f"- **Language**: `{item['language'].capitalize()}`")
            result.append(f"- **Runs as**: `{item['defaultRunAs'].upper()}`")
            if len(str(item['operatingSystems'])) != 0:
                result.append(f"- **Operating Systems**:")
                for OSItem in item['operatingSystems']:
                    result.append(f"    - `{re.sub(regex, '', OSItem)}`")
                    result.append("\n")
            else:
                result.append(f"- **Operating Systems**: None")
            if len(str(item['categoriesIds'])) != 0:
                result.append(f"- **Categories**:")
                for catItem in item['categoriesIds']:
                    result.append(f"    - `{re.sub(regex, '', catItem)}`")
                    result.append("\n")
            else:
                result.append(f"- **Categories**: None")
            result.append(f"- **Parameters**:")
            for vars in item['scriptVariables']:
                result.append(f"   - **Name**: `{vars['name']}`")
                if len(str(vars['description'])) != 0:
                    result.append(f"      - **Description**: `{re.sub(regex, ' ', vars['description'])}`")
                else:
                    result.append(f"      - **Description**: `None`")
                if str(vars['type']) == "TEXT":
                    result.append(f"      - **Type**: `String`")
                else:
                    result.append(f"      - **Type**: `{vars['type']}`")
                if len(str(vars['defaultValue'])) != 0:
                    result.append(f"      - **Default Value**: `{vars['defaultValue']}`")
                else:
                    result.append(f"      - **Default Value**: `None`")
            result.append("\n")
        
        elif 'scriptVariables' not in item:
            result.append(f"## {item['name']}")
            if len(str(item['description'])) != 0:
                result.append(f"- **Description**: `{re.sub(regex, ' ', item['description'])}`")
            else:
                result.append(f"- **Description**: `None`")
            result.append(f"- **Language**: `{item['language'].capitalize()}`")
            result.append(f"- **Runs as**: `{item['defaultRunAs'].upper()}`")
            if len(str(item['operatingSystems'])) != 0:
                result.append(f"- **Operating Systems**:")
                for OSItem in item['operatingSystems']:
                    result.append(f"    - `{re.sub(regex, '', OSItem)}`")
                    result.append("\n")
            else:
                result.append(f"- **Operating Systems**: None")
            if len(str(item['categoriesIds'])) != 0:
                result.append(f"- **Categories**:")
                for catItem in item['categoriesIds']:
                    result.append(f"    - `{re.sub(regex, '', catItem)}`")
                    result.append("\n")
            else:
                result.append(f"- **Categories**: `None`")
            result.append("**Parameters**: `None`")
            result.append("\n")
        
    return result 

def main(input_file=None, output_file=None):

    if input_file == None:
        input_file = os.path.abspath("./JSON/Result.json")

    if output_file == None:
        output_file = os.path.abspath("./JSON/Output.md")

    with open(input_file, 'r') as file:
        data = json.load(file)

    result = filter_items(data)

    count = 0
    str = ""

    for item in result:
        str += f"{item}\n"
        if re.search(r"## ", item):
            count += 1

    with open(output_file, 'w') as outfile:
        outfile.write(str)

    if os.path.exists(os.path.abspath('./pandoc-3.6/bin/pandoc')):
        exit_status = os.system(f'"{os.path.abspath("./pandoc-3.6/bin/pandoc")}" "{os.path.abspath(output_file)}" -o "{os.path.abspath("./JSON/Output.docx")}"')
        if exit_status == 0:
            print("Word Document Generated!")
        else:
            print("Failed to Generate Word Document is the pandoc-3.6 Present Next to this Script?")
    
    print(f"Generated Documentation!")
    print(f"There are a total of {count} scripts.")

        
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Filters JSON data to obtain only specified properties as a string.")
    parser.add_argument("--input_file", help="Full path to the input JSON file", type=str, required=False)
    parser.add_argument("--output_file", help="Full path to the output .txt file", type=str, required=False)
    args = parser.parse_args()

    main(args.input_file, args.output_file)