-- Hospital Management System - Inventory Management Procedures
-- This script creates procedures for automatic stock updates, alerts, and dispensing tracking

USE hospital_management_system;

-- Procedure to generate low stock alerts
DELIMITER //
CREATE PROCEDURE GenerateLowStockAlerts()
BEGIN
    -- Insert alerts for medications below minimum stock level
    INSERT INTO Medication_Alerts (medication_id, alert_type, alert_message)
    SELECT 
        m.medication_id,
        CASE 
            WHEN m.stock_quantity = 0 THEN 'OUT_OF_STOCK'
            ELSE 'LOW_STOCK'
        END,
        CASE 
            WHEN m.stock_quantity = 0 THEN 
                CONCAT('URGENT: ', m.medication_name, ' is out of stock!')
            ELSE 
                CONCAT('WARNING: ', m.medication_name, ' stock is low. Current: ', m.stock_quantity, ', Minimum: ', m.minimum_stock_level)
        END
    FROM Medications m
    LEFT JOIN Medication_Alerts ma ON m.medication_id = ma.medication_id 
        AND ma.alert_type IN ('LOW_STOCK', 'OUT_OF_STOCK') 
        AND ma.acknowledged = FALSE
    WHERE m.stock_quantity <= m.minimum_stock_level
      AND ma.medication_id IS NULL; -- Only create alert if one doesn't already exist
    
    -- Return count of new alerts created
    SELECT ROW_COUNT() AS new_alerts_created;
END//
DELIMITER ;

-- Procedure to generate expiry alerts
DELIMITER //
CREATE PROCEDURE GenerateExpiryAlerts(
    IN p_days_ahead INT
)
BEGIN
    DECLARE v_alert_date DATE;
    SET v_alert_date = DATE_ADD(CURDATE(), INTERVAL COALESCE(p_days_ahead, 30) DAY);
    
    -- Insert alerts for medications expiring soon
    INSERT INTO Medication_Alerts (medication_id, alert_type, alert_message)
    SELECT 
        m.medication_id,
        CASE 
            WHEN m.expiry_date <= CURDATE() THEN 'EXPIRED'
            ELSE 'NEAR_EXPIRY'
        END,
        CASE 
            WHEN m.expiry_date <= CURDATE() THEN 
                CONCAT('EXPIRED: ', m.medication_name, ' (Batch: ', m.batch_number, ') expired on ', m.expiry_date)
            ELSE 
                CONCAT('EXPIRING SOON: ', m.medication_name, ' (Batch: ', m.batch_number, ') expires on ', m.expiry_date, ' (', DATEDIFF(m.expiry_date, CURDATE()), ' days)')
        END
    FROM Medications m
    LEFT JOIN Medication_Alerts ma ON m.medication_id = ma.medication_id 
        AND ma.alert_type IN ('EXPIRED', 'NEAR_EXPIRY') 
        AND ma.acknowledged = FALSE
    WHERE m.expiry_date <= v_alert_date
      AND m.stock_quantity > 0
      AND ma.medication_id IS NULL; -- Only create alert if one doesn't already exist
    
    -- Return count of new alerts created
    SELECT ROW_COUNT() AS new_expiry_alerts_created;
END//
DELIMITER ;

-- Procedure to acknowledge alerts
DELIMITER //
CREATE PROCEDURE AcknowledgeAlert(
    IN p_alert_id INT,
    IN p_acknowledged_by INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_alert_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Check if alert exists and is not already acknowledged
    SELECT COUNT(*) INTO v_alert_exists
    FROM Medication_Alerts
    WHERE alert_id = p_alert_id AND acknowledged = FALSE;
    
    IF v_alert_exists = 0 THEN
        SET p_result_message = 'Alert not found or already acknowledged';
        ROLLBACK;
    END IF;
    
    -- Acknowledge the alert
    UPDATE Medication_Alerts
    SET acknowledged = TRUE,
        acknowledged_by = p_acknowledged_by,
        acknowledged_date = CURRENT_TIMESTAMP
    WHERE alert_id = p_alert_id;
    
    SET p_result_message = 'Alert acknowledged successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to get inventory summary report
DELIMITER //
CREATE PROCEDURE GetInventorySummaryReport()
BEGIN
    -- Overall inventory statistics
    SELECT 
        'Inventory Summary' AS report_section,
        COUNT(*) AS total_medications,
        SUM(stock_quantity) AS total_stock_units,
        SUM(stock_quantity * unit_price) AS total_inventory_value,
        COUNT(CASE WHEN stock_quantity <= minimum_stock_level THEN 1 END) AS low_stock_items,
        COUNT(CASE WHEN stock_quantity = 0 THEN 1 END) AS out_of_stock_items,
        COUNT(CASE WHEN expiry_date <= CURDATE() AND stock_quantity > 0 THEN 1 END) AS expired_items,
        COUNT(CASE WHEN expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 1 END) AS expiring_soon_items
    FROM Medications;
    
    -- Top 10 most valuable medications by inventory value
    SELECT 
        'Top Valuable Medications' AS report_section,
        medication_name,
        generic_name,
        stock_quantity,
        unit_price,
        (stock_quantity * unit_price) AS inventory_value,
        supplier
    FROM Medications
    WHERE stock_quantity > 0
    ORDER BY inventory_value DESC
    LIMIT 10;
    
    -- Medications requiring immediate attention
    SELECT 
        'Immediate Attention Required' AS report_section,
        medication_name,
        CASE 
            WHEN stock_quantity = 0 THEN 'OUT OF STOCK'
            WHEN stock_quantity <= minimum_stock_level THEN 'LOW STOCK'
            WHEN expiry_date <= CURDATE() THEN 'EXPIRED'
            WHEN expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'EXPIRING SOON'
        END AS issue_type,
        stock_quantity,
        minimum_stock_level,
        expiry_date,
        supplier,
        supplier_contact
    FROM Medications
    WHERE stock_quantity = 0 
       OR stock_quantity <= minimum_stock_level 
       OR expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    ORDER BY 
        CASE 
            WHEN stock_quantity = 0 THEN 1
            WHEN expiry_date <= CURDATE() THEN 2
            WHEN stock_quantity <= minimum_stock_level THEN 3
            ELSE 4
        END,
        expiry_date ASC;
END//
DELIMITER ;

-- Procedure to calculate reorder quantities and costs
DELIMITER //
CREATE PROCEDURE CalculateReorderRequirements()
BEGIN
    SELECT 
        m.medication_id,
        m.medication_name,
        m.generic_name,
        m.dosage_form,
        m.strength,
        m.stock_quantity AS current_stock,
        m.minimum_stock_level,
        m.maximum_stock_level,
        GREATEST(m.minimum_stock_level - m.stock_quantity, 0) AS minimum_reorder_qty,
        GREATEST(m.maximum_stock_level - m.stock_quantity, 0) AS optimal_reorder_qty,
        m.unit_price,
        GREATEST(m.minimum_stock_level - m.stock_quantity, 0) * m.unit_price AS minimum_reorder_cost,
        GREATEST(m.maximum_stock_level - m.stock_quantity, 0) * m.unit_price AS optimal_reorder_cost,
        m.supplier,
        m.supplier_contact,
        -- Calculate average monthly usage based on stock log
        COALESCE(usage_stats.avg_monthly_usage, 0) AS avg_monthly_usage,
        -- Calculate days of stock remaining
        CASE 
            WHEN COALESCE(usage_stats.avg_daily_usage, 0) > 0 THEN 
                FLOOR(m.stock_quantity / usage_stats.avg_daily_usage)
            ELSE NULL
        END AS days_stock_remaining
    FROM Medications m
    LEFT JOIN (
        SELECT 
            medication_id,
            AVG(ABS(quantity_change)) AS avg_monthly_usage,
            AVG(ABS(quantity_change)) / 30 AS avg_daily_usage
        FROM Medication_Stock_Log
        WHERE quantity_change < 0  -- Only dispensing records
          AND change_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        GROUP BY medication_id
    ) usage_stats ON m.medication_id = usage_stats.medication_id
    WHERE m.stock_quantity <= m.minimum_stock_level
    ORDER BY 
        CASE WHEN m.stock_quantity = 0 THEN 1 ELSE 2 END,
        minimum_reorder_cost DESC;
END//
DELIMITER ;

-- Procedure to track medication dispensing patterns
DELIMITER //
CREATE PROCEDURE GetMedicationUsageAnalysis(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_medication_id INT
)
BEGIN
    SELECT 
        m.medication_name,
        m.generic_name,
        m.dosage_form,
        m.strength,
        COUNT(p.prescription_id) AS total_prescriptions,
        SUM(p.quantity_dispensed) AS total_quantity_dispensed,
        AVG(p.quantity_dispensed) AS avg_quantity_per_prescription,
        COUNT(DISTINCT p.patient_id) AS unique_patients,
        COUNT(DISTINCT p.staff_id) AS prescribing_physicians,
        -- Most common dosage
        (SELECT dosage FROM Prescriptions 
         WHERE medication_id = m.medication_id 
           AND prescription_date BETWEEN p_start_date AND p_end_date
         GROUP BY dosage 
         ORDER BY COUNT(*) DESC 
         LIMIT 1) AS most_common_dosage,
        -- Most common frequency
        (SELECT frequency FROM Prescriptions 
         WHERE medication_id = m.medication_id 
           AND prescription_date BETWEEN p_start_date AND p_end_date
         GROUP BY frequency 
         ORDER BY COUNT(*) DESC 
         LIMIT 1) AS most_common_frequency,
        -- Stock impact
        m.stock_quantity AS current_stock,
        SUM(p.quantity_dispensed) AS total_dispensed_period,
        (m.stock_quantity + SUM(p.quantity_dispensed)) AS stock_before_period
    FROM Medications m
    LEFT JOIN Prescriptions p ON m.medication_id = p.medication_id
        AND p.prescription_date BETWEEN p_start_date AND p_end_date
        AND p.status IN ('Completed', 'Partially_Filled')
    WHERE (p_medication_id IS NULL OR m.medication_id = p_medication_id)
    GROUP BY m.medication_id, m.medication_name, m.generic_name, m.dosage_form, m.strength, m.stock_quantity
    HAVING total_prescriptions > 0
    ORDER BY total_quantity_dispensed DESC;
END//
DELIMITER ;

-- Procedure to perform automatic inventory maintenance
DELIMITER //
CREATE PROCEDURE PerformInventoryMaintenance()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_alerts_created INT DEFAULT 0;
    DECLARE v_expiry_alerts INT DEFAULT 0;
    
    -- Generate low stock alerts
    CALL GenerateLowStockAlerts();
    SELECT FOUND_ROWS() INTO v_alerts_created;
    
    -- Generate expiry alerts (30 days ahead)
    CALL GenerateExpiryAlerts(30);
    SELECT FOUND_ROWS() INTO v_expiry_alerts;
    
    -- Update prescription statuses for expired prescriptions
    UPDATE Prescriptions 
    SET status = 'Expired'
    WHERE status = 'Active' 
      AND end_date < CURDATE();
    
    -- Return maintenance summary
    SELECT 
        'Inventory Maintenance Complete' AS status,
        v_alerts_created AS low_stock_alerts_created,
        v_expiry_alerts AS expiry_alerts_created,
        ROW_COUNT() AS prescriptions_expired;
END//
DELIMITER ;

-- Create a view for comprehensive medication alerts dashboard
CREATE VIEW Medication_Alerts_Dashboard AS
SELECT 
    ma.alert_id,
    ma.alert_type,
    ma.alert_message,
    ma.alert_date,
    ma.acknowledged,
    ma.acknowledged_date,
    CONCAT(ack_staff.first_name, ' ', ack_staff.last_name) AS acknowledged_by_name,
    m.medication_name,
    m.generic_name,
    m.stock_quantity,
    m.minimum_stock_level,
    m.expiry_date,
    m.supplier,
    m.supplier_contact,
    CASE 
        WHEN ma.alert_type = 'OUT_OF_STOCK' THEN 1
        WHEN ma.alert_type = 'EXPIRED' THEN 2
        WHEN ma.alert_type = 'LOW_STOCK' THEN 3
        WHEN ma.alert_type = 'NEAR_EXPIRY' THEN 4
        ELSE 5
    END AS priority_order
FROM Medication_Alerts ma
JOIN Medications m ON ma.medication_id = m.medication_id
LEFT JOIN Medical_Staff ack_staff ON ma.acknowledged_by = ack_staff.staff_id
ORDER BY ma.acknowledged ASC, priority_order ASC, ma.alert_date DESC;

-- Show created procedures and views
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system' 
AND Name IN ('GenerateLowStockAlerts', 'GenerateExpiryAlerts', 'AcknowledgeAlert', 
             'GetInventorySummaryReport', 'CalculateReorderRequirements', 
             'GetMedicationUsageAnalysis', 'PerformInventoryMaintenance');

SHOW CREATE VIEW Medication_Alerts_Dashboard;

-- Confirmation message
SELECT 'Inventory management procedures created successfully!' AS Status;