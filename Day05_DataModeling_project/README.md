# 🏗️ Power BI Data Modeling Portfolio Project

## From Nightmare Chaos to Healthy Star Schema

**Project Type:** End-to-End Data Modeling  
**Source:** Inspired by "Data Modeling Portfolio Project" by Data with Bara  
**Status:** ✅ Complete  
**File:** [clean_data_model.pbix](./clean_data_model.pbix)

---

## 🎯 Project Overview

This project simulates a real-world scenario: joining a company and inheriting a **nightmare data model**—full chaos, bad relationships, many-to-many connections, and bi-directional filters everywhere.

My job: **Migrate this chaos into a clean, healthy star schema** that delivers correct numbers, good performance, and is ready for enterprise reporting.

---

## 📸 Before vs. After

| Before (Nightmare)                    | After (Star Schema)                       |
| ------------------------------------- | ----------------------------------------- |
| 23 messy tables                       | Clean fact + dimension tables             |
| Many-to-Many relationships everywhere | One-to-Many relationships only            |
| Bi-directional filters                | Single-direction (Dimension → Fact)       |
| Mixed naming conventions              | Consistent snake_case standards           |
| No date dimension                     | Shared Date dimension with multiple roles |
| No security                           | Row-Level Security (RLS) applied          |
| Duplicate tables                      | Consolidated into single sources of truth |

---

## 🗂️ The Nightmare Dataset

The original model contained these tables:

| #   | Table             | Type      | Issue                                            |
| --- | ----------------- | --------- | ------------------------------------------------ |
| 1   | Addresses         | Dimension | Will be merged into Customer                     |
| 2   | Campaign Log      | Fact      | Split into Dimension + Fact                      |
| 3   | Campaign SKUs     | Bridge    | List values need exploding                       |
| 4   | Cities            | Dimension | Header in first row                              |
| 5   | Customer Master   | Dimension | Foundation for Customer dim                      |
| 6   | Customer Contacts | Dimension | Different grain (multiple contacts per customer) |
| 7   | Dimension Order   | Garbage   | Single column, no context                        |
| 8   | Exchange Rate     | Garbage   | No relevance to model                            |
| 9   | Inventory         | Fact      | Wide format, months as columns                   |
| 10  | Invoice Lines     | Detail    | Header-detail pattern                            |
| 11  | Invoices          | Header    | Header-detail pattern                            |
| 12  | Order Line Items  | Detail    | Core numbers live here                           |
| 13  | Orders 2025       | Header    | Split by year                                    |
| 14  | Orders 2026       | Header    | Split by year                                    |
| 15  | Payments          | Event     | Same money repeating                             |
| 16  | Products          | Dimension | Foundation for Product dim                       |
| 17  | Regions           | Dimension | Duplicate info (already in Cities)               |
| 18  | Sales Targets     | Fact      | Mini standalone fact                             |
| 19  | Security          | Support   | RLS mapping table                                |
| 20  | Sheet1            | Duplicate | Identical to Shipments                           |
| 21  | Shipments         | Event     | Process step                                     |
| 22  | Subcategories     | Dimension | Category + Subcategory in one column             |
| 23  | User Details      | Dimension | Same entity as Customer (different name)         |

---

## 🏗️ The Migration Process

### Phase 1: Preparation

- Explored all tables to understand the business
- Identified entities (Customers, Products, Geography)
- Identified events (Orders, Invoices, Payments, Campaigns, Inventory)
- Organized Power Query into folders: `staging`, `dimensions`, `facts`, `support`

### Phase 2: Building Dimensions

- Consolidated 6 tables into `dim_customer`
- Consolidated 2 tables into `dim_product`
- Extracted `dim_order_flags` (junk dimension) from orders
- Built `dim_geo` for location data
- Built `dim_campaign` from campaign log

### Phase 3: Building Facts

- Built `fact_sales` from Order Line Items + Orders header
- Built `fact_inventory` by unpivoting wide-format table
- Built `fact_campaign_spend` from Campaign Log
- Built `fact_promotion_coverage` (factless fact) from Campaign SKUs
- Built `fact_order_process` (accumulating snapshot) combining 5 process steps

### Phase 4: Polishing

- Created `dim_date` using CALENDARAUTO()
- Applied consistent naming conventions (snake_case)
- Set date formats across all tables
- Configured aggregation defaults
- Created core measures collection
- Applied Row-Level Security (RLS)
- Final validation and testing

---

## 📐 Final Model Architecture

```text
┌─────────────────┐
│ dim_customer │
└────────┬────────┘
│
┌──────────────┼──────────────┐
↓ ↓ ↓
┌────────────┐ ┌────────────┐ ┌────────────┐
│ fact_sales │ │fact_order_ │ │fact_campaign│
│ │ │ process │ │ spend │
└─────┬──────┘ └────────────┘ └─────┬──────┘
│ │
┌────────┼────────┐ ┌────────┼────────┐
↓ ↓ ↓ ↓ ↓ ↓
┌───────┐┌───────┐┌───────┐ ┌───────┐┌───────┐┌───────┐
│dim ││dim_ ││dim_ │ │dim_ ││dim_ ││dim_ │
│product││geo ││order_ │ │product││campaign││date │
│ ││ ││flags │ │ ││ ││ │
└───────┘└───────┘└───────┘ └───────┘└───────┘└───────┘

```

---

## 🔑 Key Skills Demonstrated

| Skill                          | Applied In                                                    |
| ------------------------------ | ------------------------------------------------------------- |
| **Star Schema Design**         | Entire model rebuild                                          |
| **Header-Detail Pattern**      | Orders → Order Line Items                                     |
| **Accumulating Snapshot Fact** | Order Fulfillment Process                                     |
| **Factless Fact Table**        | Campaign Promotion Coverage                                   |
| **Junk Dimension**             | Order Flags (Channel, Status, Priority)                       |
| **Role-Playing Dimension**     | Geo (Ship-to vs Bill-to)                                      |
| **Bridge Table**               | Campaign ↔ Products                                           |
| **Unpivot**                    | Inventory (months as columns → rows)                          |
| **Data Quality Fixes**         | Duplicate products, test data, naming conflicts               |
| **Row-Level Security**         | Regional access control                                       |
| **Date Dimension**             | CALENDARAUTO() shared dimension                               |
| **Measure Collection**         | Total Sales, Total Orders, Active Customers, Avg Order-to-Pay |

---

## 📚 Rules Followed (From the Project)

1. **Always understand the grain.** Say it aloud: "One row = one \_\_\_"
2. **Build star schema.** Fact tables in center, dimensions around.
3. **Never connect facts together.** Use shared dimensions.
4. **Every column must earn its place.** Remove unnecessary data.
5. **Protect the numbers.** Know key totals by heart; test after every merge.
6. **Follow naming standards.** snake*case, `dim*`/`fact\_`prefixes,`\_key` suffix for surrogate keys.
7. **Make everything friendly.** Meaningful names for tables, columns, and values.

---

## 🧠 Key Takeaways

- **Merging different grains causes fan-out.** Always check cardinality before merging.
- **Header-Detail is everywhere in source systems.** The fact table comes from the details; the header provides dimensions.
- **Don't trust pre-aggregated values.** Remove them and calculate from the detailed data.
- **Same money repeats across process steps.** Use accumulating snapshot to track dates, not amounts.
- **Dimensions vs. Facts is about business meaning, not data types.** A table with dates can still be a dimension if it describes something static.
- **RLS should be applied on dimensions** so it cascades to all connected facts.
- **Manual data enrichment (like channel mappings) is a risk.** Ideally push it upstream to source systems.

---

## 📂 Files in This Repository

| File/Folder      | Description                                      |
| ---------------- | ------------------------------------------------ |
| `DataModel.pbix` | Complete Power BI file with final model          |
| `screenshots/`   | Before/after model diagrams, key transformations |
| `docs/`          | Additional documentation and notes               |
| `README.md`      | This file                                        |

---

## 🎯 Why This Project Matters

Most Power BI tutorials teach you how to build charts. This project demonstrates the **90% of the work that happens before visualization**—the data modeling.

If you can turn a nightmare dataset into a clean star schema, you can handle:

- Enterprise-scale models
- Legacy systems with messy data
- Multiple source systems with conflicting naming
- Real business requirements with security needs

This is the skill that separates **Power BI technicians** from **data modeling professionals**.

---

## ⏭️ Next Steps

- [ ] Add more DAX measures for deeper analysis
- [ ] Implement calculation groups for dynamic time intelligence
- [ ] Build example reports on top of this model
- [ ] Document the model for other developers

---

## 🙏 Credits

Project inspired by [Data with Bara](https://www.youtube.com/@DataWithBara) – "Power BI Data Modeling Portfolio Project End-to-End".

---

**Built with dedication. Ready for production.**
