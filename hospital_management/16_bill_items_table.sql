-- Hospital Management System - Bill Items Table
-- This script creates the Bill_Items table for detailed itemized billing

USE hospital_management_system;

-- Create Bill_Items table for detailed charges
CREATE TABLE Bill_Items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    bill_id INT NOT NULL,
    service_type ENUM('Treatment', 'Room', 'Medication', 'Consultation', 'Test', 'Surgery', 'Emergency', 'Equipment', 'Other') NOT NULL,
    service_code VARCHAR(50), -- CPT, ICD, or internal codes
    service_description VARCHAR(200) NOT NULL,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    service_date DATE,
    service_provider_id INT, -- Staff member who provided the service
    department_id INT, -- Department that provided the service
    room_id INT, -- Room where service was provided
    treatment_id INT, -- Link to specific treatment
    prescription_id INT, -- Link to specific prescription
    discount_applied DECIMAL(10,2) DEFAULT 0,
    insurance_covered BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (bill_id) REFERENCES Billing(bill_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (service_provider_id) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (prescription_id) REFERENCES Prescriptions(prescription_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_bill_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_bill_item_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_bill_item_total_price CHECK (total_price >= 0),
    CONSTRAINT chk_bill_item_discount CHECK (discount_applied >= 0 AND discount_applied <= total_price),
    CONSTRAINT chk_bill_item_service_date CHECK (service_date IS NULL OR service_date <= CURDATE())
);

-- Create indexes for performance
CREATE INDEX idx_bill_items_bill ON Bill_Items(bill_id);
CREATE INDEX idx_bill_items_service_type ON Bill_Items(service_type);
CREATE INDEX idx_bill_items_service_code ON Bill_Items(service_code);
CREATE INDEX idx_bill_items_service_date ON Bill_Items(service_date);
CREATE INDEX idx_bill_items_provider ON Bill_Items(service_provider_id);
CREATE INDEX idx_bill_items_department ON Bill_Items(department_id);

-- Create a trigger to automatically calculate total price
DELIMITER //
CREATE TRIGGER trg_bill_items_calculate_total
BEFORE INSERT ON Bill_Items
FOR EACH ROW
BEGIN
    -- Calculate total price if not provided
    IF NEW.total_price = 0 OR NEW.total_price IS NULL THEN
        SET NEW.total_price = NEW.quantity * NEW.unit_price;
    END IF;
    
    -- Apply discount if specified
    IF NEW.discount_applied > 0 THEN
        SET NEW.total_price = NEW.total_price - NEW.discount_applied;
    END IF;
    
    -- Ensure total price is not negative
    IF NEW.total_price < 0 THEN
        SET NEW.total_price = 0;
    END IF;
END//
DELIMITER ;

-- Create trigger for updates
DELIMITER //
CREATE TRIGGER trg_bill_items_update_total
BEFORE UPDATE ON Bill_Items
FOR EACH ROW
BEGIN
    -- Recalculate total price if quantity or unit price changed
    IF NEW.quantity != OLD.quantity OR NEW.unit_price != OLD.unit_price OR NEW.discount_applied != OLD.discount_applied THEN
        SET NEW.total_price = (NEW.quantity * NEW.unit_price) - NEW.discount_applied;
        
        -- Ensure total price is not negative
        IF NEW.total_price < 0 THEN
            SET NEW.total_price = 0;
        END IF;
    END IF;
END//
DELIMITER ;

-- Create a trigger to update bill total when items are added/updated/deleted
DELIMITER //
CREATE TRIGGER trg_update_bill_total_insert
AFTER INSERT ON Bill_Items
FOR EACH ROW
BEGIN
    UPDATE Billing 
    SET total_amount = (
        SELECT COALESCE(SUM(total_price), 0) 
        FROM Bill_Items 
        WHERE bill_id = NEW.bill_id
    ),
    updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = NEW.bill_id;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_update_bill_total_update
AFTER UPDATE ON Bill_Items
FOR EACH ROW
BEGIN
    UPDATE Billing 
    SET total_amount = (
        SELECT COALESCE(SUM(total_price), 0) 
        FROM Bill_Items 
        WHERE bill_id = NEW.bill_id
    ),
    updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = NEW.bill_id;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_update_bill_total_delete
AFTER DELETE ON Bill_Items
FOR EACH ROW
BEGIN
    UPDATE Billing 
    SET total_amount = (
        SELECT COALESCE(SUM(total_price), 0) 
        FROM Bill_Items 
        WHERE bill_id = OLD.bill_id
    ),
    updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = OLD.bill_id;
END//
DELIMITER ;

-- Create a procedure to add bill item
DELIMITER //
CREATE PROCEDURE AddBillItem(
    IN p_bill_id INT,
    IN p_service_type ENUM('Treatment', 'Room', 'Medication', 'Consultation', 'Test', 'Surgery', 'Emergency', 'Equipment', 'Other'),
    IN p_service_code VARCHAR(50),
    IN p_service_description VARCHAR(200),
    IN p_quantity INT,
    IN p_unit_price DECIMAL(10,2),
    IN p_service_date DATE,
    IN p_service_provider_id INT,
    IN p_department_id INT,
    IN p_treatment_id INT,
    IN p_prescription_id INT,
    IN p_notes TEXT,
    OUT p_item_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_bill_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_item_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate bill exists
    SELECT COUNT(*) INTO v_bill_exists 
    FROM Billing 
    WHERE bill_id = p_bill_id;
    
    IF v_bill_exists = 0 THEN
        SET p_result_message = 'Bill not found';
        SET p_item_id = -1;
        ROLLBACK;
    END IF;
    
    -- Insert the bill item
    INSERT INTO Bill_Items (
        bill_id, service_type, service_code, service_description, quantity,
        unit_price, service_date, service_provider_id, department_id,
        treatment_id, prescription_id, notes
    ) VALUES (
        p_bill_id, p_service_type, p_service_code, p_service_description, p_quantity,
        p_unit_price, p_service_date, p_service_provider_id, p_department_id,
        p_treatment_id, p_prescription_id, p_notes
    );
    
    SET p_item_id = LAST_INSERT_ID();
    SET p_result_message = 'Bill item added successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to add treatment to bill
DELIMITER //
CREATE PROCEDURE AddTreatmentToBill(
    IN p_bill_id INT,
    IN p_treatment_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_treatment_cost DECIMAL(10,2) DEFAULT 0;
    DECLARE v_treatment_name VARCHAR(200) DEFAULT '';
    DECLARE v_staff_id INT DEFAULT 0;
    DECLARE v_department_id INT DEFAULT 0;
    DECLARE v_room_id INT DEFAULT 0;
    DECLARE v_treatment_date DATE DEFAULT NULL;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get treatment details
    SELECT t.cost, t.treatment_name, t.staff_id, ms.department_id, t.room_id, DATE(t.treatment_date)
    INTO v_treatment_cost, v_treatment_name, v_staff_id, v_department_id, v_room_id, v_treatment_date
    FROM Treatments t
    JOIN Medical_Staff ms ON t.staff_id = ms.staff_id
    WHERE t.treatment_id = p_treatment_id;
    
    IF v_treatment_cost IS NULL THEN
        SET p_result_message = 'Treatment not found';
        ROLLBACK;
    END IF;
    
    -- Add treatment as bill item
    CALL AddBillItem(
        p_bill_id, 'Treatment', NULL, v_treatment_name, 1, v_treatment_cost,
        v_treatment_date, v_staff_id, v_department_id, p_treatment_id, NULL,
        CONCAT('Treatment ID: ', p_treatment_id), v_item_id, p_result_message
    );
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to add prescription to bill
DELIMITER //
CREATE PROCEDURE AddPrescriptionToBill(
    IN p_bill_id INT,
    IN p_prescription_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_medication_cost DECIMAL(10,2) DEFAULT 0;
    DECLARE v_medication_name VARCHAR(200) DEFAULT '';
    DECLARE v_quantity_dispensed INT DEFAULT 0;
    DECLARE v_staff_id INT DEFAULT 0;
    DECLARE v_prescription_date DATE DEFAULT NULL;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get prescription details
    SELECT m.unit_price, m.medication_name, p.quantity_dispensed, p.staff_id, DATE(p.prescription_date)
    INTO v_medication_cost, v_medication_name, v_quantity_dispensed, v_staff_id, v_prescription_date
    FROM Prescriptions p
    JOIN Medications m ON p.medication_id = m.medication_id
    WHERE p.prescription_id = p_prescription_id;
    
    IF v_medication_cost IS NULL THEN
        SET p_result_message = 'Prescription not found';
        ROLLBACK;
    END IF;
    
    -- Add prescription as bill item
    CALL AddBillItem(
        p_bill_id, 'Medication', NULL, v_medication_name, v_quantity_dispensed, v_medication_cost,
        v_prescription_date, v_staff_id, NULL, NULL, p_prescription_id,
        CONCAT('Prescription ID: ', p_prescription_id), v_item_id, p_result_message
    );
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to add room charges to bill
DELIMITER //
CREATE PROCEDURE AddRoomChargesToBill(
    IN p_bill_id INT,
    IN p_room_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_daily_rate DECIMAL(8,2) DEFAULT 0;
    DECLARE v_room_number VARCHAR(10) DEFAULT '';
    DECLARE v_room_type VARCHAR(20) DEFAULT '';
    DECLARE v_department_id INT DEFAULT 0;
    DECLARE v_days_count INT DEFAULT 0;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get room details
    SELECT daily_rate, room_number, room_type, department_id
    INTO v_daily_rate, v_room_number, v_room_type, v_department_id
    FROM Rooms
    WHERE room_id = p_room_id;
    
    IF v_daily_rate IS NULL THEN
        SET p_result_message = 'Room not found';
        ROLLBACK;
    END IF;
    
    -- Calculate number of days
    SET v_days_count = DATEDIFF(p_end_date, p_start_date) + 1;
    
    IF v_days_count <= 0 THEN
        SET p_result_message = 'Invalid date range';
        ROLLBACK;
    END IF;
    
    -- Add room charges as bill item
    CALL AddBillItem(
        p_bill_id, 'Room', NULL, 
        CONCAT(v_room_type, ' Room ', v_room_number, ' (', v_days_count, ' days)'), 
        v_days_count, v_daily_rate, p_end_date, NULL, v_department_id, NULL, NULL,
        CONCAT('Room stay from ', p_start_date, ' to ', p_end_date), 
        v_item_id, p_result_message
    );
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for detailed bill items with related information
CREATE VIEW Detailed_Bill_Items AS
SELECT 
    bi.item_id,
    bi.bill_id,
    b.bill_date,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    bi.service_type,
    bi.service_code,
    bi.service_description,
    bi.quantity,
    bi.unit_price,
    bi.discount_applied,
    bi.total_price,
    bi.service_date,
    CONCAT(sp.first_name, ' ', sp.last_name) AS service_provider_name,
    d.department_name,
    r.room_number,
    bi.insurance_covered,
    bi.notes
FROM Bill_Items bi
JOIN Billing b ON bi.bill_id = b.bill_id
JOIN Patients p ON b.patient_id = p.patient_id
LEFT JOIN Medical_Staff sp ON bi.service_provider_id = sp.staff_id
LEFT JOIN Departments d ON bi.department_id = d.department_id
LEFT JOIN Rooms r ON bi.room_id = r.room_id
ORDER BY bi.bill_id, bi.service_date, bi.item_id;

-- Create a view for service type summary
CREATE VIEW Service_Type_Summary AS
SELECT 
    service_type,
    COUNT(*) AS total_items,
    SUM(quantity) AS total_quantity,
    AVG(unit_price) AS avg_unit_price,
    SUM(total_price) AS total_revenue,
    AVG(total_price) AS avg_item_value
FROM Bill_Items
GROUP BY service_type
ORDER BY total_revenue DESC;

-- Display table structure
DESCRIBE Bill_Items;

-- Show created views and procedures
SHOW CREATE VIEW Detailed_Bill_Items;
SHOW CREATE VIEW Service_Type_Summary;
SHOW PROCEDURE STATUS WHERE Name IN ('AddBillItem', 'AddTreatmentToBill', 'AddPrescriptionToBill', 'AddRoomChargesToBill');

-- Confirmation message
SELECT 'Bill_Items table created successfully with detailed itemized billing!' AS Status;