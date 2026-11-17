package mightymite;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Transaction3_ReceiveProduct {
    public static void receiveProduct(int serialNumb, int modelNumb) {
        String insertProductSql = "INSERT INTO product (serial_numb, model_numb, date_manufactured, status_code, date_shipped, order_numb) VALUES (?, ?, GETDATE(), 1, NULL, NULL)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            conn.setAutoCommit(false);

            try (PreparedStatement ps = conn.prepareStatement(insertProductSql)) {
                ps.setInt(1, serialNumb);
                ps.setInt(2, modelNumb);
                ps.executeUpdate();

                conn.commit();
                System.out.println("TX 3 Success: Added Product Serial #" + serialNumb + " (Model " + modelNumb + ")");
            } catch (SQLException e) {
                conn.rollback();
                System.out.println("TX 3 Rollback: " + e.getMessage());
            }
        } catch (SQLException e) {
            System.out.println("TX 3 Connection Error: " + e.getMessage());
        }
    }
}
