<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor']);

$pageTitle = 'Lab Requests';
$pdo = getConnection();
$doctorId = getCurrentUserId();

$stmt = $pdo->prepare("
    SELECT lt.*, p.name as patient_name, p.patient_code 
    FROM lab_tests lt JOIN patients p ON lt.patient_id = p.id 
    WHERE lt.doctor_id = ? ORDER BY lt.requested_date DESC LIMIT 50
");
$stmt->execute([$doctorId]);
$tests = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-flask me-2"></i>Lab Requests</h1>
    <a href="lab_request.php" class="btn btn-primary"><i class="fas fa-plus me-2"></i>New Request</a>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Requested</th><th>Patient</th><th>Test</th><th>Status</th><th>Result Date</th></tr></thead>
            <tbody>
                <?php if (empty($tests)): ?>
                    <tr><td colspan="5" class="text-center text-muted py-4">No lab requests</td></tr>
                <?php else: ?>
                    <?php foreach ($tests as $test): ?>
                        <tr>
                            <td><?= formatDate($test['requested_date']) ?></td>
                            <td><strong><?= htmlspecialchars($test['patient_name']) ?></strong><br><small><?= $test['patient_code'] ?></small></td>
                            <td><?= htmlspecialchars($test['test_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($test['status']) ?>"><?= ucfirst($test['status']) ?></span></td>
                            <td><?= $test['result_date'] ? formatDate($test['result_date']) : '-' ?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
