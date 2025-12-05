-- Hospital Management System - Prescriptions Table
-- This script creates the Prescriptions table with comprehensive dosage tracking

USE hospital_management_system;

-- Create Prescriptions table with comprehensive dosage and tracking
CREATE TABLE Prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    staff_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,
    quantity_prescribed INT NOT NULL,
    quantity_dispensed INT DEFAULT 0,
    prescription_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    start_date DATE,
    end_date DATE,
    status ENUM('Active', 'Completed', 'Cancelled', 'Expired', 'Partially_Filled') DEFAULT 'Active',
    instructions TEXT,
    refills_allowed INT DEFAULT 0,
    refills_remaining INT DEFAULT 0,
    route_of_administration ENUM('Oral', 'Topical', 'Injection', 'Inhalation', 'Rectal', 'Sublingual', 'Transdermal') DEFAULT 'Oral',
    indication VARCHAR(200), -- Why the medication was prescribed
    contraindications TEXT,
    side_effects_noted TEXT,
    pharmacy_notes TEXT,
    prescriber_notes TEXT,
    dispensed_by INT,
    dispensed_date TIMESTAMP NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Medical_Staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES Medications(medication_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (dispensed_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_prescription_duration CHECK (duration_days > 0),
    CONSTRAINT chk_prescription_quantity CHECK (quantity_prescribed > 0),
    CONSTRAINT chk_prescription_dispensed CHECK (quantity_dispensed >= 0 AND quantity_dispensed <= quantity_prescribed),
    CONSTRAINT chk_prescription_refills CHECK (refills_allowed >= 0 AND refills_remaining >= 0 AND refills_remaining <= refills_allowed),
    CONSTRAINT chk_prescription_dates CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date)
);

-- Create indexes for performance
CREATE INDEX idx_prescription_patient ON Prescriptions(patient_id, prescription_date DESC);
CREATE INDEX idx_prescription_staff ON Prescriptions(staff_id, prescription_date DESC);
CREATE INDEX idx_prescription_medication ON Prescriptions(medication_id, prescription_date DESC);
CREATE INDEX idx_prescription_status ON Prescriptions(status);
CREATE INDEX idx_prescription_dates ON Prescriptions(start_date, end_date);
CREATE INDEX idx_prescription_refills ON Prescriptions(refills_remaining);

-- Create a trigger to automatically calculate end date and update medication stock
DELIMITER //
CREATE TRIGGER trg_prescription_management
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    -- Calculate end date if not provided
    IF NEW.end_date IS NULL AND NEW.start_date IS NOT NULL THEN
        SET NEW.end_date = DATE_ADD(NEW.start_date, INTERVAL NEW.duration_days DAY);
    ELSEIF NEW.end_date IS NULL AND NEW.start_date IS NULL THEN
        SET NEW.start_date = CURDATE();
        SET NEW.end_date = DATE_ADD(CURDATE(), INTERVAL NEW.duration_days DAY);
    END IF;
    
    -- Set refills_remaining to refills_allowed initially
    IF NEW.refills_remaining = 0 AND NEW.refills_allowed > 0 THEN
        SET NEW.refills_remaining = NEW.refills_allowed;
    END IF;
END//
DELIMITER ;

-- Create a trigger to update prescription status based on dates and quantities
DELIMITER //
CREATE TRIGGER trg_prescription_status_update
BEFORE UPDATE ON Prescriptions
FOR EACH ROW
BEGIN
    -- Update status based on quantity dispensed
    IF NEW.quantity_dispensed = NEW.quantity_prescribed AND OLD.quantity_dispensed < OLD.quantity_prescribed THEN
        IF NEW.refills_remaining > 0 THEN
            SET NEW.status = 'Partially_Filled';
        ELSE
            SET NEW.status = 'Completed';
        END IF;
    END IF;
    
    -- Check if prescription has expired
    IF NEW.end_date < CURDATE() AND NEW.status = 'Active' THEN
        SET NEW.status = 'Expired';
    END IF;
END//
DELIMITER ;

-- Create a procedure to create a new prescription
DELIMITER //
CREATE PROCEDURE CreatePrescription(
    IN p_patient_id INT,
    IN p_staff_id INT,
    IN p_medication_id INT,
    IN p_dosage VARCHAR(100),
    IN p_frequency VARCHAR(100),
    IN p_duration_days INT,
    IN p_quantity_prescribed INT,
    IN p_refills_allowed INT,
    IN p_route VARCHAR(50),
    IN p_indication VARCHAR(200),
    IN p_instructions TEXT,
    OUT p_prescription_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_patient_status VARCHAR(20);
    DECLARE v_staff_status VARCHAR(20);
    DECLARE v_medication_exists INT DEFAULT 0;
    DECLARE v_medication_stock INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_prescription_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate patient exists and is active
    SELECT status INTO v_patient_status 
    FROM Patients 
    WHERE patient_id = p_patient_id;
    
    IF v_patient_status IS NULL THEN
        SET p_result_message = 'Patient not found';
        SET p_prescription_id = -1;
        ROLLBACK;
    ELSEIF v_patient_status != 'Active' THEN
        SET p_result_message = 'Patient is not active';
        SET p_prescription_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate staff exists and is active
    SELECT status INTO v_staff_status 
    FROM Medical_Staff 
    WHERE staff_id = p_staff_id;
    
    IF v_staff_status IS NULL THEN
        SET p_result_message = 'Staff member not found';
        SET p_prescription_id = -1;
        ROLLBACK;
    ELSEIF v_staff_status != 'Active' THEN
        SET p_result_message = 'Staff member is not active';
        SET p_prescription_id = -1;
        ROLLBACK;
    END IF;
    
    -- Validate medication exists and check stock
    SELECT COUNT(*), stock_quantity INTO v_medication_exists, v_medication_stock
    FROM Medications 
    WHERE medication_id = p_medication_id;
    
    IF v_medication_exists = 0 THEN
        SET p_result_message = 'Medication not found';
        SET p_prescription_id = -1;
        ROLLBACK;
    ELSEIF v_medication_stock < p_quantity_prescribed THEN
        SET p_result_message = CONCAT('Insufficient medication stock. Available: ', v_medication_stock, ', Required: ', p_quantity_prescribed);
        SET p_prescription_id = -1;
        ROLLBACK;
    END IF;
    
    -- Insert the prescription
    INSERT INTO Prescriptions (
        patient_id, staff_id, medication_id, dosage, frequency, duration_days,
        quantity_prescribed, refills_allowed, route_of_administration, 
        indication, instructions
    ) VALUES (
        p_patient_id, p_staff_id, p_medication_id, p_dosage, p_frequency, p_duration_days,
        p_quantity_prescribed, p_refills_allowed, p_route, p_indication, p_instructions
    );
    
    SET p_prescription_id = LAST_INSERT_ID();
    SET p_result_message = 'Prescription created successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to dispense medication
DELIMITER //
CREATE PROCEDURE DispenseMedication(
    IN p_prescription_id INT,
    IN p_quantity_to_dispense INT,
    IN p_dispensed_by INT,
    IN p_pharmacy_notes TEXT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_current_dispensed INT DEFAULT 0;
    DECLARE v_quantity_prescribed INT DEFAULT 0;
    DECLARE v_medication_id INT DEFAULT 0;
    DECLARE v_medication_stock INT DEFAULT 0;
    DECLARE v_new_dispensed INT DEFAULT 0;
    DECLARE v_prescription_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get prescription details
    SELECT quantity_dispensed, quantity_prescribed, medication_id, status
    INTO v_current_dispensed, v_quantity_prescribed, v_medication_id, v_prescription_status
    FROM Prescriptions
    WHERE prescription_id = p_prescription_id;
    
    IF v_quantity_prescribed IS NULL THEN
        SET p_result_message = 'Prescription not found';
        ROLLBACK;
    END IF;
    
    IF v_prescription_status NOT IN ('Active', 'Partially_Filled') THEN
        SET p_result_message = CONCAT('Cannot dispense medication. Prescription status: ', v_prescription_status);
        ROLLBACK;
    END IF;
    
    SET v_new_dispensed = v_current_dispensed + p_quantity_to_dispense;
    
    -- Check if dispensing quantity is valid
    IF v_new_dispensed > v_quantity_prescribed THEN
        SET p_result_message = CONCAT('Cannot dispense more than prescribed. Prescribed: ', v_quantity_prescribed, ', Already dispensed: ', v_current_dispensed);
        ROLLBACK;
    END IF;
    
    -- Check medication stock
    SELECT stock_quantity INTO v_medication_stock
    FROM Medications
    WHERE medication_id = v_medication_id;
    
    IF v_medication_stock < p_quantity_to_dispense THEN
        SET p_result_message = CONCAT('Insufficient medication stock. Available: ', v_medication_stock, ', Requested: ', p_quantity_to_dispense);
        ROLLBACK;
    END IF;
    
    -- Update prescription
    UPDATE Prescriptions
    SET quantity_dispensed = v_new_dispensed,
        dispensed_by = p_dispensed_by,
        dispensed_date = CURRENT_TIMESTAMP,
        pharmacy_notes = COALESCE(p_pharmacy_notes, pharmacy_notes),
        updated_date = CURRENT_TIMESTAMP
    WHERE prescription_id = p_prescription_id;
    
    -- Update medication stock
    CALL UpdateMedicationStock(
        v_medication_id, 
        -p_quantity_to_dispense, 
        CONCAT('Dispensed for prescription ID: ', p_prescription_id),
        @stock_update_message
    );
    
    SET p_result_message = CONCAT('Medication dispensed successfully. Quantity: ', p_quantity_to_dispense);
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for active prescriptions
CREATE VIEW Active_Prescriptions AS
SELECT 
    p.prescription_id,
    CONCAT(pat.first_name, ' ', pat.last_name) AS patient_name,
    pat.date_of_birth,
    m.medication_name,
    m.generic_name,
    m.dosage_form,
    m.strength,
    p.dosage,
    p.frequency,
    p.route_of_administration,
    p.quantity_prescribed,
    p.quantity_dispensed,
    (p.quantity_prescribed - p.quantity_dispensed) AS remaining_quantity,
    p.start_date,
    p.end_date,
    p.refills_remaining,
    p.indication,
    p.instructions,
    CONCAT(ms.first_name, ' ', ms.last_name) AS prescriber,
    ms.specialization,
    p.status,
    DATEDIFF(p.end_date, CURDATE()) AS days_remaining
FROM Prescriptions p
JOIN Patients pat ON p.patient_id = pat.patient_id
JOIN Medications m ON p.medication_id = m.medication_id
JOIN Medical_Staff ms ON p.staff_id = ms.staff_id
WHERE p.status IN ('Active', 'Partially_Filled')
  AND p.end_date >= CURDATE()
ORDER BY p.end_date ASC;

-- Create a view for prescription refill alerts
CREATE VIEW Prescription_Refill_Alerts AS
SELECT 
    p.prescription_id,
    CONCAT(pat.first_name, ' ', pat.last_name) AS patient_name,
    pat.phone AS patient_phone,
    m.medication_name,
    p.quantity_prescribed,
    p.quantity_dispensed,
    p.refills_remaining,
    p.end_date,
    DATEDIFF(p.end_date, CURDATE()) AS days_until_expiry,
    CONCAT(ms.first_name, ' ', ms.last_name) AS prescriber
FROM Prescriptions p
JOIN Patients pat ON p.patient_id = pat.patient_id
JOIN Medications m ON p.medication_id = m.medication_id
JOIN Medical_Staff ms ON p.staff_id = ms.staff_id
WHERE p.status = 'Active'
  AND p.refills_remaining > 0
  AND p.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY p.end_date ASC;

-- Display table structure
DESCRIBE Prescriptions;

-- Show created views and procedures
SHOW CREATE VIEW Active_Prescriptions;
SHOW CREATE VIEW Prescription_Refill_Alerts;
SHOW PROCEDURE STATUS WHERE Name IN ('CreatePrescription', 'DispenseMedication');

-- Confirmation message
SELECT 'Prescriptions table created successfully with comprehensive dosage tracking!' AS Status;