<?php
/**
 * Database Configuration Example
 * Hospital Management System
 * 
 * Copy this file to database.php and update with your credentials.
 * DO NOT commit database.php with real credentials to version control.
 */

// Database credentials - UPDATE THESE VALUES
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');  // Enter your MySQL password
define('DB_NAME', 'hospital_management');

/**
 * Get PDO database connection
 * 
 * @return PDO Database connection object
 * @throws PDOException If connection fails
 */
function getConnection() {
    static $pdo = null;
    
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ];
            
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            die("Database connection failed. Please check your configuration.");
        }
    }
    
    return $pdo;
}

/**
 * Execute a prepared statement and return results
 * 
 * @param string $sql SQL query with placeholders
 * @param array $params Parameters to bind
 * @return PDOStatement Executed statement
 */
function executeQuery($sql, $params = []) {
    $pdo = getConnection();
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt;
}

/**
 * Get last inserted ID
 * 
 * @return string Last insert ID
 */
function getLastInsertId() {
    return getConnection()->lastInsertId();
}
