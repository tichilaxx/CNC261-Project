package mightymite;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class Transaction4_ReceiveMaterial {
    public static void receiveMaterial(int materialId, int addedQty) {
        String selectStockSql = "SELECT material_name, quantity_in_stock FROM raw_material WHERE material_id_numb = ?";
        String updateStockSql = "UPDATE raw_material SET quantity_in_stock = quantity_in_stock + ? WHERE material_id_numb = ?";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setTransactionIsolation(Connection.TRANSACTION_REPEATABLE_READ);
            conn.setAutoCommit(false);

            try (PreparedStatement psSelect = conn.prepareStatement(selectStockSql);
                 PreparedStatement psUpdate = conn.prepareStatement(updateStockSql)) {

                psSelect.setInt(1, materialId);
                ResultSet rs = psSelect.executeQuery();
                if (!rs.next()) {
                    throw new SQLException("Material not found: " + materialId);
                }
                String name = rs.getString("material_name");
                int oldStock = rs.getInt("quantity_in_stock");

                psUpdate.setInt(1, addedQty);
                psUpdate.setInt(2, materialId);
                psUpdate.executeUpdate();

                conn.commit();
                System.out.println("TX 4 Success: " + name + " stock updated from " + oldStock + " to " + (oldStock + addedQty));
            } catch (SQLException e) {
                conn.rollback();
                System.out.println("TX 4 Rollback: " + e.getMessage());
            }
        } catch (SQLException e) {
            System.out.println("TX 4 Connection Error: " + e.getMessage());
        }
    }
}
