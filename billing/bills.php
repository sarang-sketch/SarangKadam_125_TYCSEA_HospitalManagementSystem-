<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['admin', 'receptionist']);

$pageTitle = 'Billing';
$pdo = getConnection();

// Handle status update
if (isset($_GET['mark']) && isset($_GET['id'])) {
    $status = sanitize($_GET['mark']);
    if (in_array($status, ['paid', 'unpaid'])) {
        $stmt = $pdo->prepare("UPDATE bills SET status = ? WHERE id = ?");
        $stmt->execute([$status, (int)$_GET['id']]);
        setFlashMessage('success', 'Bill status updated.');
    }
    header('Location: bills.php');
    exit;
}

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $stmt = $pdo->prepare("DELETE FROM bills WHERE id = ?");
    $stmt->execute([$_GET['delete']]);
    setFlashMessage('success', 'Bill deleted.');
    header('Location: bills.php');
    exit;
}

$statusFilter = sanitize($_GET['status'] ?? '');
$where = $statusFilter ? "WHERE b.status = ?" : "";
$params = $statusFilter ? [$statusFilter] : [];

$stmt = $pdo->prepare("
    SELECT b.*, p.name as patient_name, p.patient_code 
    FROM bills b JOIN patients p ON b.patient_id = p.id 
    $where ORDER BY b.created_at DESC LIMIT 100
");
$stmt->execute($params);
$bills = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-file-invoice-dollar me-2"></i>Billing</h1>
    <a href="bill_form.php" class="btn btn-primary"><i class="fas fa-plus me-2"></i>Create Bill</a>
</div>

<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <select class="form-select" name="status">
                    <option value="">All Status</option>
                    <option value="unpaid" <?= $statusFilter === 'unpaid' ? 'selected' : '' ?>>Unpaid</option>
                    <option value="paid" <?= $statusFilter === 'paid' ? 'selected' : '' ?>>Paid</option>
                </select>
            </div>
            <div class="col-md-2"><button type="submit" class="btn btn-outline-primary w-100">Filter</button></div>
        </form>
    </div>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Bill #</th><th>Patient</th><th>Amount</th><th>Tax</th><th>Total</th><th>Status</th><th>Date</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($bills)): ?>
                    <tr><td colspan="8" class="text-center text-muted py-4">No bills found</td></tr>
                <?php else: ?>
                    <?php foreach ($bills as $bill): ?>
                        <tr>
                            <td><strong>#<?= $bill['id'] ?></strong></td>
                            <td><?= htmlspecialchars($bill['patient_name']) ?><br><small><?= $bill['patient_code'] ?></small></td>
                            <td><?= formatCurrency($bill['total_amount']) ?></td>
                            <td><?= formatCurrency($bill['tax_amount']) ?></td>
                            <td><strong><?= formatCurrency($bill['total_amount'] + $bill['tax_amount']) ?></strong></td>
                            <td><span class="badge bg-<?= getStatusBadge($bill['status']) ?>"><?= ucfirst($bill['status']) ?></span></td>
                            <td><?= formatDate($bill['created_at']) ?></td>
                            <td class="action-btns">
                                <a href="invoice.php?id=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-info"><i class="fas fa-eye"></i></a>
                                <?php if ($bill['status'] === 'unpaid'): ?>
                                    <a href="?mark=paid&id=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-success"><i class="fas fa-check"></i></a>
                                <?php else: ?>
                                    <a href="?mark=unpaid&id=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-warning"><i class="fas fa-undo"></i></a>
                                <?php endif; ?>
                                <a href="bill_form.php?id=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></a>
                                <a href="?delete=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-danger delete-confirm"><i class="fas fa-trash"></i></a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
