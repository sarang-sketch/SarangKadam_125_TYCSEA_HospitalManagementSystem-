<?php
/**
 * Doctor Dashboard
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['doctor']);

$pageTitle = 'Doctor Dashboard';
$pdo = getConnection();
$doctorId = getCurrentUserId();

// Stats
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM appointments WHERE doctor_id = ? AND appointment_date = CURDATE()");
$stmt->execute([$doctorId]);
$todayAppointments = $stmt->fetch()['count'];

$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM prescriptions WHERE doctor_id = ? AND status = 'pending'");
$stmt->execute([$doctorId]);
$pendingPrescriptions = $stmt->fetch()['count'];

$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM lab_tests WHERE doctor_id = ? AND status = 'completed' AND result_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
$stmt->execute([$doctorId]);
$recentLabResults = $stmt->fetch()['count'];

// Today's appointments
$stmt = $pdo->prepare("
    SELECT a.*, p.name as patient_name, p.patient_code, p.age, p.gender 
    FROM appointments a 
    JOIN patients p ON a.patient_id = p.id 
    WHERE a.doctor_id = ? AND a.appointment_date = CURDATE()
    ORDER BY a.appointment_time
");
$stmt->execute([$doctorId]);
$appointments = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1><i class="fas fa-tachometer-alt me-2"></i>Doctor Dashboard</h1>
</div>

<div class="row mb-4">
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-primary">
            <i class="fas fa-calendar-check stat-icon"></i>
            <h3><?= $todayAppointments ?></h3>
            <p>Today's Appointments</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-warning">
            <i class="fas fa-prescription stat-icon"></i>
            <h3><?= $pendingPrescriptions ?></h3>
            <p>Pending Prescriptions</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-success">
            <i class="fas fa-flask stat-icon"></i>
            <h3><?= $recentLabResults ?></h3>
            <p>Recent Lab Results</p>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0"><i class="fas fa-calendar-day me-2"></i>Today's Appointments</h5>
        <a href="appointments.php" class="btn btn-sm btn-outline-primary">View All</a>
    </div>
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Time</th><th>Patient</th><th>Age/Gender</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($appointments)): ?>
                    <tr><td colspan="5" class="text-center text-muted py-3">No appointments today</td></tr>
                <?php else: ?>
                    <?php foreach ($appointments as $apt): ?>
                        <tr>
                            <td><?= formatTime($apt['appointment_time']) ?></td>
                            <td>
                                <strong><?= htmlspecialchars($apt['patient_name']) ?></strong><br>
                                <small class="text-muted"><?= htmlspecialchars($apt['patient_code']) ?></small>
                            </td>
                            <td><?= $apt['age'] ?>y / <?= ucfirst($apt['gender']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($apt['status']) ?>"><?= ucfirst($apt['status']) ?></span></td>
                            <td>
                                <a href="prescription_form.php?patient_id=<?= $apt['patient_id'] ?>" class="btn btn-sm btn-outline-primary">
                                    <i class="fas fa-prescription"></i> Prescribe
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
