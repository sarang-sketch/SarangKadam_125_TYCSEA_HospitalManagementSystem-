<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor', 'admin', 'pharmacist', 'nurse']);

$pdo = getConnection();
if (!isset($_GET['id'])) { header('Location: prescriptions.php'); exit; }

$stmt = $pdo->prepare("SELECT pr.*, p.name as patient_name, p.patient_code, p.age, p.gender, u.name as doctor_name FROM prescriptions pr JOIN patients p ON pr.patient_id = p.id JOIN users u ON pr.doctor_id = u.id WHERE pr.id = ?");
$stmt->execute([$_GET['id']]);
$prescription = $stmt->fetch();
if (!$prescription) { header('Location: prescriptions.php'); exit; }

$stmt = $pdo->prepare("SELECT * FROM prescription_items WHERE prescription_id = ?");
$stmt->execute([$prescription['id']]);
$items = $stmt->fetchAll();

$pageTitle = 'Prescription';
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-prescription me-2"></i>Prescription</h1>
    <div>
        <button class="btn btn-outline-primary btn-print"><i class="fas fa-print me-2"></i>Print</button>
        <a href="javascript:history.back()" class="btn btn-outline-secondary">Back</a>
    </div>
</div>

<div class="card">
    <div class="card-body">
        <div class="row mb-4">
            <div class="col-md-6">
                <h5>Patient Information</h5>
                <p><strong><?= htmlspecialchars($prescription['patient_name']) ?></strong> (<?= $prescription['patient_code'] ?>)<br>
                <?= $prescription['age'] ?> years, <?= ucfirst($prescription['gender']) ?></p>
            </div>
            <div class="col-md-6 text-md-end">
                <h5>Prescription Details</h5>
                <p>Date: <?= formatDate($prescription['visit_date']) ?><br>
                Doctor: <?= htmlspecialchars($prescription['doctor_name']) ?></p>
            </div>
        </div>
        
        <hr>
        
        <div class="row mb-4">
            <div class="col-md-6">
                <h6>Symptoms</h6>
                <p><?= nl2br(htmlspecialchars($prescription['symptoms'] ?: 'N/A')) ?></p>
            </div>
            <div class="col-md-6">
                <h6>Diagnosis</h6>
                <p><?= nl2br(htmlspecialchars($prescription['diagnosis'])) ?></p>
            </div>
        </div>
        
        <h6>Medicines</h6>
        <table class="table table-bordered">
            <thead><tr><th>#</th><th>Medicine</th><th>Dosage</th><th>Frequency</th><th>Duration</th></tr></thead>
            <tbody>
                <?php foreach ($items as $i => $item): ?>
                    <tr>
                        <td><?= $i + 1 ?></td>
                        <td><?= htmlspecialchars($item['medicine_name']) ?></td>
                        <td><?= htmlspecialchars($item['dosage'] ?: '-') ?></td>
                        <td><?= htmlspecialchars($item['frequency'] ?: '-') ?></td>
                        <td><?= htmlspecialchars($item['duration'] ?: '-') ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        
        <?php if ($prescription['advice']): ?>
            <h6>Advice</h6>
            <p><?= nl2br(htmlspecialchars($prescription['advice'])) ?></p>
        <?php endif; ?>
        
        <p class="text-muted mt-4"><small>Status: <span class="badge bg-<?= getStatusBadge($prescription['status']) ?>"><?= ucfirst($prescription['status']) ?></span></small></p>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
