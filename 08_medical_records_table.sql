-- Hospital Management System - Medical Records Table
-- This script creates the Medical_Records table with comprehensive patient history tracking

USE hospital_management_system;

-- Create Medical_Records table with comprehensive tracking
CREATE TABLE Medical_Records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    staff_id INT NOT NULL,
    visit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diagnosis TEXT,
    symptoms TEXT,
    treatment_plan TEXT,
    medications_prescribed TEXT,
    allergies TEXT,
    vital_signs JSON,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    record_type ENUM('Consultation', 'Emergency', 'Surgery', 'Follow-up', 'Discharge', 'Admission') NOT NULL,
    chief_complaint VARCHAR(500),
    physical_examination TEXT,
    lab_results TEXT,
    imaging_results TEXT,
    procedure_notes TEXT,
    discharge_summary TEXT,
    admission_reason TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Medical_Staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_follow_up_date CHECK (follow_up_date IS NULL OR follow_up_date > DATE(visit_date)),
    CONSTRAINT chk_visit_date CHECK (visit_date <= CURRENT_TIMESTAMP)
);

-- Create indexes for performance
CREATE INDEX idx_medical_record_patient ON Medical_Records(patient_id, visit_date DESC);
CREATE INDEX idx_medical_record_staff ON Medical_Records(staff_id, visit_date DESC);
CREATE INDEX idx_medical_record_type ON Medical_Records(record_type);
CREATE INDEX idx_medical_record_follow_up ON Medical_Records(follow_up_required, follow_up_date);
CREATE INDEX idx_medical_record_visit_date ON Medical_Records(visit_date);

-- Create a trigger to validate vital signs JSON format
DELIMITER //
CREATE TRIGGER trg_validate_vital_signs
BEFORE INSERT ON Medical_Records
FOR EACH ROW
BEGIN
    -- Validate vital signs JSON structure if provided
    IF NEW.vital_signs IS NOT NULL THEN
        -- Check if it's valid JSON (MySQL will throw error if not)
        SET @test_json = JSON_VALID(NEW.vital_signs);
        IF @test_json = 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid JSON format for vital signs';
        END IF;
    END IF;
    
    -- Set default vital signs structure if empty
    IF NEW.vital_signs IS NULL AND NEW.record_type IN ('Consultation', 'Emergency', 'Admission') THEN
        SET NEW.vital_signs = JSON_OBJECT(
            'temperature', NULL,
            'blood_pressure_systolic', NULL,
            'blood_pressure_diastolic', NULL,
            'heart_rate', NULL,
            'respiratory_rate', NULL,
            'oxygen_saturation', NULL,
            'weight', NULL,
            'height', NULL
        );
    END IF;
END//
DELIMITER ;

-- Create trigger for update validation
DELIMITER //
CREATE TRIGGER trg_validate_vital_signs_update
BEFORE UPDATE ON Medical_Records
FOR EACH ROW
BEGIN
    -- Validate vital signs JSON structure if provided
    IF NEW.vital_signs IS NOT NULL THEN
        SET @test_json = JSON_VALID(NEW.vital_signs);
        IF @test_json = 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid JSON format for vital signs';
        END IF;
    END IF;
END//
DELIMITER ;

-- Create a view for patient medical history summary
CREATE VIEW Patient_Medical_History AS
SELECT 
    mr.record_id,
    mr.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    mr.visit_date,
    mr.record_type,
    mr.chief_complaint,
    mr.diagnosis,
    CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician,
    ms.specialization,
    mr.follow_up_required,
    mr.follow_up_date,
    -- Extract vital signs from JSON
    JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.temperature')) AS temperature,
    JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_systolic')) AS bp_systolic,
    JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_diastolic')) AS bp_diastolic,
    JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.heart_rate')) AS heart_rate,
    JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.oxygen_saturation')) AS oxygen_saturation
FROM Medical_Records mr
JOIN Patients p ON mr.patient_id = p.patient_id
JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
ORDER BY mr.patient_id, mr.visit_date DESC;

-- Create a procedure to add a new medical record with validation
DELIMITER //
CREATE PROCEDURE AddMedicalRecord(
    IN p_patient_id INT,
    IN p_staff_id INT,
    IN p_record_type ENUM('Consultation', 'Emergency', 'Surgery', 'Follow-up', 'Discharge', 'Admission'),
    IN p_chief_complaint VARCHAR(500),
    IN p_symptoms TEXT,
    IN p_diagnosis TEXT,
    IN p_treatment_plan TEXT,
    IN p_vital_signs JSON,
    IN p_follow_up_required BOOLEAN,
    IN p_follow_up_date DATE,
    OUT p_record_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_patient_exists INT DEFAULT 0;
    DECLARE v_staff_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_record_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate patient exists
    SELECT COUNT(*) INTO v_patient_exists 
    FROM Patients 
    WHERE patient_id = p_patient_id AND status = 'Active';
    
    IF v_patient_exists = 0 THEN
        SET p_result_message = 'Patient not found or inactive';
        SET p_record_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate staff exists
    SELECT COUNT(*) INTO v_staff_exists 
    FROM Medical_Staff 
    WHERE staff_id = p_staff_id AND status = 'Active';
    
    IF v_staff_exists = 0 THEN
        SET p_result_message = 'Staff member not found or inactive';
        SET p_record_id = -1;
        ROLLBACK;
    END IF;
    
    -- Insert the medical record
    INSERT INTO Medical_Records (
        patient_id, staff_id, record_type, chief_complaint, symptoms,
        diagnosis, treatment_plan, vital_signs, follow_up_required, follow_up_date
    ) VALUES (
        p_patient_id, p_staff_id, p_record_type, p_chief_complaint, p_symptoms,
        p_diagnosis, p_treatment_plan, p_vital_signs, p_follow_up_required, p_follow_up_date
    );
    
    SET p_record_id = LAST_INSERT_ID();
    SET p_result_message = 'Medical record added successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a function to get patient's latest vital signs
DELIMITER //
CREATE FUNCTION GetLatestVitalSigns(p_patient_id INT)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_vital_signs JSON DEFAULT NULL;
    
    SELECT vital_signs INTO v_vital_signs
    FROM Medical_Records
    WHERE patient_id = p_patient_id 
      AND vital_signs IS NOT NULL
    ORDER BY visit_date DESC
    LIMIT 1;
    
    RETURN v_vital_signs;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Medical_Records;

-- Show created view
SHOW CREATE VIEW Patient_Medical_History;

-- Show created procedures and functions
SHOW PROCEDURE STATUS WHERE Name = 'AddMedicalRecord';
SHOW FUNCTION STATUS WHERE Name = 'GetLatestVitalSigns';

-- Confirmation message
SELECT 'Medical_Records table created successfully with comprehensive tracking!' AS Status;