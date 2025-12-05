-- Hospital Management System - Appointment Validation Procedures
-- This script creates stored procedures for appointment scheduling, validation, and management

USE hospital_management_system;

-- Procedure to schedule a new appointment with validation
DELIMITER //
CREATE PROCEDURE ScheduleAppointment(
    IN p_patient_id INT,
    IN p_staff_id INT,
    IN p_appointment_date DATE,
    IN p_appointment_time TIME,
    IN p_duration_minutes INT,
    IN p_purpose VARCHAR(200),
    IN p_room_id INT,
    IN p_created_by INT,
    OUT p_appointment_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_staff_status VARCHAR(20);
    DECLARE v_patient_status VARCHAR(20);
    DECLARE v_room_available BOOLEAN DEFAULT TRUE;
    DECLARE v_staff_available BOOLEAN DEFAULT TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_appointment_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate patient exists and is active
    SELECT status INTO v_patient_status 
    FROM Patients 
    WHERE patient_id = p_patient_id;
    
    IF v_patient_status IS NULL THEN
        SET p_result_message = 'Patient not found';
        SET p_appointment_id = -1;
        ROLLBACK;
    ELSEIF v_patient_status != 'Active' THEN
        SET p_result_message = 'Patient is not active';
        SET p_appointment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate staff exists and is active
    SELECT status INTO v_staff_status 
    FROM Medical_Staff 
    WHERE staff_id = p_staff_id;
    
    IF v_staff_status IS NULL THEN
        SET p_result_message = 'Staff member not found';
        SET p_appointment_id = -1;
        ROLLBACK;
    ELSEIF v_staff_status != 'Active' THEN
        SET p_result_message = 'Staff member is not active';
        SET p_appointment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate appointment date is not in the past
    IF p_appointment_date < CURDATE() THEN
        SET p_result_message = 'Cannot schedule appointment in the past';
        SET p_appointment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate working hours (6 AM to 10 PM)
    IF p_appointment_time < '06:00:00' OR p_appointment_time > '22:00:00' THEN
        SET p_result_message = 'Appointment time must be between 6:00 AM and 10:00 PM';
        SET p_appointment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Check room availability if room is specified
    IF p_room_id IS NOT NULL THEN
        SELECT (current_occupancy < capacity) INTO v_room_available
        FROM Rooms 
        WHERE room_id = p_room_id AND status IN ('Available', 'Occupied');
        
        IF v_room_available IS NULL OR v_room_available = FALSE THEN
            SET p_result_message = 'Room is not available';
            SET p_appointment_id = -1;
            ROLLBACK;
        END IF;
    END IF;
    
    -- Insert the appointment (triggers will handle conflict validation)
    INSERT INTO Appointments (
        patient_id, staff_id, appointment_date, appointment_time, 
        duration_minutes, purpose, room_id, created_by
    ) VALUES (
        p_patient_id, p_staff_id, p_appointment_date, p_appointment_time,
        p_duration_minutes, p_purpose, p_room_id, p_created_by
    );
    
    SET p_appointment_id = LAST_INSERT_ID();
    SET p_result_message = 'Appointment scheduled successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to check staff availability for a given date and time range
DELIMITER //
CREATE PROCEDURE CheckStaffAvailability(
    IN p_staff_id INT,
    IN p_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME
)
BEGIN
    SELECT 
        a.appointment_id,
        a.appointment_time,
        ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) AS end_time,
        a.purpose,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        a.status
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    WHERE a.staff_id = p_staff_id
      AND a.appointment_date = p_date
      AND a.status IN ('Scheduled', 'Rescheduled')
      AND (
          (a.appointment_time >= p_start_time AND a.appointment_time < p_end_time)
          OR
          (ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) > p_start_time 
           AND ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) <= p_end_time)
          OR
          (a.appointment_time <= p_start_time 
           AND ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) >= p_end_time)
      )
    ORDER BY a.appointment_time;
END//
DELIMITER ;

-- Procedure to reschedule an appointment
DELIMITER //
CREATE PROCEDURE RescheduleAppointment(
    IN p_appointment_id INT,
    IN p_new_date DATE,
    IN p_new_time TIME,
    IN p_new_duration INT,
    IN p_updated_by INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_old_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Check if appointment exists and can be rescheduled
    SELECT status INTO v_old_status 
    FROM Appointments 
    WHERE appointment_id = p_appointment_id;
    
    IF v_old_status IS NULL THEN
        SET p_result_message = 'Appointment not found';
        ROLLBACK;
    ELSEIF v_old_status IN ('Completed', 'Cancelled') THEN
        SET p_result_message = 'Cannot reschedule completed or cancelled appointment';
        ROLLBACK;
    END IF;
    
    -- Update the appointment
    UPDATE Appointments 
    SET appointment_date = p_new_date,
        appointment_time = p_new_time,
        duration_minutes = COALESCE(p_new_duration, duration_minutes),
        status = 'Rescheduled',
        updated_date = CURRENT_TIMESTAMP
    WHERE appointment_id = p_appointment_id;
    
    SET p_result_message = 'Appointment rescheduled successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to cancel an appointment
DELIMITER //
CREATE PROCEDURE CancelAppointment(
    IN p_appointment_id INT,
    IN p_cancellation_reason TEXT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Check if appointment exists and can be cancelled
    SELECT status INTO v_current_status 
    FROM Appointments 
    WHERE appointment_id = p_appointment_id;
    
    IF v_current_status IS NULL THEN
        SET p_result_message = 'Appointment not found';
        ROLLBACK;
    ELSEIF v_current_status IN ('Completed', 'Cancelled') THEN
        SET p_result_message = 'Appointment is already completed or cancelled';
        ROLLBACK;
    END IF;
    
    -- Update appointment status to cancelled
    UPDATE Appointments 
    SET status = 'Cancelled',
        notes = CONCAT(COALESCE(notes, ''), '\nCancellation Reason: ', p_cancellation_reason),
        updated_date = CURRENT_TIMESTAMP
    WHERE appointment_id = p_appointment_id;
    
    SET p_result_message = 'Appointment cancelled successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to get daily schedule for a staff member
DELIMITER //
CREATE PROCEDURE GetDailySchedule(
    IN p_staff_id INT,
    IN p_date DATE
)
BEGIN
    SELECT 
        a.appointment_id,
        a.appointment_time,
        ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) AS end_time,
        a.duration_minutes,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.phone AS patient_phone,
        a.purpose,
        a.status,
        r.room_number,
        a.notes
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    LEFT JOIN Rooms r ON a.room_id = r.room_id
    WHERE a.staff_id = p_staff_id
      AND a.appointment_date = p_date
      AND a.status IN ('Scheduled', 'Rescheduled', 'Completed')
    ORDER BY a.appointment_time;
END//
DELIMITER ;

-- Show created procedures
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system';

-- Confirmation message
SELECT 'Appointment validation procedures created successfully!' AS Status;