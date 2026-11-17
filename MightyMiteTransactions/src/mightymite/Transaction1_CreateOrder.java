package mightymite;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class Transaction1_CreateOrder {
    public static void createOrder(int orderNumb, int customerNumb, int modelNumb, int quantity) {
        String getPriceSql = "SELECT suggested_retail_price FROM model WHERE model_numb = ?";
        String insertOrderSql = "INSERT INTO customer_order (order_numb, customer_numb, order_date, order_total, order_filled) VALUES (?, ?, GETDATE(), 0.00, 'N')";
        String insertLineSql = "INSERT INTO order_line (order_numb, model_numb, quantity_ordered, unit_price, line_total, all_shipped) VALUES (?, ?, ?, ?, ?, 'N')";
        String updateTotalSql = "UPDATE customer_order SET order_total = ? WHERE order_numb = ?";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            conn.setAutoCommit(false);

            try (PreparedStatement psPrice = conn.prepareStatement(getPriceSql);
                 PreparedStatement psOrder = conn.prepareStatement(insertOrderSql);
                 PreparedStatement psLine = conn.prepareStatement(insertLineSql);
                 PreparedStatement psUpdate = conn.prepareStatement(updateTotalSql)) {

                psPrice.setInt(1, modelNumb);
                ResultSet rs = psPrice.executeQuery();
                if (!rs.next()) {
                    throw new SQLException("Model not found: " + modelNumb);
                }
                double unitPrice = rs.getDouble("suggested_retail_price");
                double lineTotal = unitPrice * quantity;

                psOrder.setInt(1, orderNumb);
                psOrder.setInt(2, customerNumb);
                psOrder.executeUpdate();

                psLine.setInt(1, orderNumb);
                psLine.setInt(2, modelNumb);
                psLine.setInt(3, quantity);
                psLine.setDouble(4, unitPrice);
                psLine.setDouble(5, lineTotal);
                psLine.executeUpdate();

                psUpdate.setDouble(1, lineTotal);
                psUpdate.setInt(2, orderNumb);
                psUpdate.executeUpdate();

                conn.commit();
                System.out.println("TX 1 Success: Created Order #" + orderNumb + " Total = " + lineTotal);
            } catch (SQLException e) {
                conn.rollback();
                System.out.println("TX 1 Rollback: " + e.getMessage());
            }
        } catch (SQLException e) {
            System.out.println("TX 1 Connection Error: " + e.getMessage());
        }
    }
}
