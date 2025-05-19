import requests

class ScreenConnectTools:
    def __init__(self, property="Name", session_id=None, json_data=None, device_set=None, return_only_online=None, days_offline=100, uri=None, cookie=None, forgery=None, port=None, device_name=None):
        self.device_set = device_set
        self.device_name = device_name
        self.json_data = json_data
        self.uri = uri
        self.cookie = cookie
        self.forgery = forgery
        self.port = port
        self.return_only_online = return_only_online
        self.days_offline = days_offline
        self.property = property
        self.session_id = session_id

    def wake_on_lan(self):
        if self.device_name is None or self.cookie is None or self.uri is None or self.forgery is None:
            raise ValueError("Please supply the valid amount of arguments for this function")

        print(f"\nAttempting to wake device {self.device_name}...")
        session = requests.Session()

        session.cookies.set(
            name=".ASPXAUTH",
            value=f"{self.cookie}",
            domain=f"{self.uri}",
            path="/"
        )

        session.cookies.set(
            name="settings",
            value="{\"selectedTabBySessionTypeMap\":{\"0\":\"Start\",\"2\":\"Start\"},\"extendedCss\":{\"grid-resizable-column-edges\":{\"MainPanelNormalView\":{\"2\":\"14.91% 47.86% 37.23%\"}}},\"collapsedPanelMap\":{\"Device\":false,\"Session\":false},\"joinPath\":\"WindowsDesktop[6.0-X]:Firefox:Host/UrlLaunch\"}",
            domain=f"{self.uri}",
            path="/"
        )

        if self.port is None:
            url = f"https://{self.uri}/Services/PageService.ashx/GetLiveData"
            
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0",
                "Accept": "*/*",
                "Accept-Language": "en-GB,en;q=0.5",
                "Accept-Encoding": "gzip, deflate, br, zstd",
                "X-Anti-Forgery-Token": f"{self.forgery}",
                "X-Unauthorized-Status-Code": "403",
                "Origin": f"https://{self.uri}",
                "Referer": f"https://{self.uri}/Host",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "Priority": "u=0",
                "TE": "trailers"
            }
        else:
            url = f"https://{self.uri}:{self.port}/Services/PageService.ashx/GetLiveData"
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0",
                "Accept": "*/*",
                "Accept-Language": "en-GB,en;q=0.5",
                "Accept-Encoding": "gzip, deflate, br, zstd",
                "X-Anti-Forgery-Token": f"{self.forgery}",
                "X-Unauthorized-Status-Code": "403",
                "Origin": f"https://{self.uri}:{self.port}",
                "Referer": f"https://{self.uri}:{self.port}/Host",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "Priority": "u=0",
                "TE": "trailers"
            }
        
        body = [
            {
                "HostSessionInfo": {
                    "sessionType": 2,
                    "sessionGroupPathParts": ["All Machines"],
                    "filter": f"{self.device_name}",
                    "findSessionID": None,
                    "sessionLimit": 1000
                },
                "ActionCenterInfo": {}
            },
            0
        ]

        response = session.post(url, headers=headers, json=body)
        assert response.status_code == 200, response.status_code
        data = response.json()
        session_id = None
        is_wake = False
        if 'ResponseInfoMap' in data:
            host_session_info = data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    name = session.get('Name', "")
                    if name == self.device_name:
                        session_id = session.get('SessionID', "")
                        print(session_id)
                        if not len(session.get('ActiveConnections', [])) > 0 and session_id:
                            is_wake = True

        assert session_id # ensure session_id is not blank
        
        if is_wake:
            if self.port is None:
                url = f"https://{self.uri}/Services/PageService.ashx/AddSessionEvents"
            else:
                url = f"https://{self.uri}:{self.port}/Services/PageService.ashx/AddSessionEvents"

            # perform deletion
            body = [
                ["All Machines"],
                [
                    {
                        "SessionID": f"{session_id}",
                        "EventType": 43, # wake on lan
                        "Data": ""
                    }
                ]
            ]

            session = requests.Session()

            session.cookies.set(
                name=".ASPXAUTH",
                value=f"{self.cookie}",
                domain=f"{self.uri}",
                path="/"
            )

            session.cookies.set(
                name="settings",
                value="{\"selectedTabBySessionTypeMap\":{\"0\":\"Start\",\"2\":\"Start\"},\"extendedCss\":{\"grid-resizable-column-edges\":{\"MainPanelNormalView\":{\"2\":\"14.91% 47.86% 37.23%\"}}},\"collapsedPanelMap\":{\"Device\":false,\"Session\":false},\"joinPath\":\"WindowsDesktop[6.0-X]:Firefox:Host/UrlLaunch\"}",
                domain=f"{self.uri}",
                path="/"
            )

            response = session.post(url, headers=headers, json=body)
            assert response.status_code == 200, response.status_code
            return 0
        else:
            print(f"Device {self.device_name} already online...")
            return 1

    def perform_request(self):
        if self.uri is None or self.cookie is None or self.forgery is None:
            raise ValueError("Please supply a valid number of parameters!")

        session = requests.Session()

        session.cookies.set(
            name=".ASPXAUTH",
            value=f"{self.cookie}",
            domain=f"{self.uri}",
            path="/"
        )

        session.cookies.set(
            name="settings",
            value="{\"selectedTabBySessionTypeMap\":{\"0\":\"Start\",\"2\":\"Start\"},\"extendedCss\":{\"grid-resizable-column-edges\":{\"MainPanelNormalView\":{\"2\":\"14.91% 47.86% 37.23%\"}}},\"collapsedPanelMap\":{\"Device\":false,\"Session\":false},\"joinPath\":\"WindowsDesktop[6.0-X]:Firefox:Host/UrlLaunch\"}",
            domain=f"{self.uri}",
            path="/"
        )

        if self.port != None:
            url = f"https://{self.uri}:{self.port}/Services/PageService.ashx/GetLiveData"

        if self.port == None:
            url = f"https://{self.uri}/Services/PageService.ashx/GetLiveData"

        if self.port != None:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0",
                "Accept": "*/*",
                "Accept-Language": "en-GB,en;q=0.5",
                "Accept-Encoding": "gzip, deflate, br, zstd",
                "X-Anti-Forgery-Token": f"{self.forgery}",
                "X-Unauthorized-Status-Code": "403",
                "Origin": f"https://{self.uri}:{self.port}",
                "Referer": f"https://{self.uri}:{self.port}/Host",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "Priority": "u=0",
                "TE": "trailers"
            }

        if self.port == None:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0",
                "Accept": "*/*",
                "Accept-Language": "en-GB,en;q=0.5",
                "Accept-Encoding": "gzip, deflate, br, zstd",
                "X-Anti-Forgery-Token": f"{self.forgery}",
                "X-Unauthorized-Status-Code": "403",
                "Origin": f"{self.uri}",
                "Referer": f"{self.uri}/Host",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "Priority": "u=0",
                "TE": "trailers"
            }

        body = [
            {
                "HostSessionInfo": {
                    "sessionType": 2,
                    "sessionGroupPathParts": ["All Machines"],
                    "filter": f"",
                    "findSessionID": None,
                    "sessionLimit": 1000
                },
                "ActionCenterInfo": {}
            },
            0
        ]

        response = session.post(url, headers=headers, json=body)

        assert response.status_code == 200, response.status_code

        data = response.json()
        #online = has_active_connections(data)

        return data

        """
        
        if response.status_code == 200:
            print("Request was successful.")
            print("Response JSON:", response.json())
        else:
            print(f"Request failed with status code: {response.status_code}")
            print("Response:", response.text)
        """

    def filter_devices(self):
        if self.return_only_online is None:
            raise ValueError("Return Only Online Parameter Must be Provided for Filter Devices.")

        if 'ResponseInfoMap' in self.json_data:
            host_session_info = self.json_data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    device_name = session.get(f'{self.property}', "")
                    
                    if len(session.get('ActiveConnections', [])) > 0:
                        device_online = True
                    else:
                        device_online = False
                    if (self.return_only_online and device_online) or (not self.return_only_online and device_online) or (not self.return_only_online and not device_online):
                        self.device_set.add(device_name)
        return self.device_set

    def filter_offline_devices(self):
        if self.days_offline is None:
            raise ValueError("Please supply a value for days_online!")
        
        if 'ResponseInfoMap' in self.json_data:
            host_session_info = self.json_data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    device_name = session.get(f'{self.property}', "")
                    device_idle_time = session.get('GuestIdleTime', 0)
                    device_idle_time = int(device_idle_time) / 86400
                    if device_idle_time > self.days_offline:
                        self.device_set.add(device_name)
        return self.device_set

    def filter_macos_devices(self):
        if self.return_only_online is None:
            raise ValueError("Return Only Online Parameter Must be Provided for Filter MacOS Devices.")

        if 'ResponseInfoMap' in self.json_data:
            host_session_info = self.json_data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    device_name = session.get(f'{self.property}', "")
                    device_operating_system = session.get('GuestOperatingSystemName', "")
                    if len(session.get('ActiveConnections', [])) > 0:
                        device_online = True
                    else:
                        device_online = False
                    if (self.return_only_online and device_online) or (not self.return_only_online and device_online) or (not self.return_only_online and not device_online):
                        if 'Mac' in device_operating_system:
                            self.device_set.add(device_name)
        return self.device_set
    
    def has_active_connections(self):
        if 'ResponseInfoMap' in self.json_data:
            host_session_info = self.json_data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    active_connections = session.get('ActiveConnections', [])
                    if len(active_connections) > 0:
                        return True
        return False 
    
    def perform_delete_request(self):
        if self.cookie is None or self.forgery is None or self.device_name is None:
            raise ValueError("Please provide the valid number of arguments to this function")
        
        session = requests.Session()

        session.cookies.set(
            name=".ASPXAUTH",
            value=f"{self.cookie}",
            domain=f"", 
            path="/"
        )

        session.cookies.set(
            name="settings",
            value="{\"selectedTabBySessionTypeMap\":{\"0\":\"Start\",\"2\":\"Start\"},\"extendedCss\":{\"grid-resizable-column-edges\":{\"MainPanelNormalView\":{\"2\":\"14.91% 47.86% 37.23%\"}}},\"collapsedPanelMap\":{\"Device\":false,\"Session\":false},\"joinPath\":\"WindowsDesktop[6.0-X]:Firefox:Host/UrlLaunch\"}",
            domain=f"", 
            path="/"
        )

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0",
            "Accept": "*/*",
            "Accept-Language": "en-GB,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "X-Anti-Forgery-Token": f"{self.forgery}",
            "X-Unauthorized-Status-Code": "403",
            "Origin": f"", 
            "Referer": f"", 
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "Priority": "u=0",
            "TE": "trailers"
        }

        url = f"" 
        
        body = [
            {
                "HostSessionInfo": {
                    "sessionType": 2,
                    "sessionGroupPathParts": ["All Machines"],
                    "filter": f"{self.device_name}",
                    "findSessionID": None,
                    "sessionLimit": 1000
                },
                "ActionCenterInfo": {}
            },
            0
        ]

        response = session.post(url, headers=headers, json=body)
        assert response.status_code == 200, response.status_code
        data = response.json()

        delete_processing = False

        if 'ResponseInfoMap' in data:
            host_session_info = data['ResponseInfoMap'].get('HostSessionInfo', {})
            if 'Sessions' in host_session_info:
                for session in host_session_info['Sessions']:
                    name = session.get('Name', "")
                    if name == self.device_name:
                        session_id = session.get('SessionID', "")
                        print(f"{name} Has Session ID {session_id}")
                        for events in session['QueuedEvents']:
                            event_type = events.get('EventType', "")
                            if event_type == 21:
                                delete_processing = True
        if delete_processing:
            print(f"{name} Is Already being Deleted, Skipping!")
            return 1
                        
        if not delete_processing:
            url = f"" 

            # perform deletion
            body = [
                ["All Machines"],
                [
                    {
                        "SessionID": f"{session_id}",
                        "EventType": 21
                    }
                ]
            ]

            session = requests.Session()

            session.cookies.set(
                name=".ASPXAUTH",
                value=f"{self.cookie}",
                domain=f"", 
                path="/"
            )

            session.cookies.set(
                name="settings",
                value="{\"selectedTabBySessionTypeMap\":{\"0\":\"Start\",\"2\":\"Start\"},\"extendedCss\":{\"grid-resizable-column-edges\":{\"MainPanelNormalView\":{\"2\":\"14.91% 47.86% 37.23%\"}}},\"collapsedPanelMap\":{\"Device\":false,\"Session\":false},\"joinPath\":\"WindowsDesktop[6.0-X]:Firefox:Host/UrlLaunch\"}",
                domain=f"", 
                path="/"
            )

            response = session.post(url, headers=headers, json=body)
            assert response.status_code == 200, response.status_code
            return 0
        
    def sanitise_names(self):
        santised_devices = set()
        for device in self.device_set:
            parts = device.split(' - ')
            santised_devices.add(parts[0])
        return santised_devices