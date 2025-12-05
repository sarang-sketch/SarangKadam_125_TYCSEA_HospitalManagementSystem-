<?php
/**
 * Patient List
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist', 'doctor', 'nurse', 'lab']);

$pageTitle = 'Patients';
$pdo = getConnection();

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    requireRole(['admin', 'receptionist']);
    $id = (int)$_GET['delete'];
    $stmt = $pdo->prepare("DELETE FROM patients WHERE id = ?");
    $stmt->execute([$id]);
    setFlashMessage('success', 'Patient deleted successfully.');
    header('Location: patients.php');
    exit;
}

// Get filters
$search = sanitize($_GET['search'] ?? '');
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 20;

// Build query
$where = [];
$params = [];

if ($search) {
    $where[] = "(name LIKE ? OR patient_code LIKE ? OR phone LIKE ?)";
    $params[] = "%$search%";
    $params[] = "%$search%";
    $params[] = "%$search%";
}

$whereClause = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Get total count
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM patients $whereClause");
$stmt->execute($params);
$totalItems = $stmt->fetch()['count'];
$pagination = getPagination($totalItems, $page, $perPage);

// Get patients
$sql = "SELECT * FROM patients $whereClause ORDER BY created_at DESC LIMIT {$pagination['per_page']} OFFSET {$pagination['offset']}";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$patients = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-user-injured me-2"></i>Patients</h1>
    <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
        <a href="patient_form.php" class="btn btn-primary">
            <i class="fas fa-plus me-2"></i>Add Patient
        </a>
    <?php endif; ?>
</div>

<!-- Search -->
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-8">
                <div class="search-box">
                    <i class="fas fa-search search-icon"></i>
                    <input type="text" class="form-control" name="search" placeholder="Search by name, patient ID, or phone..." value="<?= htmlspecialchars($search) ?>">
                </div>
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-outline-primary w-100">
                    <i class="fas fa-search me-1"></i>Search
                </button>
            </div>
            <div class="col-md-2">
                <a href="patients.php" class="btn btn-outline-secondary w-100">
                    <i class="fas fa-times me-1"></i>Clear
                </a>
            </div>
        </form>
    </div>
</div>

<!-- Patients Table -->
<div class="card">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Patient ID</th>
                        <th>Name</th>
                        <th>Age</th>
                        <th>Gender</th>
                        <th>Blood Group</th>
                        <th>Phone</th>
                        <th>Registered</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($patients)): ?>
                        <tr><td colspan="8" class="text-center text-muted py-4">No patients found</td></tr>
                    <?php else: ?>
                        <?php foreach ($patients as $patient): ?>
                            <tr>
                                <td><strong><?= htmlspecialchars($patient['patient_code']) ?></strong></td>
                                <td><?= htmlspecialchars($patient['name']) ?></td>
                                <td><?= $patient['age'] ?></td>
                                <td><?= ucfirst($patient['gender']) ?></td>
                                <td><span class="badge bg-danger"><?= htmlspecialchars($patient['blood_group'] ?? '-') ?></span></td>
                                <td><?= htmlspecialchars($patient['phone']) ?></td>
                                <td><?= formatDate($patient['created_at']) ?></td>
                                <td class="action-btns">
                                    <a href="patient_view.php?id=<?= $patient['id'] ?>" class="btn btn-sm btn-outline-info" title="View">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                    <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
                                        <a href="patient_form.php?id=<?= $patient['id'] ?>" class="btn btn-sm btn-outline-primary" title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <a href="patients.php?delete=<?= $patient['id'] ?>" class="btn btn-sm btn-outline-danger delete-confirm" title="Delete">
                                            <i class="fas fa-trash"></i>
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
$baseUrl = "patients.php?" . http_build_query(array_filter(['search' => $search]));
renderPagination($pagination, $baseUrl);
?>

<?php include __DIR__ . '/../includes/footer.php'; ?>
