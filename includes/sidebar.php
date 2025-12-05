<?php
/**
 * Sidebar Navigation Component
 * Hospital Management System
 * 
 * Shows role-based navigation menu
 */

$role = getCurrentUserRole();
$currentPage = basename($_SERVER['PHP_SELF']);
$currentDir = basename(dirname($_SERVER['PHP_SELF']));

// Define menu items for each role
$menuItems = [
    'admin' => [
        ['url' => '/hospital_management/admin/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'admin', 'page' => 'index.php'],
        ['url' => '/hospital_management/admin/users.php', 'icon' => 'fa-users-cog', 'label' => 'User Management', 'dir' => 'admin', 'page' => 'users.php'],
        ['url' => '/hospital_management/admin/wards.php', 'icon' => 'fa-bed', 'label' => 'Ward Management', 'dir' => 'admin', 'page' => 'wards.php'],
        ['url' => '/hospital_management/receptionist/patients.php', 'icon' => 'fa-user-injured', 'label' => 'Patients', 'dir' => 'receptionist', 'page' => 'patients.php'],
        ['url' => '/hospital_management/receptionist/appointments.php', 'icon' => 'fa-calendar-check', 'label' => 'Appointments', 'dir' => 'receptionist', 'page' => 'appointments.php'],
        ['url' => '/hospital_management/receptionist/admissions.php', 'icon' => 'fa-procedures', 'label' => 'Admissions', 'dir' => 'receptionist', 'page' => 'admissions.php'],
        ['url' => '/hospital_management/billing/bills.php', 'icon' => 'fa-file-invoice-dollar', 'label' => 'Billing', 'dir' => 'billing', 'page' => 'bills.php'],
        ['url' => '/hospital_management/pharmacist/inventory.php', 'icon' => 'fa-pills', 'label' => 'Pharmacy', 'dir' => 'pharmacist', 'page' => 'inventory.php'],
    ],
    'doctor' => [
        ['url' => '/hospital_management/doctor/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'doctor', 'page' => 'index.php'],
        ['url' => '/hospital_management/doctor/appointments.php', 'icon' => 'fa-calendar-check', 'label' => 'My Appointments', 'dir' => 'doctor', 'page' => 'appointments.php'],
        ['url' => '/hospital_management/doctor/prescriptions.php', 'icon' => 'fa-prescription', 'label' => 'Prescriptions', 'dir' => 'doctor', 'page' => 'prescriptions.php'],
        ['url' => '/hospital_management/doctor/lab_requests.php', 'icon' => 'fa-flask', 'label' => 'Lab Requests', 'dir' => 'doctor', 'page' => 'lab_requests.php'],
        ['url' => '/hospital_management/receptionist/patients.php', 'icon' => 'fa-user-injured', 'label' => 'Patients', 'dir' => 'receptionist', 'page' => 'patients.php'],
    ],
    'nurse' => [
        ['url' => '/hospital_management/nurse/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'nurse', 'page' => 'index.php'],
        ['url' => '/hospital_management/receptionist/admissions.php', 'icon' => 'fa-procedures', 'label' => 'Admissions', 'dir' => 'receptionist', 'page' => 'admissions.php'],
        ['url' => '/hospital_management/nurse/patient_care.php', 'icon' => 'fa-notes-medical', 'label' => 'Patient Care', 'dir' => 'nurse', 'page' => 'patient_care.php'],
        ['url' => '/hospital_management/receptionist/patients.php', 'icon' => 'fa-user-injured', 'label' => 'Patients', 'dir' => 'receptionist', 'page' => 'patients.php'],
    ],
    'receptionist' => [
        ['url' => '/hospital_management/receptionist/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'receptionist', 'page' => 'index.php'],
        ['url' => '/hospital_management/receptionist/patients.php', 'icon' => 'fa-user-injured', 'label' => 'Patients', 'dir' => 'receptionist', 'page' => 'patients.php'],
        ['url' => '/hospital_management/receptionist/appointments.php', 'icon' => 'fa-calendar-check', 'label' => 'Appointments', 'dir' => 'receptionist', 'page' => 'appointments.php'],
        ['url' => '/hospital_management/receptionist/admissions.php', 'icon' => 'fa-procedures', 'label' => 'Admissions', 'dir' => 'receptionist', 'page' => 'admissions.php'],
        ['url' => '/hospital_management/billing/bills.php', 'icon' => 'fa-file-invoice-dollar', 'label' => 'Billing', 'dir' => 'billing', 'page' => 'bills.php'],
    ],
    'lab' => [
        ['url' => '/hospital_management/lab/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'lab', 'page' => 'index.php'],
        ['url' => '/hospital_management/lab/tests.php', 'icon' => 'fa-flask', 'label' => 'Lab Tests', 'dir' => 'lab', 'page' => 'tests.php'],
        ['url' => '/hospital_management/receptionist/patients.php', 'icon' => 'fa-user-injured', 'label' => 'Patients', 'dir' => 'receptionist', 'page' => 'patients.php'],
    ],
    'pharmacist' => [
        ['url' => '/hospital_management/pharmacist/index.php', 'icon' => 'fa-tachometer-alt', 'label' => 'Dashboard', 'dir' => 'pharmacist', 'page' => 'index.php'],
        ['url' => '/hospital_management/pharmacist/prescriptions.php', 'icon' => 'fa-prescription', 'label' => 'Prescriptions', 'dir' => 'pharmacist', 'page' => 'prescriptions.php'],
        ['url' => '/hospital_management/pharmacist/inventory.php', 'icon' => 'fa-pills', 'label' => 'Inventory', 'dir' => 'pharmacist', 'page' => 'inventory.php'],
    ],
];

$items = $menuItems[$role] ?? [];
?>

<!-- Sidebar -->
<nav class="sidebar bg-dark">
    <div class="sidebar-header">
        <h5 class="text-white mb-0">
            <i class="fas fa-hospital-user me-2"></i>
            <?= getRoleDisplayName($role) ?>
        </h5>
    </div>
    
    <ul class="nav flex-column">
        <?php foreach ($items as $item): 
            $isActive = ($currentDir === $item['dir'] && $currentPage === $item['page']);
        ?>
            <li class="nav-item">
                <a class="nav-link <?= $isActive ? 'active' : '' ?>" href="<?= $item['url'] ?>">
                    <i class="fas <?= $item['icon'] ?> me-2"></i>
                    <?= $item['label'] ?>
                </a>
            </li>
        <?php endforeach; ?>
    </ul>
</nav>
