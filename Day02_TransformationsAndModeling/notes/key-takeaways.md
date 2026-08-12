# Day 2 – Key Takeaways

## 🎯 Core Concepts Mastered

---

### 1. Custom Columns: Power Query vs. DAX

**Decision Framework:**

- Power Query Custom Column → Pre-computed, best for large tables
- DAX Calculated Column → Only when needed for further relationships
- DAX Measure → Only when calculation depends on user interaction

**Mantra:** "Pre-compute what you can. Measure what must be dynamic."

**Why It Matters in Interviews:**
Amazon/Google interviewers will test whether you understand storage vs. compute trade-offs. Saying "measures are always better because they don't use memory" is a junior mistake. Memory is cheap; CPU time on every user click is expensive.

---

### 2. Merge vs. Relationships

**The Critical Error I Almost Made:**
I initially chose Inner Join for merging Sales with Products. This would have silently deleted sales rows with missing products—corrupting revenue numbers with no error message.

**Correct Approach:**

- Always Left Outer join from fact to dimension
- Better yet: Don't merge at all—use relationships
- Star schema > flat tables

**Interview Gold:**
"Why did you choose a relationship over a merge?"
→ "Relationships preserve the star schema, improve compression, simplify maintenance, and let VertiPaq optimize queries. I only merge when I have a specific documented reason like RLS propagation or composite keys."

---

### 3. Unpivot: The Most Underrated Transformation

**The Problem:**
ERP systems love wide format (months as columns). This makes time intelligence impossible and trend analysis painful.

**The Fix (3 Clicks):**
Select ID columns → Unpivot Other Columns → Done

**Why This Is 0.1% Knowledge:**
Most tutorials teach you to click buttons. I learned WHY wide format breaks Power BI and can now explain it to stakeholders who send me messy Excel files.

---

### 4. Date Dimension: Auto Date/Time Is a Trap

**The Silent Killer:**
Auto date/time creates hidden tables for EVERY date column. 10 date columns = 10 hidden tables = bloat you can't see.

**What I Built:**

- Complete date table in M code
- Dynamic date range parameters
- IsWeekend fix (Sunday = 0, not 7)
- Fiscal year readiness for Amazon-style calendars

**Post-Loading Steps (Easy to Forget):**

1. Mark as Date Table
2. Sort MonthName by MonthNumber
3. Sort DayOfWeek by day number

---

### 5. Staging vs. Reference Queries

**Simple Rule:**

| Situation                            | Use       |
| ------------------------------------ | --------- |
| Same data, different transformations | Reference |
| Different source file                | Duplicate |
| Safe experimentation                 | Duplicate |
| Memory optimization                  | Reference |

**Enterprise Insight:**
When 10 queries reference the same base query, `Table.Buffer()` prevents re-evaluation. At enterprise scale, Dataflows solve this across multiple PBIX files.

---

## 🏗️ End of Day 2 Model Architecture

**Star Schema Principles Applied:**

- ✅ One fact table (Sales)
- ✅ Multiple dimension tables (Products, Customers, Date)
- ✅ Single-direction relationships (Dimension → Fact)
- ✅ No merged/flattened tables
- ✅ Custom date dimension (auto date/time disabled)
- ✅ Pre-computed calculated column (LineTotal) in fact table

---

## 🧠 Questions I Can Now Answer in Interviews

1. "Walk me through your data modeling process."
2. "When would you use a DAX measure vs. a Power Query calculated column?"
3. "What's wrong with Inner Join for fact-dimension merging?"
4. "Why disable auto date/time?"
5. "How do you handle wide-format data from ERP systems?"
6. "What's the difference between Duplicate and Reference in Power Query?"
7. "How do you optimize a model with 100 million rows?"

---

## ⚠️ Mistakes I Made & Fixed

| Mistake                        | Impact                           | Fix                                    |
| ------------------------------ | -------------------------------- | -------------------------------------- |
| Inner Join for merge           | Silently drops unmatched revenue | Left Outer Join                        |
| IsWeekend: `>= 5`              | Sunday marked as weekday         | `List.Contains({0, 6})`                |
| Auto date/time enabled         | Hidden table bloat               | Custom date table in M                 |
| Double function calls in M     | Slightly slower refresh          | Reuse columns (MonthName → MonthShort) |
| RELATED column kept with merge | Duplicate data in model          | Deleted merge, used relationship only  |

---

## 📚 What I'll Do Differently Going Forward

1. **Always check join type before merging** (Left Outer is default for facts)
2. **Build date table first, then load fact tables**
3. **Disable auto date/time in every new PBIX file** (File → Options → Data Load)
4. **Use Reference queries for derived tables** (save memory)
5. **Document every transformation** (future me will thank me)

---

## 🔗 Related Resources

- [Power Query M Formula Language Specification](https://learn.microsoft.com/en-us/powerquery-m/)
- [DAX Guide by SQLBI](https://dax.guide/)
- [Star Schema: The Complete Reference](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
