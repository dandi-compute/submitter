cd /orcd/data/dandi/001/all-dandi-compute/blobs-to-paths

git_output=$(git pull)
if echo "$git_output" | grep -q "Already up to date"; then
    echo "No changes, exiting script"
    exit 0
fi

module load miniforge

conda activate /orcd/data/dandi/001/environments/name-dandi+compute_env

python update.py

git add .
git commit --message "update" | true
git push

# CRON
# */3 * * * * flock -n /orcd/data/dandi/001/flocks/dandi_compute_monitor.lock bash /orcd/data/dandi/001/all-dandi-compute/monitor/script.sh
