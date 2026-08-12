// ============================================
// Power Query M Code: Date Dimension Table
// Project: Sales & Profitability Dashboard
// Day 2 - Task 6
// ============================================
// 
// Purpose:
// Generates a complete date dimension table from scratch.
// Covers full calendar year with all required columns
// for time intelligence and reporting.
//
// Why Custom Date Table?
// - Avoids auto date/time bloat (hidden tables per date column)
// - Enables custom calendars (fiscal year, 4-4-5, etc.)
// - Full control over columns and sorting
// - Required for professional production models
//
// Best Practices Applied:
// - Dynamic date range using parameters
// - All columns explicitly typed
// - IsWeekend correctly handles Sunday = 0
// - MonthShort reuses MonthName (avoids double function call)
// - DayOfWeekShort reuses DayOfWeek (same optimization)
// ============================================

let
    // ========== PARAMETERS (Change these for different date ranges) ==========
    StartDate = #date(2026, 1, 1),
    EndDate = #date(2026, 12, 31),
    
    // ========== GENERATE DATE LIST ==========
    // List.Dates creates consecutive dates from StartDate
    // Duration.Days calculates total days needed
    // +1 ensures EndDate is included in the list
    DateList = List.Dates(
        StartDate, 
        Duration.Days(EndDate - StartDate) + 1, 
        #duration(1, 0, 0, 0)
    ),
    
    // ========== CONVERT TO TABLE ==========
    #"Converted to Table" = Table.FromList(
        DateList, 
        Splitter.SplitByNothing(), 
        null, null, 
        ExtraValues.Error
    ),
    
    // ========== RENAME DEFAULT COLUMN ==========
    #"Renamed Column" = Table.RenameColumns(
        #"Converted to Table", 
        {{"Column1", "Date"}}
    ),
    
    // ========== SET DATA TYPE ==========
    #"Changed Type" = Table.TransformColumnTypes(
        #"Renamed Column", 
        {{"Date", type date}}
    ),
    
    // ========== YEAR ==========
    #"Added Year" = Table.AddColumn(
        #"Changed Type", 
        "Year", 
        each Date.Year([Date]), 
        Int64.Type
    ),
    
    // ========== MONTH NUMBER (1-12) ==========
    #"Added MonthNumber" = Table.AddColumn(
        #"Added Year", 
        "MonthNumber", 
        each Date.Month([Date]), 
        Int64.Type
    ),
    
    // ========== MONTH NAME (January, February...) ==========
    #"Added MonthName" = Table.AddColumn(
        #"Added MonthNumber", 
        "MonthName", 
        each Date.MonthName([Date]), 
        type text
    ),
    
    // ========== MONTH SHORT (Jan, Feb...) ==========
    // OPTIMIZATION: Reuses [MonthName] instead of calling Date.MonthName() again
    #"Added MonthShort" = Table.AddColumn(
        #"Added MonthName", 
        "MonthShort", 
        each Text.Start([MonthName], 3), 
        type text
    ),
    
    // ========== QUARTER (Q1, Q2, Q3, Q4) ==========
    #"Added Quarter" = Table.AddColumn(
        #"Added MonthShort", 
        "Quarter", 
        each "Q" & Text.From(Date.QuarterOfYear([Date])), 
        type text
    ),
    
    // ========== DAY OF WEEK NAME (Sunday, Monday...) ==========
    #"Added DayOfWeek" = Table.AddColumn(
        #"Added Quarter", 
        "DayOfWeek", 
        each Date.DayOfWeekName([Date]), 
        type text
    ),
    
    // ========== DAY OF WEEK SHORT (Sun, Mon...) ==========
    // OPTIMIZATION: Reuses [DayOfWeek] instead of calling function again
    #"Added DayOfWeekShort" = Table.AddColumn(
        #"Added DayOfWeek", 
        "DayOfWeekShort", 
        each Text.Start([DayOfWeek], 3), 
        type text
    ),
    
    // ========== IS WEEKEND (TRUE/FALSE) ==========
    // CRITICAL: Date.DayOfWeek() returns 0 for Sunday, 6 for Saturday
    // Using >= 5 would incorrectly mark Sunday (0) as weekday
    // List.Contains({0, 6}) correctly identifies both weekend days
    #"Added IsWeekend" = Table.AddColumn(
        #"Added DayOfWeekShort", 
        "IsWeekend", 
        each List.Contains({0, 6}, Date.DayOfWeek([Date])), 
        type logical
    )
    
in
    #"Added IsWeekend"

// ============================================
// POST-LOADING STEPS (Do these in Power BI Desktop):
// ============================================
// 1. Table View → Select Date table
// 2. Table Tools → Mark as Date Table → Select "Date" column
// 3. Select "MonthName" column → Sort by Column → "MonthNumber"
// 4. Select "MonthShort" column → Sort by Column → "MonthNumber"
// 5. Select "DayOfWeek" column → Sort by Column → Create DayOfWeekNumber column
// 6. Create relationship: Sales[OrderDate] → Date[Date]
//
// ============================================
// DYNAMIC DATE RANGE (Production Version):
// ============================================
// Replace StartDate and EndDate with:
//
// StartDate = #date(Date.Year(List.Min(Sales[OrderDate])), 1, 1),
// EndDate   = #date(Date.Year(List.Max(Sales[OrderDate])), 12, 31),
//
// This automatically expands as new data arrives.
// ============================================