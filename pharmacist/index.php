<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['pharmacist']);

$pageTitle = 'Pharmacist Dashboard';
$pdo = getConnection();

$stmt = $pdo->query("SELECT COUNT(*) as count FROM prescriptions WHERE status = 'pending'");
$pendingPrescriptions = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM medicines WHERE quantity < 20");
$lowStock = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM medicines WHERE expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)");
$expiringSoon = $stmt->fetch()['count'];

$stmt = $pdo->query("
    SELECT pr.*, p.name as patient_name, u.name as doctor_name 
    FROM prescriptions pr JOIN patients p ON pr.patient_id = p.id JOIN users u ON pr.doctor_id = u.id 
    WHERE pr.status = 'pending' ORDER BY pr.created_at DESC LIMIT 10
");
$prescriptions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-tachometer-alt me-2"></i>Pharmacist Dashboard</h1></div>

<div class="row mb-4">
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-warning">
            <i class="fas fa-prescription stat-icon"></i>
            <h3><?= $pendingPrescriptions ?></h3>
            <p>Pending Prescriptions</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-danger">
            <i class="fas fa-exclamation-triangle stat-icon"></i>
            <h3><?= $lowStock ?></h3>
            <p>Low Stock Items</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-info">
            <i class="fas fa-calendar-times stat-icon"></i>
            <h3><?= $expiringSoon ?></h3>
            <p>Expiring Soon</p>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0"><i class="fas fa-prescription me-2"></i>Pending Prescriptions</h5>
        <a href="prescriptions.php" class="btn btn-sm btn-outline-primary">View All</a>
    </div>
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Date</th><th>Patient</th><th>Doctor</th><th>Actions</th></tr></thead>
            <tbody>
                <?php foreach ($prescriptions as $pr): ?>
                    <tr>
                        <td><?= formatDate($pr['visit_date']) ?></td>
                        <td><strong><?= htmlspecialchars($pr['patient_name']) ?></strong></td>
                        <td><?= htmlspecialchars($pr['doctor_name']) ?></td>
                        <td>
                            <a href="/hospital_management/doctor/prescription_view.php?id=<?= $pr['id'] ?>" class="btn btn-sm btn-outline-info"><i class="fas fa-eye"></i></a>
                            <a href="prescriptions.php?dispense=<?= $pr['id'] ?>" class="btn btn-sm btn-outline-success" onclick="return confirm('Mark as dispensed?')"><i class="fas fa-check"></i> Dispense</a>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
