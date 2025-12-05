-- Hospital Management System - Treatments Table
-- This script creates the Treatments table with procedure details and cost tracking

USE hospital_management_system;

-- Create Treatments table with comprehensive cost tracking
CREATE TABLE Treatments (
    treatment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    staff_id INT NOT NULL,
    treatment_name VARCHAR(200) NOT NULL,
    treatment_code VARCHAR(50), -- CPT or ICD codes
    treatment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_minutes INT,
    cost DECIMAL(10,2) NOT NULL,
    room_id INT,
    status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'On Hold') DEFAULT 'Scheduled',
    notes TEXT,
    pre_treatment_notes TEXT,
    post_treatment_notes TEXT,
    complications TEXT,
    equipment_used TEXT,
    anesthesia_type ENUM('None', 'Local', 'Regional', 'General'),
    anesthesia_staff_id INT,
    priority ENUM('Routine', 'Urgent', 'Emergency', 'Elective') DEFAULT 'Routine',
    consent_obtained BOOLEAN DEFAULT FALSE,
    insurance_approved BOOLEAN DEFAULT FALSE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Medical_Staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (anesthesia_staff_id) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_treatment_cost CHECK (cost >= 0),
    CONSTRAINT chk_treatment_duration CHECK (duration_minutes IS NULL OR duration_minutes > 0),
    CONSTRAINT chk_treatment_date CHECK (treatment_date >= created_date)
);

-- Create indexes for performance
CREATE INDEX idx_treatment_patient ON Treatments(patient_id, treatment_date DESC);
CREATE INDEX idx_treatment_staff ON Treatments(staff_id, treatment_date);
CREATE INDEX idx_treatment_room ON Treatments(room_id, treatment_date);
CREATE INDEX idx_treatment_status ON Treatments(status);
CREATE INDEX idx_treatment_date ON Treatments(treatment_date);
CREATE INDEX idx_treatment_code ON Treatments(treatment_code);
CREATE INDEX idx_treatment_priority ON Treatments(priority);

-- Create a trigger to update room occupancy when treatment is scheduled/completed
DELIMITER //
CREATE TRIGGER trg_treatment_room_occupancy
AFTER UPDATE ON Treatments
FOR EACH ROW
BEGIN
    -- If treatment status changed to 'In Progress' and room is assigned
    IF NEW.status = 'In Progress' AND OLD.status != 'In Progress' AND NEW.room_id IS NOT NULL THEN
        UPDATE Rooms 
        SET current_occupancy = current_occupancy + 1 
        WHERE room_id = NEW.room_id AND current_occupancy < capacity;
    END IF;
    
    -- If treatment status changed from 'In Progress' to completed/cancelled
    IF OLD.status = 'In Progress' AND NEW.status IN ('Completed', 'Cancelled') AND NEW.room_id IS NOT NULL THEN
        UPDATE Rooms 
        SET current_occupancy = GREATEST(current_occupancy - 1, 0) 
        WHERE room_id = NEW.room_id;
    END IF;
    
    -- If room changed while treatment is in progress
    IF NEW.status = 'In Progress' AND OLD.room_id != NEW.room_id THEN
        -- Decrease occupancy in old room
        IF OLD.room_id IS NOT NULL THEN
            UPDATE Rooms 
            SET current_occupancy = GREATEST(current_occupancy - 1, 0) 
            WHERE room_id = OLD.room_id;
        END IF;
        
        -- Increase occupancy in new room
        IF NEW.room_id IS NOT NULL THEN
            UPDATE Rooms 
            SET current_occupancy = current_occupancy + 1 
            WHERE room_id = NEW.room_id AND current_occupancy < capacity;
        END IF;
    END IF;
END//
DELIMITER ;

-- Create a procedure to schedule a treatment
DELIMITER //
CREATE PROCEDURE ScheduleTreatment(
    IN p_patient_id INT,
    IN p_staff_id INT,
    IN p_treatment_name VARCHAR(200),
    IN p_treatment_code VARCHAR(50),
    IN p_treatment_date TIMESTAMP,
    IN p_duration_minutes INT,
    IN p_cost DECIMAL(10,2),
    IN p_room_id INT,
    IN p_priority ENUM('Routine', 'Urgent', 'Emergency', 'Elective'),
    IN p_notes TEXT,
    OUT p_treatment_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_patient_status VARCHAR(20);
    DECLARE v_staff_status VARCHAR(20);
    DECLARE v_room_available BOOLEAN DEFAULT TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_treatment_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate patient exists and is active
    SELECT status INTO v_patient_status 
    FROM Patients 
    WHERE patient_id = p_patient_id;
    
    IF v_patient_status IS NULL THEN
        SET p_result_message = 'Patient not found';
        SET p_treatment_id = -1;
        ROLLBACK;
    ELSEIF v_patient_status != 'Active' THEN
        SET p_result_message = 'Patient is not active';
        SET p_treatment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate staff exists and is active
    SELECT status INTO v_staff_status 
    FROM Medical_Staff 
    WHERE staff_id = p_staff_id;
    
    IF v_staff_status IS NULL THEN
        SET p_result_message = 'Staff member not found';
        SET p_treatment_id = -1;
        ROLLBACK;
    ELSEIF v_staff_status != 'Active' THEN
        SET p_result_message = 'Staff member is not active';
        SET p_treatment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Check room availability if room is specified
    IF p_room_id IS NOT NULL THEN
        SELECT (current_occupancy < capacity AND status IN ('Available', 'Occupied')) INTO v_room_available
        FROM Rooms 
        WHERE room_id = p_room_id;
        
        IF v_room_available IS NULL OR v_room_available = FALSE THEN
            SET p_result_message = 'Room is not available';
            SET p_treatment_id = -1;
            ROLLBACK;
        END IF;
    END IF;
    
    -- Insert the treatment
    INSERT INTO Treatments (
        patient_id, staff_id, treatment_name, treatment_code, treatment_date,
        duration_minutes, cost, room_id, priority, notes
    ) VALUES (
        p_patient_id, p_staff_id, p_treatment_name, p_treatment_code, p_treatment_date,
        p_duration_minutes, p_cost, p_room_id, p_priority, p_notes
    );
    
    SET p_treatment_id = LAST_INSERT_ID();
    SET p_result_message = 'Treatment scheduled successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to update treatment status
DELIMITER //
CREATE PROCEDURE UpdateTreatmentStatus(
    IN p_treatment_id INT,
    IN p_new_status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'On Hold'),
    IN p_post_treatment_notes TEXT,
    IN p_complications TEXT,
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
    
    -- Check if treatment exists
    SELECT status INTO v_current_status 
    FROM Treatments 
    WHERE treatment_id = p_treatment_id;
    
    IF v_current_status IS NULL THEN
        SET p_result_message = 'Treatment not found';
        ROLLBACK;
    END IF;
    
    -- Update treatment status and notes
    UPDATE Treatments 
    SET status = p_new_status,
        post_treatment_notes = COALESCE(p_post_treatment_notes, post_treatment_notes),
        complications = COALESCE(p_complications, complications),
        updated_date = CURRENT_TIMESTAMP
    WHERE treatment_id = p_treatment_id;
    
    SET p_result_message = CONCAT('Treatment status updated to ', p_new_status);
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for treatment cost analysis
CREATE VIEW Treatment_Cost_Analysis AS
SELECT 
    t.treatment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    t.treatment_name,
    t.treatment_code,
    t.treatment_date,
    t.cost,
    t.status,
    t.priority,
    CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician,
    ms.specialization,
    r.room_number,
    r.room_type,
    r.daily_rate AS room_daily_rate,
    -- Calculate total cost including room charges
    CASE 
        WHEN t.duration_minutes IS NOT NULL AND r.daily_rate IS NOT NULL THEN
            t.cost + (r.daily_rate * (t.duration_minutes / 1440.0))
        ELSE t.cost
    END AS total_estimated_cost
FROM Treatments t
JOIN Patients p ON t.patient_id = p.patient_id
JOIN Medical_Staff ms ON t.staff_id = ms.staff_id
LEFT JOIN Rooms r ON t.room_id = r.room_id;

-- Create a function to calculate total treatment cost for a patient
DELIMITER //
CREATE FUNCTION GetPatientTreatmentCost(p_patient_id INT, p_start_date DATE, p_end_date DATE)
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_cost DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(cost), 0) INTO v_total_cost
    FROM Treatments
    WHERE patient_id = p_patient_id
      AND DATE(treatment_date) BETWEEN p_start_date AND p_end_date
      AND status = 'Completed';
    
    RETURN v_total_cost;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Treatments;

-- Show created views, procedures, and functions
SHOW CREATE VIEW Treatment_Cost_Analysis;
SHOW PROCEDURE STATUS WHERE Name IN ('ScheduleTreatment', 'UpdateTreatmentStatus');
SHOW FUNCTION STATUS WHERE Name = 'GetPatientTreatmentCost';

-- Confirmation message
SELECT 'Treatments table created successfully with cost tracking and procedures!' AS Status;