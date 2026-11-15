-- ============================================================================
-- Project: Mighty-Mite Motors (MMM) Database
-- Description: 10 Transactions SQL with Idempotent Auto-Clean & Transaction Control
-- DBMS Target: Microsoft SQL Server (SSMS) - T-SQL Compatible
-- Feature: สามารถกด Execute (F5) ซ้ำกี่รอบก็ได้ โดยไม่ติด Duplicate Key Error
-- ============================================================================

-- ============================================================================
-- Transaction 1: การบันทึกคำสั่งซื้อสินค้าจากตัวแทนจำหน่าย (Reseller Order Placement)
-- สถานการณ์: ลูกค้า 104 (Kiddie Wonderland Inc.) สั่งซื้อรถ Model 1 (ATV) จำนวน 20 คัน
-- และ Model 8 (Pickup) จำนวน 15 คัน ออกเป็นใบสั่งซื้อใหม่เลขที่ 5004
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- [Auto-Clean]: ลบข้อมูลทดสอบเดิมของ Order 5004 ก่อน (เพื่อให้กดรันซ้ำกี่รอบก็ได้)
DELETE FROM shipment WHERE order_numb = 5004;
DELETE FROM order_line WHERE order_numb = 5004;
DELETE FROM customer_order WHERE order_numb = 5004;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบข้อมูลลูกค้าและราคารถ
    SELECT customer_numb, customer_name, contact_person 
    FROM customer 
    WHERE customer_numb = 104;

    SELECT model_numb, model_description, suggested_retail_price 
    FROM model 
    WHERE model_numb IN (1, 8);

    -- Step 2: สร้างใบสั่งซื้อหลัก (Order #5004)
    INSERT INTO customer_order (order_numb, customer_numb, order_date, order_total, order_filled)
    VALUES (5004, 104, CAST(GETDATE() AS DATE), 0.00, 'N');

    -- Step 3: เพิ่มรายการสินค้าย่อยลงใน order_line
    INSERT INTO order_line (order_numb, model_numb, quantity_ordered, unit_price, line_total, all_shipped)
    VALUES 
    (5004, 1, 20, 124.95, 2499.00, 'N'),
    (5004, 8, 15, 189.95, 2849.25, 'N');

    -- Step 4: คำนวณและอัปเดตยอดเงินรวมของใบสั่งซื้อ ($5,348.25)
    UPDATE customer_order
    SET order_total = (SELECT SUM(line_total) FROM order_line WHERE order_numb = 5004)
    WHERE order_numb = 5004;

    COMMIT TRANSACTION;
    PRINT 'Transaction 1: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 1: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 2: การบันทึกการจัดส่งสินค้าและตัดสต็อกสินค้าสำเร็จรูป (Product Shipment & Finished Goods Deduction)
-- สถานการณ์: จัดส่งรถ Model 8 จำนวน 2 คัน (Serial: 20009, 20010) ให้แก่ Order 5004
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- [Auto-Clean]: คืนค่าสถานะรถเดิมก่อนเทสซ้ำ
DELETE FROM shipment WHERE order_numb = 5004 AND model_numb = 8;
UPDATE product SET status_code = 1, date_shipped = NULL, order_numb = NULL WHERE serial_numb IN (20009, 20010);
UPDATE order_line SET all_shipped = 'N' WHERE order_numb = 5004 AND model_numb = 8;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ค้นหารถในคลังที่พร้อมส่ง (status_code = 1) รุ่น Model 8 เรียงตามวันผลิต FIFO
    SELECT TOP (2) serial_numb, model_numb, date_manufactured 
    FROM product 
    WHERE model_numb = 8 AND status_code = 1 
    ORDER BY date_manufactured ASC;

    -- Step 2: บันทึกประวัติการจัดส่งใน shipment
    INSERT INTO shipment (order_numb, model_numb, shipping_date, quantity_shipped)
    VALUES (5004, 8, CAST(GETDATE() AS DATE), 2);

    -- Step 3: ตัดสต็อกรถยนต์ เปลี่ยนสถานะเป็นจัดส่งแล้ว (status_code = 2) และบันทึกเลขที่ Order
    UPDATE product
    SET status_code = 2, date_shipped = CAST(GETDATE() AS DATE), order_numb = 5004
    WHERE serial_numb IN (20009, 20010);

    -- Step 4: ตรวจสอบและอัปเดตสถานะ all_shipped ใน order_line หากส่งครบตามยอดสั่ง
    UPDATE order_line
    SET all_shipped = 'Y'
    WHERE order_numb = 5004 AND model_numb = 8
      AND quantity_ordered <= (
          SELECT SUM(quantity_shipped) 
          FROM shipment 
          WHERE order_numb = 5004 AND model_numb = 8
      );

    COMMIT TRANSACTION;
    PRINT 'Transaction 2: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 2: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 3: การรับมอบสินค้าสำเร็จรูปจากการผลิตเข้าสู่คลังสินค้า (Finished Goods Receiving)
-- สถานการณ์: สายการผลิต Line 1 ผลิตรถ Model 8 เสร็จ 3 คัน แผนกคลังสินค้ารับมอบและลงทะเบียน Serial Number ใหม่ (20051, 20052, 20053)
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- [Auto-Clean]: ลบซีเรียลเดิมที่เคยเทสไว้ก่อนหน้า
DELETE FROM product WHERE serial_numb IN (20051, 20052, 20053);

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบยอดตามแผนการผลิตใน line_schedule
    SELECT line_numb, production_date, model_numb, quantity_to_produce
    FROM line_schedule
    WHERE line_numb = 1 AND production_date = '2026-11-15';

    -- Step 2: บันทึกรถยนต์สำเร็จรูปคันใหม่เข้าสต็อกคลัง (status_code = 1: In Stock)
    INSERT INTO product (serial_numb, model_numb, date_manufactured, status_code, date_shipped, order_numb)
    VALUES 
    (20051, 8, CAST(GETDATE() AS DATE), 1, NULL, NULL),
    (20052, 8, CAST(GETDATE() AS DATE), 1, NULL, NULL),
    (20053, 8, CAST(GETDATE() AS DATE), 1, NULL, NULL);

    -- Step 3: ตรวจนับสต็อกรถสำเร็จรูปรุ่น Model 8 ที่พร้อมขายหลังรับเข้า
    SELECT model_numb, COUNT(serial_numb) AS current_in_stock
    FROM product
    WHERE model_numb = 8 AND status_code = 1
    GROUP BY model_numb;

    COMMIT TRANSACTION;
    PRINT 'Transaction 3: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 3: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 4: การรับมอบวัตถุดิบเข้าคลังสินค้าจากซัพพลายเออร์ (Raw Material Receiving & Stock-In)
-- สถานการณ์: ตรวจรับวัตถุดิบ Plastic #3 (material_id_numb = 1) จำนวน 500 lbs ที่ส่งมาจากซัพพลายเออร์ตามใบสั่งซื้อ PO #1001
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบข้อมูลในใบสั่งซื้อ PO #1001
    SELECT po_numb, material_id_numb, material_quantity, material_cost_each
    FROM material_order_line
    WHERE po_numb = 1001 AND material_id_numb = 1;

    -- Step 2: เพิ่มจำนวนสต็อกวัตถุดิบใน raw_material (+500 lbs)
    UPDATE raw_material
    SET quantity_in_stock = quantity_in_stock + 500
    WHERE material_id_numb = 1;

    -- Step 3: ดูยอดสต็อกคงเหลือล่าสุดหลังรับของ
    SELECT material_id_numb, material_name, quantity_in_stock, unit_of_measurement
    FROM raw_material
    WHERE material_id_numb = 1;

    COMMIT TRANSACTION;
    PRINT 'Transaction 4: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 4: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 5: การกำหนดตารางการผลิตประจำวันสำหรับสายการผลิต (Manufacturing Line Scheduling)
-- สถานการณ์: วางแผนตารางการผลิตวันที่ 2026-11-18 ให้สายการผลิต Line 1 ผลิต Model 2 จำนวน 180 คัน
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- [Auto-Clean]: ลบตารางผลิตของวันที่ 2026-11-18 ออกก่อน
DELETE FROM line_schedule WHERE line_numb = 1 AND production_date = '2026-11-18';

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบสถานะความพร้อมของ Line 1
    SELECT line_numb, line_status 
    FROM manufacturing_line 
    WHERE line_numb = 1 AND line_status = 'Active';

    -- Step 2: บันทึกกำหนดการผลิตลงใน line_schedule
    INSERT INTO line_schedule (line_numb, production_date, model_numb, quantity_to_produce)
    VALUES (1, '2026-11-18', 2, 180);

    -- Step 3: ปรับเปลี่ยนยอดการผลิตเป็น 220 คัน (กรณีปรับแผน)
    UPDATE line_schedule
    SET quantity_to_produce = 220
    WHERE line_numb = 1 AND production_date = '2026-11-18';

    COMMIT TRANSACTION;
    PRINT 'Transaction 5: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 5: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 6: การสร้างใบสั่งซื้อวัตถุดิบจากซัพพลายเออร์ (Raw Material Purchase Order Generation)
-- สถานการณ์: เปิด PO ใหม่เลขที่ 1004 ส่งไปยัง Apex Industrial Plastics (supplier_numb = 201) เพื่อสั่งซื้อ Plastic #3 จำนวน 600 lbs @ $2.50
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- [Auto-Clean]: ลบ PO 1004 เดิมก่อน
DELETE FROM material_order_line WHERE po_numb = 1004;
DELETE FROM material_order WHERE po_numb = 1004;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบวัตถุดิบและซัพพลายเออร์
    SELECT material_id_numb, material_name, quantity_in_stock, reorder_point 
    FROM raw_material WHERE material_id_numb = 1;

    SELECT supplier_numb, supplier_name 
    FROM supplier WHERE supplier_numb = 201;

    -- Step 2: สร้างใบสั่งซื้อวัตถุดิบหลัก (PO #1004)
    INSERT INTO material_order (po_numb, supplier_numb, material_order_date, material_order_total)
    VALUES (1004, 201, CAST(GETDATE() AS DATE), 0.00);

    -- Step 3: เพิ่มรายการวัตถุดิบลงใน material_order_line
    INSERT INTO material_order_line (po_numb, material_id_numb, material_quantity, material_cost_each, material_line_cost)
    VALUES (1004, 1, 600, 2.50, (600 * 2.50));

    -- Step 4: คำนวณและอัปเดตยอดเงินรวมของ PO #1004 ($1,500.00)
    UPDATE material_order
    SET material_order_total = (SELECT SUM(material_line_cost) FROM material_order_line WHERE po_numb = 1004)
    WHERE po_numb = 1004;

    COMMIT TRANSACTION;
    PRINT 'Transaction 6: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 6: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 7: การตรวจสอบและคำนวณความต้องการวัตถุดิบล่วงหน้าตามยอดสั่งซื้อ (Pre-production Material Requirement Check)
-- สถานการณ์: ตรวจสอบคำนวณวัตถุดิบทั้งหมดที่ต้องใช้ตามสูตรการผลิต (BOM) สำหรับออเดอร์ที่ยังค้างส่ง เพื่อดูว่าวัตถุดิบในคลังเพียงพอหรือไม่
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
BEGIN TRY
    SELECT 
        rm.material_id_numb,
        rm.material_name,
        rm.quantity_in_stock AS current_stock,
        SUM(ol.quantity_ordered * mn.quantity_needed) AS total_material_required,
        (rm.quantity_in_stock - SUM(ol.quantity_ordered * mn.quantity_needed)) AS projected_balance
    FROM order_line ol
    JOIN material_needed mn ON ol.model_numb = mn.model_numb
    JOIN raw_material rm ON mn.material_id_numb = rm.material_id_numb
    WHERE ol.all_shipped = 'N'
    GROUP BY rm.material_id_numb, rm.material_name, rm.quantity_in_stock
    ORDER BY projected_balance ASC;

    COMMIT TRANSACTION;
    PRINT 'Transaction 7: Query Completed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 7: Error occurred.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 8: การตัดสต็อกวัตถุดิบประจำวันตามตารางการผลิต (Raw Material Inventory Deduction)
-- สถานการณ์: เช้าวันที่ 2026-11-15 ทำการตัดสต็อกวัตถุดิบสำหรับ Line 2 ที่จะผลิต Model 2 (Cruiser) จำนวน 150 คัน
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: คำนวณยอดวัตถุดิบที่ต้องใช้สำหรับ Line 2 ในวันนี้
    SELECT 
        mn.material_id_numb, 
        rm.material_name,
        rm.quantity_in_stock,
        (ls.quantity_to_produce * mn.quantity_needed) AS deduction_qty
    FROM line_schedule ls
    JOIN material_needed mn ON ls.model_numb = mn.model_numb
    JOIN raw_material rm ON mn.material_id_numb = rm.material_id_numb
    WHERE ls.production_date = '2026-11-15' AND ls.line_numb = 2;

    -- Step 2: ตัดสต็อก Plastic #4 (ใช้วัตถุดิบ 150 คัน x 20 lbs = 3,000 lbs)
    UPDATE raw_material
    SET quantity_in_stock = quantity_in_stock - 3000
    WHERE material_id_numb = 4;

    -- Step 3: ตัดสต็อก Red dye 109 (ใช้วัตถุดิบ 150 คัน x 1 gal = 150 gals)
    UPDATE raw_material
    SET quantity_in_stock = quantity_in_stock - 150
    WHERE material_id_numb = 2;

    -- Step 4: ตรวจสอบความถูกต้องว่าสต็อกคงเหลือติดลบหรือไม่
    SELECT material_id_numb, material_name, quantity_in_stock 
    FROM raw_material 
    WHERE material_id_numb IN (2, 4);

    COMMIT TRANSACTION;
    PRINT 'Transaction 8: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 8: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 9: การเพิ่มข้อมูลรุ่นผลิตภัณฑ์ใหม่เข้าสู่ระบบแคตาล็อก (New Model Introduction)
-- สถานการณ์: เพิ่มรถรุ่นใหม่ Model 13 "Mini Electric Go-Kart", ราคาแนะนำ $329.95, น้ำหนักจัดส่ง 50 lbs, เวลาผลิต 02:40:00 พร้อมผูกสูตรชิ้นส่วน BOM
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- [Auto-Clean]: ลบข้อมูล Model 13 เดิมออกก่อน
DELETE FROM material_needed WHERE model_numb = 13;
DELETE FROM model WHERE model_numb = 13;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: เพิ่มข้อมูลรุ่นรถใหม่ลงใน model
    INSERT INTO model (model_numb, model_description, suggested_retail_price, shipping_weight, time_to_manufacture)
    VALUES (13, 'Mini Electric Go-Kart', 329.95, 50.00, '02:40:00');

    -- Step 2: กำหนดสูตรการผลิต (BOM) ใน material_needed (ใช้ Plastic #4: 25 lbs, Wheel 12": 4 pcs, Axle 24": 2 pcs)
    INSERT INTO material_needed (model_numb, material_id_numb, quantity_needed)
    VALUES 
    (13, 4, 25),
    (13, 3,  4),
    (13, 8,  2);

    -- Step 3: ปรับราคาโปรโมชั่นเปิดตัวเป็น $319.95
    UPDATE model
    SET suggested_retail_price = 319.95
    WHERE model_numb = 13;

    COMMIT TRANSACTION;
    PRINT 'Transaction 9: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 9: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO

-- ============================================================================
-- Transaction 10: การอัปเดตสถานะคำสั่งซื้อและการจัดส่งบางส่วน (Order Fulfillment & Partial Shipment Status Update)
-- สถานการณ์: ตรวจสอบ Order 5002 (ซึ่งเดิมสั่ง Model 2 ไว้ 100 คัน ส่งไปแล้ว 40 คัน ค้างส่งอีก 60 คัน) จากนั้นบันทึกการจัดส่งส่วนที่เหลือ 60 คัน และปิดออเดอร์
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- [Auto-Clean]: คืนค่าสถานะ Order 5002 เป็นก่อนส่งงวดที่ 2
DELETE FROM shipment WHERE order_numb = 5002 AND quantity_shipped = 60;
UPDATE order_line SET all_shipped = 'N' WHERE order_numb = 5002 AND model_numb = 2;
UPDATE customer_order SET order_filled = 'N' WHERE order_numb = 5002;

BEGIN TRANSACTION;
BEGIN TRY
    -- Step 1: ตรวจสอบสถานะการทยอยจัดส่งสะสมของ Order 5002
    SELECT 
        ol.order_numb,
        ol.model_numb,
        ol.quantity_ordered,
        COALESCE(SUM(s.quantity_shipped), 0) AS total_shipped,
        (ol.quantity_ordered - COALESCE(SUM(s.quantity_shipped), 0)) AS remaining_to_ship,
        CASE 
            WHEN COALESCE(SUM(s.quantity_shipped), 0) >= ol.quantity_ordered THEN 'COMPLETED'
            WHEN COALESCE(SUM(s.quantity_shipped), 0) > 0 THEN 'PARTIAL'
            ELSE 'PENDING'
        END AS shipment_status
    FROM order_line ol
    LEFT JOIN shipment s ON ol.order_numb = s.order_numb AND ol.model_numb = s.model_numb
    WHERE ol.order_numb = 5002
    GROUP BY ol.order_numb, ol.model_numb, ol.quantity_ordered;

    -- Step 2: บันทึกการส่งมอบสินค้าส่วนที่เหลือ 60 คัน ของ Model 2
    INSERT INTO shipment (order_numb, model_numb, shipping_date, quantity_shipped)
    VALUES (5002, 2, CAST(GETDATE() AS DATE), 60);

    -- Step 3: ปรับสถานะ all_shipped ใน order_line เป็นส่งครบแล้ว ('Y')
    UPDATE order_line
    SET all_shipped = 'Y'
    WHERE order_numb = 5002 AND model_numb = 2;

    -- Step 4: ปรับสถานะปิดใบสั่งซื้อหลัก order_filled = 'Y' เมื่อทุกรายการในออเดอร์ส่งครบ 100%
    UPDATE customer_order
    SET order_filled = 'Y'
    WHERE order_numb = 5002
      AND NOT EXISTS (
          SELECT 1 FROM order_line WHERE order_numb = 5002 AND all_shipped = 'N'
      );

    COMMIT TRANSACTION;
    PRINT 'Transaction 10: Completed and Committed Successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction 10: Error occurred, transaction rolled back.';
    THROW;
END CATCH;
GO
