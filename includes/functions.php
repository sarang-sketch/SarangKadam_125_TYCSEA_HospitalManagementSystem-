<?php
/**
 * Helper Functions
 * Hospital Management System
 */

/**
 * Sanitize user input
 * 
 * @param string $data Input data to sanitize
 * @return string Sanitized data
 */
function sanitize($data) {
    if ($data === null) return '';
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}

/**
 * Generate unique patient code
 * 
 * @param PDO $pdo Database connection
 * @return string Unique patient code (e.g., PT202500001)
 */
function generatePatientCode($pdo) {
    $year = date('Y');
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM patients WHERE YEAR(created_at) = ?");
    $stmt->execute([$year]);
    $count = $stmt->fetch()['count'] + 1;
    return 'PT' . $year . str_pad($count, 5, '0', STR_PAD_LEFT);
}

/**
 * Format date for display
 * 
 * @param string $date Date string
 * @return string Formatted date (e.g., 05 Dec 2025)
 */
function formatDate($date) {
    if (empty($date)) return '-';
    return date('d M Y', strtotime($date));
}

/**
 * Format datetime for display
 * 
 * @param string $datetime Datetime string
 * @return string Formatted datetime (e.g., 05 Dec 2025 14:30)
 */
function formatDateTime($datetime) {
    if (empty($datetime)) return '-';
    return date('d M Y H:i', strtotime($datetime));
}

/**
 * Format time for display
 * 
 * @param string $time Time string
 * @return string Formatted time (e.g., 02:30 PM)
 */
function formatTime($time) {
    if (empty($time)) return '-';
    return date('h:i A', strtotime($time));
}

/**
 * Get Bootstrap badge class for status
 * 
 * @param string $status Status value
 * @return string Bootstrap badge class
 */
function getStatusBadge($status) {
    $badges = [
        'pending' => 'warning',
        'completed' => 'success',
        'cancelled' => 'danger',
        'admitted' => 'info',
        'discharged' => 'secondary',
        'paid' => 'success',
        'unpaid' => 'danger',
        'requested' => 'warning',
        'in-progress' => 'info',
        'dispensed' => 'success'
    ];
    return $badges[strtolower($status)] ?? 'secondary';
}

/**
 * Set flash message in session
 * 
 * @param string $type Message type (success, danger, warning, info)
 * @param string $message Message content
 */
function setFlashMessage($type, $message) {
    $_SESSION['flash'] = ['type' => $type, 'message' => $message];
}

/**
 * Get and clear flash message from session
 * 
 * @return array|null Flash message array or null
 */
function getFlashMessage() {
    if (isset($_SESSION['flash'])) {
        $flash = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $flash;
    }
    return null;
}

/**
 * Display flash message as Bootstrap alert
 */
function displayFlashMessage() {
    $flash = getFlashMessage();
    if ($flash): ?>
        <div class="alert alert-<?= $flash['type'] ?> alert-dismissible fade show" role="alert">
            <?= htmlspecialchars($flash['message']) ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    <?php endif;
}

/**
 * Display validation errors
 * 
 * @param array $errors Array of error messages
 */
function displayValidationErrors($errors) {
    if (!empty($errors)): ?>
        <div class="alert alert-danger">
            <ul class="mb-0">
                <?php foreach ($errors as $error): ?>
                    <li><?= htmlspecialchars($error) ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif;
}

/**
 * Validate email format
 * 
 * @param string $email Email to validate
 * @return bool True if valid
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Validate phone number (10-15 digits)
 * 
 * @param string $phone Phone number to validate
 * @return bool True if valid
 */
function isValidPhone($phone) {
    return preg_match('/^[0-9]{10,15}$/', $phone);
}

/**
 * Format currency amount
 * 
 * @param float $amount Amount to format
 * @return string Formatted amount with currency symbol
 */
function formatCurrency($amount) {
    return '$' . number_format($amount, 2);
}

/**
 * Get pagination data
 * 
 * @param int $totalItems Total number of items
 * @param int $currentPage Current page number
 * @param int $perPage Items per page
 * @return array Pagination data
 */
function getPagination($totalItems, $currentPage = 1, $perPage = 20) {
    $totalPages = ceil($totalItems / $perPage);
    $currentPage = max(1, min($currentPage, $totalPages));
    $offset = ($currentPage - 1) * $perPage;
    
    return [
        'total_items' => $totalItems,
        'total_pages' => $totalPages,
        'current_page' => $currentPage,
        'per_page' => $perPage,
        'offset' => $offset,
        'has_prev' => $currentPage > 1,
        'has_next' => $currentPage < $totalPages
    ];
}

/**
 * Render pagination links
 * 
 * @param array $pagination Pagination data from getPagination()
 * @param string $baseUrl Base URL for pagination links
 */
function renderPagination($pagination, $baseUrl = '?') {
    if ($pagination['total_pages'] <= 1) return;
    
    $separator = strpos($baseUrl, '?') !== false ? '&' : '?';
    ?>
    <nav aria-label="Page navigation">
        <ul class="pagination justify-content-center">
            <li class="page-item <?= !$pagination['has_prev'] ? 'disabled' : '' ?>">
                <a class="page-link" href="<?= $baseUrl . $separator ?>page=<?= $pagination['current_page'] - 1 ?>">Previous</a>
            </li>
            <?php for ($i = 1; $i <= $pagination['total_pages']; $i++): ?>
                <li class="page-item <?= $i == $pagination['current_page'] ? 'active' : '' ?>">
                    <a class="page-link" href="<?= $baseUrl . $separator ?>page=<?= $i ?>"><?= $i ?></a>
                </li>
            <?php endfor; ?>
            <li class="page-item <?= !$pagination['has_next'] ? 'disabled' : '' ?>">
                <a class="page-link" href="<?= $baseUrl . $separator ?>page=<?= $pagination['current_page'] + 1 ?>">Next</a>
            </li>
        </ul>
    </nav>
    <?php
}

/**
 * Get base URL for the application
 * 
 * @return string Base URL
 */
function getBaseUrl() {
    return '/hospital_management';
}

/**
 * Redirect to a URL
 * 
 * @param string $url URL to redirect to
 */
function redirect($url) {
    header("Location: " . $url);
    exit;
}

/**
 * Check if request is POST
 * 
 * @return bool True if POST request
 */
function isPost() {
    return $_SERVER['REQUEST_METHOD'] === 'POST';
}

/**
 * Get POST value with default
 * 
 * @param string $key POST key
 * @param mixed $default Default value
 * @return mixed POST value or default
 */
function post($key, $default = '') {
    return isset($_POST[$key]) ? $_POST[$key] : $default;
}

/**
 * Get GET value with default
 * 
 * @param string $key GET key
 * @param mixed $default Default value
 * @return mixed GET value or default
 */
function get($key, $default = '') {
    return isset($_GET[$key]) ? $_GET[$key] : $default;
}
