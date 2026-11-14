-- ============================================================================
-- Section 2.2: Logins, Roles & Permission Grants
-- ============================================================================

-- 1. สร้าง Database Roles
CREATE ROLE role_sales_clerk;
CREATE ROLE role_production_planner;
CREATE ROLE role_warehouse_staff;
CREATE ROLE role_purchasing_officer;

-- 2. กำหนดสิทธิ์ให้แก่ Role: ฝ่ายขาย (role_sales_clerk)
GRANT SELECT ON dbo.customer TO role_sales_clerk;
GRANT INSERT, UPDATE ON dbo.customer TO role_sales_clerk;
GRANT SELECT ON dbo.model TO role_sales_clerk;
GRANT SELECT, INSERT, UPDATE ON dbo.customer_order TO role_sales_clerk;
GRANT SELECT, INSERT, UPDATE ON dbo.order_line TO role_sales_clerk;
GRANT SELECT ON dbo.product_status TO role_sales_clerk;

-- 3. กำหนดสิทธิ์ให้แก่ Role: ฝ่ายวางแผนการผลิต (role_production_planner)
GRANT SELECT ON dbo.model TO role_production_planner;
GRANT SELECT, UPDATE ON dbo.manufacturing_line TO role_production_planner;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.line_schedule TO role_production_planner;
GRANT SELECT ON dbo.material_needed TO role_production_planner;
GRANT SELECT ON dbo.raw_material TO role_production_planner;
GRANT SELECT ON dbo.order_line TO role_production_planner;

-- 4. กำหนดสิทธิ์ให้แก่ Role: ฝ่ายคลังสินค้าและการจัดส่ง (role_warehouse_staff)
GRANT SELECT, INSERT, UPDATE ON dbo.product TO role_warehouse_staff;
GRANT SELECT, INSERT ON dbo.shipment TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.order_line TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.customer_order TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.raw_material TO role_warehouse_staff;
GRANT SELECT ON dbo.line_schedule TO role_warehouse_staff;

-- 5. กำหนดสิทธิ์ให้แก่ Role: ฝ่ายจัดซื้อ (role_purchasing_officer)
GRANT SELECT ON dbo.raw_material TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE ON dbo.supplier TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE ON dbo.material_order TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.material_order_line TO role_purchasing_officer;

-- ----------------------------------------------------------------------------
-- 6. สร้าง Application Logins และ Users พร้อมมอบสิทธิ์
-- ----------------------------------------------------------------------------

-- Login สำหรับ Web Portal ตัวแทนจำหน่าย
CREATE LOGIN app_reseller_login WITH PASSWORD = 'ResellerStrongPwd!2026';
CREATE USER app_reseller_portal FOR LOGIN app_reseller_login;

-- ให้สิทธิ์เฉพาะการสั่งซื้อผ่านหน้าเว็บ
GRANT SELECT ON dbo.customer TO app_reseller_portal;
GRANT INSERT ON dbo.customer_order TO app_reseller_portal;
GRANT INSERT ON dbo.order_line TO app_reseller_portal;

-- Login สำหรับระบบหน้าสายการผลิต (Shop Floor / Warehouse Terminal)
CREATE LOGIN app_shopfloor_login WITH PASSWORD = 'ShopFloorStrongPwd!2026';
CREATE USER app_shopfloor_system FOR LOGIN app_shopfloor_login;

-- เพิ่ม User เข้า Role เพื่อรับสิทธิ์
ALTER ROLE role_warehouse_staff ADD MEMBER app_shopfloor_system;