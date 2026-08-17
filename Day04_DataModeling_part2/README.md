# Day 3 – Data Modeling & Star Schema (Complete)

**Date:** [17/08/2026]  
**Status:** ✅ Complete  
**PBIX File:** [FintechDashboard.pbix](./FintechDashboard.pbix)  
**Project:** Revolut-style Fintech Transaction Dashboard

---

## 🎯 Overview

Day 3 covered the most critical skill in Power BI—**data modeling**. From hidden dimensions to row-level security, I learned the architectural patterns that transform messy data into enterprise-grade analytical models.

**Topics Covered:**

| Chapter | Topic                      | Key Concept                          |
| ------- | -------------------------- | ------------------------------------ |
| 4       | Dimensions Hidden in Facts | Degenerate Dimensions                |
| 4       | Junk Dimensions            | Combining flags into one table       |
| 4       | Role-Playing Dimensions    | Multiple dates, one Date table       |
| 5       | Grain of a Fact Table      | What one row represents              |
| 5       | Multiple Fact Tables       | Different granularities in one model |
| 5       | Bridge & Shared Dimensions | Many-to-many patterns                |
| 6       | Row-Level Security         | User-specific data filtering         |

---

## 📊 The Dataset

Built a Revolut-style payment analytics model with 6 tables:

| Table             | Type        | Description                     |
| ----------------- | ----------- | ------------------------------- |
| Transactions      | Fact        | Individual payment events       |
| CustomerMerchants | Bridge/Fact | Customer-merchant relationships |
| Customers         | Dimension   | Who made the transaction        |
| Accounts          | Dimension   | Which account was used          |
| Currencies        | Dimension   | What currency                   |
| Merchants         | Dimension   | Where money went                |

---

---

# CHAPTER 4: Dimensions

---

## 📚 Dimensions Hidden in Facts (Degenerate Dimensions)

### What Is a Degenerate Dimension?

A **degenerate dimension** is a dimension attribute that's stored directly in the fact table without a corresponding dimension table.

### My Example:

`TransactionID` in the Transactions table.

### Why It's Degenerate:

| Characteristic                 | Explanation                                               |
| ------------------------------ | --------------------------------------------------------- |
| **No descriptive attributes**  | TransactionID has no name, category, or other information |
| **Just an identifier**         | It only identifies each row uniquely                      |
| **Not worth a separate table** | Creating a TransactionID dimension would serve no purpose |

### Other Real-World Examples:

| Industry   | Degenerate Dimension           |
| ---------- | ------------------------------ |
| E-commerce | OrderID, InvoiceNumber         |
| Banking    | TransactionID, ReferenceNumber |
| Healthcare | ClaimNumber, PrescriptionID    |
| Logistics  | TrackingNumber, BillOfLading   |

### Why Keep It in the Fact Table?

| Reason           | Explanation                                |
| ---------------- | ------------------------------------------ |
| **Drillthrough** | Users can identify individual transactions |
| **Debugging**    | Easy to trace specific rows                |
| **Audit trail**  | Maintains traceability to source systems   |

### The 0.1% Rule:

If a column has no descriptive attributes and is only used for identification, it belongs in the fact table—not a separate dimension.

---

## 📚 Junk Dimension

### What Is a Junk Dimension?

A **junk dimension** combines multiple low-cardinality flags, statuses, and indicators into a single dimension table.

### The Problem It Solves:

Without junk dimensions, your fact table gets cluttered with:

| Column          | Cardinality                  | Problem                                               |
| --------------- | ---------------------------- | ----------------------------------------------------- |
| Status          | 3 (Completed/Failed/Pending) | Takes space, doesn't compress well with other columns |
| IsInternational | 2 (Yes/No)                   | Same                                                  |
| IsHighRisk      | 2 (Yes/No)                   | Same                                                  |
| TransactionType | 3 (Online/POS/ATM)           | Same                                                  |
| IsFraud         | 2 (Yes/No)                   | Same                                                  |

### The Solution:

Create ONE **TransactionStatus** dimension:

| StatusKey | Status    | IsInternational | IsHighRisk | TransactionType | IsFraud |
| --------- | --------- | --------------- | ---------- | --------------- | ------- |
| 1         | Completed | Yes             | No         | Online          | No      |
| 2         | Completed | No              | No         | POS             | No      |
| 3         | Failed    | Yes             | Yes        | Online          | Yes     |
| 4         | Pending   | No              | No         | ATM             | No      |
| 5         | Completed | No              | Yes        | Online          | Yes     |

### Benefits:

| Benefit                     | Explanation                          |
| --------------------------- | ------------------------------------ |
| **Narrower fact table**     | 5 columns become 1 foreign key       |
| **Better compression**      | Dimension values compress well       |
| **Single management point** | Update statuses in one place         |
| **Faster queries**          | Fact table has fewer columns to scan |

### How to Build in Power Query:

1. Select all flag columns in fact table
2. Remove them from fact table
3. Create unique combinations table
4. Add StatusKey column
5. Replace flags with StatusKey in fact table

### The 0.1% Rule:

When you have 5+ low-cardinality flags in a fact table, create a junk dimension.

---

## 📚 Role-Playing Dimensions

### What Is a Role-Playing Dimension?

A **role-playing dimension** occurs when the same dimension table connects to a fact table multiple times, playing different roles.

### My Example:

The Transactions table has three date columns:

| Date Column     | Role                      |
| --------------- | ------------------------- |
| TransactionDate | When transaction occurred |
| SettlementDate  | When money moved          |
| RefundDate      | When refunded             |

All three connect to the SAME Date table.

### The Relationships:

| Relationship                               | Status      |
| ------------------------------------------ | ----------- |
| Transactions[TransactionDate] → Date[Date] | ✅ Active   |
| Transactions[SettlementDate] → Date[Date]  | ❌ Inactive |
| Transactions[RefundDate] → Date[Date]      | ❌ Inactive |

### The DAX Pattern:

```dax
-- Refunded amount by refund date
Total Refunded =
CALCULATE(
    SUM(Transactions[Amount]),
    USERELATIONSHIP(Transactions[RefundDate], Date[Date])
)

-- Settled amount by settlement date
Total Settled =
CALCULATE(
    SUM(Transactions[Amount]),
    USERELATIONSHIP(Transactions[SettlementDate], Date[Date])
)
```

# Why Not Make All Relationships Active?

## Problem: Multiple Active Relationships

| Problem            | Explanation                             |
| ------------------ | --------------------------------------- |
| Filter ambiguity   | Which date should filter Transactions?  |
| Circular paths     | Creates confusion in filter propagation |
| Wrong results      | Multiple dates filter simultaneously    |
| Performance issues | Engine evaluates all paths              |

---

## User-Friendly Toggle Solution

Use **Field Parameters** to let users switch between date perspectives:

```dax
Date Basis = {
    ("Transaction Date", NAMEOF(Transactions[Amount by TransactionDate]), 0),
    ("Settlement Date", NAMEOF(Transactions[Amount by SettlementDate]), 1),
    ("Refund Date", NAMEOF(Transactions[Amount by RefundDate]), 2)
}
```

## The 0.1% Rule

**Role-playing dimensions** are the standard for 2-3 date columns. Separate Date tables are a performance optimization for extreme scale.

---

# CHAPTER 5: Fact Tables

## 📚 Grain of a Fact Table

### What Is "Grain"?

The **grain** of a fact table defines what a **single row represents**. It's the most important decision in dimensional modeling.

### My Example:

**Transactions table grain:** One row = One transaction

| Column          | What It Means                           |
| --------------- | --------------------------------------- |
| TransactionID   | Unique identifier for each row          |
| Amount          | Amount of that specific transaction     |
| TransactionDate | When that specific transaction occurred |

---

### Why Grain Matters:

| Reason                     | Impact                                                      |
| -------------------------- | ----------------------------------------------------------- |
| Measures must match grain  | SUM(Amount) at transaction grain = total transaction amount |
| Double-counting prevention | Wrong grain = wrong numbers                                 |
| Dimension relationships    | Grain determines which dimensions connect                   |
| Aggregation strategy       | Higher grain = more rows = slower                           |

---

### Different Grains in My Model:

| Table             | Grain                   | One Row =                                      |
| ----------------- | ----------------------- | ---------------------------------------------- |
| Transactions      | Transaction level       | One individual transaction                     |
| CustomerMerchants | Customer-Merchant level | One relationship between customer and merchant |

---

## The 0.1% Rule

**Never mix grains in a single fact table.** If `TransactionAmount` (transaction grain) and `MonthlyBalance` (month grain) exist, they belong in **separate fact tables**.

## 📚 Multiple Fact Tables

### Why Have Multiple Fact Tables?

Different business processes have different natural grains and dimensions.

### In My Fintech Model

| Fact Table        | Grain                                      | Dimensions                                       |
| ----------------- | ------------------------------------------ | ------------------------------------------------ |
| Transactions      | One row per transaction                    | Customers, Merchants, Accounts, Currencies, Date |
| CustomerMerchants | One row per customer-merchant relationship | Customers, Merchants, Date                       |

### How to Decide When to Split

| Scenario                                   | Decision               |
| ------------------------------------------ | ---------------------- |
| Same grain, same dimensions                | Keep in one fact table |
| Different grain (daily vs. transactional)  | Separate fact tables   |
| Different dimensions (sales vs. inventory) | Separate fact tables   |
| Same process, different granularity levels | Separate fact tables   |

### Benefits of Multiple Fact Tables

| Benefit            | Explanation                      |
| ------------------ | -------------------------------- |
| Clean grains       | Each table has a clear purpose   |
| Better compression | Columns don't mix unrelated data |
| Simpler DAX        | Measures are clearly scoped      |
| Accurate results   | No accidental double-counting    |

### The 0.1% Rule

If you're writing complex DAX to exclude rows from a fact table based on a status column, that's a signal you should have separate fact tables.

## 📚 Bridge & Shared Dimension

### What Is a Shared Dimension?

A shared dimension (also called conformed dimension) is a dimension table that connects to multiple fact tables.

### In My Model

| Dimension | Connects To                                       |
| --------- | ------------------------------------------------- |
| Customers | Transactions, CustomerMerchants                   |
| Merchants | Transactions, CustomerMerchants                   |
| Date      | Transactions (3 relationships), CustomerMerchants |

### What Is a Bridge Table?

A bridge table sits between two dimension tables to resolve many-to-many relationships.

### My Example

Customers ↔ Merchants is many-to-many:

- One customer transacts with many merchants
- One merchant serves many customers

**Solution:** CustomerMerchants bridge table

### Relationships for Bridge Table

| From      | To                | Cardinality | Direction |
| --------- | ----------------- | ----------- | --------- |
| Customers | CustomerMerchants | One-to-Many | Single    |
| Merchants | CustomerMerchants | One-to-Many | Single    |

### Bridge Table as Fact

The CustomerMerchants table is also a fact table because:

- Contains foreign keys
- Has measures (TransactionCount)
- Each row represents a business event (relationship established)

### Key Distinction

| Table Type        | Purpose                | Example                                       |
| ----------------- | ---------------------- | --------------------------------------------- |
| Junction Table    | Only keys, no measures | StudentCourses with only StudentID + CourseID |
| Fact Bridge Table | Keys + measures        | CustomerMerchants with TransactionCount       |

### The 0.1% Rule

A bridge table with measures is a fact table. Treat it like any other fact—check its grain, connect proper dimensions, and ensure relationships are One-to-Many from dimensions.

# CHAPTER 6: Row-Level Security

## 📚 Row-Level Security (RLS)

### What Is RLS?

Row-Level Security restricts which rows a user can see in the model based on their identity.

### How It Works

1. Define roles in Power BI Desktop
2. Write DAX filters for each role
3. Assign users to roles in Power BI Service

### Types of RLS

| Type        | Description                           | Example                            |
| ----------- | ------------------------------------- | ---------------------------------- |
| Static RLS  | Same filter for all users in a role   | "Country = 'USA'"                  |
| Dynamic RLS | Filter changes based on user identity | "CustomerID = USERPRINCIPALNAME()" |

### Static RLS Example

```dax
-- Role: US_Only
-- Applied on Customers table
[Country] = "USA"
```

**Effect:** Each manager sees only their assigned customers.

### Implementing RLS in My Fintech Model

**Step 1:** Create a mapping table (UserAccess):

| UserEmail      | AllowedCountry |
| -------------- | -------------- |
| alice@bank.com | USA            |
| bob@bank.com   | UK             |
| carol@bank.com | Germany        |

**Step 2:** Create relationship:

- UserAccess[UserEmail] → Users[UserEmail] (for lookup)
- UserAccess[AllowedCountry] → Customers[Country] (for filtering)

**Step 3:** Create role:

```dax
-- Role: CountryFilter
-- Applied on UserAccess table
[UserEmail] = USERPRINCIPALNAME()
```

**Step 4:** Publish and assign users in Power BI Service.

### Key RLS Rules

| Rule               | Explanation                                                        |
| ------------------ | ------------------------------------------------------------------ |
| Filters cascade    | RLS on Customers automatically filters Transactions                |
| Multiple roles     | User in multiple roles gets UNION of permissions (most permissive) |
| Service assignment | RLS is configured in Desktop, enforced in Service                  |
| Workspace roles    | Admin/Member/Viewer also affect access                             |

### The 0.1% Rule

Use a UserAccess mapping table for dynamic RLS. Never hardcode email addresses in DAX roles. The mapping table approach scales to thousands of users.

# 🧠 Day 4 Complete Summary

## What I Built

text ```

A Revolut-style Fintech model demonstrating:

                    ┌──────────┐
                    │Customers │
                    │  (Dim)   │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ↓          ↓          ↓
       ┌──────────┐ ┌──────────┐ ┌──────────┐
       │Merchants │→│CustomerMerchants│←│Accounts  │
       │  (Dim)   │ │  (Bridge/Fact) │ │  (Dim)    │
       └────┬─────┘ └──────────┘ └────┬─────┘
            ↓                          ↓
       ┌──────────┐              ┌──────────┐
       │TRANSACTIONS│←──────────→│   Date    │
       │  (Fact)  │  (3 roles)   │  (Dim)    │
       └────┬─────┘              └──────────┘
            ↓
       ┌──────────┐
       │Currencies │
       │  (Dim)   │
       └──────────┘

text

## Complete Topic Checklist

| #   | Topic                              | Status |
| --- | ---------------------------------- | ------ |
| 1   | Relationships & Cardinality        | ✅     |
| 2   | Star Schema Architecture           | ✅     |
| 3   | Filter Direction & Cross Filtering | ✅     |
| 4   | Dimensions Hidden in Facts         | ✅     |
| 5   | Junk Dimensions                    | ✅     |
| 6   | Role-Playing Dimensions            | ✅     |
| 7   | Grain of a Fact Table              | ✅     |
| 8   | Multiple Fact Tables               | ✅     |
| 9   | Bridge & Shared Dimensions         | ✅     |
| 10  | Model Optimization & VertiPaq      | ✅     |
| 11  | Row-Level Security                 | ✅     |

## Key Skills Demonstrated

- ✅ Data modeling fundamentals
- ✅ Star vs. Snowflake decision-making
- ✅ Bridge table pattern for many-to-many
- ✅ Degenerate, junk, and role-playing dimensions
- ✅ USERELATIONSHIP() for alternate dates
- ✅ Multiple fact table architecture
- ✅ VertiPaq compression understanding
- ✅ Dynamic RLS implementation

## Key Skills Demonstrated

- ✅ Data modeling fundamentals
- ✅ Star vs. Snowflake decision-making
- ✅ Bridge table pattern for many-to-many
- ✅ Degenerate, junk, and role-playing dimensions
- ✅ USERELATIONSHIP() for alternate dates
- ✅ Multiple fact table architecture
- ✅ VertiPaq compression understanding
- ✅ Dynamic RLS implementation
