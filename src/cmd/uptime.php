<?php
$conn = pg_connect('host=' . getenv('HP_DB_HOST') . ' user=postgres');
$result = pg_query($conn, 'select * from test');
while ($row = pg_fetch_row($result)) {
  echo "$row[0] ";
}
?>
