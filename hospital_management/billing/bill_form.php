<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['admin', 'receptionist']);

$pdo = getConnection();
$errors = [];
$bill = ['id' => '', 'patient_id' => '', 'admission_id' => ''];
$items = [];
$isEdit = false;

if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM bills WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existing = $stmt->fetch();
    if ($existing) {
        $bill = $existing;
        $isEdit = true;
        $stmt = $pdo->prepare("SELECT * FROM bill_items WHERE bill_id = ?");
        $stmt->execute([$bill['id']]);
        $items = $stmt->fetchAll();
    }
}

$pageTitle = $isEdit ? 'Edit Bill' : 'Create Bill';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $bill['patient_id'] = (int)($_POST['patient_id'] ?? 0);
    $bill['admission_id'] = (int)($_POST['admission_id'] ?? 0) ?: null;
    $postItems = $_POST['items'] ?? [];
    $taxRate = (float)($_POST['tax_rate'] ?? 5);
    
    if (!$bill['patient_id']) $errors[] = 'Please select a patient.';
    
    if (empty($errors)) {
        try {
            $pdo->beginTransaction();
            
            $subtotal = 0;
            foreach ($postItems as $item) {
                if (!empty($item['description']) && is_numeric($item['amount'])) {
                    $subtotal += (float)$item['amount'];
                }
            }
            $taxAmount = $subtotal * ($taxRate / 100);
            
            if ($isEdit) {
                $stmt = $pdo->prepare("UPDATE bills SET patient_id = ?, admission_id = ?, total_amount = ?, tax_amount = ? WHERE id = ?");
                $stmt->execute([$bill['patient_id'], $bill['admission_id'], $subtotal, $taxAmount, $bill['id']]);
                $pdo->prepare("DELETE FROM bill_items WHERE bill_id = ?")->execute([$bill['id']]);
                $billId = $bill['id'];
            } else {
                $stmt = $pdo->prepare("INSERT INTO bills (patient_id, admission_id, total_amount, tax_amount) VALUES (?, ?, ?, ?)");
                $stmt->execute([$bill['patient_id'], $bill['admission_id'], $subtotal, $taxAmount]);
                $billId = $pdo->lastInsertId();
            }
            
            $stmt = $pdo->prepare("INSERT INTO bill_items (bill_id, description, amount) VALUES (?, ?, ?)");
            foreach ($postItems as $item) {
                if (!empty($item['description']) && is_numeric($item['amount'])) {
                    $stmt->execute([$billId, sanitize($item['description']), (float)$item['amount']]);
                }
            }
            
            $pdo->commit();
            setFlashMessage('success', 'Bill saved.');
            header('Location: bills.php');
            exit;
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errors[] = 'Error saving bill.';
        }
    }
}

$patients = $pdo->query("SELECT id, patient_code, name FROM patients ORDER BY name")->fetchAll();
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-file-invoice-dollar me-2"></i><?= $pageTitle ?></h1></div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        <form method="POST">
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Patient <span class="text-danger">*</span></label>
                    <select class="form-select" name="patient_id" required>
                        <option value="">Select Patient</option>
                        <?php foreach ($patients as $p): ?>
                            <option value="<?= $p['id'] ?>" <?= $bill['patient_id'] == $p['id'] ? 'selected' : '' ?>><?= htmlspecialchars($p['patient_code'] . ' - ' . $p['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label">Tax Rate (%)</label>
                    <input type="number" step="0.1" class="form-control" name="tax_rate" id="taxRate" value="5">
                </div>
            </div>
            
            <h5 class="mt-4 mb-3">Bill Items</h5>
            <div id="billItems">
                <?php if (empty($items)): ?>
                    <div class="row mb-3 bill-item">
                        <div class="col-md-8"><input type="text" class="form-control" name="items[0][description]" placeholder="Description" required></div>
                        <div class="col-md-3"><input type="number" step="0.01" class="form-control item-amount" name="items[0][amount]" placeholder="Amount" required></div>
                        <div class="col-md-1"><button type="button" class="btn btn-danger btn-sm remove-bill-item"><i class="fas fa-trash"></i></button></div>
                    </div>
                <?php else: ?>
                    <?php foreach ($items as $i => $item): ?>
                        <div class="row mb-3 bill-item">
                            <div class="col-md-8"><input type="text" class="form-control" name="items[<?= $i ?>][description]" value="<?= htmlspecialchars($item['description']) ?>" required></div>
                            <div class="col-md-3"><input type="number" step="0.01" class="form-control item-amount" name="items[<?= $i ?>][amount]" value="<?= $item['amount'] ?>" required></div>
                            <div class="col-md-1"><button type="button" class="btn btn-danger btn-sm remove-bill-item"><i class="fas fa-trash"></i></button></div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
            <button type="button" class="btn btn-outline-secondary btn-sm mb-4" id="addBillItem"><i class="fas fa-plus me-1"></i>Add Item</button>
            
            <div class="row">
                <div class="col-md-6 offset-md-6">
                    <table class="table">
                        <tr><td>Subtotal:</td><td class="text-end" id="subtotal">$0.00</td></tr>
                        <tr><td>Tax:</td><td class="text-end" id="taxAmount">$0.00</td></tr>
                        <tr class="fw-bold"><td>Total:</td><td class="text-end" id="totalAmount">$0.00</td></tr>
                    </table>
                </div>
            </div>
            
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i>Save Bill</button>
            <a href="bills.php" class="btn btn-outline-secondary ms-2">Cancel</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
