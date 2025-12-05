-- Hospital Management System - Appointments Table
-- This script creates the Appointments table with scheduling logic and conflict prevention

USE hospital_management_system;

-- Create Appointments table with comprehensive scheduling features
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    staff_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INT DEFAULT 30,
    purpose VARCHAR(200),
    status ENUM('Scheduled', 'Completed', 'Cancelled', 'No Show', 'Rescheduled') DEFAULT 'Scheduled',
    notes TEXT,
    room_id INT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    
    -- Foreign key constraints
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Medical_Staff(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Unique constraint to prevent double-booking of staff
    UNIQUE KEY unique_staff_datetime (staff_id, appointment_date, appointment_time),
    
    -- Constraints for data validation
    CONSTRAINT chk_appointment_date CHECK (appointment_date >= CURDATE()),
    CONSTRAINT chk_appointment_duration CHECK (duration_minutes > 0 AND duration_minutes <= 480),
    CONSTRAINT chk_appointment_time CHECK (appointment_time BETWEEN '06:00:00' AND '22:00:00')
);

-- Create indexes for performance
CREATE INDEX idx_appointment_date ON Appointments(appointment_date);
CREATE INDEX idx_appointment_patient ON Appointments(patient_id, appointment_date);
CREATE INDEX idx_appointment_staff ON Appointments(staff_id, appointment_date);
CREATE INDEX idx_appointment_status ON Appointments(status);
CREATE INDEX idx_appointment_datetime ON Appointments(appointment_date, appointment_time);

-- Create a trigger to prevent overlapping appointments for the same staff member
DELIMITER //
CREATE TRIGGER trg_prevent_appointment_overlap
BEFORE INSERT ON Appointments
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT DEFAULT 0;
    DECLARE end_time TIME;
    
    -- Calculate end time of new appointment
    SET end_time = ADDTIME(NEW.appointment_time, SEC_TO_TIME(NEW.duration_minutes * 60));
    
    -- Check for overlapping appointments
    SELECT COUNT(*) INTO overlap_count
    FROM Appointments
    WHERE staff_id = NEW.staff_id
      AND appointment_date = NEW.appointment_date
      AND status IN ('Scheduled', 'Rescheduled')
      AND (
          -- New appointment starts during existing appointment
          (NEW.appointment_time >= appointment_time 
           AND NEW.appointment_time < ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
          OR
          -- New appointment ends during existing appointment
          (end_time > appointment_time 
           AND end_time <= ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
          OR
          -- New appointment completely encompasses existing appointment
          (NEW.appointment_time <= appointment_time 
           AND end_time >= ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
      );
    
    IF overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Appointment time conflicts with existing appointment for this staff member';
    END IF;
END//
DELIMITER ;

-- Create similar trigger for updates
DELIMITER //
CREATE TRIGGER trg_prevent_appointment_overlap_update
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT DEFAULT 0;
    DECLARE end_time TIME;
    
    -- Only check if scheduling details are being changed
    IF NEW.staff_id != OLD.staff_id OR NEW.appointment_date != OLD.appointment_date 
       OR NEW.appointment_time != OLD.appointment_time OR NEW.duration_minutes != OLD.duration_minutes THEN
        
        -- Calculate end time of updated appointment
        SET end_time = ADDTIME(NEW.appointment_time, SEC_TO_TIME(NEW.duration_minutes * 60));
        
        -- Check for overlapping appointments (excluding current appointment)
        SELECT COUNT(*) INTO overlap_count
        FROM Appointments
        WHERE staff_id = NEW.staff_id
          AND appointment_date = NEW.appointment_date
          AND appointment_id != NEW.appointment_id
          AND status IN ('Scheduled', 'Rescheduled')
          AND (
              -- Updated appointment starts during existing appointment
              (NEW.appointment_time >= appointment_time 
               AND NEW.appointment_time < ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
              OR
              -- Updated appointment ends during existing appointment
              (end_time > appointment_time 
               AND end_time <= ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
              OR
              -- Updated appointment completely encompasses existing appointment
              (NEW.appointment_time <= appointment_time 
               AND end_time >= ADDTIME(appointment_time, SEC_TO_TIME(duration_minutes * 60)))
          );
        
        IF overlap_count > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Updated appointment time conflicts with existing appointment for this staff member';
        END IF;
    END IF;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Appointments;

-- Show created triggers
SHOW TRIGGERS LIKE 'Appointments';

-- Confirmation message
SELECT 'Appointments table created successfully with scheduling logic and conflict prevention!' AS Status;