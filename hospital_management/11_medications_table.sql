-- Hospital Management System - Medications Inventory Table
-- This script creates the Medications table with comprehensive inventory tracking

USE hospital_management_system;

-- Create Medications table with comprehensive inventory management
CREATE TABLE Medications (
    medication_id INT PRIMARY KEY AUTO_INCREMENT,
    medication_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    brand_name VARCHAR(200),
    manufacturer VARCHAR(100),
    dosage_form ENUM('Tablet', 'Capsule', 'Liquid', 'Injection', 'Cream', 'Ointment', 'Inhaler', 'Drops', 'Patch') NOT NULL,
    strength VARCHAR(50),
    unit_price DECIMAL(8,2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    minimum_stock_level INT DEFAULT 10,
    maximum_stock_level INT DEFAULT 1000,
    expiry_date DATE,
    batch_number VARCHAR(50),
    supplier VARCHAR(100),
    supplier_contact VARCHAR(100),
    storage_requirements TEXT,
    prescription_required BOOLEAN DEFAULT TRUE,
    controlled_substance BOOLEAN DEFAULT FALSE,
    controlled_schedule ENUM('I', 'II', 'III', 'IV', 'V') NULL,
    ndc_number VARCHAR(20), -- National Drug Code
    lot_number VARCHAR(50),
    purchase_date DATE,
    last_restocked_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints for data validation
    CONSTRAINT chk_medication_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_medication_stock_quantity CHECK (stock_quantity >= 0),
    CONSTRAINT chk_medication_min_stock CHECK (minimum_stock_level >= 0),
    CONSTRAINT chk_medication_max_stock CHECK (maximum_stock_level >= minimum_stock_level),
    CONSTRAINT chk_medication_expiry_date CHECK (expiry_date IS NULL OR expiry_date > purchase_date),
    CONSTRAINT chk_controlled_schedule CHECK (
        (controlled_substance = FALSE AND controlled_schedule IS NULL) OR
        (controlled_substance = TRUE AND controlled_schedule IS NOT NULL)
    ),
    
    -- Unique constraints
    UNIQUE KEY unique_medication_batch (medication_name, batch_number, supplier),
    UNIQUE KEY unique_ndc_lot (ndc_number, lot_number)
);

-- Create indexes for performance
CREATE INDEX idx_medication_name ON Medications(medication_name);
CREATE INDEX idx_medication_generic ON Medications(generic_name);
CREATE INDEX idx_medication_stock_level ON Medications(stock_quantity, minimum_stock_level);
CREATE INDEX idx_medication_expiry ON Medications(expiry_date);
CREATE INDEX idx_medication_supplier ON Medications(supplier);
CREATE INDEX idx_medication_controlled ON Medications(controlled_substance, controlled_schedule);
CREATE INDEX idx_medication_batch ON Medications(batch_number);
CREATE INDEX idx_medication_ndc ON Medications(ndc_number);

-- Create a trigger to alert for low stock levels
DELIMITER //
CREATE TRIGGER trg_medication_low_stock_alert
AFTER UPDATE ON Medications
FOR EACH ROW
BEGIN
    -- Check if stock level dropped below minimum
    IF NEW.stock_quantity <= NEW.minimum_stock_level AND OLD.stock_quantity > OLD.minimum_stock_level THEN
        -- Insert alert into a log table (we'll create this)
        INSERT INTO Medication_Alerts (
            medication_id, alert_type, alert_message, alert_date
        ) VALUES (
            NEW.medication_id, 
            'LOW_STOCK', 
            CONCAT('Stock level for ', NEW.medication_name, ' is below minimum threshold. Current: ', NEW.stock_quantity, ', Minimum: ', NEW.minimum_stock_level),
            CURRENT_TIMESTAMP
        );
    END IF;
    
    -- Check for expired medications
    IF NEW.expiry_date <= CURDATE() AND (OLD.expiry_date IS NULL OR OLD.expiry_date > CURDATE()) THEN
        INSERT INTO Medication_Alerts (
            medication_id, alert_type, alert_message, alert_date
        ) VALUES (
            NEW.medication_id, 
            'EXPIRED', 
            CONCAT('Medication ', NEW.medication_name, ' (Batch: ', NEW.batch_number, ') has expired on ', NEW.expiry_date),
            CURRENT_TIMESTAMP
        );
    END IF;
END//
DELIMITER ;

-- Create Medication_Alerts table for tracking inventory alerts
CREATE TABLE Medication_Alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    medication_id INT NOT NULL,
    alert_type ENUM('LOW_STOCK', 'EXPIRED', 'NEAR_EXPIRY', 'OUT_OF_STOCK') NOT NULL,
    alert_message TEXT NOT NULL,
    alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT,
    acknowledged_date TIMESTAMP NULL,
    
    FOREIGN KEY (medication_id) REFERENCES Medications(medication_id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL
);

-- Create index for alerts
CREATE INDEX idx_medication_alerts_type ON Medication_Alerts(alert_type, acknowledged);
CREATE INDEX idx_medication_alerts_date ON Medication_Alerts(alert_date);

-- Create a procedure to add new medication to inventory
DELIMITER //
CREATE PROCEDURE AddMedicationToInventory(
    IN p_medication_name VARCHAR(200),
    IN p_generic_name VARCHAR(200),
    IN p_brand_name VARCHAR(200),
    IN p_manufacturer VARCHAR(100),
    IN p_dosage_form ENUM('Tablet', 'Capsule', 'Liquid', 'Injection', 'Cream', 'Ointment', 'Inhaler', 'Drops', 'Patch'),
    IN p_strength VARCHAR(50),
    IN p_unit_price DECIMAL(8,2),
    IN p_stock_quantity INT,
    IN p_minimum_stock_level INT,
    IN p_expiry_date DATE,
    IN p_batch_number VARCHAR(50),
    IN p_supplier VARCHAR(100),
    IN p_ndc_number VARCHAR(20),
    IN p_controlled_substance BOOLEAN,
    IN p_controlled_schedule ENUM('I', 'II', 'III', 'IV', 'V'),
    OUT p_medication_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_duplicate_count INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_medication_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Check for duplicate medication with same batch
    SELECT COUNT(*) INTO v_duplicate_count
    FROM Medications
    WHERE medication_name = p_medication_name 
      AND batch_number = p_batch_number 
      AND supplier = p_supplier;
    
    IF v_duplicate_count > 0 THEN
        SET p_result_message = 'Medication with same name, batch number, and supplier already exists';
        SET p_medication_id = -1;
        ROLLBACK;
    END IF;
    
    -- Insert new medication
    INSERT INTO Medications (
        medication_name, generic_name, brand_name, manufacturer, dosage_form,
        strength, unit_price, stock_quantity, minimum_stock_level, expiry_date,
        batch_number, supplier, ndc_number, controlled_substance, controlled_schedule,
        purchase_date, last_restocked_date
    ) VALUES (
        p_medication_name, p_generic_name, p_brand_name, p_manufacturer, p_dosage_form,
        p_strength, p_unit_price, p_stock_quantity, p_minimum_stock_level, p_expiry_date,
        p_batch_number, p_supplier, p_ndc_number, p_controlled_substance, p_controlled_schedule,
        CURDATE(), CURDATE()
    );
    
    SET p_medication_id = LAST_INSERT_ID();
    SET p_result_message = 'Medication added to inventory successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to update medication stock
DELIMITER //
CREATE PROCEDURE UpdateMedicationStock(
    IN p_medication_id INT,
    IN p_quantity_change INT, -- Positive for restock, negative for dispensing
    IN p_reason VARCHAR(200),
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_current_stock INT DEFAULT 0;
    DECLARE v_new_stock INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get current stock level
    SELECT stock_quantity INTO v_current_stock
    FROM Medications
    WHERE medication_id = p_medication_id;
    
    IF v_current_stock IS NULL THEN
        SET p_result_message = 'Medication not found';
        ROLLBACK;
    END IF;
    
    SET v_new_stock = v_current_stock + p_quantity_change;
    
    -- Prevent negative stock
    IF v_new_stock < 0 THEN
        SET p_result_message = CONCAT('Insufficient stock. Current: ', v_current_stock, ', Requested: ', ABS(p_quantity_change));
        ROLLBACK;
    END IF;
    
    -- Update stock quantity
    UPDATE Medications
    SET stock_quantity = v_new_stock,
        last_restocked_date = CASE WHEN p_quantity_change > 0 THEN CURDATE() ELSE last_restocked_date END,
        updated_date = CURRENT_TIMESTAMP
    WHERE medication_id = p_medication_id;
    
    -- Log the stock change
    INSERT INTO Medication_Stock_Log (
        medication_id, quantity_change, previous_stock, new_stock, reason, change_date
    ) VALUES (
        p_medication_id, p_quantity_change, v_current_stock, v_new_stock, p_reason, CURRENT_TIMESTAMP
    );
    
    SET p_result_message = CONCAT('Stock updated successfully. New quantity: ', v_new_stock);
    
    COMMIT;
END//
DELIMITER ;

-- Create Medication_Stock_Log table for audit trail
CREATE TABLE Medication_Stock_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    medication_id INT NOT NULL,
    quantity_change INT NOT NULL,
    previous_stock INT NOT NULL,
    new_stock INT NOT NULL,
    reason VARCHAR(200),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by INT,
    
    FOREIGN KEY (medication_id) REFERENCES Medications(medication_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL
);

-- Create index for stock log
CREATE INDEX idx_medication_stock_log_date ON Medication_Stock_Log(change_date);
CREATE INDEX idx_medication_stock_log_med ON Medication_Stock_Log(medication_id, change_date);

-- Create a view for low stock medications
CREATE VIEW Low_Stock_Medications AS
SELECT 
    m.medication_id,
    m.medication_name,
    m.generic_name,
    m.dosage_form,
    m.strength,
    m.stock_quantity,
    m.minimum_stock_level,
    (m.minimum_stock_level - m.stock_quantity) AS shortage_quantity,
    m.supplier,
    m.supplier_contact,
    m.unit_price,
    (m.minimum_stock_level - m.stock_quantity) * m.unit_price AS reorder_cost,
    m.expiry_date,
    DATEDIFF(m.expiry_date, CURDATE()) AS days_to_expiry
FROM Medications m
WHERE m.stock_quantity <= m.minimum_stock_level
ORDER BY m.stock_quantity ASC, m.expiry_date ASC;

-- Create a view for expired medications
CREATE VIEW Expired_Medications AS
SELECT 
    m.medication_id,
    m.medication_name,
    m.generic_name,
    m.batch_number,
    m.stock_quantity,
    m.expiry_date,
    DATEDIFF(CURDATE(), m.expiry_date) AS days_expired,
    m.unit_price,
    (m.stock_quantity * m.unit_price) AS loss_value,
    m.supplier
FROM Medications m
WHERE m.expiry_date <= CURDATE()
  AND m.stock_quantity > 0
ORDER BY m.expiry_date ASC;

-- Display table structures
DESCRIBE Medications;
DESCRIBE Medication_Alerts;
DESCRIBE Medication_Stock_Log;

-- Show created views and procedures
SHOW CREATE VIEW Low_Stock_Medications;
SHOW CREATE VIEW Expired_Medications;
SHOW PROCEDURE STATUS WHERE Name IN ('AddMedicationToInventory', 'UpdateMedicationStock');

-- Confirmation message
SELECT 'Medications inventory table created successfully with comprehensive tracking!' AS Status;