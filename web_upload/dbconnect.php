<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "kz";


$conn = mysqli_connect($servername, $username, $password, $dbname);

if (!$conn) {
  die ("Connection could not be established to the database.");
}
