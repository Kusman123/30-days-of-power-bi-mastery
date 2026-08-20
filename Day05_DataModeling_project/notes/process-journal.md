# Process Journal – Data Modeling Project

## My Approach

### Phase 1: Exploration

- Explored all 23 tables to understand the business
- Identified: B2B sales company with orders, invoices, payments, campaigns, inventory
- Key entities: Customers, Products, Geo locations
- Key events: Orders, Shipments, Invoices, Payments, Campaigns, Inventory

### Phase 2: Dimension Building

- Customer dimension was the biggest challenge (6 tables, different grains)
- Learned: Merging different grains causes fan-out
- Fixed: Filtered contacts to primary only before merging
- Product dimension had duplicate products (data quality issue)
- Fixed: Removed duplicates using source_id

### Phase 3: Fact Building

- Header-detail pattern was the most valuable lesson
- Built fact_sales from details (order line items) + header context
- Removed pre-aggregated values (order total from header)
- Created accumulating snapshot for order process
- Built factless fact for campaign-product mapping

### Phase 4: Polishing

- Created date dimension with CALENDARAUTO()
- Applied RLS on customer dimension (cascades to 2 facts)
- Created core measures collection
- Final validation: tested with different user emails

## Biggest Challenges

1. Understanding grain differences before merging
2. Header-detail pattern (most confusing)
3. Deciding what to keep vs. remove
4. Data quality issues (duplicates, test data, naming conflicts)

## What I'd Do Differently

- Test more during each merge (not just at the end)
- Document decisions as I go
- Take more screenshots during the process
