##
# File managed by puppet (class profile::azure_billing_report), changes will be lost.

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from datetime import datetime, timedelta

import os
import time

# To always have a complete month
START_DATE_FORMAT = "%Y-%m-01"
END_DATE_FORMAT = "%Y-%m-%d"
BASE_SPONSORSHIP_URL = "https://www.microsoftazuresponsorships.com"
EXPECTED_FILE = "AzureUsage.csv"

def wait_for_download():
    MAX_COUNT = 10
    print("Waiting for download", end="")
    count = 0

    while not os.path.exists(EXPECTED_FILE) and count < MAX_COUNT:
        time.sleep(2)
        print(".", end="")
        count += 1
    if count >= MAX_COUNT:
        raise Exception("File not found")
    print("")
    print("done!")


if __name__ == '__main__':
    login = os.environ.get("LOGIN")
    password = os.environ.get("PASSWORD")
    DEBUG = os.environ.get("DEBUG") in ["1", "true"]

    assert login is not None
    assert password is not None

    now = datetime.now()
    last_year = now - timedelta(365)
    end = time.strftime(END_DATE_FORMAT, now.timetuple())
    start = time.strftime(START_DATE_FORMAT, last_year.timetuple())

    print(f"Retrieving consumption from {start} to {end}")

    CSV_URL = f"{BASE_SPONSORSHIP_URL}/Usage/DownloadUsage?startDate={start}&endDate={end}&fileType=csv"
    print(f"CSV url: {CSV_URL}")

    options = webdriver.ChromeOptions()
    options.add_argument("no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=800,600")
    options.add_argument("--headless")

    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(30)
    
    print("Going to the portal login page...")
    driver.get(f"{BASE_SPONSORSHIP_URL}/Account/Login")
    wait = WebDriverWait(driver, 30)

    wait.until(EC.visibility_of_element_located((By.NAME, "loginfmt")))

    print("Entering login...")
    loginInput = driver.find_element(by=By.NAME, value="loginfmt")
    loginInput.send_keys(login, Keys.ENTER)
    if DEBUG:
        driver.save_screenshot("user.png")

    wait.until(EC.visibility_of_element_located((By.NAME, "passwd")))

    print("Entering password...")

    passwordInput = driver.find_element(by=By.NAME, value="passwd")

    try:
        passwordInput.send_keys(password, Keys.ENTER)
    finally:
        if DEBUG:
            driver.save_screenshot("password.png")

    print("Waiting for stay signed page...")

    try:
        wait.until(EC.visibility_of_element_located((By.CSS_SELECTOR, "form")))
    finally:
        if DEBUG:
            driver.save_screenshot("staysigned.png")

    print("On stay signed page")
    button = driver.find_element(by=By.CSS_SELECTOR, value="input[value='No']")
    button.send_keys(Keys.ENTER)

    print("Waiting for home page")
    try:
        wait.until(EC.visibility_of_element_located((By.CSS_SELECTOR, "div.pagecontent")))
    finally:
        if DEBUG:
            driver.save_screenshot("sponsorships-home.png")

    print("Downloading usage summary csv")
    driver.get(CSV_URL)

    wait_for_download()

    print(f"Usage csv file downloaded and available in the {EXPECTED_FILE} file")

    driver.close()
