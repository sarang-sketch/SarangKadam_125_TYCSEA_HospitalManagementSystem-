<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['nurse']);

$pageTitle = 'Nurse Dashboard';
$pdo = getConnection();

$stmt = $pdo->query("SELECT COUNT(*) as count FROM admissions WHERE status = 'admitted'");
$admittedPatients = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT w.*, (SELECT COUNT(*) FROM admissions WHERE ward_id = w.id AND status = 'admitted') as occupied FROM wards w");
$wards = $stmt->fetchAll();

$stmt = $pdo->query("
    SELECT ad.*, p.name as patient_name, p.patient_code, w.ward_name, u.name as doctor_name 
    FROM admissions ad JOIN patients p ON ad.patient_id = p.id JOIN wards w ON ad.ward_id = w.id JOIN users u ON ad.doctor_id = u.id 
    WHERE ad.status = 'admitted' ORDER BY ad.admission_date DESC LIMIT 10
");
$admissions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-tachometer-alt me-2"></i>Nurse Dashboard</h1></div>

<div class="row mb-4">
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-info">
            <i class="fas fa-procedures stat-icon"></i>
            <h3><?= $admittedPatients ?></h3>
            <p>Admitted Patients</p>
        </div>
    </div>
    <?php foreach (array_slice($wards, 0, 2) as $ward): ?>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-secondary">
            <i class="fas fa-bed stat-icon"></i>
            <h3><?= $ward['occupied'] ?>/<?= $ward['total_beds'] ?></h3>
            <p><?= htmlspecialchars($ward['ward_name']) ?></p>
        </div>
    </div>
    <?php endforeach; ?>
</div>

<div class="card">
    <div class="card-header bg-white"><h5 class="mb-0"><i class="fas fa-procedures me-2"></i>Current Admissions</h5></div>
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Patient</th><th>Ward</th><th>Bed</th><th>Doctor</th><th>Actions</th></tr></thead>
            <tbody>
                <?php foreach ($admissions as $adm): ?>
                    <tr>
                        <td><strong><?= htmlspecialchars($adm['patient_name']) ?></strong></td>
                        <td><?= htmlspecialchars($adm['ward_name']) ?></td>
                        <td><?= htmlspecialchars($adm['bed_number']) ?></td>
                        <td><?= htmlspecialchars($adm['doctor_name']) ?></td>
                        <td><a href="patient_care.php?id=<?= $adm['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-notes-medical"></i></a></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
