<?php
require_once("dbconnect.php");
if (!isset($_GET['map'])) {
		header("Location: index.php");
		return;
} else {
		$map = mysqli_real_escape_string($conn, $_GET['map']);
}
?>

<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta http-equiv="x-ua-compatible" content="ie=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="./LiteCSS.css">
	<title>Map</title>
</head>
<body>
	<div class="container">
		<div class=content>
			<?php
			$sql = "SELECT * FROM playertimes WHERE mapname = '{$map}' ORDER BY runtime DESC";
			$result = mysqli_query($conn, $sql);
			$final = "
      <h3>Showing times for $map</h3>
      <table>
        <tr>
          <th>Name</th>
          <th>Steam ID</th>
          <th>Run Time</th>
        </tr>";

			if(mysqli_num_rows($result) > 0) {
				while($row = mysqli_fetch_assoc($result)) {
					$sid = $row['steamid'];
					$name = $row['name'];
					$runtime = $row['runtime'];

					$final .= "
						<tr>
							<td>$name</td>
							<td>$sid</td>
							<td>$runtime</td>
						</tr>";
			}
			echo $final;
		} else {
			echo "nothing to display";
		}
		?>
	</table></div>
	<?php echo file_get_contents('footer.php');?>
	</div>
</body>
</html>
