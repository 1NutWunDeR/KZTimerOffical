<?php
require_once("dbconnect_temp.php");
if (!isset($_GET['sid'])) {
    header("Location: index.php");
    return;
} else {
    $sid = $_GET['sid'];
}
?>

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="./LiteCSS.css">
  <title>Players Profile</title>
</head>
<body>
  <div class="container">
    <div class=content>
      <?php
      $sql = "SELECT * FROM playerrank WHERE steamid = '{$sid}'";
      $result = mysqli_query($conn, $sql);
      $final = "
      <h3>Showing players profile</h3>
      ";

      if(mysqli_num_rows($result) > 0) {
        while($row = mysqli_fetch_assoc($result)) {
          $sid = $row['steamid'];
          $name = $row['name'];
          $country = $row['country'];
          $points = $row['points'];
          $finishedmaps = $row['finishedmaps'];
          $lastseen = $row['lastseen'];

          $final .= "
          <table>
            <tr>
              <th colspan='2'>Name: $name</th>
              <th colspan='4' rowspan='3'></th>
            </tr>
            <tr>
              <td colspan='2'>Steam ID: $sid</td>
            </tr>
            <tr>
              <td colspan='2'>Points: $points</td>
            </tr>
            <tr>
              <td colspan='2'>$country</td>
              <td colspan='2'>Last Seen: $lastseen</td>
              <td colspan='2'>Maps Finished: $finishedmaps</td>
            </tr>
            <tr>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>

          ";
        }
        echo $final;
      } else {
        echo "nothing to display";
      }
      ?>
  </div>
  </div>
</body>
</html>
