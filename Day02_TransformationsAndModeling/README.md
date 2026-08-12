# Day 2 – Transformations & Data Modeling Fundamentals

**Date:** [12/08/2026]  
**Status:** ✅ Complete  
**PBIX File:** [SalesDashboardDay2.pbix](./SalesDashboardDay2.pbix)

---

## 🎯 Overview

Day 2 covered five critical Power Query and data modeling concepts. I transformed raw CSV files into a clean, production-ready data model with proper star schema design.

**Topics Covered:**

1. Custom Columns – Power Query vs. DAX decision framework
2. Merging vs. Relationships – Architectural trade-offs
3. Unpivot – Reshaping wide-format data for analysis
4. Date Dimension – Building from scratch in M
5. Staging vs. Reference Queries – Enterprise ETL patterns

---

## 📚 Tasks & Learnings

---

### Task 3 – Custom Column: LineTotal

**Goal:** Calculate `LineTotal = Quantity × UnitPrice × (1 - Discount)`

**M Code (Power Query):**

```m
Table.AddColumn(#"Changed Type", "LineTotal", each [UnitPrice] * [Quantity] * (1 - [Discount]))
```

**DAX Alternative:**

```dax
Total Revenue = SUMX(
    'Sales',
    'Sales'[UnitPrice] * 'Sales'[Quantity] * (1 - 'Sales'[Discount])
)
```

## 🔑 Key Decision Framework

| Approach                      | Use When                                                |
| ----------------------------- | ------------------------------------------------------- |
| **Power Query Custom Column** | Pre-compute for performance. Best for 100M+ row tables. |
| **DAX Calculated Column**     | Only if value needed for further DAX relationships.     |
| **DAX Measure**               | When calculation depends on user filters/slicers.       |

> 💡 **0.1% Insight:** _"Measures don't use memory" ≠ "Measures are always better."_ Memory is cheap. CPU time on every user click is expensive. Pre-compute what you can. Measure what must be dynamic.

![Custom Column LineTotal](https://images/custom-column-linetotal.png)

# Task 4 – Merging vs. Relationships

**Goal:** Bring `Category` and `CostPrice` from `Products` into `Sales` analysis.

## Approach Tested: Merge in Power Query

```m
Table.ExpandTableColumn(#"Merged Queries", "Products", {"Category", "CostPrice"}, {"Category", "CostPrice"})
```

**Join Kind: Left Outer** ← Critical choice!

- **Inner Join** silently drops sales rows with no matching product
- **Left Outer** preserves all revenue—missing products appear as `NULL`

---

## 🔑 Merge vs. Relationship Ranking (50M-row table)

| Rank | Approach                               | Storage  | Performance |
| ---- | -------------------------------------- | -------- | ----------- |
| 🥇   | Relationship + use directly in visuals | Minimal  | Best        |
| 🥈   | Relationship + RELATED() column        | Moderate | Good        |
| 🥉   | Merge in Power Query                   | Bloated  | Worst       |

> 💡 **0.1% Insight:** Merge only when necessary—RLS propagation, multi-column composite keys, or complex ETL requiring dimension values during transformation.

![Merge Left Outer](https://images/merge-left-outer.png)

# Task 5 – Unpivot / Pivot Scenario

**Goal:** Transform wide-format ERP export into analysis-ready tall format.

## The Problem – Wide Format:

- Each month is a separate column (`Jan_Revenue`, `Feb_Revenue`, `Mar_Revenue`, `Apr_Revenue`)
- Can't use time intelligence DAX
- Can't create dynamic monthly trends
- Breaks when new months arrive

### Before Unpivot:

![Before Unpivot](https://images/unpivot-before.png)

---

## The Fix – Unpivot in Power Query:

```m
Table.UnpivotOtherColumns(#"Changed Type", {"ProductID", "ProductName"}, "Month", "Revenue")
```

### After Unpivot:

![After Unpivot](https://images/unpivot-after.png)

## 🔑 Why Never Pivot Back:

- Breaks star schema
- Prevents dynamic analysis
- Undoes normalization

> 💡 **0.1% Insight:** Clean month names after unpivotting:

```m
Text.BeforeDelimiter([Month], "_")   // "Jan_Revenue" → "Jan"
```

Then sort Month name by Month number to prevent alphabetical ordering.

# Task 6 – Building a Date Dimension

**Goal:** Create a complete date table from scratch, disabling auto date/time.

## Why Disable Auto Date/Time:

- Hidden tables bloat model (50+ invisible tables in large models)
- Can't use custom calendars (fiscal, 4-4-5)
- Relationship ambiguity with multiple date columns

---

## Complete M Code:

```m
let
    StartDate = #date(2026, 1, 1),
    EndDate = #date(2026, 12, 31),

    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),

    #"Converted to Table" = Table.FromList(DateList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Column" = Table.RenameColumns(#"Converted to Table", {{"Column1", "Date"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Column", {{"Date", type date}}),

    #"Added Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),
    #"Added MonthNumber" = Table.AddColumn(#"Added Year", "MonthNumber", each Date.Month([Date]), Int64.Type),
    #"Added MonthName" = Table.AddColumn(#"Added MonthNumber", "MonthName", each Date.MonthName([Date]), type text),
    #"Added MonthShort" = Table.AddColumn(#"Added MonthName", "MonthShort", each Text.Start([MonthName], 3), type text),
    #"Added Quarter" = Table.AddColumn(#"Added MonthShort", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    #"Added DayOfWeek" = Table.AddColumn(#"Added Quarter", "DayOfWeek", each Date.DayOfWeekName([Date]), type text),
    #"Added DayOfWeekShort" = Table.AddColumn(#"Added DayOfWeek", "DayOfWeekShort", each Text.Start([DayOfWeek], 3), type text),
    #"Added IsWeekend" = Table.AddColumn(#"Added DayOfWeekShort", "IsWeekend", each List.Contains({0, 6}, Date.DayOfWeek([Date])), type logical)
in
    #"Added IsWeekend"
```

## Post-Loading Steps:

1. **Mark as Date Table:** Table View → Table Tools → Mark as Date Table → Select `Date` column
2. **Sort `MonthName`** by `MonthNumber`
3. **Sort `DayOfWeek`** by `DayOfWeek` number

![Mark as Date Table](https://images/mark-as-date-table.png)
![Data Table M Code](https://images/date-table-m-code.png)

# Task 7 – Staging vs. Reference Queries

**Goal:** Understand when to Duplicate and when to Reference queries.

---

## 🔑 The Fundamental Difference:

| Feature            | Duplicate                         | Reference                            |
| ------------------ | --------------------------------- | ------------------------------------ |
| **M Code**         | Full independent copy             | Points to original's output          |
| **Source Changes** | Does NOT update                   | Automatically updates                |
| **Memory Usage**   | Loads data again (2× RAM)         | Reuses loaded data (1× RAM)          |
| **Use Case**       | Different source, sandbox testing | Same data, different transformations |

---

## 📊 Decision Matrix:

| Scenario                               | Choice        | Reason                                            |
| -------------------------------------- | ------------- | ------------------------------------------------- |
| Aggregated version of same data        | **Reference** | Same data, different transform. Memory-efficient. |
| Different source file (same structure) | **Duplicate** | Different source = needs independence.            |
| Debug/experiment safely                | **Duplicate** | Sandbox. Don't risk breaking original.            |
| Different filters on same data         | **Reference** | Same base, lightweight views.                     |

![Staging vs Reference](https://images/staging-vs-reference.png)

---

> 💡 **Enterprise Performance:**
>
> - `Table.Buffer()` forces single evaluation when multiple references cause repeated queries
> - Dataflows solve this across multiple PBIX files at enterprise scale

# 🏗️ Final Model Architecture (End of Day 2)

```text
Sales (Fact)                    Products (Dimension)         Date (Dimension)
├── OrderID                     ├── ProductID ←─────┐       ├── Date ←──────────┐
├── OrderDate ───────────────────────────────────────┼───────┤ Year              │
├── ProductID ──────────────────┘                    │       ├── MonthNumber     │
├── CustomerID                                       │       ├── MonthName       │
├── Quantity                                         │       ├── Quarter         │
├── UnitPrice                                        │       ├── DayOfWeek       │
├── Discount                                         │       └── IsWeekend       │
└── LineTotal                                        │                           │
                                                     │                           │
Customers (Dimension)                                │                           │
├── CustomerID ──────────────────────────────────────┘                           │
├── CustomerName                                                                 │
├── Country                                                                      │
└── Segment                                                                      │
```

![data Model](https://images/data_model.png)

## Design Principles Applied:

✅ Star schema: One fact table, multiple dimensions  
✅ Single-direction relationships from dimensions → fact  
✅ No merged/flattened tables  
✅ Custom date dimension (auto date/time disabled)  
✅ Pre-computed `LineTotal` in Power Query

---

## 🧠 Key Takeaways (Day 2)

- **Pre-compute in Power Query, measure what's dynamic in DAX.** Storage is cheap, CPU per click is expensive.

- **Always Left Outer join from fact to dimension.** Inner joins silently delete revenue.

- **Default to relationships over merges.** Star schema > flat tables.

- **Unpivot wide data immediately.** Wide format is the enemy of analysis.

- **Build your own date table.** Auto date/time is a rookie crutch.

- **Reference saves memory, Duplicate provides independence.** Choose deliberately.

## 📂 Files in This Directory

| File/Folder           | Description                                    |
| --------------------- | ---------------------------------------------- |
| `SalesDashboard.pbix` | Power BI report with all Day 2 transformations |
| `data/`               | Source CSV files including wide-format example |
| `images/`             | Screenshots documenting each task              |
| `scripts/`            | Standalone M and DAX code files                |
| `notes/`              | Additional detailed notes                      |
