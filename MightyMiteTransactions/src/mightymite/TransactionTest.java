package mightymite;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class TransactionTest {
    public static void cleanupTestData() {
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps1 = conn.prepareStatement("DELETE FROM order_line WHERE order_numb = ?");
                 PreparedStatement ps2 = conn.prepareStatement("DELETE FROM customer_order WHERE order_numb = ?");
                 PreparedStatement ps3 = conn.prepareStatement("DELETE FROM product WHERE serial_numb = ?");
                 PreparedStatement ps4 = conn.prepareStatement("DELETE FROM line_schedule WHERE line_numb = ? AND production_date = ?")) {

                ps1.setInt(1, 5010);
                ps1.executeUpdate();

                ps2.setInt(1, 5010);
                ps2.executeUpdate();

                ps3.setInt(1, 20099);
                ps3.executeUpdate();

                ps4.setInt(1, 1);
                ps4.setDate(2, Date.valueOf("2026-11-25"));
                ps4.executeUpdate();

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
            }
        } catch (SQLException e) {
            System.out.println("Cleanup Error: " + e.getMessage());
        }
    }

    public static void printCurrentMaterialStock(int materialId) {
        String sql = "SELECT material_id_numb, material_name, quantity_in_stock FROM raw_material WHERE material_id_numb = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, materialId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                System.out.println("Verified Stock -> ID: " + rs.getInt("material_id_numb")
                        + ", Name: " + rs.getString("material_name")
                        + ", Stock: " + rs.getInt("quantity_in_stock"));
            }
        } catch (SQLException e) {
            System.out.println("Verify Error: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        cleanupTestData();

        System.out.println("=== TEST 1: Create Customer Order (TX 1) ===");
        Transaction1_CreateOrder.createOrder(5010, 101, 1, 5);

        System.out.println("=== TEST 2: Receive Finished Product (TX 3) ===");
        Transaction3_ReceiveProduct.receiveProduct(20099, 8);

        System.out.println("=== TEST 3: Receive Raw Material (TX 4) ===");
        Transaction4_ReceiveMaterial.receiveMaterial(1, 100);
        printCurrentMaterialStock(1);

        System.out.println("=== TEST 4: Schedule Manufacturing Line (TX 5) ===");
        Transaction5_LineSchedule.scheduleLine(1, "2026-11-25", 2, 150);

        System.out.println("=== TEST 5: Rollback on Duplicate Order ===");
        Transaction1_CreateOrder.createOrder(5010, 101, 1, 5);

        System.out.println("=== TEST 6: Isolation Level REPEATABLE READ Concurrency Test ===");
        Thread t1 = new Thread(new Runnable() {
            public void run() {
                Transaction4_ReceiveMaterial.receiveMaterial(1, 50);
            }
        });

        Thread t2 = new Thread(new Runnable() {
            public void run() {
                Transaction4_ReceiveMaterial.receiveMaterial(1, 30);
            }
        });

        t1.start();
        t2.start();

        try {
            t1.join();
            t2.join();
        } catch (InterruptedException e) {
            System.out.println("Thread interrupted: " + e.getMessage());
        }

        printCurrentMaterialStock(1);
    }
}
