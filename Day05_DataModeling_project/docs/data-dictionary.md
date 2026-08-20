# Data Dictionary – Final Star Schema

## Dimensions

| Table           | Key Column   | Description                               |
| --------------- | ------------ | ----------------------------------------- |
| dim_customer    | customer_id  | Companies that purchase from us           |
| dim_product     | product_key  | Products we sell (surrogate key created)  |
| dim_geo         | geo_key      | Cities for shipping and billing           |
| dim_order_flags | flag_key     | Junk dimension: channel, status, priority |
| dim_campaign    | campaign_key | Marketing campaigns                       |
| dim_date        | date         | Calendar dates (CALENDARAUTO)             |

## Facts

| Table                   | Grain                                  | Key Measures               |
| ----------------------- | -------------------------------------- | -------------------------- |
| fact_sales              | One row = one order line               | quantity, line_total, cost |
| fact_inventory          | One row = one product per month        | units                      |
| fact_campaign_spend     | One row = one campaign per day         | impressions, clicks, spend |
| fact_promotion_coverage | One row = one campaign-product mapping | (factless)                 |
| fact_order_process      | One row = one order                    | All milestone dates        |
| fact_sales_targets      | One row = one month target sales       | months, target             |

## Support Tables

| Table      | Purpose                          |
| ---------- | -------------------------------- |
| security   | RLS mapping: user email → region |
| \_measures | Collection of core DAX measures  |
