-- Hospital Management System - Rooms Table
-- This script creates the Rooms table with capacity and occupancy management

USE hospital_management_system;

-- Create Rooms table with occupancy management
CREATE TABLE Rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    room_type ENUM('General', 'Private', 'ICU', 'Emergency', 'Operating') NOT NULL,
    department_id INT,
    capacity INT DEFAULT 1,
    current_occupancy INT DEFAULT 0,
    daily_rate DECIMAL(8,2),
    status ENUM('Available', 'Occupied', 'Maintenance', 'Reserved') DEFAULT 'Available',
    equipment_list TEXT,
    last_maintenance_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_room_capacity CHECK (capacity > 0),
    CONSTRAINT chk_room_occupancy CHECK (current_occupancy >= 0 AND current_occupancy <= capacity),
    CONSTRAINT chk_room_daily_rate CHECK (daily_rate IS NULL OR daily_rate >= 0),
    CONSTRAINT chk_room_maintenance_date CHECK (last_maintenance_date IS NULL OR last_maintenance_date <= CURDATE())
);

-- Create indexes for performance
CREATE INDEX idx_room_number ON Rooms(room_number);
CREATE INDEX idx_room_type ON Rooms(room_type);
CREATE INDEX idx_room_department ON Rooms(department_id);
CREATE INDEX idx_room_status ON Rooms(status);
CREATE INDEX idx_room_occupancy ON Rooms(current_occupancy, capacity);

-- Create a trigger to automatically update room status based on occupancy
DELIMITER //
CREATE TRIGGER trg_room_status_update 
BEFORE UPDATE ON Rooms
FOR EACH ROW
BEGIN
    -- Auto-update status based on occupancy (unless manually set to Maintenance)
    IF NEW.status != 'Maintenance' THEN
        IF NEW.current_occupancy = 0 THEN
            SET NEW.status = 'Available';
        ELSEIF NEW.current_occupancy = NEW.capacity THEN
            SET NEW.status = 'Occupied';
        ELSEIF NEW.current_occupancy > 0 AND NEW.current_occupancy < NEW.capacity THEN
            SET NEW.status = 'Occupied';
        END IF;
    END IF;
END//
DELIMITER ;

-- Create a procedure to check room availability
DELIMITER //
CREATE PROCEDURE CheckRoomAvailability(
    IN p_room_type ENUM('General', 'Private', 'ICU', 'Emergency', 'Operating'),
    IN p_department_id INT
)
BEGIN
    SELECT 
        room_id,
        room_number,
        room_type,
        capacity,
        current_occupancy,
        (capacity - current_occupancy) AS available_beds,
        status,
        daily_rate
    FROM Rooms 
    WHERE (p_room_type IS NULL OR room_type = p_room_type)
      AND (p_department_id IS NULL OR department_id = p_department_id)
      AND status IN ('Available', 'Occupied')
      AND current_occupancy < capacity
    ORDER BY room_type, room_number;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Rooms;

-- Show created triggers and procedures
SHOW TRIGGERS LIKE 'Rooms';
SHOW PROCEDURE STATUS WHERE Name = 'CheckRoomAvailability';

-- Confirmation message
SELECT 'Rooms table created successfully with occupancy management and triggers!' AS Status;