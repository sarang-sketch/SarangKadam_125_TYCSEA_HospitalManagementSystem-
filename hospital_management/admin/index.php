<?php
/**
 * Admin Dashboard
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin']);

$pageTitle = 'Admin Dashboard';
$pdo = getConnection();

// Get statistics
$stats = [];

// Total patients
$stmt = $pdo->query("SELECT COUNT(*) as count FROM patients");
$stats['total_patients'] = $stmt->fetch()['count'];

// Today's appointments
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM appointments WHERE appointment_date = CURDATE()");
$stmt->execute();
$stats['today_appointments'] = $stmt->fetch()['count'];

// Admitted patients
$stmt = $pdo->query("SELECT COUNT(*) as count FROM admissions WHERE status = 'admitted'");
$stats['admitted_patients'] = $stmt->fetch()['count'];

// Available beds
$stmt = $pdo->query("SELECT SUM(total_beds) as total FROM wards");
$totalBeds = $stmt->fetch()['total'] ?? 0;
$stmt = $pdo->query("SELECT COUNT(*) as occupied FROM admissions WHERE status = 'admitted'");
$occupiedBeds = $stmt->fetch()['occupied'];
$stats['available_beds'] = $totalBeds - $occupiedBeds;

// Pending lab reports
$stmt = $pdo->query("SELECT COUNT(*) as count FROM lab_tests WHERE status != 'completed'");
$stats['pending_labs'] = $stmt->fetch()['count'];

// Unpaid bills total
$stmt = $pdo->query("SELECT COALESCE(SUM(total_amount + tax_amount), 0) as total FROM bills WHERE status = 'unpaid'");
$stats['unpaid_bills'] = $stmt->fetch()['total'];

// Recent appointments
$stmt = $pdo->query("
    SELECT a.*, p.name as patient_name, u.name as doctor_name 
    FROM appointments a 
    JOIN patients p ON a.patient_id = p.id 
    JOIN users u ON a.doctor_id = u.id 
    ORDER BY a.appointment_date DESC, a.appointment_time DESC 
    LIMIT 5
");
$recentAppointments = $stmt->fetchAll();

// Recent admissions
$stmt = $pdo->query("
    SELECT ad.*, p.name as patient_name, u.name as doctor_name, w.ward_name 
    FROM admissions ad 
    JOIN patients p ON ad.patient_id = p.id 
    JOIN users u ON ad.doctor_id = u.id 
    JOIN wards w ON ad.ward_id = w.id 
    WHERE ad.status = 'admitted'
    ORDER BY ad.admission_date DESC 
    LIMIT 5
");
$recentAdmissions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-tachometer-alt me-2"></i>Admin Dashboard</h1>
    <span class="text-muted"><?= date('l, F j, Y') ?></span>
</div>

<!-- Stats Cards -->
<div class="row mb-4">
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-primary">
            <i class="fas fa-users stat-icon"></i>
            <h3><?= number_format($stats['total_patients']) ?></h3>
            <p>Total Patients</p>
        </div>
    </div>
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-success">
            <i class="fas fa-calendar-check stat-icon"></i>
            <h3><?= number_format($stats['today_appointments']) ?></h3>
            <p>Today's Appointments</p>
        </div>
    </div>
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-info">
            <i class="fas fa-procedures stat-icon"></i>
            <h3><?= number_format($stats['admitted_patients']) ?></h3>
            <p>Admitted Patients</p>
        </div>
    </div>
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-warning">
            <i class="fas fa-bed stat-icon"></i>
            <h3><?= number_format($stats['available_beds']) ?></h3>
            <p>Available Beds</p>
        </div>
    </div>
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-secondary">
            <i class="fas fa-flask stat-icon"></i>
            <h3><?= number_format($stats['pending_labs']) ?></h3>
            <p>Pending Lab Tests</p>
        </div>
    </div>
    <div class="col-md-4 col-lg-2 mb-3">
        <div class="stat-card bg-danger">
            <i class="fas fa-file-invoice-dollar stat-icon"></i>
            <h3><?= formatCurrency($stats['unpaid_bills']) ?></h3>
            <p>Unpaid Bills</p>
        </div>
    </div>
</div>

<div class="row">
    <!-- Recent Appointments -->
    <div class="col-lg-6 mb-4">
        <div class="card">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="fas fa-calendar-alt me-2"></i>Recent Appointments</h5>
                <a href="/hospital_management/receptionist/appointments.php" class="btn btn-sm btn-outline-primary">View All</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Patient</th>
                                <th>Doctor</th>
                                <th>Date</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($recentAppointments)): ?>
                                <tr><td colspan="4" class="text-center text-muted py-3">No appointments found</td></tr>
                            <?php else: ?>
                                <?php foreach ($recentAppointments as $apt): ?>
                                    <tr>
                                        <td><?= htmlspecialchars($apt['patient_name']) ?></td>
                                        <td><?= htmlspecialchars($apt['doctor_name']) ?></td>
                                        <td><?= formatDate($apt['appointment_date']) ?></td>
                                        <td>
                                            <span class="badge bg-<?= getStatusBadge($apt['status']) ?>">
                                                <?= ucfirst($apt['status']) ?>
                                            </span>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Current Admissions -->
    <div class="col-lg-6 mb-4">
        <div class="card">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="fas fa-procedures me-2"></i>Current Admissions</h5>
                <a href="/hospital_management/receptionist/admissions.php" class="btn btn-sm btn-outline-primary">View All</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Patient</th>
                                <th>Ward</th>
                                <th>Bed</th>
                                <th>Admitted</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($recentAdmissions)): ?>
                                <tr><td colspan="4" class="text-center text-muted py-3">No current admissions</td></tr>
                            <?php else: ?>
                                <?php foreach ($recentAdmissions as $adm): ?>
                                    <tr>
                                        <td><?= htmlspecialchars($adm['patient_name']) ?></td>
                                        <td><?= htmlspecialchars($adm['ward_name']) ?></td>
                                        <td><?= htmlspecialchars($adm['bed_number']) ?></td>
                                        <td><?= formatDate($adm['admission_date']) ?></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
