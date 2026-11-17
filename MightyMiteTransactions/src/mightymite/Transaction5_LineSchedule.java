package mightymite;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class Transaction5_LineSchedule {
    public static void scheduleLine(int lineNumb, String productionDate, int modelNumb, int qtyToProduce) {
        String checkLineSql = "SELECT line_status FROM manufacturing_line WHERE line_numb = ?";
        String insertScheduleSql = "INSERT INTO line_schedule (line_numb, production_date, model_numb, quantity_to_produce) VALUES (?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            conn.setAutoCommit(false);

            try (PreparedStatement psCheck = conn.prepareStatement(checkLineSql);
                 PreparedStatement psInsert = conn.prepareStatement(insertScheduleSql)) {

                psCheck.setInt(1, lineNumb);
                ResultSet rs = psCheck.executeQuery();
                if (!rs.next()) {
                    throw new SQLException("Line not found: " + lineNumb);
                }
                String status = rs.getString("line_status");
                if (!"Active".equalsIgnoreCase(status.trim())) {
                    throw new SQLException("Line " + lineNumb + " is not Active");
                }

                psInsert.setInt(1, lineNumb);
                psInsert.setDate(2, Date.valueOf(productionDate));
                psInsert.setInt(3, modelNumb);
                psInsert.setInt(4, qtyToProduce);
                psInsert.executeUpdate();

                conn.commit();
                System.out.println("TX 5 Success: Scheduled Line " + lineNumb + " on " + productionDate + " for Model " + modelNumb);
            } catch (SQLException e) {
                conn.rollback();
                System.out.println("TX 5 Rollback: " + e.getMessage());
            }
        } catch (SQLException e) {
            System.out.println("TX 5 Connection Error: " + e.getMessage());
        }
    }
}
