# Load and Prepare Data
import pandas as pd

df = pd.read_csv('RetailCleaned.csv', header=None)
df.columns = ['Invoice', 'StockCode', 'Description', 'Quantity', 'InvoiceDate', 'Price', 'Customer_ID', 'Country', 'SourceSheet']

df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
print(df.shape)
df.info()

print("Step 1: Starting RFM calculation...")

# Filter and Calculate Recency, Frequency, Monetary
rfm_data = df[(df['Customer_ID'].notna()) & (df['Quantity'] > 0)].copy()
snapshot_date = pd.to_datetime('2011-12-10')

rfm = rfm_data.groupby('Customer_ID').agg(
    Recency=('InvoiceDate', lambda x: (snapshot_date - x.max()).days),
    Frequency=('Invoice', 'nunique'),
    Monetary=('Quantity', lambda x: (x * rfm_data.loc[x.index, 'Price']).sum())
).reset_index()

print("Step 2: RFM calculation completed!")

# Score Customers and Assign Business Segment
rfm['R_Score'] = pd.qcut(rfm['Recency'], 5, labels=[5, 4, 3, 2, 1]).astype(int)
rfm['F_Score'] = pd.qcut(rfm['Frequency'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5]).astype(int)
rfm['M_Score'] = pd.qcut(rfm['Monetary'], 5, labels=[1, 2, 3, 4, 5]).astype(int)

def segment_customer(row):
    if row['R_Score'] >= 4 and row['F_Score'] >= 4 and row['M_Score'] >= 4:
        return 'Champions'
    elif row['R_Score'] >= 3 and row['F_Score'] >= 3:
        return 'Loyal'
    elif row['R_Score'] <= 2 and row['F_Score'] >= 3:
        return 'At Risk'
    elif row['R_Score'] >= 4 and row['F_Score'] <= 2:
        return 'New'
    elif row['R_Score'] == 3 and row['F_Score'] <= 2:
        return 'Needs Attention'
    else:
        return 'Lost'

rfm['Segment'] = rfm.apply(segment_customer, axis=1)
rfm['IsChurned'] = rfm['Recency'] > 90

print("Step 3: Scoring and segmentation completed!")

print("Step 4: Merging transaction data...")

# MERGE RFM RESULTS BACK ONTO TRANSACTIONS AND EXPORT
df = df[(df['Customer_ID'].notna()) & (df['Quantity'] > 0)].copy()
df['InvoiceMonth'] = df['InvoiceDate'].dt.to_period('M').dt.to_timestamp()
df['Revenue'] = df['Quantity'] * df['Price']

df_final = df.merge(
    rfm[['Customer_ID', 'Recency', 'Frequency', 'Monetary', 'R_Score', 'F_Score', 'M_Score', 'Segment', 'IsChurned']],
    on='Customer_ID', how='left'
)

df_final.to_excel('EcommerceDashboardData.xlsx', index=False)

print("Step 6: Excel export completed!")