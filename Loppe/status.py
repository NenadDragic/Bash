import os
import csv

def process_file(filename, target_stand):
    total_price = 0
    line_count = 0

    with open(filename, 'r', encoding='utf-8') as file:
        reader = csv.reader(file)
        for fields in reader:
            if len(fields) >= 4:
                stand_str = fields[2].strip()
                price_str = fields[3].strip()

                # Remove " kr." and whitespace from the price string
                price_str = price_str.replace(' kr.', '').strip()

                # Replace comma with a period for correct float conversion
                price_str = price_str.replace(',', '.')

                # Remove all periods (thousands separators)
                price_str = price_str.replace('.', '')

                # If there are multiple periods, replace the last one with a decimal point
                if price_str.count('.') > 1:
                    parts = price_str.rsplit('.', 1)
                    price_str = parts[0] + '.' + parts[1]

                try:
                    price = float(price_str)
                    # print(f"Pris konverteret til float: {price}")
                except ValueError:
                    # print(f"Pris konverteret til float: {price}")
                    print(f"Fejl: Kunne ikke konvertere pris til tal: {price_str}")
                    continue

                # Check if stand_str is a number
                if stand_str.isdigit():
                    stand = int(stand_str)
                else:
                    print(f"Fejl: Stand er ikke et tal: {stand_str}")
                    continue

                # Check if the stand matches the target_stand
                if stand == target_stand:
                    line_count += 1
                    total_price += price
            else:
                print(f"Fejl: Linje har ikke nok felter: {fields}")

    # Divide the total price by 100 to reflect the correct amount
    total_price /= 100

    return total_price, line_count

def process_folder(folder_path, target_stand):
    # Find all .csv files in the folder
    csv_files = [f for f in os.listdir(folder_path) if f.endswith('.csv')]

    if not csv_files:
        print(f"Ingen .csv-filer fundet i mappen: {folder_path}")
        return

    # Sort files by modification time (newest first)
    csv_files.sort(key=lambda f: os.path.getmtime(os.path.join(folder_path, f)), reverse=True)

    print(f"Behandler {len(csv_files)} .csv-filer i mappen: {folder_path}")

    # Process each file and display status
    for csv_file in csv_files:
        file_path = os.path.join(folder_path, csv_file)
        total_price, line_count = process_file(file_path, target_stand)
        print(f"Status for {csv_file}: Antal fundet: {line_count} | Total beløb: {total_price:.2f} kr.")

# Example usage
folder_path = '/home/admina/Loppe'  # Replace with the path to the folder containing .csv files
target_stand = 54  # The stand number you want to search for

process_folder(folder_path, target_stand)

