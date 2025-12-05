<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['pharmacist']);

$pageTitle = 'Prescriptions';
$pdo = getConnection();

// Handle dispense
if (isset($_GET['dispense']) && is_numeric($_GET['dispense'])) {
    $stmt = $pdo->prepare("UPDATE prescriptions SET status = 'dispensed' WHERE id = ?");
    $stmt->execute([$_GET['dispense']]);
    setFlashMessage('success', 'Prescription marked as dispensed.');
    header('Location: prescriptions.php');
    exit;
}

$statusFilter = sanitize($_GET['status'] ?? 'pending');
$where = $statusFilter ? "WHERE pr.status = ?" : "";
$params = $statusFilter ? [$statusFilter] : [];

$stmt = $pdo->prepare("
    SELECT pr.*, p.name as patient_name, p.patient_code, u.name as doctor_name 
    FROM prescriptions pr JOIN patients p ON pr.patient_id = p.id JOIN users u ON pr.doctor_id = u.id 
    $where ORDER BY pr.created_at DESC LIMIT 50
");
$stmt->execute($params);
$prescriptions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-prescription me-2"></i>Prescriptions</h1></div>

<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <select class="form-select" name="status">
                    <option value="pending" <?= $statusFilter === 'pending' ? 'selected' : '' ?>>Pending</option>
                    <option value="dispensed" <?= $statusFilter === 'dispensed' ? 'selected' : '' ?>>Dispensed</option>
                    <option value="">All</option>
                </select>
            </div>
            <div class="col-md-2"><button type="submit" class="btn btn-outline-primary w-100">Filter</button></div>
        </form>
    </div>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Date</th><th>Patient</th><th>Doctor</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($prescriptions)): ?>
                    <tr><td colspan="5" class="text-center text-muted py-4">No prescriptions</td></tr>
                <?php else: ?>
                    <?php foreach ($prescriptions as $pr): ?>
                        <tr>
                            <td><?= formatDate($pr['visit_date']) ?></td>
                            <td><strong><?= htmlspecialchars($pr['patient_name']) ?></strong><br><small><?= $pr['patient_code'] ?></small></td>
                            <td><?= htmlspecialchars($pr['doctor_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($pr['status']) ?>"><?= ucfirst($pr['status']) ?></span></td>
                            <td>
                                <a href="/hospital_management/doctor/prescription_view.php?id=<?= $pr['id'] ?>" class="btn btn-sm btn-outline-info"><i class="fas fa-eye"></i></a>
                                <?php if ($pr['status'] === 'pending'): ?>
                                    <a href="?dispense=<?= $pr['id'] ?>" class="btn btn-sm btn-outline-success" onclick="return confirm('Mark as dispensed?')"><i class="fas fa-check"></i></a>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
