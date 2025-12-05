-- Hospital Management System - Payments Table
-- This script creates the Payments table for comprehensive transaction tracking

USE hospital_management_system;

-- Create Payments table for transaction tracking
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    bill_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount_paid DECIMAL(12,2) NOT NULL,
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Check', 'Bank Transfer', 'Insurance', 'Online Payment', 'Mobile Payment') NOT NULL,
    transaction_reference VARCHAR(100),
    check_number VARCHAR(50),
    card_last_four VARCHAR(4),
    authorization_code VARCHAR(50),
    payment_status ENUM('Pending', 'Completed', 'Failed', 'Cancelled', 'Refunded', 'Disputed') DEFAULT 'Completed',
    payment_processor VARCHAR(100), -- Stripe, PayPal, etc.
    processor_transaction_id VARCHAR(100),
    refund_amount DECIMAL(12,2) DEFAULT 0,
    refund_date TIMESTAMP NULL,
    refund_reason TEXT,
    notes TEXT,
    received_by INT, -- Staff member who processed the payment
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (bill_id) REFERENCES Billing(bill_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (received_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_payment_amount CHECK (amount_paid > 0),
    CONSTRAINT chk_payment_refund CHECK (refund_amount >= 0 AND refund_amount <= amount_paid),
    CONSTRAINT chk_payment_check_number CHECK (
        (payment_method = 'Check' AND check_number IS NOT NULL) OR 
        (payment_method != 'Check')
    ),
    CONSTRAINT chk_payment_card_info CHECK (
        (payment_method IN ('Credit Card', 'Debit Card') AND card_last_four IS NOT NULL) OR 
        (payment_method NOT IN ('Credit Card', 'Debit Card'))
    )
);

-- Create indexes for performance
CREATE INDEX idx_payments_bill ON Payments(bill_id, payment_date DESC);
CREATE INDEX idx_payments_date ON Payments(payment_date);
CREATE INDEX idx_payments_method ON Payments(payment_method);
CREATE INDEX idx_payments_status ON Payments(payment_status);
CREATE INDEX idx_payments_reference ON Payments(transaction_reference);
CREATE INDEX idx_payments_processor_id ON Payments(processor_transaction_id);
CREATE INDEX idx_payments_received_by ON Payments(received_by);

-- Create a trigger to update bill payment status when payments are added
DELIMITER //
CREATE TRIGGER trg_update_bill_payment_status
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    DECLARE v_total_paid DECIMAL(12,2) DEFAULT 0;
    DECLARE v_bill_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_new_status VARCHAR(20) DEFAULT 'Pending';
    
    -- Only process if payment is completed
    IF NEW.payment_status = 'Completed' THEN
        -- Get total amount paid for this bill
        SELECT COALESCE(SUM(amount_paid - refund_amount), 0) INTO v_total_paid
        FROM Payments 
        WHERE bill_id = NEW.bill_id AND payment_status = 'Completed';
        
        -- Get bill final amount
        SELECT final_amount INTO v_bill_amount
        FROM Billing 
        WHERE bill_id = NEW.bill_id;
        
        -- Determine new payment status
        IF v_total_paid >= v_bill_amount THEN
            SET v_new_status = 'Paid';
        ELSEIF v_total_paid > 0 THEN
            SET v_new_status = 'Partial';
        ELSE
            SET v_new_status = 'Pending';
        END IF;
        
        -- Update bill payment status
        UPDATE Billing 
        SET payment_status = v_new_status,
            updated_date = CURRENT_TIMESTAMP
        WHERE bill_id = NEW.bill_id;
    END IF;
END//
DELIMITER ;

-- Create trigger for payment updates (refunds, status changes)
DELIMITER //
CREATE TRIGGER trg_update_bill_payment_status_on_update
AFTER UPDATE ON Payments
FOR EACH ROW
BEGIN
    DECLARE v_total_paid DECIMAL(12,2) DEFAULT 0;
    DECLARE v_bill_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_new_status VARCHAR(20) DEFAULT 'Pending';
    
    -- Recalculate if payment status or refund amount changed
    IF NEW.payment_status != OLD.payment_status OR NEW.refund_amount != OLD.refund_amount THEN
        -- Get total amount paid for this bill
        SELECT COALESCE(SUM(amount_paid - refund_amount), 0) INTO v_total_paid
        FROM Payments 
        WHERE bill_id = NEW.bill_id AND payment_status = 'Completed';
        
        -- Get bill final amount
        SELECT final_amount INTO v_bill_amount
        FROM Billing 
        WHERE bill_id = NEW.bill_id;
        
        -- Determine new payment status
        IF v_total_paid >= v_bill_amount THEN
            SET v_new_status = 'Paid';
        ELSEIF v_total_paid > 0 THEN
            SET v_new_status = 'Partial';
        ELSE
            SET v_new_status = 'Pending';
        END IF;
        
        -- Update bill payment status
        UPDATE Billing 
        SET payment_status = v_new_status,
            updated_date = CURRENT_TIMESTAMP
        WHERE bill_id = NEW.bill_id;
    END IF;
END//
DELIMITER ;

-- Create a procedure to process a payment
DELIMITER //
CREATE PROCEDURE ProcessPayment(
    IN p_bill_id INT,
    IN p_amount_paid DECIMAL(12,2),
    IN p_payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Check', 'Bank Transfer', 'Insurance', 'Online Payment', 'Mobile Payment'),
    IN p_transaction_reference VARCHAR(100),
    IN p_check_number VARCHAR(50),
    IN p_card_last_four VARCHAR(4),
    IN p_authorization_code VARCHAR(50),
    IN p_payment_processor VARCHAR(100),
    IN p_processor_transaction_id VARCHAR(100),
    IN p_notes TEXT,
    IN p_received_by INT,
    OUT p_payment_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_bill_exists INT DEFAULT 0;
    DECLARE v_outstanding_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_payment_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate bill exists and get outstanding amount
    SELECT COUNT(*), MAX(final_amount - COALESCE((
        SELECT SUM(amount_paid - refund_amount) 
        FROM Payments 
        WHERE bill_id = p_bill_id AND payment_status = 'Completed'
    ), 0))
    INTO v_bill_exists, v_outstanding_amount
    FROM Billing 
    WHERE bill_id = p_bill_id;
    
    IF v_bill_exists = 0 THEN
        SET p_result_message = 'Bill not found';
        SET p_payment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Check if payment amount is reasonable
    IF p_amount_paid > v_outstanding_amount * 1.1 THEN -- Allow 10% overpayment
        SET p_result_message = CONCAT('Payment amount exceeds outstanding balance. Outstanding: $', v_outstanding_amount);
        SET p_payment_id = -1;
        ROLLBACK;
    END IF;
    
    -- Insert the payment
    INSERT INTO Payments (
        bill_id, amount_paid, payment_method, transaction_reference,
        check_number, card_last_four, authorization_code, payment_processor,
        processor_transaction_id, notes, received_by
    ) VALUES (
        p_bill_id, p_amount_paid, p_payment_method, p_transaction_reference,
        p_check_number, p_card_last_four, p_authorization_code, p_payment_processor,
        p_processor_transaction_id, p_notes, p_received_by
    );
    
    SET p_payment_id = LAST_INSERT_ID();
    SET p_result_message = 'Payment processed successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to process a refund
DELIMITER //
CREATE PROCEDURE ProcessRefund(
    IN p_payment_id INT,
    IN p_refund_amount DECIMAL(12,2),
    IN p_refund_reason TEXT,
    IN p_processed_by INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_payment_exists INT DEFAULT 0;
    DECLARE v_original_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_current_refund DECIMAL(12,2) DEFAULT 0;
    DECLARE v_max_refund DECIMAL(12,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get payment details
    SELECT COUNT(*), MAX(amount_paid), MAX(refund_amount)
    INTO v_payment_exists, v_original_amount, v_current_refund
    FROM Payments 
    WHERE payment_id = p_payment_id AND payment_status = 'Completed';
    
    IF v_payment_exists = 0 THEN
        SET p_result_message = 'Payment not found or not completed';
        ROLLBACK;
    END IF;
    
    SET v_max_refund = v_original_amount - v_current_refund;
    
    -- Validate refund amount
    IF p_refund_amount > v_max_refund THEN
        SET p_result_message = CONCAT('Refund amount exceeds available amount. Maximum refund: $', v_max_refund);
        ROLLBACK;
    END IF;
    
    -- Process the refund
    UPDATE Payments 
    SET refund_amount = refund_amount + p_refund_amount,
        refund_date = CURRENT_TIMESTAMP,
        refund_reason = CONCAT(
            COALESCE(refund_reason, ''), 
            IF(refund_reason IS NOT NULL, '\n', ''),
            'Refund $', p_refund_amount, ': ', COALESCE(p_refund_reason, 'No reason specified')
        ),
        payment_status = IF(refund_amount + p_refund_amount = amount_paid, 'Refunded', payment_status),
        updated_date = CURRENT_TIMESTAMP
    WHERE payment_id = p_payment_id;
    
    SET p_result_message = CONCAT('Refund of $', p_refund_amount, ' processed successfully');
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for payment summary with bill and patient information
CREATE VIEW Payment_Summary AS
SELECT 
    p.payment_id,
    p.payment_date,
    b.bill_id,
    b.bill_date,
    CONCAT(pat.first_name, ' ', pat.last_name) AS patient_name,
    p.amount_paid,
    p.refund_amount,
    (p.amount_paid - p.refund_amount) AS net_payment,
    p.payment_method,
    p.transaction_reference,
    p.payment_status,
    p.payment_processor,
    CONCAT(staff.first_name, ' ', staff.last_name) AS received_by_name,
    b.final_amount AS bill_amount,
    -- Calculate remaining balance
    (b.final_amount - COALESCE((
        SELECT SUM(amount_paid - refund_amount) 
        FROM Payments p2 
        WHERE p2.bill_id = b.bill_id AND p2.payment_status = 'Completed'
    ), 0)) AS remaining_balance
FROM Payments p
JOIN Billing b ON p.bill_id = b.bill_id
JOIN Patients pat ON b.patient_id = pat.patient_id
LEFT JOIN Medical_Staff staff ON p.received_by = staff.staff_id
ORDER BY p.payment_date DESC;

-- Create a view for daily payment summary
CREATE VIEW Daily_Payment_Summary AS
SELECT 
    DATE(payment_date) AS payment_date,
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(amount_paid) AS total_collected,
    SUM(refund_amount) AS total_refunded,
    SUM(amount_paid - refund_amount) AS net_collected,
    AVG(amount_paid) AS avg_payment_amount
FROM Payments
WHERE payment_status = 'Completed'
GROUP BY DATE(payment_date), payment_method
ORDER BY payment_date DESC, payment_method;

-- Create a function to get total payments for a bill
DELIMITER //
CREATE FUNCTION GetTotalPaymentsForBill(p_bill_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_payments DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(amount_paid - refund_amount), 0) INTO v_total_payments
    FROM Payments
    WHERE bill_id = p_bill_id
      AND payment_status = 'Completed';
    
    RETURN v_total_payments;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Payments;

-- Show created views, procedures, and functions
SHOW CREATE VIEW Payment_Summary;
SHOW CREATE VIEW Daily_Payment_Summary;
SHOW PROCEDURE STATUS WHERE Name IN ('ProcessPayment', 'ProcessRefund');
SHOW FUNCTION STATUS WHERE Name = 'GetTotalPaymentsForBill';

-- Confirmation message
SELECT 'Payments table created successfully with comprehensive transaction tracking!' AS Status;