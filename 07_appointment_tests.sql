-- Hospital Management System - Appointment Scheduling Unit Tests
-- This script contains comprehensive tests for appointment scheduling functionality

USE hospital_management_system;

-- Create a test results table to track test outcomes
CREATE TEMPORARY TABLE test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(200),
    test_status ENUM('PASS', 'FAIL') DEFAULT 'FAIL',
    test_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data for appointments testing
INSERT INTO Departments (department_name, location, description) VALUES
('Cardiology', 'Building A, Floor 2', 'Heart and cardiovascular care'),
('Emergency', 'Building A, Floor 1', 'Emergency medical services'),
('Pediatrics', 'Building B, Floor 3', 'Children healthcare');

INSERT INTO Medical_Staff (first_name, last_name, role, specialization, department_id, email, hire_date, license_number) VALUES
('Dr. John', 'Smith', 'Doctor', 'Cardiologist', 1, 'john.smith@hospital.com', '2020-01-15', 'LIC001'),
('Dr. Sarah', 'Johnson', 'Doctor', 'Emergency Medicine', 2, 'sarah.johnson@hospital.com', '2019-03-20', 'LIC002'),
('Nurse Mary', 'Wilson', 'Nurse', 'Pediatric Nursing', 3, 'mary.wilson@hospital.com', '2021-06-10', 'LIC003');

INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email) VALUES
('Alice', 'Brown', '1985-05-15', 'Female', '555-0101', 'alice.brown@email.com'),
('Bob', 'Davis', '1990-08-22', 'Male', '555-0102', 'bob.davis@email.com'),
('Carol', 'Miller', '1978-12-03', 'Female', '555-0103', 'carol.miller@email.com');

INSERT INTO Rooms (room_number, room_type, department_id, capacity, daily_rate) VALUES
('101', 'General', 1, 2, 150.00),
('201', 'Private', 2, 1, 300.00),
('301', 'ICU', 2, 1, 500.00);

-- Test 1: Valid appointment creation
DELIMITER //
CREATE PROCEDURE Test_ValidAppointmentCreation()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Schedule a valid appointment
    CALL ScheduleAppointment(
        1, 1, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00:00', 30, 
        'Regular checkup', 1, 1, v_appointment_id, v_result_message
    );
    
    -- Check if appointment was created successfully
    IF v_appointment_id > 0 AND v_result_message = 'Appointment scheduled successfully' THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Valid Appointment Creation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Appointment ID: ', v_appointment_id, ', Message: ', v_result_message));
END//
DELIMITER ;

-- Test 2: Double-booking prevention
DELIMITER //
CREATE PROCEDURE Test_DoubleBookingPrevention()
BEGIN
    DECLARE v_appointment_id1 INT DEFAULT 0;
    DECLARE v_appointment_id2 INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Schedule first appointment
    CALL ScheduleAppointment(
        1, 1, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '14:00:00', 60, 
        'First appointment', NULL, 1, v_appointment_id1, v_result_message1
    );
    
    -- Try to schedule overlapping appointment (should fail)
    CALL ScheduleAppointment(
        2, 1, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '14:30:00', 30, 
        'Overlapping appointment', NULL, 1, v_appointment_id2, v_result_message2
    );
    
    -- Test passes if first succeeds and second fails
    IF v_appointment_id1 > 0 AND v_appointment_id2 = -1 THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Double-booking Prevention', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('First: ', v_result_message1, ', Second: ', v_result_message2));
END//
DELIMITER ;

-- Test 3: Past date validation
DELIMITER //
CREATE PROCEDURE Test_PastDateValidation()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Try to schedule appointment in the past (should fail)
    CALL ScheduleAppointment(
        1, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '10:00:00', 30, 
        'Past appointment', NULL, 1, v_appointment_id, v_result_message
    );
    
    -- Test passes if appointment creation fails
    IF v_appointment_id = -1 AND v_result_message LIKE '%past%' THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Past Date Validation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Message: ', v_result_message));
END//
DELIMITER ;

-- Test 4: Working hours validation
DELIMITER //
CREATE PROCEDURE Test_WorkingHoursValidation()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Try to schedule appointment outside working hours (should fail)
    CALL ScheduleAppointment(
        1, 1, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '23:00:00', 30, 
        'Late appointment', NULL, 1, v_appointment_id, v_result_message
    );
    
    -- Test passes if appointment creation fails
    IF v_appointment_id = -1 AND v_result_message LIKE '%6:00 AM and 10:00 PM%' THEN
        SET v_test_passed = TRUE;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Working Hours Validation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Message: ', v_result_message));
END//
DELIMITER ;

-- Test 5: Appointment rescheduling
DELIMITER //
CREATE PROCEDURE Test_AppointmentRescheduling()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_new_date DATE;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    SET v_new_date = DATE_ADD(CURDATE(), INTERVAL 3 DAY);
    
    -- Create an appointment first
    CALL ScheduleAppointment(
        2, 2, v_new_date, '09:00:00', 30, 
        'Initial appointment', NULL, 2, v_appointment_id, v_result_message1
    );
    
    -- Reschedule the appointment
    IF v_appointment_id > 0 THEN
        CALL RescheduleAppointment(
            v_appointment_id, v_new_date, '11:00:00', 45, 2, v_result_message2
        );
        
        IF v_result_message2 = 'Appointment rescheduled successfully' THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Appointment Rescheduling', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Create: ', v_result_message1, ', Reschedule: ', v_result_message2));
END//
DELIMITER ;

-- Test 6: Appointment cancellation
DELIMITER //
CREATE PROCEDURE Test_AppointmentCancellation()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message1 VARCHAR(500) DEFAULT '';
    DECLARE v_result_message2 VARCHAR(500) DEFAULT '';
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    
    -- Create an appointment first
    CALL ScheduleAppointment(
        3, 3, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '15:00:00', 30, 
        'Appointment to cancel', NULL, 3, v_appointment_id, v_result_message1
    );
    
    -- Cancel the appointment
    IF v_appointment_id > 0 THEN
        CALL CancelAppointment(
            v_appointment_id, 'Patient requested cancellation', v_result_message2
        );
        
        IF v_result_message2 = 'Appointment cancelled successfully' THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Appointment Cancellation', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Create: ', v_result_message1, ', Cancel: ', v_result_message2));
END//
DELIMITER ;

-- Test 7: Staff availability check
DELIMITER //
CREATE PROCEDURE Test_StaffAvailabilityCheck()
BEGIN
    DECLARE v_appointment_id INT DEFAULT 0;
    DECLARE v_result_message VARCHAR(500) DEFAULT '';
    DECLARE v_availability_count INT DEFAULT 0;
    DECLARE v_test_passed BOOLEAN DEFAULT FALSE;
    DECLARE v_test_date DATE;
    
    SET v_test_date = DATE_ADD(CURDATE(), INTERVAL 5 DAY);
    
    -- Create an appointment
    CALL ScheduleAppointment(
        1, 1, v_test_date, '16:00:00', 60, 
        'Availability test', NULL, 1, v_appointment_id, v_result_message
    );
    
    -- Check staff availability during that time
    IF v_appointment_id > 0 THEN
        -- Count appointments in the time range
        SELECT COUNT(*) INTO v_availability_count
        FROM (
            SELECT * FROM (
                CALL CheckStaffAvailability(1, v_test_date, '15:30:00', '17:00:00')
            ) AS temp_result
        ) AS availability_result;
        
        -- Test passes if we find the scheduled appointment
        IF v_availability_count > 0 THEN
            SET v_test_passed = TRUE;
        END IF;
    END IF;
    
    INSERT INTO test_results (test_name, test_status, test_message) VALUES
    ('Staff Availability Check', 
     IF(v_test_passed, 'PASS', 'FAIL'),
     CONCAT('Appointments found: ', v_availability_count));
END//
DELIMITER ;

-- Execute all tests
CALL Test_ValidAppointmentCreation();
CALL Test_DoubleBookingPrevention();
CALL Test_PastDateValidation();
CALL Test_WorkingHoursValidation();
CALL Test_AppointmentRescheduling();
CALL Test_AppointmentCancellation();
CALL Test_StaffAvailabilityCheck();

-- Display test results
SELECT 
    test_name,
    test_status,
    test_message,
    execution_time
FROM test_results
ORDER BY test_id;

-- Summary of test results
SELECT 
    test_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM test_results), 2) as percentage
FROM test_results
GROUP BY test_status;

-- Clean up test procedures
DROP PROCEDURE Test_ValidAppointmentCreation;
DROP PROCEDURE Test_DoubleBookingPrevention;
DROP PROCEDURE Test_PastDateValidation;
DROP PROCEDURE Test_WorkingHoursValidation;
DROP PROCEDURE Test_AppointmentRescheduling;
DROP PROCEDURE Test_AppointmentCancellation;
DROP PROCEDURE Test_StaffAvailabilityCheck;

-- Confirmation message
SELECT 'Appointment scheduling unit tests completed!' AS Status;