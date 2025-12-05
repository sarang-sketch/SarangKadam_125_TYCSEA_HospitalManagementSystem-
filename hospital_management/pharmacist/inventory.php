<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['pharmacist', 'admin']);

$pageTitle = 'Medicine Inventory';
$pdo = getConnection();

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $stmt = $pdo->prepare("DELETE FROM medicines WHERE id = ?");
    $stmt->execute([$_GET['delete']]);
    setFlashMessage('success', 'Medicine deleted.');
    header('Location: inventory.php');
    exit;
}

$search = sanitize($_GET['search'] ?? '');
$where = $search ? "WHERE name LIKE ?" : "";
$params = $search ? ["%$search%"] : [];

$stmt = $pdo->prepare("SELECT * FROM medicines $where ORDER BY name LIMIT 100");
$stmt->execute($params);
$medicines = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-pills me-2"></i>Medicine Inventory</h1>
    <a href="medicine_form.php" class="btn btn-primary"><i class="fas fa-plus me-2"></i>Add Medicine</a>
</div>

<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-6">
                <input type="text" class="form-control" name="search" placeholder="Search medicine..." value="<?= htmlspecialchars($search) ?>">
            </div>
            <div class="col-md-2"><button type="submit" class="btn btn-outline-primary w-100">Search</button></div>
            <div class="col-md-2"><a href="inventory.php" class="btn btn-outline-secondary w-100">Clear</a></div>
        </form>
    </div>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Name</th><th>Batch</th><th>Quantity</th><th>Expiry</th><th>Purchase</th><th>Selling</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($medicines)): ?>
                    <tr><td colspan="7" class="text-center text-muted py-4">No medicines found</td></tr>
                <?php else: ?>
                    <?php foreach ($medicines as $med): 
                        $isLowStock = $med['quantity'] < 20;
                        $isExpiring = $med['expiry_date'] && strtotime($med['expiry_date']) <= strtotime('+30 days');
                    ?>
                        <tr class="<?= $isLowStock ? 'table-warning' : ($isExpiring ? 'table-danger' : '') ?>">
                            <td><strong><?= htmlspecialchars($med['name']) ?></strong></td>
                            <td><?= htmlspecialchars($med['batch_no'] ?: '-') ?></td>
                            <td>
                                <span class="badge bg-<?= $isLowStock ? 'danger' : 'success' ?>"><?= $med['quantity'] ?></span>
                                <?php if ($isLowStock): ?><small class="text-danger">Low</small><?php endif; ?>
                            </td>
                            <td>
                                <?= $med['expiry_date'] ? formatDate($med['expiry_date']) : '-' ?>
                                <?php if ($isExpiring): ?><small class="text-danger">Expiring</small><?php endif; ?>
                            </td>
                            <td><?= formatCurrency($med['purchase_price'] ?? 0) ?></td>
                            <td><?= formatCurrency($med['selling_price'] ?? 0) ?></td>
                            <td class="action-btns">
                                <a href="medicine_form.php?id=<?= $med['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></a>
                                <a href="?delete=<?= $med['id'] ?>" class="btn btn-sm btn-outline-danger delete-confirm"><i class="fas fa-trash"></i></a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
