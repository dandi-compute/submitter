# DANDI Compute: AIND Job Submitter

Automatic CRON-based submission of jobs from the [DANDI Compute: AIND Queue](https://github.com/dandi-compute/queue).



## Why doesn't this repository allow Pull Requests?

This repository uses a self-hosted runner instead of GitHub-hosted Actions runners.

This means that external users could otherwise fork and submit a pull request that contains code modifications that could expose secrets and other hostile actions.

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



## How to submit a job request (manual)

Ask Cody (@CodyCBakerPhD) and he has a private manual dispatcher.
