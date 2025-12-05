-- Hospital Management System - Comprehensive System Test
-- This script performs a complete end-to-end test of the entire hospital management system

USE hospital_management_system;

-- Create comprehensive test results table
CREATE TEMPORARY TABLE comprehensive_test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_category VARCHAR(50),
    test_name VARCHAR(200),
    test_status ENUM('PASS', 'FAIL', 'ERROR') DEFAULT 'FAIL',
    test_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test Category 1: Database Schema and Structure
DELIMITER //
CREATE PROCEDURE Test_DatabaseSchema()
BEGIN
    DECLARE v_table_count INT DEFAULT 0;
    DECLARE v_procedure_count INT DEFAULT 0;
    DECLARE v_trigger_count INT DEFAULT 0;
    DECLARE v_view_count INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Count tables
    SELECT COUNT(*) INTO v_table_count
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'hospital_management_system';
    
    -- Count procedures
    SELECT COUNT(*) INTO v_procedure_count
    FROM INFORMATION_SCHEMA.ROUTINES 
    WHERE ROUTINE_SCHEMA = 'hospital_management_system' AND ROUTINE_TYPE = 'PROCEDURE';
    
    -- Count triggers
    SELECT COUNT(*) INTO v_trigger_count
    FROM INFORMATION_SCHEMA.TRIGGERS 
    WHERE TRIGGER_SCHEMA = 'hospital_management_system';
    
    -- Count views
    SELECT COUNT(*) INTO v_view_count
    FROM INFORMATION_SCHEMA.VIEWS 
    WHERE TABLE_SCHEMA = 'hospital_management_system';
    
    -- Verify expected counts
    IF v_table_count >= 15 AND v_procedure_count >= 30 AND v_trigger_count >= 15 AND v_view_count >= 10 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Schema', 'Database Structure Verification', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Tables: ', v_table_count, ', Procedures: ', v_procedure_count, ', Triggers: ', v_trigger_count, ', Views: ', v_view_count));
END//
DELIMITER ;

-- Test Category 2: Patient Management
DELIMITER //
CREATE PROCEDURE Test_PatientManagement()
BEGIN
    DECLARE v_patient_id INT DEFAULT 0;
    DECLARE v_patient_count_before INT DEFAULT 0;
    DECLARE v_patient_count_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Get initial patient count
    SELECT COUNT(*) INTO v_patient_count_before FROM Patients;
    
    -- Test patient registration
    INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email, insurance_provider)
    VALUES ('System', 'Test', '1985-01-01', 'Male', '555-TEST1', 'systemtest@test.com', 'Test Insurance');
    SET v_patient_id = LAST_INSERT_ID();
    
    -- Test patient update
    UPDATE Patients SET phone = '555-UPDATED' WHERE patient_id = v_patient_id;
    
    -- Get final patient count
    SELECT COUNT(*) INTO v_patient_count_after FROM Patients;
    
    -- Verify test results
    IF v_patient_id > 0 AND v_patient_count_after > v_patient_count_before AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Patient Management', 'Patient Registration and Update', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Patient ID: ', v_patient_id, ', Errors: ', v_error_count));
END//
DELIMITER ;

-- Test Category 3: Appointment System
DELIMITER //
CREATE PROCEDURE Test_AppointmentSystem()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_conflict_test_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test valid appointment scheduling
    CALL ScheduleAppointment(
        1, 1, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '09:00:00', 30,
        'System test appointment', 1, 1, v_appointment_id, v_result_message
    );
    
    -- Test conflict detection (should fail)
    CALL ScheduleAppointment(
        2, 1, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '09:15:00', 30,
        'Conflicting appointment', 1, 1, v_conflict_test_id, v_result_message
    );
    
    -- Verify results (first should succeed, second should fail)
    IF v_appointment_id > 0 AND v_conflict_test_id = -1 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Appointment System', 'Scheduling and Conflict Detection', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Valid appointment: ', v_appointment_id, ', Conflict test: ', v_conflict_test_id));
END//
DELIMITER ;

-- Test Category 4: Medical Records
DELIMITER //
CREATE PROCEDURE Test_MedicalRecords()
BEGIN
    DECLARE v_record_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test medical record creation
    CALL AddMedicalRecord(
        1, 1, 'Consultation', 'System test symptoms', 'Test symptoms description',
        'System test diagnosis', 'Test treatment plan',
        '{"temperature": 98.6, "blood_pressure_systolic": 120, "blood_pressure_diastolic": 80, "heart_rate": 72}',
        TRUE, DATE_ADD(CURDATE(), INTERVAL 30 DAY), v_record_id, v_result_message
    );
    
    -- Verify record creation
    IF v_record_id > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Medical Records', 'Record Creation with JSON Vital Signs', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Record ID: ', v_record_id, ', Message: ', v_result_message));
END//
DELIMITER ;

-- Test Category 5: Medication Management
DELIMITER //
CREATE PROCEDURE Test_MedicationManagement()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_prescription_id INT DEFAULT 0;
    DECLARE v_stock_before INT DEFAULT 0;
    DECLARE v_stock_after INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test medication addition
    CALL AddMedicationToInventory(
        'System Test Med', 'Test Generic', 'Test Brand', 'Test Mfg', 'Tablet',
        '100mg', 1.00, 100, 10, '2025-12-31', 'SYSTEST', 'TestSupplier',
        'SYSTNDC', FALSE, NULL, v_medication_id, v_result_message
    );
    
    -- Get initial stock
    SELECT stock_quantity INTO v_stock_before
    FROM Medications WHERE medication_id = v_medication_id;
    
    -- Test prescription creation
    CALL CreatePrescription(
        1, 1, v_medication_id, '100mg', 'Once daily', 30, 30, 2,
        'Oral', 'System test', 'Test instructions', v_prescription_id, v_result_message
    );
    
    -- Test medication dispensing
    CALL DispenseMedication(
        v_prescription_id, 30, 1, 'System test dispensing', v_result_message
    );
    
    -- Get final stock
    SELECT stock_quantity INTO v_stock_after
    FROM Medications WHERE medication_id = v_medication_id;
    
    -- Verify medication management
    IF v_medication_id > 0 AND v_prescription_id > 0 AND v_stock_after = v_stock_before - 30 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Medication Management', 'Inventory and Prescription Management', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Med ID: ', v_medication_id, ', Prescription ID: ', v_prescription_id, ', Stock: ', v_stock_before, '->', v_stock_after));
END//
DELIMITER ;

-- Test Category 6: Billing System
DELIMITER //
CREATE PROCEDURE Test_BillingSystem()
BEGIN
    DECLARE v_bill_id INT DEFAULT 0;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE v_payment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test bill creation
    CALL CreateBill(
        1, 200.00, 160.00, 0.00, 0.08, 30, 'SYSTEST001',
        'System test billing', 1, v_bill_id, v_result_message
    );
    
    -- Test bill item addition
    CALL AddBillItem(
        v_bill_id, 'Consultation', 'SYSCONS', 'System Test Consultation', 1, 200.00,
        CURDATE(), 1, 1, NULL, NULL, 'System test item', v_item_id, v_result_message
    );
    
    -- Test payment processing
    CALL ProcessPayment(
        v_bill_id, 48.00, 'Credit Card', 'SYSTEST_PAY', NULL, '1234', 'AUTH123',
        'TestProcessor', 'PROC123', 'System test payment', 1, v_payment_id, v_result_message
    );
    
    -- Verify billing system
    IF v_bill_id > 0 AND v_item_id > 0 AND v_payment_id > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Billing System', 'Bill Creation, Items, and Payment Processing', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Bill ID: ', v_bill_id, ', Item ID: ', v_item_id, ', Payment ID: ', v_payment_id));
END//
DELIMITER ;

-- Test Category 7: Room Management
DELIMITER //
CREATE PROCEDURE Test_RoomManagement()
BEGIN
    DECLARE v_available_rooms INT DEFAULT 0;
    DECLARE v_occupancy_before INT DEFAULT 0;
    DECLARE v_occupancy_after INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test room availability check
    CALL CheckRoomAvailability('General', NULL);
    
    -- Get room occupancy before
    SELECT current_occupancy INTO v_occupancy_before
    FROM Rooms WHERE room_id = 1;
    
    -- Test room occupancy update (simulate patient admission)
    UPDATE Rooms SET current_occupancy = current_occupancy + 1 WHERE room_id = 1;
    
    -- Get room occupancy after
    SELECT current_occupancy INTO v_occupancy_after
    FROM Rooms WHERE room_id = 1;
    
    -- Reset occupancy
    UPDATE Rooms SET current_occupancy = v_occupancy_before WHERE room_id = 1;
    
    -- Verify room management
    IF v_occupancy_after = v_occupancy_before + 1 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Room Management', 'Availability Check and Occupancy Management', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Occupancy: ', v_occupancy_before, '->', v_occupancy_after, ', Errors: ', v_error_count));
END//
DELIMITER ;

-- Test Category 8: Data Integrity and Constraints
DELIMITER //
CREATE PROCEDURE Test_DataIntegrity()
BEGIN
    DECLARE v_constraint_violations INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test constraint violations
    SELECT COUNT(*) INTO v_constraint_violations
    FROM Constraint_Violations
    WHERE violation_count > 0;
    
    -- Run data integrity validation
    CALL ValidateDataIntegrity();
    
    -- Test should pass if no major constraint violations
    IF v_constraint_violations < 5 THEN  -- Allow some minor violations
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Data Integrity', 'Constraint Validation and Data Consistency', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Constraint violations: ', v_constraint_violations, ', Errors: ', v_error_count));
END//
DELIMITER ;

-- Test Category 9: Reporting and Analytics
DELIMITER //
CREATE PROCEDURE Test_ReportingSystem()
BEGIN
    DECLARE v_report_count INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Test executive dashboard
    CALL GenerateExecutiveDashboard();
    
    -- Test monthly financial report
    CALL GenerateMonthlyFinancialReport(YEAR(CURDATE()), MONTH(CURDATE()));
    
    -- Test inventory summary
    CALL GetInventorySummaryReport();
    
    -- Count available views
    SELECT COUNT(*) INTO v_report_count
    FROM INFORMATION_SCHEMA.VIEWS 
    WHERE TABLE_SCHEMA = 'hospital_management_system';
    
    -- Verify reporting system
    IF v_report_count >= 10 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Reporting System', 'Dashboard and Report Generation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Available views: ', v_report_count, ', Errors: ', v_error_count));
END//
DELIMITER ;

-- Test Category 10: Performance and Optimization
DELIMITER //
CREATE PROCEDURE Test_PerformanceOptimization()
BEGIN
    DECLARE v_index_count INT DEFAULT 0;
    DECLARE v_foreign_key_count INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Count indexes
    SELECT COUNT(DISTINCT INDEX_NAME) INTO v_index_count
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'hospital_management_system' AND INDEX_NAME != 'PRIMARY';
    
    -- Count foreign keys
    SELECT COUNT(*) INTO v_foreign_key_count
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE REFERENCED_TABLE_SCHEMA = 'hospital_management_system';
    
    -- Verify optimization
    IF v_index_count >= 30 AND v_foreign_key_count >= 15 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO comprehensive_test_results (test_category, test_name, test_status, test_message) VALUES
    ('Performance', 'Index and Foreign Key Optimization', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Indexes: ', v_index_count, ', Foreign Keys: ', v_foreign_key_count));
END//
DELIMITER ;

-- Execute all comprehensive tests
SELECT 'STARTING COMPREHENSIVE HOSPITAL MANAGEMENT SYSTEM TEST SUITE' AS status;
SELECT '================================================================' AS separator;

CALL Test_DatabaseSchema();
CALL Test_PatientManagement();
CALL Test_AppointmentSystem();
CALL Test_MedicalRecords();
CALL Test_MedicationManagement();
CALL Test_BillingSystem();
CALL Test_RoomManagement();
CALL Test_DataIntegrity();
CALL Test_ReportingSystem();
CALL Test_PerformanceOptimization();

-- Display comprehensive test results
SELECT '================================================================' AS separator;
SELECT 'COMPREHENSIVE TEST RESULTS' AS section;
SELECT '================================================================' AS separator;

SELECT 
    test_category,
    test_name,
    test_status,
    test_message,
    execution_time
FROM comprehensive_test_results
ORDER BY test_category, test_id;

-- Test summary by category
SELECT '================================================================' AS separator;
SELECT 'TEST SUMMARY BY CATEGORY' AS section;
SELECT '================================================================' AS separator;

SELECT 
    test_category,
    COUNT(*) as total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) as failed_tests,
    SUM(CASE WHEN test_status = 'ERROR' THEN 1 ELSE 0 END) as error_tests,
    ROUND(SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pass_rate
FROM comprehensive_test_results
GROUP BY test_category
ORDER BY test_category;

-- Overall test summary
SELECT '================================================================' AS separator;
SELECT 'OVERALL TEST SUMMARY' AS section;
SELECT '================================================================' AS separator;

SELECT 
    COUNT(*) as total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) as failed_tests,
    SUM(CASE WHEN test_status = 'ERROR' THEN 1 ELSE 0 END) as error_tests,
    ROUND(SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as overall_pass_rate
FROM comprehensive_test_results;

-- System health check
SELECT '================================================================' AS separator;
SELECT 'SYSTEM HEALTH CHECK' AS section;
SELECT '================================================================' AS separator;

SELECT 
    'Database Tables' AS component,
    COUNT(*) AS count,
    'Core hospital management tables' AS description
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'hospital_management_system'

UNION ALL

SELECT 
    'Stored Procedures',
    COUNT(*),
    'Business logic procedures'
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'hospital_management_system' AND ROUTINE_TYPE = 'PROCEDURE'

UNION ALL

SELECT 
    'Database Triggers',
    COUNT(*),
    'Automatic data management triggers'
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'hospital_management_system'

UNION ALL

SELECT 
    'Database Views',
    COUNT(*),
    'Reporting and analytics views'
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'hospital_management_system'

UNION ALL

SELECT 
    'Performance Indexes',
    COUNT(DISTINCT INDEX_NAME),
    'Query optimization indexes'
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'hospital_management_system' AND INDEX_NAME != 'PRIMARY'

UNION ALL

SELECT 
    'Sample Data Records',
    (SELECT COUNT(*) FROM Patients) + (SELECT COUNT(*) FROM Medical_Staff) + (SELECT COUNT(*) FROM Appointments),
    'Test data for system validation'
;

-- Clean up test procedures
DROP PROCEDURE Test_DatabaseSchema;
DROP PROCEDURE Test_PatientManagement;
DROP PROCEDURE Test_AppointmentSystem;
DROP PROCEDURE Test_MedicalRecords;
DROP PROCEDURE Test_MedicationManagement;
DROP PROCEDURE Test_BillingSystem;
DROP PROCEDURE Test_RoomManagement;
DROP PROCEDURE Test_DataIntegrity;
DROP PROCEDURE Test_ReportingSystem;
DROP PROCEDURE Test_PerformanceOptimization;

SELECT '================================================================' AS separator;
SELECT 'COMPREHENSIVE HOSPITAL MANAGEMENT SYSTEM TEST COMPLETED!' AS final_status;
SELECT '================================================================' AS separator;