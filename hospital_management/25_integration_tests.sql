-- Hospital Management System - Integration Tests
-- This script contains comprehensive integration tests for complete hospital workflows

USE hospital_management_system;

-- Create integration test results table
CREATE TEMPORARY TABLE integration_test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(200),
    test_status ENUM('PASS', 'FAIL') DEFAULT 'FAIL',
    test_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Integration Test 1: Complete Patient Admission to Discharge Workflow
DELIMITER //
CREATE PROCEDURE Test_PatientAdmissionToDischarge()
BEGIN
    DECLARE v_patient_id INT DEFAULT 0;
    DECLARE v_staff_id INT DEFAULT 1;
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_record_id INT DEFAULT 0;
    DECLARE v_treatment_id INT DEFAULT 0;
    DECLARE v_prescription_id INT DEFAULT 0;
    DECLARE v_bill_id INT DEFAULT 0;
    DECLARE v_payment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
        GET DIAGNOSTICS CONDITION 1
            v_result_message = MESSAGE_TEXT;
    END;
    
    -- Step 1: Register new patient
    INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email, insurance_provider, insurance_policy_number)
    VALUES ('Test', 'Patient', '1990-01-01', 'Male', '555-TEST', 'test@email.com', 'Test Insurance', 'TEST123');
    SET v_patient_id = LAST_INSERT_ID();
    
    -- Step 2: Schedule appointment
    CALL ScheduleAppointment(
        v_patient_id, v_staff_id, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00:00', 60,
        'Integration test appointment', 1, v_staff_id, v_appointment_id, v_result_message
    );
    
    -- Step 3: Create medical record
    CALL AddMedicalRecord(
        v_patient_id, v_staff_id, 'Consultation', 'Test symptoms', 'Test symptoms description',
        'Test diagnosis', 'Test treatment plan', 
        '{"temperature": 98.6, "blood_pressure_systolic": 120, "blood_pressure_diastolic": 80, "heart_rate": 72}',
        TRUE, DATE_ADD(CURDATE(), INTERVAL 30 DAY), v_record_id, v_result_message
    );
    
    -- Step 4: Schedule treatment
    CALL ScheduleTreatment(
        v_patient_id, v_staff_id, 'Test Treatment', 'TEST001', CURRENT_TIMESTAMP, 30, 200.00,
        1, 'Routine', 'Integration test treatment', v_treatment_id, v_result_message
    );
    
    -- Step 5: Update treatment status to completed
    CALL UpdateTreatmentStatus(
        v_treatment_id, 'Completed', 'Treatment completed successfully', NULL, v_result_message
    );
    
    -- Step 6: Create prescription
    CALL CreatePrescription(
        v_patient_id, v_staff_id, 1, '81mg', 'Once daily', 30, 30, 2,
        'Oral', 'Test indication', 'Test instructions', v_prescription_id, v_result_message
    );
    
    -- Step 7: Dispense medication
    CALL DispenseMedication(
        v_prescription_id, 30, v_staff_id, 'Integration test dispensing', v_result_message
    );
    
    -- Step 8: Generate bill
    CALL GeneratePatientBill(
        v_patient_id, CURDATE(), CURDATE(), 80.0, 0.08, v_staff_id, v_bill_id, v_result_message
    );
    
    -- Step 9: Process payment
    CALL ProcessPayment(
        v_bill_id, 50.00, 'Credit Card', 'TEST_PAYMENT_001', NULL, '1234', 'AUTH123',
        'TestProcessor', 'PROC123', 'Integration test payment', v_staff_id, v_payment_id, v_result_message
    );
    
    -- Verify workflow completion
    IF v_patient_id > 0 AND v_appointment_id > 0 AND v_record_id > 0 AND 
       v_treatment_id > 0 AND v_prescription_id > 0 AND v_bill_id > 0 AND 
       v_payment_id > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = 'Complete patient workflow executed successfully';
    ELSE
        SET v_result_message = CONCAT('Workflow failed. Errors: ', v_error_count, '. Last message: ', v_result_message);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Complete Patient Admission to Discharge Workflow', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Integration Test 2: Appointment Scheduling to Billing Process
DELIMITER //
CREATE PROCEDURE Test_AppointmentToBilling()
BEGIN
    DECLARE v_patient_id INT DEFAULT 1;
    DECLARE v_staff_id INT DEFAULT 2;
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_bill_id INT DEFAULT 0;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Step 1: Schedule appointment
    CALL ScheduleAppointment(
        v_patient_id, v_staff_id, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '14:00:00', 45,
        'Billing integration test', 2, v_staff_id, v_appointment_id, v_result_message
    );
    
    -- Step 2: Create bill
    CALL CreateBill(
        v_patient_id, 150.00, 120.00, 0.00, 0.08, 30, 'CLAIM123',
        'Integration test billing', v_staff_id, v_bill_id, v_result_message
    );
    
    -- Step 3: Add consultation service to bill
    CALL AddBillItem(
        v_bill_id, 'Consultation', 'CONS001', 'Cardiology Consultation', 1, 150.00,
        CURDATE(), v_staff_id, 2, NULL, NULL, 'Integration test consultation',
        v_item_id, v_result_message
    );
    
    -- Verify billing process
    IF v_appointment_id > 0 AND v_bill_id > 0 AND v_item_id > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = 'Appointment to billing process completed successfully';
    ELSE
        SET v_result_message = CONCAT('Billing process failed. Errors: ', v_error_count);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Appointment Scheduling to Billing Process', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Integration Test 3: Medication Prescription to Inventory Update Flow
DELIMITER //
CREATE PROCEDURE Test_PrescriptionToInventoryUpdate()
BEGIN
    DECLARE v_patient_id INT DEFAULT 2;
    DECLARE v_staff_id INT DEFAULT 1;
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
    
    -- Step 1: Add test medication to inventory
    CALL AddMedicationToInventory(
        'Test Integration Med', 'Test Generic', 'Test Brand', 'Test Mfg', 'Tablet',
        '100mg', 1.50, 100, 10, '2025-12-31', 'TESTBATCH', 'TestSupplier',
        'TESTNDC', FALSE, NULL, v_medication_id, v_result_message
    );
    
    -- Get initial stock
    SELECT stock_quantity INTO v_stock_before
    FROM Medications WHERE medication_id = v_medication_id;
    
    -- Step 2: Create prescription
    CALL CreatePrescription(
        v_patient_id, v_staff_id, v_medication_id, '100mg', 'Twice daily', 14, 28, 1,
        'Oral', 'Integration test', 'Test prescription instructions', 
        v_prescription_id, v_result_message
    );
    
    -- Step 3: Dispense medication
    CALL DispenseMedication(
        v_prescription_id, 28, v_staff_id, 'Integration test dispensing', v_result_message
    );
    
    -- Get stock after dispensing
    SELECT stock_quantity INTO v_stock_after
    FROM Medications WHERE medication_id = v_medication_id;
    
    -- Verify inventory update
    IF v_medication_id > 0 AND v_prescription_id > 0 AND 
       v_stock_after = v_stock_before - 28 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = CONCAT('Prescription to inventory update completed. Stock: ', v_stock_before, ' -> ', v_stock_after);
    ELSE
        SET v_result_message = CONCAT('Inventory update failed. Errors: ', v_error_count, '. Stock: ', v_stock_before, ' -> ', v_stock_after);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Medication Prescription to Inventory Update Flow', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Integration Test 4: Room Assignment and Billing Integration
DELIMITER //
CREATE PROCEDURE Test_RoomAssignmentBilling()
BEGIN
    DECLARE v_patient_id INT DEFAULT 3;
    DECLARE v_room_id INT DEFAULT 1;
    DECLARE v_bill_id INT DEFAULT 0;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE v_occupancy_before INT DEFAULT 0;
    DECLARE v_occupancy_after INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Get initial room occupancy
    SELECT current_occupancy INTO v_occupancy_before
    FROM Rooms WHERE room_id = v_room_id;
    
    -- Step 1: Create bill
    CALL CreateBill(
        v_patient_id, 0.00, 0.00, 0.00, 0.08, 30, NULL,
        'Room assignment integration test', 1, v_bill_id, v_result_message
    );
    
    -- Step 2: Add room charges to bill (3-day stay)
    CALL AddRoomChargesToBill(
        v_bill_id, v_room_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 DAY), v_result_message
    );
    
    -- Verify room billing
    SELECT COUNT(*) INTO v_item_id
    FROM Bill_Items 
    WHERE bill_id = v_bill_id AND service_type = 'Room';
    
    IF v_bill_id > 0 AND v_item_id > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = 'Room assignment and billing integration completed successfully';
    ELSE
        SET v_result_message = CONCAT('Room billing integration failed. Errors: ', v_error_count);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Room Assignment and Billing Integration', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Integration Test 5: Insurance Processing Workflow
DELIMITER //
CREATE PROCEDURE Test_InsuranceProcessingWorkflow()
BEGIN
    DECLARE v_patient_id INT DEFAULT 4;
    DECLARE v_bill_id INT DEFAULT 0;
    DECLARE v_payment_id INT DEFAULT 0;
    DECLARE v_bills_processed INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Step 1: Create bill with insurance coverage
    CALL CreateBill(
        v_patient_id, 500.00, 0.00, 0.00, 0.08, 30, 'INS_CLAIM_TEST',
        'Insurance processing test', 1, v_bill_id, v_result_message
    );
    
    -- Step 2: Apply insurance coverage
    CALL ApplyInsuranceCoverage(
        v_bill_id, 80.0, 50.00, 20.00, 1000.00, v_result_message
    );
    
    -- Step 3: Process bulk insurance payment
    CALL ProcessBulkInsurancePayment(
        'UnitedHealth', 1000.00, 'BULK_INS_001', 1, v_bills_processed, v_result_message
    );
    
    -- Verify insurance processing
    IF v_bill_id > 0 AND v_bills_processed > 0 AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = CONCAT('Insurance processing completed. Bills processed: ', v_bills_processed);
    ELSE
        SET v_result_message = CONCAT('Insurance processing failed. Errors: ', v_error_count);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Insurance Processing Workflow', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Integration Test 6: Inventory Management and Alerts
DELIMITER //
CREATE PROCEDURE Test_InventoryManagementAlerts()
BEGIN
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_alert_count_before INT DEFAULT 0;
    DECLARE v_alert_count_after INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
    END;
    
    -- Count existing alerts
    SELECT COUNT(*) INTO v_alert_count_before FROM Medication_Alerts;
    
    -- Step 1: Add medication with low stock
    CALL AddMedicationToInventory(
        'Low Stock Test Med', 'Test Generic', 'Test Brand', 'Test Mfg', 'Tablet',
        '50mg', 0.75, 5, 50, '2025-01-15', 'LOWSTOCK', 'TestSupplier',
        'LOWNDC', FALSE, NULL, v_medication_id, v_result_message
    );
    
    -- Step 2: Generate alerts
    CALL GenerateLowStockAlerts();
    CALL GenerateExpiryAlerts(45);
    
    -- Step 3: Run inventory maintenance
    CALL PerformInventoryMaintenance();
    
    -- Count alerts after
    SELECT COUNT(*) INTO v_alert_count_after FROM Medication_Alerts;
    
    -- Verify alert generation
    IF v_medication_id > 0 AND v_alert_count_after > v_alert_count_before AND v_error_count = 0 THEN
        SET v_test_passed = TRUE;
        SET v_result_message = CONCAT('Inventory alerts generated. Before: ', v_alert_count_before, ', After: ', v_alert_count_after);
    ELSE
        SET v_result_message = CONCAT('Inventory alert generation failed. Errors: ', v_error_count);
    END IF;
    
    INSERT INTO integration_test_results (test_name, test_status, test_message) VALUES
    ('Inventory Management and Alerts', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     v_result_message);
END//
DELIMITER ;

-- Execute all integration tests
CALL Test_PatientAdmissionToDischarge();
CALL Test_AppointmentToBilling();
CALL Test_PrescriptionToInventoryUpdate();
CALL Test_RoomAssignmentBilling();
CALL Test_InsuranceProcessingWorkflow();
CALL Test_InventoryManagementAlerts();

-- Display integration test results
SELECT 'INTEGRATION TEST RESULTS' AS section;
SELECT 
    test_name,
    test_status,
    test_message,
    execution_time
FROM integration_test_results
ORDER BY test_id;

-- Summary of integration test results
SELECT 'INTEGRATION TEST SUMMARY' AS section;
SELECT 
    test_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM integration_test_results), 2) as percentage
FROM integration_test_results
GROUP BY test_status;

-- Test data integrity after integration tests
CALL ValidateDataIntegrity();

-- Clean up integration test procedures
DROP PROCEDURE Test_PatientAdmissionToDischarge;
DROP PROCEDURE Test_AppointmentToBilling;
DROP PROCEDURE Test_PrescriptionToInventoryUpdate;
DROP PROCEDURE Test_RoomAssignmentBilling;
DROP PROCEDURE Test_InsuranceProcessingWorkflow;
DROP PROCEDURE Test_InventoryManagementAlerts;

-- Confirmation message
SELECT 'Integration tests for complete workflows completed!' AS Status;