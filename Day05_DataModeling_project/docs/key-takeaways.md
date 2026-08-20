# 🧠 Key Takeaways – Data Modeling Project

## From Nightmare Chaos to Healthy Star Schema

---

## 📌 THE 7 GOLDEN RULES OF DATA MODELING

### Rule 1: Always Understand the Grain First

**Say it aloud:** "One row represents one \_\_\_"

| Table             | Grain                                         |
| ----------------- | --------------------------------------------- |
| Customer Master   | One row = One customer                        |
| Customer Contacts | One row = One contact (multiple per customer) |
| Orders            | One row = One order                           |
| Order Line Items  | One row = One line within an order            |
| Inventory         | One row = One product per month               |

**Why it matters:** Merging tables with different grains causes fan-out (duplicates). This is the #1 cause of wrong numbers in Power BI.

**Lesson learned:** I merged Customer Contacts (contact grain) into Customer Master (customer grain) and got 60 customers → 200+ rows. The fix: filter to primary contacts only BEFORE merging.

---

### Rule 2: Build Star Schema—Always

**Structure:**

Fact Table (center)
↓ ↑
Dimension Tables (around)

**Never:**

- Connect fact tables directly to each other
- Use bi-directional filters
- Flatten everything into one table

**Why:** Star schema = better compression, faster queries, simpler DAX, easier maintenance.

---

### Rule 3: Every Column Must Earn Its Place

**Remove:**

- Hash keys (take 20%+ space, never used in reporting)
- Source IDs (garbage from source systems)
- Long text descriptions (not for analytics)
- Debug/audit columns
- Pre-aggregated values (calculate from raw instead)

**Keep:**

- Foreign keys
- Numeric measures
- Descriptive attributes used for filtering

**Lesson learned:** Removed `order_total` from header because it duplicated the sum of line totals from the details. Don't trust pre-aggregated values—calculate from the detailed data.

---

### Rule 4: Protect the Numbers

**Before any merge, know your key total. After the merge, verify it hasn't changed.**

**My protected number:** Total Sales = SUM(fact_sales[line_total])

**Process:**

1. Note the number before merging
2. Perform the merge
3. Check the number after merging
4. If changed → fan-out occurred → investigate

**Lesson learned:** Merging products by name caused fan-out because of duplicate product names in the dimension. The total sales changed. Found and fixed duplicate products in dim_product.

---

### Rule 5: Follow Naming Standards

| Element          | Standard       | Example                 |
| ---------------- | -------------- | ----------------------- |
| Dimension tables | `dim_` prefix  | `dim_customer`          |
| Fact tables      | `fact_` prefix | `fact_sales`            |
| Surrogate keys   | `_key` suffix  | `product_key`           |
| Source IDs       | `_id` suffix   | `customer_id`           |
| Columns          | snake_case     | `line_total`            |
| All text values  | Capitalized    | "Premium" not "premium" |

**Why:** In multi-developer projects, standards prevent chaos. Without them, one person calls it `D_Customer`, another `DimCustomer`, another `CustomerDim`.

---

### Rule 6: Make Everything Friendly

**Replace technical codes with meaningful names:**

| Before | After          |
| ------ | -------------- |
| 10     | Online Store   |
| 20     | Retail Partner |
| 30     | Wholesale      |
| 40     | Field Sale     |

**Lesson learned:** Source systems store cryptic codes. Your job is to map them to human-readable values. But document the mapping—new codes from the source will break it.

---

### Rule 7: Never Connect Fact Tables Together

**Wrong:**

fact_sales ↔ fact_inventory

**Right:**

fact_sales → dim_product ← fact_inventory

**Why:** Connecting facts directly creates circular filters, ambiguity, and wrong numbers. Use shared dimensions instead.

---

## 📌 THE HEADER-DETAIL PATTERN

### What It Is

Transactional systems store data in two parts:

- **Header:** Top-level info (order date, customer, status)
- **Details:** Line items (product, quantity, price)

### The Correct Way to Model

Order Header (context) → Provides dimensions
Order Details (numbers) → Becomes the fact table
