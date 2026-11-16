-- ============================================================================
-- Project: Mighty-Mite Motors (MMM) Database
-- Description: Mock Data Insertion Script (Matching Case Study Figures)
-- DBMS Target: Microsoft SQL Server (SSMS) / Standard ANSI SQL Compatible
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. INSERT INTO model (อ้างอิงจาก Product Catalog ใน Figure 13.1 & Figure 13.5)
-- ----------------------------------------------------------------------------
INSERT INTO model (model_numb, model_description, suggested_retail_price, shipping_weight, time_to_manufacture) VALUES
(1,  'All Terrain Vehicle (ATV)',         124.95, 25.50, '01:30:00'),
(2,  '4-Wheel Drive Cruiser',             249.99, 42.00, '02:45:00'),
(3,  'Classic Roadster',                  189.95, 38.00, '02:15:00'),
(4,  'Sports Car #1 (Speedster)',         249.95, 35.00, '02:00:00'),
(5,  'Sports Car #2 (With Phone)',        249.95, 36.50, '02:10:00'),
(6,  'Turbo-Injected Porsche',            299.95, 45.00, '03:15:00'),
(7,  'Indy Car (Dual Motors)',            269.95, 40.00, '02:50:00'),
(8,  '2-Ton Pickup Truck',                189.95, 48.00, '02:30:00'),
(9,  'Santa Fe Train Locomotive',         159.95, 32.00, '01:45:00'),
(10, 'Oval Track (76" x 168")',            39.95, 12.00, '00:30:00'),
(11, '6 Pieces Straight Track Section',    19.95,  6.50, '00:15:00'),
(12, 'Rechargeable Battery (6V / 12V)',    27.95,  8.00, '00:20:00');

-- ----------------------------------------------------------------------------
-- 2. INSERT INTO manufacturing_line (สายการผลิตหลัก 3 สาย ตาม Figure 13.6)
-- ----------------------------------------------------------------------------
INSERT INTO manufacturing_line (line_numb, line_status) VALUES
(1, 'Active'),
(2, 'Active'),
(3, 'Active');

-- ----------------------------------------------------------------------------
-- 3. INSERT INTO raw_material (อ้างอิงจาก Raw Materials Inventory ใน Figure 13.7)
-- ----------------------------------------------------------------------------
INSERT INTO raw_material (material_id_numb, material_name, unit_of_measurement, quantity_in_stock, reorder_point) VALUES
(1,  'Plastic #3',           'lbs',   95,  150), -- ต่ำกว่า Reorder Point (รอสั่งซื้อ)
(2,  'Red dye 109',          'gals',  25,   50), -- ต่ำกว่า Reorder Point
(3,  'Wheel 12"',            'each', 120,  200), -- ต่ำกว่า Reorder Point
(4,  'Plastic #4',           'lbs',  300,  250),
(5,  'Yellow dye 110',       'gals',   5,   20), -- ต่ำกว่า Reorder Point
(6,  'Yellow dye 65',        'gals',  30,   25),
(7,  'Strut 15"',            'each',  99,  100), -- ต่ำกว่า Reorder Point
(8,  'Axle 24"',             'each', 250,  200),
(9,  'Blu dye 25',           'gals',  18,   15),
(10, 'Plastic #8',           'lbs',  350,  300),
(11, 'Cotter pin: small',    'each', 515,  400),
(12, 'Cotter pin: medium',   'each', 109,  150); -- ต่ำกว่า Reorder Point

-- ----------------------------------------------------------------------------
-- 4. INSERT INTO supplier (ผู้จัดหาวัตถุดิบ)
-- ----------------------------------------------------------------------------
INSERT INTO supplier (supplier_numb, supplier_name, supplier_street, supplier_city, supplier_state, supplier_zip, supplier_contact, supplier_phone) VALUES
(201, 'Apex Industrial Plastics Corp.', '100 Polymer Way',       'Akron',     'OH', '44301', 'David Miller',   '330-555-0144'),
(202, 'Spectrum Color & Dyes LLC',      '450 Chemical Park Blvd', 'Charlotte', 'NC', '28202', 'Sarah Jenkins',  '704-555-0188'),
(203, 'DuraWheel Precision Molding',    '88 Rolling Hills Rd',    'Detroit',   'MI', '48201', 'Robert Kovacs',  '313-555-0192'),
(204, 'Keystone Fasteners & Hardware',  '12 Steel Mill Lane',     'Pittsburgh','PA', '15201', 'Thomas Shelby',  '412-555-0133');

-- ----------------------------------------------------------------------------
-- 5. INSERT INTO customer (ร้านค้าตัวแทนจำหน่าย Toy Stores & Catalog Houses)
-- ----------------------------------------------------------------------------
INSERT INTO customer (customer_numb, customer_name, customer_street, customer_city, customer_state, customer_zip, contact_person, contact_phone, contact_fax) VALUES
(101, 'Toys "R" Magic Northwest',     '1200 Pine Street',       'Seattle',       'WA', '98101', 'Alice Johnson',  '206-555-1100', '206-555-1101'),
(102, 'Whimsical Toy Emporium',       '742 Evergreen Terrace',  'Portland',      'OR', '97201', 'Ned Flanders',   '503-555-2200', '503-555-2201'),
(103, 'PlayTime Mega Superstore',     '888 Market Street',      'San Francisco', 'CA', '94103', 'Bruce Wayne',    '415-555-3300', '415-555-3301'),
(104, 'Kiddie Wonderland Inc.',       '500 Grand Avenue',       'Los Angeles',   'CA', '90012', 'Diana Prince',   '213-555-4400', '213-555-4401'),
(105, 'Rocky Mountain Hobby & Toys',  '300 Colorado Blvd',      'Denver',        'CO', '80202', 'Clark Kent',     '303-555-5500', '303-555-5501');

-- ----------------------------------------------------------------------------
-- 6. INSERT INTO material_needed (สูตรการผลิต BOM: แต่ละรุ่นต้องใช้วัตถุดิบอะไรบ้าง)
-- ----------------------------------------------------------------------------
-- Model 1 (ATV): Plastic #3 (12 lbs), Wheel 12" (4 pcs), Axle 24" (2 pcs), Cotter pin small (4 pcs)
INSERT INTO material_needed (model_numb, material_id_numb, quantity_needed) VALUES
(1, 1,  12),
(1, 3,   4),
(1, 8,   2),
(1, 11,  4);

-- Model 2 (4WD Cruiser): Plastic #4 (20 lbs), Red dye 109 (1 gal), Wheel 12" (4 pcs), Axle 24" (2 pcs), Cotter pin medium (4 pcs)
INSERT INTO material_needed (model_numb, material_id_numb, quantity_needed) VALUES
(2, 4,  20),
(2, 2,   1),
(2, 3,   4),
(2, 8,   2),
(2, 12,  4);

-- Model 8 (2-Ton Pickup): Plastic #8 (25 lbs), Blu dye 25 (1 gal), Wheel 12" (4 pcs), Axle 24" (2 pcs), Strut 15" (2 pcs)
INSERT INTO material_needed (model_numb, material_id_numb, quantity_needed) VALUES
(8, 10, 25),
(8, 9,   1),
(8, 3,   4),
(8, 8,   2),
(8, 7,   2);

-- Model 9 (Santa Fe Train): Plastic #3 (10 lbs), Red dye 109 (1 gal), Yellow dye 110 (1 gal), Cotter pin small (6 pcs)
INSERT INTO material_needed (model_numb, material_id_numb, quantity_needed) VALUES
(9, 1,  10),
(9, 2,   1),
(9, 5,   1),
(9, 11,  6);

-- ----------------------------------------------------------------------------
-- 7. INSERT INTO line_schedule (ตารางการผลิตประจำวัน อ้างอิงจาก Figure 13.6)
-- ----------------------------------------------------------------------------
INSERT INTO line_schedule (line_numb, production_date, model_numb, quantity_to_produce) VALUES
(1, '2026-11-15', 8,  300), -- Line 1 ผลิต Pickup 300 คัน
(2, '2026-11-15', 2,  150), -- Line 2 ผลิต Cruiser 150 คัน
(3, '2026-11-15', 10, 200), -- Line 3 ผลิต Oval Track 200 ชุด
(1, '2026-11-16', 8,  200),
(2, '2026-11-16', 3,  400),
(3, '2026-11-16', 5,  300),
(1, '2026-11-17', 8,  250),
(2, '2026-11-17', 6,  100),
(3, '2026-11-17', 2,  300);

-- ----------------------------------------------------------------------------
-- 8. INSERT INTO material_order & material_order_line (ใบสั่งซื้อวัตถุดิบไปยังซัพพลายเออร์)
-- ----------------------------------------------------------------------------
-- PO #1001: สั่งพลาสติกจาก Apex Industrial Plastics
INSERT INTO material_order (po_numb, supplier_numb, material_order_date, material_order_total) VALUES
(1001, 201, '2026-11-10', 2550.00);

INSERT INTO material_order_line (po_numb, material_id_numb, material_quantity, material_cost_each, material_line_cost) VALUES
(1001, 1,  500, 2.50, 1250.00), -- Plastic #3 (500 lbs @ $2.50)
(1001, 4,  400, 3.25, 1300.00); -- Plastic #4 (400 lbs @ $3.25)

-- PO #1002: สั่งล้อและเพลาจาก DuraWheel
INSERT INTO material_order (po_numb, supplier_numb, material_order_date, material_order_total) VALUES
(1002, 203, '2026-11-11', 5250.00);

INSERT INTO material_order_line (po_numb, material_id_numb, material_quantity, material_cost_each, material_line_cost) VALUES
(1002, 3,  1000, 3.00, 3000.00), -- Wheel 12" (1,000 pcs @ $3.00)
(1002, 8,   500, 4.50, 2250.00); -- Axle 24" (500 pcs @ $4.50)

-- PO #1003: สั่งสีย้อมจาก Spectrum Color
INSERT INTO material_order (po_numb, supplier_numb, material_order_date, material_order_total) VALUES
(1003, 202, '2026-11-12', 1500.00);

INSERT INTO material_order_line (po_numb, material_id_numb, material_quantity, material_cost_each, material_line_cost) VALUES
(1003, 2,   50, 18.00,  900.00), -- Red dye 109 (50 gals @ $18.00)
(1003, 5,   30, 20.00,  600.00); -- Yellow dye 110 (30 gals @ $20.00)

-- ----------------------------------------------------------------------------
-- 9. INSERT INTO customer_order & order_line (คำสั่งซื้อจากตัวแทนจำหน่าย)
-- ----------------------------------------------------------------------------
-- ออเดอร์ #5001: เจ้าหน้าที่ฝ่ายขายบันทึกข้อมูล (order_by = 'Sales') ส่งมอบครบแล้ว 100% (Order Filled = 'Y')
INSERT INTO customer_order (order_numb, customer_numb, order_date, order_total, order_filled, order_by) VALUES
(5001, 101, '2026-11-05', 13747.20, 'Y', 'Sales');

INSERT INTO order_line (order_numb, model_numb, quantity_ordered, unit_price, line_total, all_shipped) VALUES
(5001, 1, 50, 124.95,  6247.50, 'Y'),
(5001, 2, 30, 249.99,  7499.70, 'Y');

-- ออเดอร์ #5002: ร้านค้าตัวแทนสั่งซื้อผ่านระบบออนไลน์ (order_by = 'Reseller') ทยอยส่งบางส่วน
INSERT INTO customer_order (order_numb, customer_numb, order_date, order_total, order_filled, order_by) VALUES
(5002, 102, '2026-11-08', 34496.50, 'N', 'Reseller');

INSERT INTO order_line (order_numb, model_numb, quantity_ordered, unit_price, line_total, all_shipped) VALUES
(5002, 8,  50, 189.95,  9497.50, 'Y'), -- สั่ง 50 ส่งครบแล้ว 50
(5002, 2, 100, 249.99, 24999.00, 'N'); -- สั่ง 100 เพิ่งส่งไป 40 ค้างส่ง 60

-- ออเดอร์ #5003: ร้านค้าตัวแทนสั่งซื้อผ่านระบบออนไลน์ (order_by = 'Reseller') เพิ่งสั่งเข้ามา ยังไม่ได้จัดส่ง
INSERT INTO customer_order (order_numb, customer_numb, order_date, order_total, order_filled, order_by) VALUES
(5003, 103, '2026-11-13', 23994.75, 'N', 'Reseller');

INSERT INTO order_line (order_numb, model_numb, quantity_ordered, unit_price, line_total, all_shipped) VALUES
(5003, 4, 80, 249.95, 19996.00, 'N'),
(5003, 9, 25, 159.95,  3998.75, 'N');

-- ----------------------------------------------------------------------------
-- 10. INSERT INTO shipment (ประวัติการจัดส่งสินค้าแต่ละงวด)
-- ----------------------------------------------------------------------------
-- การจัดส่งสำหรับ Order 5001 (ส่งครบ)
INSERT INTO shipment (order_numb, model_numb, shipping_date, quantity_shipped) VALUES
(5001, 1, '2026-11-07', 50),
(5001, 2, '2026-11-07', 30);

-- การจัดส่งสำหรับ Order 5002 (ส่งงวดแรก)
INSERT INTO shipment (order_numb, model_numb, shipping_date, quantity_shipped) VALUES
(5002, 8, '2026-11-10', 50), -- ส่งครบตามจำนวน
(5002, 2, '2026-11-10', 40); -- ส่งงวดแรก 40 คัน (ค้าง 60 คัน)

-- ----------------------------------------------------------------------------
-- 11. INSERT INTO product (รถของเล่นแต่ละคันที่มี Serial Number เฉพาะตัว)
-- ----------------------------------------------------------------------------
-- รถที่จัดส่งไปแล้ว (status_code = 2, มี date_shipped และ order_numb)
INSERT INTO product (serial_numb, model_numb, date_manufactured, status_code, date_shipped, order_numb) VALUES
(10001, 1, '2026-11-01', 2, '2026-11-07', 5001),
(10002, 1, '2026-11-01', 2, '2026-11-07', 5001),
(10003, 2, '2026-11-02', 2, '2026-11-07', 5001),
(10004, 2, '2026-11-02', 2, '2026-11-07', 5001),
(10005, 8, '2026-11-04', 2, '2026-11-10', 5002),
(10006, 8, '2026-11-04', 2, '2026-11-10', 5002),
(10007, 2, '2026-11-05', 2, '2026-11-10', 5002),
(10008, 2, '2026-11-05', 2, '2026-11-10', 5002);

-- รถที่ยังอยู่ในคลังสินค้าพร้อมจำหน่าย (status_code = 1: In Stock, date_shipped = NULL, order_numb = NULL)
INSERT INTO product (serial_numb, model_numb, date_manufactured, status_code, date_shipped, order_numb) VALUES
(20001, 1, '2026-11-11', 1, NULL, NULL),
(20002, 1, '2026-11-11', 1, NULL, NULL),
(20003, 1, '2026-11-11', 1, NULL, NULL),
(20004, 2, '2026-11-12', 1, NULL, NULL),
(20005, 2, '2026-11-12', 1, NULL, NULL),
(20006, 3, '2026-11-12', 1, NULL, NULL),
(20007, 4, '2026-11-13', 1, NULL, NULL),
(20008, 4, '2026-11-13', 1, NULL, NULL),
(20009, 8, '2026-11-13', 1, NULL, NULL),
(20010, 8, '2026-11-13', 1, NULL, NULL),
(20011, 8, '2026-11-13', 1, NULL, NULL),
(20012, 9, '2026-11-14', 1, NULL, NULL);
