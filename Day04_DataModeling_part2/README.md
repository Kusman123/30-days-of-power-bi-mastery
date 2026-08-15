# 📊 Day 4: Advanced Data Modeling - Role-Playing Dimensions & Fact Tables

Welcome to Day 4 of my Data Modeling journey! Today, we went deeper into the advanced concepts that separate good models from great ones. We explored how to handle dimensions that serve multiple purposes, how to define the "grain" of your data, and how to manage multiple fact tables in a real-world scenario.

Understanding these concepts is what allows you to build enterprise-grade Power BI solutions that are both flexible and performant.

---

## 📖 Chapter 4 (Continued): Role-Playing Dimensions

### Role-Playing Dimensions (1:20:00)

**The Problem:**

Imagine you have a single `Date` table in your model. But your sales data has three different dates:

- **Order Date** (when the customer placed the order)
- **Ship Date** (when the order was shipped)
- **Delivery Date** (when the customer received it)

You need to analyze sales by all three dates, but you only have **one** Date table.

**The Solution:**

A **Role-Playing Dimension** is a single dimension table (like `Date`) that is used multiple times in your model, playing different "roles" or relationships.

- You create **multiple inactive relationships** between the `Date` table and the `Sales` table—one for each date role.
- You then use the `USERELATIONSHIP` function in DAX to activate the specific relationship you need for a given calculation.

**Example:**

```dax
Total Sales by Order Date = SUM(Sales[Amount])  -- Uses the active relationship (Order Date)

Total Sales by Ship Date =
CALCULATE(
    SUM(Sales[Amount]),
    USERELATIONSHIP(Sales[ShipDateKey], Date[DateKey])
)
```
