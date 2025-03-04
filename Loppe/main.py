import subprocess
import sys
import shutil
import os

# Function to check if `requests` is installed, if not install it

def install_missing_packages():

    try:

        import requests  # Try importing requests

    except ImportError:

        print("Requests module not found. Installing...")



        # Determine the correct pip command (pip or pip3)

        pip_cmd = shutil.which("pip") or shutil.which("pip3")

        

        if not pip_cmd:

            print("Error: pip is not found on the system. Please install pip manually.")

            sys.exit(1)  # Exit if pip is completely missing



        # Install requests using the detected pip command

        subprocess.check_call([pip_cmd, "install", "requests"])

        import requests  # Re-import after installation



install_missing_packages()  # Ensure dependencies before execution



import requests
import csv

# Base URL for API pagination
BASE_URL = "https://www.boerneloppen.dk/boerneloppen-theme/searches/search.json"

# CSV file to store the data
#CSV_FILENAME = "output.csv"

# Define the path to the output file
CSV_FILENAME = os.path.expanduser("/home/admina/Loppe/output.csv")

# Ensure the directory exists
os.makedirs(os.path.dirname(CSV_FILENAME), exist_ok=True)


# Headers for CSV

HEADERS = ["name", "store", "stand", "price"]



def fetch_data(page):

    """Fetch JSON data for a given page."""

    params = {

        "page": page,

        "query": "",

        "boerneloppen_theme_store_id": 12,

        "boerneloppen_theme_status_id": "",

        "sort": "image",

        "direction": "DESC",

        "only_own_products": "false",

        "show_marked_inactive": "false"

    }

    

    response = requests.get(BASE_URL, params=params)

    if response.status_code == 200:

        return response.json()

    else:

        print(f"Failed to fetch page {page}, Status Code: {response.status_code}")

        return None



def scrape_all_pages():

    """Scrape all pages until no data is found."""

    page = 1

    first_write = True  # To write headers only once



    while True:

        print(f"Fetching page {page}...")

        data = fetch_data(page)



        if not data or "data" not in data or not data["data"]:

            print("No more data found. Stopping...")

            break



        # Extract relevant data

        rows = [[item.get("name", "").strip(), 

                 item.get("store", "").strip(), 

                 item.get("stand", "").strip(), 

                 item.get("price", "").strip()] for item in data["data"]]



        # Append to CSV (UTF-8-SIG ensures correct special character encoding)

        with open(CSV_FILENAME, mode="a", newline="", encoding="utf-8-sig") as file:

            writer = csv.writer(file)

            if first_write:  # Write headers only on the first page

                writer.writerow(HEADERS)

                first_write = False

            writer.writerows(rows)



        page += 1



if __name__ == "__main__":

    scrape_all_pages()

    print(f"Scraping completed. Data saved to {CSV_FILENAME}")
