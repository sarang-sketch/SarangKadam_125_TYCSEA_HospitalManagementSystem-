<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['lab']);

$pageTitle = 'Lab Tests';
$pdo = getConnection();

$statusFilter = sanitize($_GET['status'] ?? '');
$where = $statusFilter ? "WHERE lt.status = ?" : "";
$params = $statusFilter ? [$statusFilter] : [];

$stmt = $pdo->prepare("
    SELECT lt.*, p.name as patient_name, p.patient_code, u.name as doctor_name 
    FROM lab_tests lt JOIN patients p ON lt.patient_id = p.id JOIN users u ON lt.doctor_id = u.id 
    $where ORDER BY lt.requested_date DESC LIMIT 100
");
$stmt->execute($params);
$tests = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-flask me-2"></i>Lab Tests</h1></div>

<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <select class="form-select" name="status">
                    <option value="">All Status</option>
                    <option value="requested" <?= $statusFilter === 'requested' ? 'selected' : '' ?>>Requested</option>
                    <option value="in-progress" <?= $statusFilter === 'in-progress' ? 'selected' : '' ?>>In Progress</option>
                    <option value="completed" <?= $statusFilter === 'completed' ? 'selected' : '' ?>>Completed</option>
                </select>
            </div>
            <div class="col-md-2"><button type="submit" class="btn btn-outline-primary w-100">Filter</button></div>
        </form>
    </div>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Requested</th><th>Patient</th><th>Test</th><th>Doctor</th><th>Status</th><th>Result Date</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($tests)): ?>
                    <tr><td colspan="7" class="text-center text-muted py-4">No tests found</td></tr>
                <?php else: ?>
                    <?php foreach ($tests as $test): ?>
                        <tr>
                            <td><?= formatDate($test['requested_date']) ?></td>
                            <td><strong><?= htmlspecialchars($test['patient_name']) ?></strong><br><small><?= $test['patient_code'] ?></small></td>
                            <td><?= htmlspecialchars($test['test_name']) ?></td>
                            <td><?= htmlspecialchars($test['doctor_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($test['status']) ?>"><?= ucfirst($test['status']) ?></span></td>
                            <td><?= $test['result_date'] ? formatDate($test['result_date']) : '-' ?></td>
                            <td><a href="test_result.php?id=<?= $test['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></a></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
