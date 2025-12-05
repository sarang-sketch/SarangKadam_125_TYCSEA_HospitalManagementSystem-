-- Hospital Management System - Patients Table Creation
-- This script creates the Patients table with all required fields and validation constraints

USE hospital_management_system;

-- Create Patients table with comprehensive validation
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    address TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(15),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Active', 'Inactive', 'Deceased') DEFAULT 'Active',
    
    -- Constraints for data validation
    CONSTRAINT chk_patient_dob CHECK (date_of_birth <= CURDATE()),
    CONSTRAINT chk_patient_phone CHECK (phone REGEXP '^[0-9+\-\s()]+$' OR phone IS NULL),
    CONSTRAINT chk_patient_email CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL),
    CONSTRAINT chk_emergency_phone CHECK (emergency_contact_phone REGEXP '^[0-9+\-\s()]+$' OR emergency_contact_phone IS NULL),
    
    -- Unique constraints to prevent duplicates
    UNIQUE KEY unique_patient_email (email),
    UNIQUE KEY unique_insurance_policy (insurance_provider, insurance_policy_number)
);

-- Create index for efficient patient name searches
CREATE INDEX idx_patient_name ON Patients(last_name, first_name);
CREATE INDEX idx_patient_registration_date ON Patients(registration_date);
CREATE INDEX idx_patient_status ON Patients(status);

-- Display table structure
DESCRIBE Patients;

-- Confirmation message
SELECT 'Patients table created successfully with validation constraints!' AS Status;