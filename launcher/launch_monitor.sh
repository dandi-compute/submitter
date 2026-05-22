#!/bin/bash
#SBATCH --job-name=DANDI-Compute-Monitor
#SBATCH --output=/orcd/data/dandi/001/dandi-compute/monitor/logs/job-%j_slurm.log
#SBATCH --mem=100MB
#SBATCH --cpus-per-task 1
#SBATCH --partition=mit_preemptable
#SBATCH --time=48:00:00

source /etc/profile.d/modules.sh
flock -n /orcd/data/dandi/001/dandi-compute/flocks/monitor.lock /orcd/data/dandi/001/dandi-compute/runners/monitor/actions-runner/run.sh
