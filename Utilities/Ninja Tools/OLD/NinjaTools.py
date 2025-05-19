import requests
import os

class NinjaTools:
    def __init__(self, token=None, mfacode=None, cookies=None, url=None, request_body=None, session_key_file_path=None, headers=None, device_set=None):
        self.url = url
        self.request_body = request_body
        self.token = token
        self.mfacode = mfacode
        self.cookies = cookies
        self.session_key_file_path = session_key_file_path
        self.headers = headers
        self.device_set = device_set

    def handle_ninja_mfa(self):
        if self.url is None or self.request_body is None or self.token is None or self.mfacode is None or self.cookies is None or self.headers is None:  
            raise ValueError("Please Provide The Correct Number of Parameters") 

        if self.request_body != None:
            url = self.url + f"?token={self.token}&mfacode={self.mfacode}"
            print(url)
            response = requests.post(url, json=self.request_body, cookies=self.cookies, headers=self.headers)
            print("MFA Response:")
            print(response.text)
            print(response.status_code)
            return response
        else:
            print("Failed on first request!")
            exit(1)

    def get_ninja_session_key(self):
        if self.session_key_file_path is None:
            raise ValueError("Session Key File Path Parameter Must be Provided for Get Session Key.")

        try:
            with open(self.session_key_file_path, 'r') as file:
                session_key = file.read().strip()
            return session_key
        except FileNotFoundError:
            print(f"Error: The file '{self.session_key_file_path}' was not found!")
            return None
        except IOError:
            print(f"Error: An I/O error occurred while reading the file '{self.session_key_file_path}'")
            return None
        
    def get_all_ninja_devices(self):
        if self.session_key_file_path is None: 
            self.session_key_file_path = os.path.abspath('./active_sessionkey.txt')

        session_key = self.get_ninja_session_key()

        cookies = {
            'sessionKey': session_key
        }

        headers = {
            'Accept': '*/*',
            'Content-Type': 'application/json'  # Ensure the server knows you're sending JSON
        }

        request_body = {
            "searchCriteria": [
                {
                    "type": "all-devices",
                    "customFields": "{}"
                }
            ],
            "columns": []
        }

        advance_page = True
        
        ninja_device_set = set()
        runCount = 0
        
        page_size = '150'
        index = '150'
        device_count = 602 # hardcoded value need to sort this TODO

        while advance_page:
            runCount = runCount + 1
            if runCount > 1:
                index = str(int(index) + 150)
                nextURLSub = f'&index={index}'
                baseURL = f"https://eu.ninjarmm.com/s10/search/runner?pageSize={page_size}{nextURLSub}&sortProperty=name&sortDirection=asc"
            else:
                baseURL = f"https://eu.ninjarmm.com/s10/search/runner?pageSize={page_size}&sortProperty=name&sortDirection=asc"

            if int(index) + int(page_size) >= device_count:
                advance_page = False
                return ninja_device_set

            response = requests.post(baseURL, json=request_body, cookies=cookies, headers=headers)
            if response.status_code in (200, 201):
                mainData = response.json()
                
            elif response.status_code == 401:
                print(f"\nPlease provide a valid NinjaRMM token. Status Code: {response.status_code}")
                exit(1)
            elif response.status_code == 406:
                mainData = response.json()
                if mainData.get('resultCode') == "MFA_REQUIRED":
                    print("MFA Required, please reinput MFA")
                    while True:
                        mfacode = input("Please enter your MFA token: ")
                        if mfacode.isdigit() and len(mfacode) == 6:
                            obj_NinjaTools = NinjaTools(token=mainData['loginToken'], mfacode=mfacode, cookies=cookies, request_body=request_body, url=baseURL)
                            response = obj_NinjaTools.handle_ninja_mfa()
                            if response.status_code in (200, 201):
                                mainData = response.json()
                                print("Successfully Performed Request after MFA!")
                                break
                        else:
                            print("Invalid MFA token. Please try again.")
            else:
                print(f"Failed to obtain current devices with Status Code: {response.status_code}")
                exit(1)


            if 'items' in mainData:
                for item in mainData['items']:
                    ninja_device = item['name'].strip()
                    ninja_device_set.add(ninja_device)

    def check_in_ninja(self):
        if self.device_set is None:
            raise ValueError("Please supply a value for device_set!")
        
        obj_NinjaTools = NinjaTools()
        ninja_device_set = obj_NinjaTools.get_all_ninja_devices()

        result_set = ninja_device_set & self.device_set # Devices in Ninja and ScreenConnect

        return result_set