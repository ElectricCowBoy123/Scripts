from BitDefenderTools import BitDefenderTools

token = ""

def main():
    BitDefenderTools_obj = BitDefenderTools(total_pages=8 token=token)
    bitdefender_device_set = BitDefenderTools_obj.perform_device_request()
    for device in bitdefender_device_set:
        print(device)

if __name__ == "__main__":
    main()
