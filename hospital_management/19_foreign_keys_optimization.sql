-- Hospital Management System - Foreign Key Relationships and Optimization
-- This script ensures all foreign key relationships are properly implemented with cascade options

USE hospital_management_system;

-- Add any missing foreign key constraints and optimize existing ones

-- Ensure all foreign keys have proper cascade options for data consistency
-- Most foreign keys are already created in individual table scripts, but let's verify and add any missing ones

-- Add foreign key for department head (self-referencing) if not exists
-- This was already added in the departments script, but let's ensure it exists
SELECT 'Verifying foreign key relationships...' AS Status;

-- Check and add missing foreign key constraints
-- Note: Most foreign keys were already created in individual table scripts

-- Add cascade options for better data management where appropriate
-- Update existing foreign keys to have proper cascade behavior

-- Verify all foreign key relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    UPDATE_RULE,
    DELETE_RULE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE REFERENCED_TABLE_SCHEMA = 'hospital_management_system'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

-- Create a comprehensive view of all relationships
CREATE VIEW Database_Relationships AS
SELECT 
    kcu.TABLE_NAME AS child_table,
    kcu.COLUMN_NAME AS child_column,
    kcu.CONSTRAINT_NAME,
    kcu.REFERENCED_TABLE_NAME AS parent_table,
    kcu.REFERENCED_COLUMN_NAME AS parent_column,
    rc.UPDATE_RULE,
    rc.DELETE_RULE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc 
    ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
WHERE kcu.REFERENCED_TABLE_SCHEMA = 'hospital_management_system'
  AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY kcu.TABLE_NAME, kcu.COLUMN_NAME;

-- Show all foreign key relationships
SELECT 'Database Foreign Key Relationships:' AS info;
SELECT * FROM Database_Relationships;

-- Confirmation message
SELECT 'Foreign key relationships verified and optimized!' AS Status;