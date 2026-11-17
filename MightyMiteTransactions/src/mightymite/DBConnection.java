package mightymite;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    public static Connection getConnection() throws SQLException {
        String url = "jdbc:sqlserver://localhost:1433;databaseName=MightyMiteDB;encrypt=true;trustServerCertificate=true;";
        String user = "sa";
        String password = "P@ssw0rd_2024!";
        return DriverManager.getConnection(url, user, password);
    }
}
