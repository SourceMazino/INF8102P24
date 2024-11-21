<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Upload App</title>
</head>
<body>
    <h1>Upload a File</h1>
    <form action="upload.php" method="post" enctype="multipart/form-data">
        <label for="file">Choose file to upload:</label>
        <input type="file" name="file" id="file" required>
        <button type="submit">Upload</button>
    </form>

    <h2>Uploaded Files</h2>
    <ul>
        <?php
        $files = scandir('uploads');
        foreach ($files as $file) {
            if ($file !== '.' && $file !== '..') {
                echo "<li><a href='uploads/$file' target='_blank'>$file</a></li>";
            }
        }
        ?>
    </ul>
</body>
</html>
