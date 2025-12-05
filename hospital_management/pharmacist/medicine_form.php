<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['pharmacist', 'admin']);

$pdo = getConnection();
$errors = [];
$medicine = ['id' => '', 'name' => '', 'batch_no' => '', 'quantity' => '', 'expiry_date' => '', 'purchase_price' => '', 'selling_price' => ''];
$isEdit = false;

if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM medicines WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existing = $stmt->fetch();
    if ($existing) { $medicine = $existing; $isEdit = true; }
}

$pageTitle = $isEdit ? 'Edit Medicine' : 'Add Medicine';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $medicine['name'] = sanitize($_POST['name'] ?? '');
    $medicine['batch_no'] = sanitize($_POST['batch_no'] ?? '');
    $medicine['quantity'] = (int)($_POST['quantity'] ?? 0);
    $medicine['expiry_date'] = sanitize($_POST['expiry_date'] ?? '');
    $medicine['purchase_price'] = (float)($_POST['purchase_price'] ?? 0);
    $medicine['selling_price'] = (float)($_POST['selling_price'] ?? 0);
    
    if (empty($medicine['name'])) $errors[] = 'Name is required.';
    if ($medicine['quantity'] < 0) $errors[] = 'Quantity cannot be negative.';
    
    if (empty($errors)) {
        if ($isEdit) {
            $stmt = $pdo->prepare("UPDATE medicines SET name = ?, batch_no = ?, quantity = ?, expiry_date = ?, purchase_price = ?, selling_price = ? WHERE id = ?");
            $stmt->execute([$medicine['name'], $medicine['batch_no'], $medicine['quantity'], $medicine['expiry_date'] ?: null, $medicine['purchase_price'], $medicine['selling_price'], $medicine['id']]);
            setFlashMessage('success', 'Medicine updated.');
        } else {
            $stmt = $pdo->prepare("INSERT INTO medicines (name, batch_no, quantity, expiry_date, purchase_price, selling_price) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->execute([$medicine['name'], $medicine['batch_no'], $medicine['quantity'], $medicine['expiry_date'] ?: null, $medicine['purchase_price'], $medicine['selling_price']]);
            setFlashMessage('success', 'Medicine added.');
        }
        header('Location: inventory.php');
        exit;
    }
}

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-pills me-2"></i><?= $pageTitle ?></h1></div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        <form method="POST">
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Medicine Name <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" name="name" value="<?= htmlspecialchars($medicine['name']) ?>" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Batch Number</label>
                    <input type="text" class="form-control" name="batch_no" value="<?= htmlspecialchars($medicine['batch_no']) ?>">
                </div>
            </div>
            <div class="row">
                <div class="col-md-3 mb-3">
                    <label class="form-label">Quantity <span class="text-danger">*</span></label>
                    <input type="number" class="form-control" name="quantity" min="0" value="<?= $medicine['quantity'] ?>" required>
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label">Expiry Date</label>
                    <input type="date" class="form-control" name="expiry_date" value="<?= htmlspecialchars($medicine['expiry_date']) ?>">
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label">Purchase Price</label>
                    <input type="number" step="0.01" class="form-control" name="purchase_price" value="<?= $medicine['purchase_price'] ?>">
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label">Selling Price</label>
                    <input type="number" step="0.01" class="form-control" name="selling_price" value="<?= $medicine['selling_price'] ?>">
                </div>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i><?= $isEdit ? 'Update' : 'Add' ?> Medicine</button>
            <a href="inventory.php" class="btn btn-outline-secondary ms-2">Cancel</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
