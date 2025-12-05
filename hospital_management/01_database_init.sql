-- Hospital Management System Database Initialization Script
-- This script creates the HMS database with proper configuration

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS hospital_management_system;

-- Use the database
USE hospital_management_system;

-- Set character encoding and collation for proper data handling
ALTER DATABASE hospital_management_system 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Display confirmation message
SELECT 'Hospital Management System database created successfully!' AS Status;

-- Show database information
SHOW CREATE DATABASE hospital_management_system;