<?php
/**
 * Admissions List
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist', 'doctor', 'nurse']);

$pageTitle = 'Admissions';
$pdo = getConnection();

// Handle discharge
if (isset($_GET['discharge']) && is_numeric($_GET['discharge'])) {
    $id = (int)$_GET['discharge'];
    $stmt = $pdo->prepare("UPDATE admissions SET status = 'discharged', discharge_date = NOW() WHERE id = ?");
    $stmt->execute([$id]);
    setFlashMessage('success', 'Patient discharged successfully.');
    header('Location: admissions.php');
    exit;
}

// Get filters
$statusFilter = sanitize($_GET['status'] ?? 'admitted');
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 20;

$where = [];
$params = [];

if ($statusFilter) {
    $where[] = "ad.status = ?";
    $params[] = $statusFilter;
}

$whereClause = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Get total
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admissions ad $whereClause");
$stmt->execute($params);
$totalItems = $stmt->fetch()['count'];
$pagination = getPagination($totalItems, $page, $perPage);

// Get admissions
$sql = "SELECT ad.*, p.name as patient_name, p.patient_code, u.name as doctor_name, w.ward_name 
        FROM admissions ad 
        JOIN patients p ON ad.patient_id = p.id 
        JOIN users u ON ad.doctor_id = u.id 
        JOIN wards w ON ad.ward_id = w.id 
        $whereClause 
        ORDER BY ad.admission_date DESC 
        LIMIT {$pagination['per_page']} OFFSET {$pagination['offset']}";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$admissions = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-procedures me-2"></i>Admissions</h1>
    <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
        <a href="admission_form.php" class="btn btn-primary">
            <i class="fas fa-plus me-2"></i>New Admission
        </a>
    <?php endif; ?>
</div>

<!-- Filters -->
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <select class="form-select" name="status">
                    <option value="admitted" <?= $statusFilter === 'admitted' ? 'selected' : '' ?>>Currently Admitted</option>
                    <option value="discharged" <?= $statusFilter === 'discharged' ? 'selected' : '' ?>>Discharged</option>
                    <option value="">All</option>
                </select>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-outline-primary w-100">Filter</button>
            </div>
        </form>
    </div>
</div>

<!-- Admissions Table -->
<div class="card">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Patient</th>
                        <th>Ward</th>
                        <th>Bed</th>
                        <th>Doctor</th>
                        <th>Admitted</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($admissions)): ?>
                        <tr><td colspan="7" class="text-center text-muted py-4">No admissions found</td></tr>
                    <?php else: ?>
                        <?php foreach ($admissions as $adm): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($adm['patient_name']) ?></strong><br>
                                    <small class="text-muted"><?= htmlspecialchars($adm['patient_code']) ?></small>
                                </td>
                                <td><?= htmlspecialchars($adm['ward_name']) ?></td>
                                <td><span class="badge bg-info"><?= htmlspecialchars($adm['bed_number']) ?></span></td>
                                <td><?= htmlspecialchars($adm['doctor_name']) ?></td>
                                <td><?= formatDateTime($adm['admission_date']) ?></td>
                                <td>
                                    <span class="badge bg-<?= getStatusBadge($adm['status']) ?>">
                                        <?= ucfirst($adm['status']) ?>
                                    </span>
                                </td>
                                <td class="action-btns">
                                    <a href="admission_view.php?id=<?= $adm['id'] ?>" class="btn btn-sm btn-outline-info" title="View">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                    <?php if ($adm['status'] === 'admitted'): ?>
                                        <a href="admission_form.php?id=<?= $adm['id'] ?>" class="btn btn-sm btn-outline-primary" title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <a href="?discharge=<?= $adm['id'] ?>" class="btn btn-sm btn-outline-warning" title="Discharge" onclick="return confirm('Discharge this patient?')">
                                            <i class="fas fa-sign-out-alt"></i>
                                        </a>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php 
renderPagination($pagination, "admissions.php?status=$statusFilter");
include __DIR__ . '/../includes/footer.php'; 
?>
