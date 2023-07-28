# WHAT
This little NF project facilitates automated graceful rebuild the compute nodes in the SGE cluster (in the event of rolling out updated OS image). In a high level, this workflow scans the compute nodes inside a given SGE queue, and detects if it is running outdated OS image. Then it does scheduling and marking the nodes that should be decommissioned for rebuild, and keeps track of the overall progress.

Note that, the actual decommission/reboot is actioned by R2D2, when it detects the marker. The BLUEFISH project (together with the HPC management toolkit) then handles the actual node rebuild.

# HOW
```
# maybe good to clean up the stuff generated by previous run:
$ rm -rf work/

# Note the failed runs is how NF reacts based on the script exit code,
# and it is purely intentional when the script detects a node is running
# outdated OS image.
$ nextflow run vd_run_rebuild_sge.nf --sgeQueue "short.q"
N E X T F L O W  ~  version 21.04.1
Launching `vd_run_rebuild_sge.nf` [chaotic_carson] - revision: 90d291decd
 V E D A - N F   S G E   R E B U I L D E R
 ==========================================
 sgeQueue   : short.q
 safe       : % of completed nodes > 0.50
 done       : % of completed nodes = 1
 survival   : % of disabled nodes <= 0.50
 Log        : /tmp/vd_progress_check_sge.log
 
executor >  local (288)
executor >  local (288)
[51/53e95b] process > progressCheck      [100%] 1 of 1 ✔
[0d/9718b6] process > checkSurvival (92) [100%] 92 of 92
[2c/cc5f23] process > findMismatch (92)  [100%] 92 of 92, failed: 92
[ae/f41cda] process > disable (94)       [100%] 94 of 94, failed: 9
[88/f1b6fd] process > rebuild (9)        [100%] 9 of 9
```
The overall process time highly depends on how busy the cluster is. 