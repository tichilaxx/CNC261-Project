-- ============================================================================
-- Project: Mighty-Mite Motors (MMM) Database
-- Description: Non-Clustered Indexes for Query Optimization (Guideline Section 2.4)
-- DBMS Target: Microsoft SQL Server (SSMS)
-- ============================================================================

-- [Index 1: รองรับ Query 1.1.1 แคตาล็อกสินค้า]
-- เหตุผล: เพิ่มความเร็วในการค้นหารถตามช่วงราคา (BETWEEN ? AND ?) และดึงข้อมูลสเปกด้วย INCLUDE
CREATE NONCLUSTERED INDEX idx_model_price_desc
ON dbo.model (suggested_retail_price)
INCLUDE (model_description, shipping_weight, time_to_manufacture);
GO

-- [Index 2: รองรับ Query 1.2.1, 1.3.2 และ Transaction 10 รายการสั่งซื้อค้างส่ง]
-- เหตุผล: กรองเฉพาะแถวที่ all_shipped = 'N' และช่วยให้การเชื่อมโยงกับตาราง shipment ทำได้เร็วขึ้น
CREATE NONCLUSTERED INDEX idx_orderline_shipped
ON dbo.order_line (all_shipped, model_numb)
INCLUDE (quantity_ordered, line_total);
GO

-- [Index 3: รองรับ Query 1.2.2 และ Transaction 6 วัตถุดิบถึงจุดสั่งซื้อซ้ำ]
-- เหตุผล: เพิ่มความเร็วในการสแกนหาสต็อกคงเหลือที่ <= reorder_point โดยไม่ต้องสแกนทั้งตาราง
CREATE NONCLUSTERED INDEX idx_rawmaterial_reorder
ON dbo.raw_material (quantity_in_stock, reorder_point)
INCLUDE (material_name, unit_of_measurement);
GO

-- [Index 4: รองรับ Query 1.3.1 และ Transaction 2 ค้นหารถในสต็อกที่พร้อมจัดส่ง]
-- เหตุผล: เร่งการค้นหารถตามรุ่น (model_numb) ที่มีสถานะ 'In Stock' (status_code = 1) และเรียงตามวันผลิต (FIFO)
CREATE NONCLUSTERED INDEX idx_product_model_status
ON dbo.product (model_numb, status_code, date_manufactured)
INCLUDE (serial_numb);
GO

-- [Index 5: รองรับ Transaction 2 และ 10 ประวัติการทยอยจัดส่งสินค้า (Partial Shipment)]
-- เหตุผล: เร่งการคำนวณหายอดรวมสินค้าที่ส่งไปแล้ว SUM(quantity_shipped) ในแต่ละออเดอร์
CREATE NONCLUSTERED INDEX idx_shipment_order_model
ON dbo.shipment (order_numb, model_numb)
INCLUDE (quantity_shipped, shipping_date);
GO

-- [Index 6: รองรับ Query 1.2.3 และ Transaction 8 ตารางการผลิตประจำวัน]
-- เหตุผล: กรองตารางการผลิตตามวันที่ (production_date) เพื่อคำนวณเบิกจ่ายวัตถุดิบช่วงเช้า
CREATE NONCLUSTERED INDEX idx_lineschedule_date
ON dbo.line_schedule (production_date, line_numb)
INCLUDE (model_numb, quantity_to_produce);
GO
