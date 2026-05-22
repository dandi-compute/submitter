# DANDI Compute: AIND Job Submitter

Automatic CRON-based submission of jobs from the [DANDI Compute: AIND Queue](https://github.com/dandi-compute/queue).



## Why doesn't this repository allow Pull Requests from external forks?

This repository uses a self-hosted runner instead of GitHub-hosted Actions runners.

This means that external users could fork and submit a pull request that contains code modifications that might expose secrets or other hostile actions.

While this could be mitigated through careful permissioning and approval of run triggers before accepting contributions, it is much safer overall to simply disable them.

If you have any questions or suggestions, please raise an Issue instead.

The repository is kept public to allow anyone to see the runtime logs of the submission process, as well as the success/failure/timestamp of the triggers.



## How to setup the runner

1. Go to Settings -> Actions -> Runners -> New self-hosted runner -> Linux
2. Log into https://engaging-ood.mit.edu/ -> Open a new cluster shell
3. `cd /orcd/data/dandi/001/dandi-compute/submitter`
4. Follow copy & paste instructions from Settings
5. Use the default runner group
6. Give this runner the name `compute`
7. Add the labels `mit`, `engaging`, and `compute`
8. Use the default work directory
9. Setup a `crontab` with the following:

```
# For whatever reason, this particular job is sensitive to the usage of `/bin/bash -l` in order to 'behave properly'. Otherwise the SLURM job does run, the self-hosted runner is active, but the conda init does not trigger and so no environment is found.
*/1 * * * * /bin/bash -l -c 'flock -n /orcd/data/dandi/001/dandi-compute/flocks/submitter.lock -c "/orcd/data/dandi/001/dandi-compute/submitter/launcher/guarded-submit -- sbatch --output /dev/null --error=/dev/null /orcd/data/dandi/001/dandi-compute/submitter/launcher/launch_runner.sh" || echo "$(date): lock held, skipping submit"' > /dev/null 2>&1
*/1 * * * * /bin/bash -l -c 'flock -n /orcd/data/dandi/001/dandi-compute/flocks/monitor.lock -c "/orcd/data/dandi/001/dandi-compute/submitter/launcher/guarded-submit -- sbatch --output /dev/null --error=/dev/null /orcd/data/dandi/001/dandi-compute/submitter/launcher/launch_monitor.sh" || echo "$(date): lock held, skipping submit"' > /dev/null 2>&1
```



## How to prepare the queue (manual)

Use the [Prepare queue](https://github.com/dandi-compute/submitter/actions/workflows/prepare-queue.yml) workflow dispatch.

| Input | Description | Default |
|---|---|---|
| `limit` | Maximum number of jobs to add to the queue. | `5` |
| `min_waiting` | Skip preparation if at least this many jobs are already waiting. | `0` |
| `max_backlog` | Maximum number of jobs allowed in the backlog (leave blank for no cap). | _(none)_ |
| `test` | Run in test mode (no changes will be committed or pushed). | `false` |

## How to prepare a specific AIND job (manual)

Use the [Prepare AIND job](https://github.com/dandi-compute/submitter/actions/workflows/prepare-aind.yml) workflow dispatch.

| Input | Description | Default |
|---|---|---|
| `test` | Prepare test queue entries. | `false` |
| `id` | Content ID to process (required unless `dandiset` and `dandipath` are provided). | _(none)_ |
| `dandiset` | Dandiset ID (required unless `id` is provided). | _(none)_ |
| `dandipath` | Local Dandiset path (required unless `id` is provided; ignored with `test=true`). | _(none)_ |
| `config` | Registered configuration key. | `default` |
| `pipeline` | Local path to pipeline repository. | `./aind-ephys-pipeline.cody` |
| `version` | Pipeline version (required when `test=false`). | _(none)_ |
| `params` | Parameters key. | `default` |
| `submit` | Automatically submit after preparation (ignored with `test=true`). | `false` |
| `silent` | Suppress output messages (ignored with `test=true`). | `false` |
| `queue` | Queue directory path (required when `test=true`). | `./queue` |
