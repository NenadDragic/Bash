import pandas as pd
from itertools import product

# Load the Excel file
df = pd.read_excel('trendyscreen-channels.xlsx', engine='openpyxl')

# Find unique values in the specified columns
unikke_A = df['Type'].dropna().unique()
unikke_B = df['Stream'].dropna().unique()

# Generate all combinations
kombinationer = list(product(unikke_A, unikke_B))

# Print the combinations with line count
for index, kombi in enumerate(kombinationer, start=1):
    print(f"{index}: {kombi}")
