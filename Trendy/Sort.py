import pandas as pd
from itertools import product

# Load the Excel file
df = pd.read_excel('trendyscreen-channels.xlsx', engine='openpyxl')

# Filter the DataFrame based on the 'Type' column
df_filtered = df[df['Type'].isin(["Live Streams", "Movies"])]
    
# Find unique values in the specified columns from the filtered DataFrame
unikke_A = df_filtered['Type'].dropna().unique()
unikke_B = df_filtered['Stream'].dropna().unique()

# Generate all combinations
kombinationer = list(product(unikke_A, unikke_B))

# Create a DataFrame from the combinations
kombinationer_df = pd.DataFrame(kombinationer, columns=['Type', 'Stream'])

# Save the DataFrame to an Excel file
kombinationer_df.to_excel('Trendy_Keep.xlsx', index=False)

print("Combinations saved to Trendy_Keep.xlsx")