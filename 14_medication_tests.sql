-- Hospital Management System - Medication Management Unit Tests
-- This script contains comprehensive tests for medication inventory and prescription functionality

USE hospital_management_system;

-- Create a test results table to track test outcomes
CREATE TEMPORARY TABLE medication_test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(200),
    test_status ENUM('PASS', 'FAIL') DEFAULT 'FAIL',
    test_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test 1: Add medication to inventory
DELIMITER //
CREATE PROCEDURE Test_AddMedicationToInventory()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Add a new medication
    CALL AddMedicationToInventory(
        'Aspirin 100mg', 'Acetylsalicylic Acid', 'Bayer Aspirin', 'Bayer', 'Tablet',
        '100mg', 0.50, 1000, 50, '2025-12-31', 'BATCH001', 'PharmaCorp',
        'NDC12345', FALSE, NULL, v_medication_id, v_result_message
    );
    
    -- Check if medication was added successfully
    IF v_medication_id > 0 AND v_result_message = 'Medication added to inventory successfully' THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Add Medication to Inventory', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Medication ID: ', v_medication_id, ', Message: ', v_result_message));
END//
DELIMITER ;

-- Test 2: Update medication stock
DELIMITER //
CREATE PROCEDURE Test_UpdateMedicationStock()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_stock_before INT DEFAULT 0;
    DECLARE v_stock_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Add a medication first
    CALL AddMedicationToInventory(
        'Ibuprofen 200mg', 'Ibuprofen', 'Advil', 'Pfizer', 'Tablet',
        '200mg', 0.75, 500, 25, '2025-06-30', 'BATCH002', 'MediSupply',
        'NDC67890', FALSE, NULL, v_medication_id, v_result_message1
    );
    
    IF v_medication_id > 0 THEN
        -- Get initial stock
        SELECT stock_quantity INTO v_stock_before
        FROM Medications WHERE medication_id = v_medication_id;
        
        -- Update stock (add 100 units)
        CALL UpdateMedicationStock(v_medication_id, 100, 'Test restock', v_result_message2);
        
        -- Get updated stock
        SELECT stock_quantity INTO v_stock_after
        FROM Medications WHERE medication_id = v_medication_id;
        
        -- Test passes if stock increased by 100
        IF v_stock_after = v_stock_before + 100 AND v_result_message2 LIKE '%Stock updated successfully%' THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Update Medication Stock', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Before: ', v_stock_before, ', After: ', v_stock_after, ', Message: ', v_result_message2));
END//
DELIMITER ;

-- Test 3: Low stock alert generation
DELIMITER //
CREATE PROCEDURE Test_LowStockAlertGeneration()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_alert_count_before INT DEFAULT 0;
    DECLARE v_alert_count_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Count existing alerts
    SELECT COUNT(*) INTO v_alert_count_before FROM Medication_Alerts;
    
    -- Add a medication with low stock
    CALL AddMedicationToInventory(
        'Paracetamol 500mg', 'Acetaminophen', 'Tylenol', 'J&J', 'Tablet',
        '500mg', 0.25, 5, 50, '2025-03-15', 'BATCH003', 'HealthSupply',
        'NDC11111', FALSE, NULL, v_medication_id, v_result_message
    );
    
    IF v_medication_id > 0 THEN
        -- Generate low stock alerts
        CALL GenerateLowStockAlerts();
        
        -- Count alerts after generation
        SELECT COUNT(*) INTO v_alert_count_after FROM Medication_Alerts;
        
        -- Test passes if new alert was created
        IF v_alert_count_after > v_alert_count_before THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Low Stock Alert Generation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Alerts before: ', v_alert_count_before, ', After: ', v_alert_count_after));
END//
DELIMITER ;

-- Test 4: Create prescription
DELIMITER //
CREATE PROCEDURE Test_CreatePrescription()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_prescription_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Add a medication first
    CALL AddMedicationToInventory(
        'Amoxicillin 250mg', 'Amoxicillin', 'Amoxil', 'GSK', 'Capsule',
        '250mg', 2.50, 200, 20, '2025-08-20', 'BATCH004', 'AntibioticCorp',
        'NDC22222', TRUE, NULL, v_medication_id, v_result_message1
    );
    
    IF v_medication_id > 0 THEN
        -- Create a prescription
        CALL CreatePrescription(
            1, 1, v_medication_id, '250mg', 'Three times daily', 7, 21, 1,
            'Oral', 'Bacterial infection', 'Take with food', 
            v_prescription_id, v_result_message2
        );
        
        -- Test passes if prescription was created
        IF v_prescription_id > 0 AND v_result_message2 = 'Prescription created successfully' THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Create Prescription', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Prescription ID: ', v_prescription_id, ', Message: ', v_result_message2));
END//
DELIMITER ;

-- Test 5: Dispense medication
DELIMITER //
CREATE PROCEDURE Test_DispenseMedication()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_prescription_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message3 VARCHAR(500) DEFAULT '';
    DECLARE v_stock_before INT DEFAULT 0;
    DECLARE v_stock_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Add a medication first
    CALL AddMedicationToInventory(
        'Metformin 500mg', 'Metformin HCl', 'Glucophage', 'BristolMS', 'Tablet',
        '500mg', 1.25, 100, 10, '2025-11-30', 'BATCH005', 'DiabetesMeds',
        'NDC33333', TRUE, NULL, v_medication_id, v_result_message1
    );
    
    IF v_medication_id > 0 THEN
        -- Get initial stock
        SELECT stock_quantity INTO v_stock_before
        FROM Medications WHERE medication_id = v_medication_id;
        
        -- Create a prescription
        CALL CreatePrescription(
            2, 2, v_medication_id, '500mg', 'Twice daily', 30, 60, 2,
            'Oral', 'Type 2 Diabetes', 'Take with meals', 
            v_prescription_id, v_result_message2
        );
        
        IF v_prescription_id > 0 THEN
            -- Dispense medication
            CALL DispenseMedication(
                v_prescription_id, 30, 3, 'First month supply dispensed', v_result_message3
            );
            
            -- Get stock after dispensing
            SELECT stock_quantity INTO v_stock_after
            FROM Medications WHERE medication_id = v_medication_id;
            
            -- Test passes if stock decreased and dispensing was successful
            IF v_stock_after = v_stock_before - 30 AND v_result_message3 LIKE '%dispensed successfully%' THEN
                SET v_test_passed = TRUE;
            END IF;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Dispense Medication', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Stock before: ', v_stock_before, ', After: ', v_stock_after, ', Message: ', v_result_message3));
END//
DELIMITER ;

-- Test 6: Insufficient stock prevention
DELIMITER //
CREATE PROCEDURE Test_InsufficientStockPrevention()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_prescription_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message3 VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Add a medication with low stock
    CALL AddMedicationToInventory(
        'Lisinopril 10mg', 'Lisinopril', 'Prinivil', 'Merck', 'Tablet',
        '10mg', 0.80, 10, 5, '2025-09-15', 'BATCH006', 'CardioMeds',
        'NDC44444', TRUE, NULL, v_medication_id, v_result_message1
    );
    
    IF v_medication_id > 0 THEN
        -- Try to create prescription for more than available stock
        CALL CreatePrescription(
            3, 1, v_medication_id, '10mg', 'Once daily', 30, 50, 0,
            'Oral', 'Hypertension', 'Take in morning', 
            v_prescription_id, v_result_message2
        );
        
        -- Test passes if prescription creation failed due to insufficient stock
        IF v_prescription_id = -1 AND v_result_message2 LIKE '%Insufficient medication stock%' THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Insufficient Stock Prevention', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Prescription ID: ', v_prescription_id, ', Message: ', v_result_message2));
END//
DELIMITER ;

-- Test 7: Expiry alert generation
DELIMITER //
CREATE PROCEDURE Test_ExpiryAlertGeneration()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_alert_count_before INT DEFAULT 0;
    DECLARE v_alert_count_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Count existing expiry alerts
    SELECT COUNT(*) INTO v_alert_count_before 
    FROM Medication_Alerts 
    WHERE alert_type IN ('EXPIRED', 'NEAR_EXPIRY');
    
    -- Add a medication that expires soon
    CALL AddMedicationToInventory(
        'Expired Test Med', 'Test Generic', 'Test Brand', 'TestCorp', 'Tablet',
        '100mg', 1.00, 50, 10, DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'BATCH007', 'TestSupplier',
        'NDC55555', FALSE, NULL, v_medication_id, v_result_message
    );
    
    IF v_medication_id > 0 THEN
        -- Generate expiry alerts (30 days ahead)
        CALL GenerateExpiryAlerts(30);
        
        -- Count alerts after generation
        SELECT COUNT(*) INTO v_alert_count_after 
        FROM Medication_Alerts 
        WHERE alert_type IN ('EXPIRED', 'NEAR_EXPIRY');
        
        -- Test passes if new expiry alert was created
        IF v_alert_count_after > v_alert_count_before THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Expiry Alert Generation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Expiry alerts before: ', v_alert_count_before, ', After: ', v_alert_count_after));
END//
DELIMITER ;

-- Test 8: Inventory summary report
DELIMITER //
CREATE PROCEDURE Test_InventorySummaryReport()
BEGIN
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_total_medications INT DEFAULT 0;
    
    -- Call inventory summary report
    CALL GetInventorySummaryReport();
    
    -- Check if we have medications in inventory
    SELECT COUNT(*) INTO v_total_medications FROM Medications;
    
    -- Test passes if we have medications (from previous tests)
    IF v_total_medications > 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO medication_test_results (test_name, test_status, test_message) VALUES
    ('Inventory Summary Report', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Total medications in inventory: ', v_total_medications));
END//
DELIMITER ;

-- Execute all medication tests
CALL Test_AddMedicationToInventory();
CALL Test_UpdateMedicationStock();
CALL Test_LowStockAlertGeneration();
CALL Test_CreatePrescription();
CALL Test_DispenseMedication();
CALL Test_InsufficientStockPrevention();
CALL Test_ExpiryAlertGeneration();
CALL Test_InventorySummaryReport();

-- Display test results
SELECT 
    test_name,
    test_status,
    test_message,
    execution_time
FROM medication_test_results
ORDER BY test_id;

-- Summary of test results
SELECT 
    test_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM medication_test_results), 2) as percentage
FROM medication_test_results
GROUP BY test_status;

-- Show sample data created during tests
SELECT 'Sample Medications Created:' AS info;
SELECT medication_name, stock_quantity, minimum_stock_level, expiry_date, supplier 
FROM Medications 
ORDER BY medication_id DESC 
LIMIT 5;

SELECT 'Sample Alerts Generated:' AS info;
SELECT alert_type, alert_message, alert_date 
FROM Medication_Alerts 
ORDER BY alert_date DESC 
LIMIT 5;

-- Clean up test procedures
DROP PROCEDURE Test_AddMedicationToInventory;
DROP PROCEDURE Test_UpdateMedicationStock;
DROP PROCEDURE Test_LowStockAlertGeneration;
DROP PROCEDURE Test_CreatePrescription;
DROP PROCEDURE Test_DispenseMedication;
DROP PROCEDURE Test_InsufficientStockPrevention;
DROP PROCEDURE Test_ExpiryAlertGeneration;
DROP PROCEDURE Test_InventorySummaryReport;

-- Confirmation message
SELECT 'Medication management unit tests completed!' AS Status;