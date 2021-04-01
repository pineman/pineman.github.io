<?= `mpc status | awk 'NR==2' | perl -ne "print /\[(.*)\]/g"` ?>
