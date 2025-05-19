import requests  # type: ignore
import json
import argparse
import os

all_policies_url = "https://eu.ninjarmm.com/s10/policy/list?nodeClassGroup=RMM"

def main(session_key=None, output_file_path=None):
    if output_file_path is None:
        output_file_path = os.path.abspath("./policy-report.md")
    
    if os.path.exists(output_file_path):
        os.remove(output_file_path)

    if session_key is None:
        session_key_file_path = os.path.abspath("./Deployment/active_sessionkey.txt")
        with open(session_key_file_path, 'r') as file:
            session_key = file.read().strip()
    
    # Validate session key
    if not session_key or '\n' in session_key or len(session_key) < 10:  # Adjust length check as needed
        print("Invalid session key. Please check the contents of active_sessionkey.txt.")
        exit(1)

    print(f"Using Session Key: {session_key}")
    # Set up cookies for the request
    cookies = {
        'sessionKey': session_key
    }
    
    response = requests.get(all_policies_url, cookies=cookies)

    if response.status_code != 200:
        print(f"Failed to fetch policies: {response.status_code}")
        exit(1)

    response_body = response.json()

    policies_to_scripts = []
    policies = {}
    for policy in response_body:
        policies[policy['id']] = policy['name']

    for policy_id in policies:  # Use policy_id instead of policy
        policy_name = policies[policy_id]  # Get the policy name using the ID
        policies_to_scripts.append(f"# {policy_name} ({policy_id})\n")
        policy_base_url = f"https://eu.ninjarmm.com/s10/policy/{policy_id}?_=1734533913315"
        response = requests.get(policy_base_url, cookies=cookies)
        if response.status_code != 200:
            print(f"Failed to fetch policy: {response.status_code}")
            exit(1)
        response_body = response.json()

        # debug code:
        # debug code
        debug_response_file_path = os.path.abspath(f"./JSON/Policies/{policy_id}.json")
        if os.path.exists(debug_response_file_path):
            os.remove(debug_response_file_path)
        with open(debug_response_file_path, 'w') as file:
            json.dump(response_body, file, indent=4)

        actionset_schedules = response_body.get('policy', {}).get('content', {}).get('actionsetSchedules', [])
        
        if not actionset_schedules:
            policies_to_scripts.append(f"Empty Policy!\n")

        for key, item in actionset_schedules.items():
            scripts = item.get('scripts', [])
            action_set_name = item.get('actionsetScheduleName', "")
            inheritance_object = item.get('inheritance', {})
            if action_set_name:
                policies_to_scripts.append(f"\n## {action_set_name}\n")
                if inheritance_object: 
                    policies_to_scripts.append(f"Is Inherited: `{inheritance_object.get('inherited')}`\n")
            if scripts:
                for script in scripts:
                    policies_to_scripts.append(f"- `{script.get('scriptName')}`\n")  # Use policy_name
            else:
                print(f"No scripts found for action set schedule key: {key}")
        policies_to_scripts.append(f"\n")
        
    with open(output_file_path, 'w') as file:
        for entry in policies_to_scripts:
            file.write(entry)
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch and display policies and their action set schedules.")
    parser.add_argument("--session_key", help="Session key cookie value to use for the request.", type=str, required=False)
    parser.add_argument("--output_file_path", help="Path to the output file for the policy report.", type=str, required=False)
    args = parser.parse_args()
    main(args.session_key, args.output_file_path)
