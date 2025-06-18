import pandas as pd

# Load the Excel file
df = pd.read_excel('trendyscreen-channels.xlsx', engine='openpyxl')

# Find unique values in column 'A' (Type)
unikke_A = df['Type'].dropna().unique()

# Create a DataFrame from the unique values of column 'A'
unikke_A_df = pd.DataFrame(unikke_A, columns=['Type'])

# Save the DataFrame to an Excel file
unikke_A_df.to_excel('trendy_column_A.xlsx', index=False)

print("Unique values from column 'A' (Type) saved to trendy_column_A.xlsx")