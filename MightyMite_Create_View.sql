IF OBJECT_ID('dbo.mv_Production_Pending_Summary', 'V') IS NOT NULL
    DROP VIEW dbo.mv_Production_Pending_Summary;
GO

IF OBJECT_ID('dbo.v_Reseller_Catalog', 'V') IS NOT NULL
    DROP VIEW dbo.v_Reseller_Catalog;
GO

CREATE VIEW dbo.v_Reseller_Catalog
AS
SELECT 
    m.model_numb,
    m.model_description,
    m.suggested_retail_price,
    m.shipping_weight,
    COUNT(p.serial_numb) AS available_in_stock
FROM dbo.model m
LEFT JOIN dbo.product p 
    ON m.model_numb = p.model_numb AND p.status_code = 1
GROUP BY 
    m.model_numb, 
    m.model_description, 
    m.suggested_retail_price, 
    m.shipping_weight;
GO

GRANT SELECT ON dbo.v_Reseller_Catalog TO app_reseller_portal;
GO

CREATE VIEW dbo.mv_Production_Pending_Summary
WITH SCHEMABINDING
AS
SELECT 
    ol.model_numb,
    SUM(ol.quantity_ordered) AS total_units_ordered,
    COUNT_BIG(*) AS total_order_rows
FROM dbo.order_line ol
WHERE ol.all_shipped = 'N'
GROUP BY ol.model_numb;
GO

CREATE UNIQUE CLUSTERED INDEX cdx_mv_prod_pending 
ON dbo.mv_Production_Pending_Summary (model_numb);
GO