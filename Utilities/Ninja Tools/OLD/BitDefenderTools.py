import requests

class BitDefenderTools:
    def __init__(self, json_data=None, token=None, total_pages=None):
        self.token = token
        self.total_pages = total_pages

    def perform_device_request(self):
        device_set = set()

        cookies = {
            "AMCV_0E920C0F53DA9E9B0A490D45@AdobeOrg": "",
            "lang": "en_US",
            "deviceId": "",
            "_cq_duid": "",
            "bd112": "",
            "AMCVS_0E920C0F53DA9E9B0A490D45@AdobeOrg": "",
            "at_check": "",
            "_cq_suid": "",
            "__cfruid": "",
            "lastUnifiedUsedService": "",
            "lastUsedService": "",
            "s_ips": "",
            "s_tp": "",
            "s_cc": "",
            "s_sq": "",
            "PHPSESSID": "",
            "nexus-auth-session": self.token,
            "s_ppv": ""
        }

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:134.0) Gecko/20100101 Firefox/134.0",
            "Accept": "*/*",
            "Accept-Language": "en-GB,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "Referer": "https://cloudgz.gravityzone.bitdefender.com/",
            "X-Requested-With": "XMLHttpRequest",
            "Origin": "https://cloudgz.gravityzone.bitdefender.com",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin"
        }

        for page in range(1, self.total_pages + 1):
            body = {
                "action": "ProtectedEntitiesEPS",
                "method": "readRecords",
                "data": {
                    "nodeId": "5f3d48f83973973961350dbd",
                    "viewType": 10,
                    "additionalFilters": {
                        "policyTemplate": "",
                        "depth": 1,
                        "tagType": 1,
                        "tagAttribute": "",
                        "tagValue": "",
                        "type": ["computers", "virtualMachines"]
                    },
                    "page": page,
                    "limit": 100,
                    "sort": "specifics.clientPolicy.policyName",
                    "dir": "ASC"
                },
                "type": "rpc",
                "tid": 34
            }

            session = requests.Session()

            response = session.post(
                "https://cloudgz.gravityzone.bitdefender.com/webservice/CEPS/model?csrfToken=788fc3c66bd9d6eee4b688d81d6b04a93e6510a6", 
                headers=headers,
                cookies=cookies,
                json=body
            )

            assert response.status_code == 200, response.status_code

            response_obj = response.json()
            if 'result' in response_obj:
                data_obj = response_obj['result'].get('data', [])
                for data in data_obj:
                    if 'name' in data:
                        device_name = data['name']
                        device_set.add(device_name)
        return device_set