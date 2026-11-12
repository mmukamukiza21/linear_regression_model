
import pandas as pd

file_path = "summative/linear_regression/data/raw/online_retail_II.xlsx"

print("Reading Excel dataset. Please wait...")

# Read both sheets
sheets = pd.read_excel(file_path, sheet_name=None)

# Combine both years
df = pd.concat(sheets.values(), ignore_index=True)

# Convert invoice numbers to strings
df["Invoice"] = df["Invoice"].astype(str)

print("\nDATASET SIZE:")
print(df.shape)

print("\nDATE RANGE:")
print(df["InvoiceDate"].min(), "to", df["InvoiceDate"].max())

print("\nMISSING VALUES:")
print(df.isna().sum())

print("\nCANCELLED INVOICE ROWS:")
print(df["Invoice"].str.startswith("C").sum())

print("\nNEGATIVE QUANTITY ROWS:")
print((df["Quantity"] < 0).sum())

print("\nZERO OR NEGATIVE PRICE ROWS:")
print((df["Price"] <= 0).sum())

print("\nUNIQUE PRODUCTS:")
print(df["StockCode"].nunique())

print("\nUNIQUE CUSTOMERS:")
print(df["Customer ID"].nunique())

print("\nUNIQUE COUNTRIES:")
print(df["Country"].nunique())

print("\nQUANTITY SUMMARY:")
print(df["Quantity"].describe())

print("\nPRICE SUMMARY:")
print(df["Price"].describe())

print("\nINSPECTION COMPLETED!")
