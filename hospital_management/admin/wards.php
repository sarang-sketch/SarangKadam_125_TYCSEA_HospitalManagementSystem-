<?php
/**
 * Ward Management
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin']);

$pageTitle = 'Ward Management';
$pdo = getConnection();
$errors = [];
$editWard = null;

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    // Check if ward has admissions
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admissions WHERE ward_id = ? AND status = 'admitted'");
    $stmt->execute([$id]);
    if ($stmt->fetch()['count'] > 0) {
        setFlashMessage('danger', 'Cannot delete ward with active admissions.');
    } else {
        $stmt = $pdo->prepare("DELETE FROM wards WHERE id = ?");
        $stmt->execute([$id]);
        setFlashMessage('success', 'Ward deleted successfully.');
    }
    header('Location: wards.php');
    exit;
}

// Load ward for edit
if (isset($_GET['edit']) && is_numeric($_GET['edit'])) {
    $stmt = $pdo->prepare("SELECT * FROM wards WHERE id = ?");
    $stmt->execute([$_GET['edit']]);
    $editWard = $stmt->fetch();
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $wardName = sanitize($_POST['ward_name'] ?? '');
    $totalBeds = (int)($_POST['total_beds'] ?? 0);
    $wardId = (int)($_POST['ward_id'] ?? 0);
    
    if (empty($wardName)) {
        $errors[] = 'Ward name is required.';
    }
    
    if ($totalBeds < 1) {
        $errors[] = 'Total beds must be at least 1.';
    }
    
    if (empty($errors)) {
        try {
            if ($wardId) {
                // Check if reducing beds below occupied count
                $stmt = $pdo->prepare("SELECT COUNT(*) as occupied FROM admissions WHERE ward_id = ? AND status = 'admitted'");
                $stmt->execute([$wardId]);
                $occupied = $stmt->fetch()['occupied'];
                
                if ($totalBeds < $occupied) {
                    $errors[] = "Cannot reduce beds below occupied count ($occupied).";
                } else {
                    $stmt = $pdo->prepare("UPDATE wards SET ward_name = ?, total_beds = ? WHERE id = ?");
                    $stmt->execute([$wardName, $totalBeds, $wardId]);
                    setFlashMessage('success', 'Ward updated successfully.');
                    header('Location: wards.php');
                    exit;
                }
            } else {
                $stmt = $pdo->prepare("INSERT INTO wards (ward_name, total_beds) VALUES (?, ?)");
                $stmt->execute([$wardName, $totalBeds]);
                setFlashMessage('success', 'Ward created successfully.');
                header('Location: wards.php');
                exit;
            }
        } catch (PDOException $e) {
            error_log("Ward save error: " . $e->getMessage());
            $errors[] = 'An error occurred. Please try again.';
        }
    }
}

// Get all wards with occupancy
$stmt = $pdo->query("
    SELECT w.*, 
           COALESCE((SELECT COUNT(*) FROM admissions WHERE ward_id = w.id AND status = 'admitted'), 0) as occupied_beds
    FROM wards w 
    ORDER BY w.ward_name
");
$wards = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1><i class="fas fa-bed me-2"></i>Ward Management</h1>
</div>

<div class="row">
    <!-- Ward Form -->
    <div class="col-md-4 mb-4">
        <div class="card">
            <div class="card-header bg-white">
                <h5 class="mb-0">
                    <i class="fas fa-<?= $editWard ? 'edit' : 'plus' ?> me-2"></i>
                    <?= $editWard ? 'Edit Ward' : 'Add New Ward' ?>
                </h5>
            </div>
            <div class="card-body">
                <?php displayValidationErrors($errors); ?>
                
                <form method="POST">
                    <input type="hidden" name="ward_id" value="<?= $editWard['id'] ?? '' ?>">
                    
                    <div class="mb-3">
                        <label for="ward_name" class="form-label">Ward Name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="ward_name" name="ward_name" 
                               value="<?= htmlspecialchars($editWard['ward_name'] ?? '') ?>" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="total_beds" class="form-label">Total Beds <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="total_beds" name="total_beds" min="1"
                               value="<?= $editWard['total_beds'] ?? '' ?>" required>
                    </div>
                    
                    <div class="d-grid gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-2"></i><?= $editWard ? 'Update' : 'Add' ?> Ward
                        </button>
                        <?php if ($editWard): ?>
                            <a href="wards.php" class="btn btn-outline-secondary">
                                <i class="fas fa-times me-2"></i>Cancel
                            </a>
                        <?php endif; ?>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- Wards List -->
    <div class="col-md-8 mb-4">
        <div class="card">
            <div class="card-header bg-white">
                <h5 class="mb-0"><i class="fas fa-list me-2"></i>All Wards</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Ward Name</th>
                                <th>Total Beds</th>
                                <th>Occupied</th>
                                <th>Available</th>
                                <th>Occupancy</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($wards)): ?>
                                <tr><td colspan="6" class="text-center text-muted py-4">No wards found</td></tr>
                            <?php else: ?>
                                <?php foreach ($wards as $ward): 
                                    $available = $ward['total_beds'] - $ward['occupied_beds'];
                                    $occupancyPercent = $ward['total_beds'] > 0 ? round(($ward['occupied_beds'] / $ward['total_beds']) * 100) : 0;
                                ?>
                                    <tr>
                                        <td><strong><?= htmlspecialchars($ward['ward_name']) ?></strong></td>
                                        <td><?= $ward['total_beds'] ?></td>
                                        <td><span class="badge bg-danger"><?= $ward['occupied_beds'] ?></span></td>
                                        <td><span class="badge bg-success"><?= $available ?></span></td>
                                        <td>
                                            <div class="progress" style="height: 20px;">
                                                <div class="progress-bar bg-<?= $occupancyPercent > 80 ? 'danger' : ($occupancyPercent > 50 ? 'warning' : 'success') ?>" 
                                                     style="width: <?= $occupancyPercent ?>%">
                                                    <?= $occupancyPercent ?>%
                                                </div>
                                            </div>
                                        </td>
                                        <td class="action-btns">
                                            <a href="wards.php?edit=<?= $ward['id'] ?>" class="btn btn-sm btn-outline-primary" title="Edit">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            <?php if ($ward['occupied_beds'] == 0): ?>
                                                <a href="wards.php?delete=<?= $ward['id'] ?>" class="btn btn-sm btn-outline-danger delete-confirm" title="Delete">
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
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
