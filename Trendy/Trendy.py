import pandas as pd
from itertools import product

# Load the Excel file
df = pd.read_excel('trendyscreen-channels.xlsx', engine='openpyxl')

# Find unique values in the specified columns
unikke_A = df['Type'].dropna().unique()
unikke_B = df['Stream'].dropna().unique()

# Generate all combinations
kombinationer = list(product(unikke_A, unikke_B))

# Create a DataFrame from the combinations
kombinationer_df = pd.DataFrame(kombinationer, columns=['Type', 'Stream'])

# Save the DataFrame to an Excel file
kombinationer_df.to_excel('trendy.xlsx', index=False)

print("Combinations saved to trendy.xlsx")
