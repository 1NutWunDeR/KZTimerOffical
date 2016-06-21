<?php
require_once("dbconnect_temp.php");
?>

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="./LiteCSS.css">
  <title>Latest Records</title>
</head>
<body>
  <div class="container">
    <div class="content">
      <?php
        $sql = "SELECT * FROM latestrecords ORDER BY date DESC";
        $result = mysqli_query($conn, $sql);
        $final = "
        <h3>Latest Records</h3>
        <table>
        <tr>
          <th>Date</th>
          <th>Name</th>
          <th>Map</th>
          <th>Run Time</th>
          <th>Teleports</th>
          <th>Steam ID</th>
        </tr>";

        if (mysqli_num_rows($result) > 0) {
          while($row = mysqli_fetch_assoc($result)) {
            $sid = $row['steamid'];
            $name = $row['name'];
            $runtime = $row['runtime'];
            $teleports = $row['teleports'];
            $map = $row['map'];
            $date = $row['date'];

            $final .="
              <tr>
                <td>$date</td>
                <td>$name</td>
                <td><a href='map.php?map=$map'>$map</a></td>
                <td>$runtime</td>
                <td>$teleports</td>
                <td><a href='player.php?sid=$sid'>$sid</td>
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
