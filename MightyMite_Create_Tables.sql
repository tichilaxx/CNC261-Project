-- ============================================================================
-- Project: Mighty-Mite Motors (MMM) Database
-- Description: DDL Create Tables Script (14 Tables based on Approach 1)
-- DBMS Target: Microsoft SQL Server (SSMS) / Standard ANSI SQL Compatible
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DROP EXISTING TABLES (Reverse Dependency Order to prevent FK errors)
-- ----------------------------------------------------------------------------
IF OBJECT_ID('shipment', 'U') IS NOT NULL DROP TABLE shipment;
IF OBJECT_ID('product', 'U') IS NOT NULL DROP TABLE product;
IF OBJECT_ID('order_line', 'U') IS NOT NULL DROP TABLE order_line;
IF OBJECT_ID('customer_order', 'U') IS NOT NULL DROP TABLE customer_order;
IF OBJECT_ID('material_order_line', 'U') IS NOT NULL DROP TABLE material_order_line;
IF OBJECT_ID('material_order', 'U') IS NOT NULL DROP TABLE material_order;
IF OBJECT_ID('material_needed', 'U') IS NOT NULL DROP TABLE material_needed;
IF OBJECT_ID('line_schedule', 'U') IS NOT NULL DROP TABLE line_schedule;
IF OBJECT_ID('product_status', 'U') IS NOT NULL DROP TABLE product_status;
IF OBJECT_ID('customer', 'U') IS NOT NULL DROP TABLE customer;
IF OBJECT_ID('supplier', 'U') IS NOT NULL DROP TABLE supplier;
IF OBJECT_ID('raw_material', 'U') IS NOT NULL DROP TABLE raw_material;
IF OBJECT_ID('manufacturing_line', 'U') IS NOT NULL DROP TABLE manufacturing_line;
IF OBJECT_ID('model', 'U') IS NOT NULL DROP TABLE model;

-- ============================================================================
-- 2. CREATE STRONG / LOOKUP TABLES (Parent Tables - Level 0)
-- ============================================================================

-- [Table 1: model] เก็บข้อมูลแคตาล็อกรถของเล่น สเปก และราคา
CREATE TABLE model
(
    model_numb              INT             NOT NULL,
    model_description       VARCHAR(100)    NOT NULL,
    suggested_retail_price  DECIMAL(8, 2)   NOT NULL,
    shipping_weight         DECIMAL(6, 2)   NOT NULL,
    time_to_manufacture     TIME            NOT NULL,
    CONSTRAINT pk_model PRIMARY KEY (model_numb)
);

-- [Table 2: manufacturing_line] ข้อมูลสายการผลิต
CREATE TABLE manufacturing_line
(
    line_numb               INT             NOT NULL,
    line_status             VARCHAR(20)     NOT NULL, -- เช่น 'Active', 'Maintenance', 'Idle'
    CONSTRAINT pk_manufacturing_line PRIMARY KEY (line_numb)
);

-- [Table 3: raw_material] ข้อมูลวัตถุดิบและสต็อกคงคลัง
CREATE TABLE raw_material
(
    material_id_numb        INT             NOT NULL,
    material_name           VARCHAR(50)     NOT NULL,
    unit_of_measurement     VARCHAR(20)     NOT NULL, -- เช่น 'lbs', 'gals', 'each'
    quantity_in_stock       INT             NOT NULL DEFAULT 0,
    reorder_point           INT             NOT NULL DEFAULT 0,
    CONSTRAINT pk_raw_material PRIMARY KEY (material_id_numb)
);

-- [Table 4: supplier] ข้อมูลซัพพลายเออร์วัตถุดิบ
CREATE TABLE supplier
(
    supplier_numb           INT             NOT NULL,
    supplier_name           VARCHAR(100)    NOT NULL,
    supplier_street         VARCHAR(100)    NULL,
    supplier_city           VARCHAR(50)     NULL,
    supplier_state          CHAR(2)         NULL,
    supplier_zip            VARCHAR(10)     NULL,
    supplier_contact        VARCHAR(50)     NULL,
    supplier_phone          VARCHAR(20)     NULL,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_numb)
);

-- [Table 5: customer] ร้านค้าตัวแทนจำหน่าย (Toy Stores & Resellers)
CREATE TABLE customer
(
    customer_numb           INT             NOT NULL,
    customer_name           VARCHAR(100)    NOT NULL,
    customer_street         VARCHAR(100)    NULL,
    customer_city           VARCHAR(50)     NULL,
    customer_state          CHAR(2)         NULL,
    customer_zip            VARCHAR(10)     NULL,
    contact_person          VARCHAR(50)     NULL,
    contact_phone           VARCHAR(20)     NULL,
    contact_fax             VARCHAR(20)     NULL,
    CONSTRAINT pk_customer PRIMARY KEY (customer_numb)
);

-- [Table 6: product_status] ตารางสถานะของรถสำเร็จรูป
CREATE TABLE product_status
(
    status_code             INT             NOT NULL,
    status_description      VARCHAR(50)     NOT NULL, -- เช่น 'In Stock', 'Shipped', 'Under Repair'
    CONSTRAINT pk_product_status PRIMARY KEY (status_code)
);

-- ============================================================================
-- 3. CREATE INTERMEDIATE TABLES (Level 1)
-- ============================================================================

-- [Table 7: line_schedule] Weak Entity - ตารางกำหนดการผลิตประจำวันของแต่ละสายการผลิต
CREATE TABLE line_schedule
(
    line_numb               INT             NOT NULL,
    production_date         DATE            NOT NULL,
    model_numb              INT             NOT NULL,
    quantity_to_produce     INT             NOT NULL,
    CONSTRAINT pk_line_schedule PRIMARY KEY (line_numb, production_date),
    CONSTRAINT fk_linesched_line FOREIGN KEY (line_numb) 
        REFERENCES manufacturing_line (line_numb) ON DELETE CASCADE,
    CONSTRAINT fk_linesched_model FOREIGN KEY (model_numb) 
        REFERENCES model (model_numb)
);

-- [Table 8: material_needed] Weak Entity - สูตรโครงสร้างวัตถุดิบในการผลิต (BOM)
CREATE TABLE material_needed
(
    model_numb              INT             NOT NULL,
    material_id_numb        INT             NOT NULL,
    quantity_needed         INT             NOT NULL,
    CONSTRAINT pk_material_needed PRIMARY KEY (model_numb, material_id_numb),
    CONSTRAINT fk_matneed_model FOREIGN KEY (model_numb) 
        REFERENCES model (model_numb) ON DELETE CASCADE,
    CONSTRAINT fk_matneed_mat FOREIGN KEY (material_id_numb) 
        REFERENCES raw_material (material_id_numb)
);

-- [Table 9: material_order] ใบสั่งซื้อวัตถุดิบ (PO) ส่งไปยังซัพพลายเออร์
CREATE TABLE material_order
(
    po_numb                 INT             NOT NULL,
    supplier_numb           INT             NOT NULL,
    material_order_date     DATE            NOT NULL,
    material_order_total    DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_material_order PRIMARY KEY (po_numb),
    CONSTRAINT fk_matord_supplier FOREIGN KEY (supplier_numb) 
        REFERENCES supplier (supplier_numb)
);

-- [Table 10: customer_order] ใบสั่งซื้อสินค้าจากตัวแทนจำหน่าย
CREATE TABLE customer_order
(
    order_numb              INT             NOT NULL,
    customer_numb           INT             NOT NULL,
    order_date              DATE            NOT NULL,
    order_total             DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    order_filled            CHAR(1)         NOT NULL DEFAULT 'N',
    order_by                VARCHAR(20)     NOT NULL DEFAULT 'Sales', -- 'Sales' หรือ 'Reseller'
    CONSTRAINT pk_customer_order PRIMARY KEY (order_numb),
    CONSTRAINT fk_custord_customer FOREIGN KEY (customer_numb) 
        REFERENCES customer (customer_numb),
    CONSTRAINT chk_order_filled CHECK (order_filled IN ('Y', 'N')),
    CONSTRAINT chk_order_by CHECK (order_by IN ('Sales', 'Reseller'))
);

-- ============================================================================
-- 4. CREATE DETAIL / TRANSACTION TABLES (Level 2)
-- ============================================================================

-- [Table 11: material_order_line] Weak Entity - รายการวัตถุดิบในใบสั่งซื้อ (PO Line)
CREATE TABLE material_order_line
(
    po_numb                 INT             NOT NULL,
    material_id_numb        INT             NOT NULL,
    material_quantity       INT             NOT NULL,
    material_cost_each      DECIMAL(8, 2)   NOT NULL,
    material_line_cost      DECIMAL(10, 2)  NOT NULL,
    CONSTRAINT pk_material_order_line PRIMARY KEY (po_numb, material_id_numb),
    CONSTRAINT fk_matordline_po FOREIGN KEY (po_numb) 
        REFERENCES material_order (po_numb) ON DELETE CASCADE,
    CONSTRAINT fk_matordline_mat FOREIGN KEY (material_id_numb) 
        REFERENCES raw_material (material_id_numb)
);

-- [Table 12: order_line] Weak Entity - รายการสินค้าที่ตัวแทนจำหน่ายสั่งซื้อ
CREATE TABLE order_line
(
    order_numb              INT             NOT NULL,
    model_numb              INT             NOT NULL,
    quantity_ordered        INT             NOT NULL,
    unit_price              DECIMAL(8, 2)   NOT NULL,
    line_total              DECIMAL(10, 2)  NOT NULL,
    all_shipped             CHAR(1)         NOT NULL DEFAULT 'N',
    CONSTRAINT pk_order_line PRIMARY KEY (order_numb, model_numb),
    CONSTRAINT fk_ordline_order FOREIGN KEY (order_numb) 
        REFERENCES customer_order (order_numb) ON DELETE CASCADE,
    CONSTRAINT fk_ordline_model FOREIGN KEY (model_numb) 
        REFERENCES model (model_numb),
    CONSTRAINT chk_all_shipped CHECK (all_shipped IN ('Y', 'N'))
);

-- [Table 13: product] บันทึกรถของเล่นสำเร็จรูปแต่ละคันตามหมายเลขซีเรียล (Serial Number)
CREATE TABLE product
(
    serial_numb             INT             NOT NULL,
    model_numb              INT             NOT NULL,
    date_manufactured       DATE            NOT NULL,
    status_code             INT             NOT NULL, -- FK to product_status (1 = In Stock, 2 = Shipped)
    date_shipped            DATE            NULL,
    order_numb              INT             NULL,     -- บันทึกเมื่อถูกตัดจ่ายส่งให้ Order ใด
    CONSTRAINT pk_product PRIMARY KEY (serial_numb),
    CONSTRAINT fk_prod_model FOREIGN KEY (model_numb) 
        REFERENCES model (model_numb),
    CONSTRAINT fk_prod_status FOREIGN KEY (status_code) 
        REFERENCES product_status (status_code),
    CONSTRAINT fk_prod_order FOREIGN KEY (order_numb) 
        REFERENCES customer_order (order_numb)
);

-- ============================================================================
-- 5. CREATE SHIPMENT DETAIL TABLE (Level 3)
-- ============================================================================

-- [Table 14: shipment] Weak Entity - บันทึกประวัติการจัดส่งสินค้าแต่ละล็อต (รองรับ Partial Shipment)
CREATE TABLE shipment
(
    order_numb              INT             NOT NULL,
    model_numb              INT             NOT NULL,
    shipping_date           DATE            NOT NULL,
    quantity_shipped        INT             NOT NULL,
    CONSTRAINT pk_shipment PRIMARY KEY (order_numb, model_numb, shipping_date),
    CONSTRAINT fk_shipment_orderline FOREIGN KEY (order_numb, model_numb) 
        REFERENCES order_line (order_numb, model_numb) ON DELETE CASCADE
);

-- ============================================================================
-- 6. INITIAL SEED DATA (ข้อมูลเริ่มต้นสำหรับ Lookup / Master)
-- ============================================================================
INSERT INTO product_status (status_code, status_description) VALUES (1, 'In Stock');
INSERT INTO product_status (status_code, status_description) VALUES (2, 'Shipped');
INSERT INTO product_status (status_code, status_description) VALUES (3, 'Reserved');
