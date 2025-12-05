-- Hospital Management System - Departments and Medical Staff Tables
-- This script creates the Departments and Medical_Staff tables with organizational structure

USE hospital_management_system;

-- Create Departments table first (referenced by Medical_Staff)
CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_head_id INT,
    location VARCHAR(100),
    phone VARCHAR(15),
    description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints for data validation
    CONSTRAINT chk_dept_phone CHECK (phone REGEXP '^[0-9+\-\s()]+$' OR phone IS NULL)
);

-- Create Medical_Staff table with foreign key to Departments
CREATE TABLE Medical_Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('Doctor', 'Nurse', 'Technician', 'Administrator') NOT NULL,
    specialization VARCHAR(100),
    department_id INT,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    hire_date DATE NOT NULL,
    license_number VARCHAR(50) UNIQUE,
    license_expiry_date DATE,
    salary DECIMAL(10,2),
    status ENUM('Active', 'Inactive', 'On Leave') DEFAULT 'Active',
    
    -- Foreign key constraint
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_staff_hire_date CHECK (hire_date <= CURDATE()),
    CONSTRAINT chk_staff_license_expiry CHECK (license_expiry_date IS NULL OR license_expiry_date > hire_date),
    CONSTRAINT chk_staff_phone CHECK (phone REGEXP '^[0-9+\-\s()]+$' OR phone IS NULL),
    CONSTRAINT chk_staff_email CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL),
    CONSTRAINT chk_staff_salary CHECK (salary IS NULL OR salary >= 0)
);

-- Add foreign key constraint for department head (self-referencing)
ALTER TABLE Departments 
ADD CONSTRAINT fk_dept_head 
FOREIGN KEY (department_head_id) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE;

-- Create indexes for performance
CREATE INDEX idx_dept_name ON Departments(department_name);
CREATE INDEX idx_staff_department ON Medical_Staff(department_id);
CREATE INDEX idx_staff_name ON Medical_Staff(last_name, first_name);
CREATE INDEX idx_staff_role ON Medical_Staff(role);
CREATE INDEX idx_staff_status ON Medical_Staff(status);
CREATE INDEX idx_staff_license_expiry ON Medical_Staff(license_expiry_date);

-- Display table structures
DESCRIBE Departments;
DESCRIBE Medical_Staff;

-- Confirmation message
SELECT 'Departments and Medical_Staff tables created successfully with organizational structure!' AS Status;