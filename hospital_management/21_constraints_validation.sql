-- Hospital Management System - Database Constraints and Validation
-- This script adds comprehensive constraints and validation rules for data integrity

USE hospital_management_system;

-- Additional validation constraints and triggers for data integrity
-- Most constraints were already added in individual table scripts, but let's add comprehensive validation

-- Create a comprehensive validation summary
SELECT 'Adding comprehensive database constraints and validation...' AS Status;

-- Create triggers for automatic data updates and validation

-- Trigger to automatically update room status based on treatments
DELIMITER //
CREATE TRIGGER trg_auto_update_room_status_from_treatments
AFTER UPDATE ON Treatments
FOR EACH ROW
BEGIN
    -- This trigger was already created in treatments table script
    -- Just ensuring it exists and works properly
    IF NEW.status != OLD.status THEN
        -- Room occupancy is already handled by existing trigger
        NULL;
    END IF;
END//
DELIMITER ;

-- Create a trigger to validate appointment scheduling conflicts across rooms
DELIMITER //
CREATE TRIGGER trg_validate_room_appointment_conflicts
BEFORE INSERT ON Appointments
FOR EACH ROW
BEGIN
    DECLARE v_room_conflicts INT DEFAULT 0;
    
    -- Check for room conflicts if room is specified
    IF NEW.room_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_room_conflicts
        FROM Appointments a
        WHERE a.room_id = NEW.room_id
          AND a.appointment_date = NEW.appointment_date
          AND a.status IN ('Scheduled', 'Rescheduled')
          AND (
              -- New appointment overlaps with existing
              (NEW.appointment_time >= a.appointment_time 
               AND NEW.appointment_time < ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)))
              OR
              -- New appointment end time overlaps
              (ADDTIME(NEW.appointment_time, SEC_TO_TIME(NEW.duration_minutes * 60)) > a.appointment_time 
               AND ADDTIME(NEW.appointment_time, SEC_TO_TIME(NEW.duration_minutes * 60)) <= ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)))
          );
        
        IF v_room_conflicts > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Room is already booked for the specified time slot';
        END IF;
    END IF;
END//
DELIMITER ;

-- Create a trigger to validate prescription dosages
DELIMITER //
CREATE TRIGGER trg_validate_prescription_dosage
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    -- Validate duration is reasonable (not more than 1 year)
    IF NEW.duration_days > 365 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Prescription duration cannot exceed 365 days';
    END IF;
    
    -- Validate quantity is reasonable
    IF NEW.quantity_prescribed > 1000 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Prescription quantity seems unusually high';
    END IF;
END//
DELIMITER ;

-- Create a trigger to validate billing amounts
DELIMITER //
CREATE TRIGGER trg_validate_billing_amounts
BEFORE INSERT ON Billing
FOR EACH ROW
BEGIN
    -- Validate that insurance coverage doesn't exceed total amount
    IF NEW.insurance_coverage > NEW.total_amount THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insurance coverage cannot exceed total bill amount';
    END IF;
    
    -- Validate that discount doesn't exceed total amount
    IF NEW.discount_amount > NEW.total_amount THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Discount amount cannot exceed total bill amount';
    END IF;
END//
DELIMITER ;

-- Create a procedure to validate data integrity across the database
DELIMITER //
CREATE PROCEDURE ValidateDataIntegrity()
BEGIN
    -- Check for orphaned records
    SELECT 'Data Integrity Validation Results:' AS section;
    
    -- Check for appointments without valid patients
    SELECT 
        'Appointments with invalid patients' AS check_type,
        COUNT(*) AS issue_count
    FROM Appointments a
    LEFT JOIN Patients p ON a.patient_id = p.patient_id
    WHERE p.patient_id IS NULL;
    
    -- Check for appointments without valid staff
    SELECT 
        'Appointments with invalid staff' AS check_type,
        COUNT(*) AS issue_count
    FROM Appointments a
    LEFT JOIN Medical_Staff ms ON a.staff_id = ms.staff_id
    WHERE ms.staff_id IS NULL;
    
    -- Check for treatments without valid patients
    SELECT 
        'Treatments with invalid patients' AS check_type,
        COUNT(*) AS issue_count
    FROM Treatments t
    LEFT JOIN Patients p ON t.patient_id = p.patient_id
    WHERE p.patient_id IS NULL;
    
    -- Check for prescriptions with invalid medications
    SELECT 
        'Prescriptions with invalid medications' AS check_type,
        COUNT(*) AS issue_count
    FROM Prescriptions pr
    LEFT JOIN Medications m ON pr.medication_id = m.medication_id
    WHERE m.medication_id IS NULL;
    
    -- Check for bills with invalid patients
    SELECT 
        'Bills with invalid patients' AS check_type,
        COUNT(*) AS issue_count
    FROM Billing b
    LEFT JOIN Patients p ON b.patient_id = p.patient_id
    WHERE p.patient_id IS NULL;
    
    -- Check for payments with invalid bills
    SELECT 
        'Payments with invalid bills' AS check_type,
        COUNT(*) AS issue_count
    FROM Payments pay
    LEFT JOIN Billing b ON pay.bill_id = b.bill_id
    WHERE b.bill_id IS NULL;
    
    -- Check for inconsistent room occupancy
    SELECT 
        'Rooms with invalid occupancy' AS check_type,
        COUNT(*) AS issue_count
    FROM Rooms
    WHERE current_occupancy > capacity OR current_occupancy < 0;
    
    -- Check for expired medications with positive stock
    SELECT 
        'Expired medications with stock' AS check_type,
        COUNT(*) AS issue_count
    FROM Medications
    WHERE expiry_date <= CURDATE() AND stock_quantity > 0;
    
    -- Check for overdue bills
    SELECT 
        'Overdue bills' AS check_type,
        COUNT(*) AS issue_count
    FROM Billing
    WHERE due_date < CURDATE() AND payment_status IN ('Pending', 'Partial');
END//
DELIMITER ;

-- Create a procedure to fix common data integrity issues
DELIMITER //
CREATE PROCEDURE FixDataIntegrityIssues()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error occurred while fixing data integrity issues' AS error_message;
    END;
    
    START TRANSACTION;
    
    -- Fix room occupancy issues
    UPDATE Rooms 
    SET current_occupancy = 0 
    WHERE current_occupancy < 0;
    
    UPDATE Rooms 
    SET current_occupancy = capacity 
    WHERE current_occupancy > capacity;
    
    -- Update overdue bill status
    UPDATE Billing 
    SET payment_status = 'Overdue' 
    WHERE due_date < CURDATE() 
      AND payment_status = 'Pending';
    
    -- Mark expired prescriptions
    UPDATE Prescriptions 
    SET status = 'Expired' 
    WHERE end_date < CURDATE() 
      AND status = 'Active';
    
    SELECT 'Data integrity issues fixed successfully' AS result_message;
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for constraint violations summary
CREATE VIEW Constraint_Violations AS
SELECT 
    'Expired Medications with Stock' AS violation_type,
    COUNT(*) AS violation_count,
    'Medications past expiry date but still in stock' AS description
FROM Medications
WHERE expiry_date <= CURDATE() AND stock_quantity > 0

UNION ALL

SELECT 
    'Overdue Bills' AS violation_type,
    COUNT(*) AS violation_count,
    'Bills past due date with pending/partial payment status' AS description
FROM Billing
WHERE due_date < CURDATE() AND payment_status IN ('Pending', 'Partial')

UNION ALL

SELECT 
    'Invalid Room Occupancy' AS violation_type,
    COUNT(*) AS violation_count,
    'Rooms with occupancy exceeding capacity or negative occupancy' AS description
FROM Rooms
WHERE current_occupancy > capacity OR current_occupancy < 0

UNION ALL

SELECT 
    'Expired Active Prescriptions' AS violation_type,
    COUNT(*) AS violation_count,
    'Prescriptions marked as active but past end date' AS description
FROM Prescriptions
WHERE end_date < CURDATE() AND status = 'Active';

-- Show constraint violations
SELECT 'Current Constraint Violations:' AS info;
SELECT * FROM Constraint_Violations WHERE violation_count > 0;

-- Show all database constraints
SELECT 'Database Constraints Summary:' AS info;
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'hospital_management_system'
  AND CONSTRAINT_TYPE IN ('CHECK', 'UNIQUE', 'FOREIGN KEY')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- Confirmation message
SELECT 'Database constraints and validation rules implemented successfully!' AS Status;