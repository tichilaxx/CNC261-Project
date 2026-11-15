-- ============================================================================
-- Project: Mighty-Mite Motors (MMM) Database
-- Description: Complete Security Setup (Logins, Users, Roles & Permissions)
-- DBMS Target: Microsoft SQL Server (SSMS)
-- Feature: รันซ้ำได้ (Safe Drop & Create), กำหนด Login เข้าใช้งานได้จริง
-- ============================================================================

-- หมายเหตุ: หากฐานข้อมูลของคุณชื่ออื่น ให้เปลี่ยนชื่อในคำสั่ง USE ด้านล่างนี้
-- USE MightyMiteDB;
-- GO

-- ----------------------------------------------------------------------------
-- 1. DROP EXISTING USERS & LOGINS (เคลียร์ของเดิมออกก่อนเพื่อให้รันซ้ำได้ไม่ติด Error)
-- ----------------------------------------------------------------------------
-- ลบ Users ออกจาก Database
IF USER_ID('user_sales') IS NOT NULL DROP USER user_sales;
IF USER_ID('user_planner') IS NOT NULL DROP USER user_planner;
IF USER_ID('user_warehouse') IS NOT NULL DROP USER user_warehouse;
IF USER_ID('user_purchasing') IS NOT NULL DROP USER user_purchasing;
IF USER_ID('app_reseller_portal') IS NOT NULL DROP USER app_reseller_portal;
IF USER_ID('app_shopfloor_system') IS NOT NULL DROP USER app_shopfloor_system;

-- ลบ Logins ออกจาก SQL Server Instance
IF SUSER_ID('user_sales') IS NOT NULL DROP LOGIN user_sales;
IF SUSER_ID('user_planner') IS NOT NULL DROP LOGIN user_planner;
IF SUSER_ID('user_warehouse') IS NOT NULL DROP LOGIN user_warehouse;
IF SUSER_ID('user_purchasing') IS NOT NULL DROP LOGIN user_purchasing;
IF SUSER_ID('app_reseller_login') IS NOT NULL DROP LOGIN app_reseller_login;
IF SUSER_ID('app_shopfloor_login') IS NOT NULL DROP LOGIN app_shopfloor_login;

-- ----------------------------------------------------------------------------
-- 2. CREATE ROLES (สร้างกลุ่มสิทธิ์ตามแผนก)
-- ----------------------------------------------------------------------------
IF DATABASE_PRINCIPAL_ID('role_sales_clerk') IS NULL CREATE ROLE role_sales_clerk;
IF DATABASE_PRINCIPAL_ID('role_production_planner') IS NULL CREATE ROLE role_production_planner;
IF DATABASE_PRINCIPAL_ID('role_warehouse_staff') IS NULL CREATE ROLE role_warehouse_staff;
IF DATABASE_PRINCIPAL_ID('role_purchasing_officer') IS NULL CREATE ROLE role_purchasing_officer;
GO

-- ----------------------------------------------------------------------------
-- 3. GRANT PERMISSIONS TO ROLES (กำหนดสิทธิ์ให้แต่ละ Role)
-- ----------------------------------------------------------------------------

-- [Role 1: ฝ่ายขาย role_sales_clerk]
GRANT SELECT, INSERT, UPDATE ON dbo.customer TO role_sales_clerk;
GRANT SELECT ON dbo.model TO role_sales_clerk;
GRANT SELECT, INSERT, UPDATE ON dbo.customer_order TO role_sales_clerk;
GRANT SELECT, INSERT, UPDATE ON dbo.order_line TO role_sales_clerk;
GRANT SELECT ON dbo.product_status TO role_sales_clerk;

-- [Role 2: ฝ่ายวางแผนการผลิต role_production_planner]
GRANT SELECT ON dbo.model TO role_production_planner;
GRANT SELECT, UPDATE ON dbo.manufacturing_line TO role_production_planner;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.line_schedule TO role_production_planner;
GRANT SELECT ON dbo.material_needed TO role_production_planner;
GRANT SELECT ON dbo.raw_material TO role_production_planner;
GRANT SELECT ON dbo.order_line TO role_production_planner;

-- [Role 3: ฝ่ายคลังสินค้าและการจัดส่ง role_warehouse_staff]
GRANT SELECT, INSERT, UPDATE ON dbo.product TO role_warehouse_staff;
GRANT SELECT, INSERT ON dbo.shipment TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.order_line TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.customer_order TO role_warehouse_staff;
GRANT SELECT, UPDATE ON dbo.raw_material TO role_warehouse_staff;
GRANT SELECT ON dbo.line_schedule TO role_warehouse_staff;

-- [Role 4: ฝ่ายจัดซื้อ role_purchasing_officer]
GRANT SELECT ON dbo.raw_material TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE ON dbo.supplier TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE ON dbo.material_order TO role_purchasing_officer;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.material_order_line TO role_purchasing_officer;
GO

-- ----------------------------------------------------------------------------
-- 4. CREATE LOGINS & USERS (สร้างบัญชีผู้ใช้งานจริงที่ใช้ล็อกอินเข้าสู่ระบบได้)
-- (ใส่ CHECK_POLICY = OFF เพื่อป้องกันนโยบายความซับซ้อนของรหัสผ่านในเครื่อง Windows)
-- ----------------------------------------------------------------------------

-- [User 1: พนักงานฝ่ายขาย]
CREATE LOGIN user_sales WITH PASSWORD = 'SalesUser@2026', CHECK_POLICY = OFF;
CREATE USER user_sales FOR LOGIN user_sales;
ALTER ROLE role_sales_clerk ADD MEMBER user_sales;

-- [User 2: ผู้ควบคุมการผลิต / Supervisor]
CREATE LOGIN user_planner WITH PASSWORD = 'PlannerUser@2026', CHECK_POLICY = OFF;
CREATE USER user_planner FOR LOGIN user_planner;
ALTER ROLE role_production_planner ADD MEMBER user_planner;

-- [User 3: เจ้าหน้าที่คลังสินค้าและการจัดส่ง]
CREATE LOGIN user_warehouse WITH PASSWORD = 'WarehouseUser@2026', CHECK_POLICY = OFF;
CREATE USER user_warehouse FOR LOGIN user_warehouse;
ALTER ROLE role_warehouse_staff ADD MEMBER user_warehouse;

-- [User 4: เจ้าหน้าที่จัดซื้อวัตถุดิบ]
CREATE LOGIN user_purchasing WITH PASSWORD = 'PurchasingUser@2026', CHECK_POLICY = OFF;
CREATE USER user_purchasing FOR LOGIN user_purchasing;
ALTER ROLE role_purchasing_officer ADD MEMBER user_purchasing;

-- ----------------------------------------------------------------------------
-- 5. CREATE APPLICATION ACCOUNTS (บัญชีสำหรับระบบและแอปพลิเคชันเชื่อมต่อ)
-- ----------------------------------------------------------------------------

-- [App 1: Web Portal สำหรับตัวแทนจำหน่าย (ร้านของเล่น)]
CREATE LOGIN app_reseller_login WITH PASSWORD = 'ResellerStrongPwd!2026', CHECK_POLICY = OFF;
CREATE USER app_reseller_portal FOR LOGIN app_reseller_login;
GRANT SELECT ON dbo.customer TO app_reseller_portal;
GRANT INSERT ON dbo.customer_order TO app_reseller_portal;
GRANT INSERT ON dbo.order_line TO app_reseller_portal;
-- ให้ดูแคตาล็อกผ่าน View เท่านั้น (ถ้ามี View สร้างไว้)
IF OBJECT_ID('dbo.v_Reseller_Catalog', 'V') IS NOT NULL
    GRANT SELECT ON dbo.v_Reseller_Catalog TO app_reseller_portal;

-- [App 2: ระบบสแกนเนอร์หน้าสายการผลิต / คลังสินค้า (Shop Floor System)]
CREATE LOGIN app_shopfloor_login WITH PASSWORD = 'ShopFloorStrongPwd!2026', CHECK_POLICY = OFF;
CREATE USER app_shopfloor_system FOR LOGIN app_shopfloor_login;
ALTER ROLE role_warehouse_staff ADD MEMBER app_shopfloor_system;
GO

PRINT '============================================================';
PRINT 'Setup Completed: Logins, Users, Roles & Grants Successfully Created!';
PRINT '============================================================';
