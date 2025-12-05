<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor']);

$pageTitle = 'My Prescriptions';
$pdo = getConnection();
$doctorId = getCurrentUserId();

$stmt = $pdo->prepare("
    SELECT pr.*, p.name as patient_name, p.patient_code 
    FROM prescriptions pr JOIN patients p ON pr.patient_id = p.id 
    WHERE pr.doctor_id = ? ORDER BY pr.visit_date DESC LIMIT 50
");
$stmt->execute([$doctorId]);
$prescriptions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-prescription me-2"></i>My Prescriptions</h1>
    <a href="prescription_form.php" class="btn btn-primary"><i class="fas fa-plus me-2"></i>New Prescription</a>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Date</th><th>Patient</th><th>Diagnosis</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($prescriptions)): ?>
                    <tr><td colspan="5" class="text-center text-muted py-4">No prescriptions</td></tr>
                <?php else: ?>
                    <?php foreach ($prescriptions as $pr): ?>
                        <tr>
                            <td><?= formatDate($pr['visit_date']) ?></td>
                            <td><strong><?= htmlspecialchars($pr['patient_name']) ?></strong><br><small><?= $pr['patient_code'] ?></small></td>
                            <td><?= htmlspecialchars(substr($pr['diagnosis'], 0, 50)) ?>...</td>
                            <td><span class="badge bg-<?= getStatusBadge($pr['status']) ?>"><?= ucfirst($pr['status']) ?></span></td>
                            <td><a href="prescription_view.php?id=<?= $pr['id'] ?>" class="btn btn-sm btn-outline-info"><i class="fas fa-eye"></i> View</a></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
