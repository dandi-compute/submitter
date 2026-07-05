#!/bin/bash
#SBATCH --job-name=revive
#SBATCH --output=/orcd/data/dandi/001/dandi-compute/tmp/revive-logs/%x-%j.out
#SBATCH --time=00:10:00
#SBATCH --qos=shortrun
#SBATCH --partition=mit_preemptable
#SBATCH --mem=100MB
#SBATCH --cpus-per-task=1

set -uo pipefail

JOBNAME="dandi-submitter"
INTERVAL_MIN=60
SELF="/orcd/data/dandi/001/dandi-compute/submitter/launcher/submit-loop.sh"

OTHERS=$(squeue --noheader --name="$JOBNAME" --user="$USER" \
         --states=PENDING,RUNNING --format="%A" \
         | grep -v "^${SLURM_JOB_ID}$" || true)

if [ -n "$OTHERS" ]; then
    echo "$(date) duplicate $JOBNAME found ($OTHERS) — exiting."
    exit 0
fi

sbatch --begin="now+${INTERVAL_MIN}minutes" "$SELF"

echo "$(date) running submitter on $(hostname)"

ssh loginn007
crontab /orcd/data/dandi/001/dandi-compute/submitter/launcher/crontab
