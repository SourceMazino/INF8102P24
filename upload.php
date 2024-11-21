<?php
// Ensure the uploads directory exists 
$uploadDir = 'uploads/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
        $filename = basename($_FILES['file']['name']);
        $targetFile = $uploadDir . $filename;

        if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFile)) {
            echo "File uploaded successfully: <a href='$targetFile' target='_blank'>$filename</a>";
        } else {
            echo "Error: Could not upload the file.";
        }
    } else {
        echo "Error: No file uploaded or upload error.";
    }
} else {
    echo "Invalid request method.";
}
?>
