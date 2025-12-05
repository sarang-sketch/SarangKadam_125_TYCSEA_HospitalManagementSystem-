<?php
/**
 * Authentication Check Module
 * Hospital Management System
 * 
 * Include this file at the top of protected pages
 */

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Check if user is logged in
 * 
 * @return bool True if logged in
 */
function isLoggedIn() {
    return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
}

/**
 * Require user to be logged in
 * Redirects to login page if not authenticated
 */
function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: /hospital_management/auth/login.php');
        exit;
    }
}

/**
 * Require specific role(s) for access
 * Redirects to access denied page if role not allowed
 * 
 * @param array|string $allowed_roles Single role or array of allowed roles
 */
function requireRole($allowed_roles) {
    requireLogin();
    
    if (!is_array($allowed_roles)) {
        $allowed_roles = [$allowed_roles];
    }
    
    if (!in_array($_SESSION['role'], $allowed_roles)) {
        header('Location: /hospital_management/access_denied.php');
        exit;
    }
}

/**
 * Get current logged in user data
 * 
 * @return array User data array
 */
function getCurrentUser() {
    return [
        'id' => $_SESSION['user_id'] ?? null,
        'name' => $_SESSION['user_name'] ?? null,
        'role' => $_SESSION['role'] ?? null,
        'email' => $_SESSION['email'] ?? null
    ];
}

/**
 * Get current user ID
 * 
 * @return int|null User ID or null
 */
function getCurrentUserId() {
    return $_SESSION['user_id'] ?? null;
}

/**
 * Get current user role
 * 
 * @return string|null User role or null
 */
function getCurrentUserRole() {
    return $_SESSION['role'] ?? null;
}

/**
 * Get current user name
 * 
 * @return string|null User name or null
 */
function getCurrentUserName() {
    return $_SESSION['user_name'] ?? null;
}

/**
 * Check if current user has specific role
 * 
 * @param string $role Role to check
 * @return bool True if user has role
 */
function hasRole($role) {
    return isset($_SESSION['role']) && $_SESSION['role'] === $role;
}

/**
 * Check if current user is admin
 * 
 * @return bool True if admin
 */
function isAdmin() {
    return hasRole('admin');
}

/**
 * Check if current user is doctor
 * 
 * @return bool True if doctor
 */
function isDoctor() {
    return hasRole('doctor');
}

/**
 * Check if current user is nurse
 * 
 * @return bool True if nurse
 */
function isNurse() {
    return hasRole('nurse');
}

/**
 * Check if current user is receptionist
 * 
 * @return bool True if receptionist
 */
function isReceptionist() {
    return hasRole('receptionist');
}

/**
 * Check if current user is lab technician
 * 
 * @return bool True if lab technician
 */
function isLabTech() {
    return hasRole('lab');
}

/**
 * Check if current user is pharmacist
 * 
 * @return bool True if pharmacist
 */
function isPharmacist() {
    return hasRole('pharmacist');
}

/**
 * Get dashboard URL based on user role
 * 
 * @return string Dashboard URL
 */
function getDashboardUrl() {
    $role = getCurrentUserRole();
    $base = '/hospital_management';
    
    switch ($role) {
        case 'admin':
            return $base . '/admin/index.php';
        case 'doctor':
            return $base . '/doctor/index.php';
        case 'nurse':
            return $base . '/nurse/index.php';
        case 'receptionist':
            return $base . '/receptionist/index.php';
        case 'lab':
            return $base . '/lab/index.php';
        case 'pharmacist':
            return $base . '/pharmacist/index.php';
        default:
            return $base . '/auth/login.php';
    }
}

/**
 * Get role display name
 * 
 * @param string $role Role key
 * @return string Display name
 */
function getRoleDisplayName($role) {
    $roles = [
        'admin' => 'Administrator',
        'doctor' => 'Doctor',
        'nurse' => 'Nurse',
        'receptionist' => 'Receptionist',
        'lab' => 'Lab Technician',
        'pharmacist' => 'Pharmacist',
        'patient' => 'Patient'
    ];
    return $roles[$role] ?? ucfirst($role);
}
