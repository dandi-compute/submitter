# DANDI Compute Job Submitter

Submit jobs to DANDI Compute.



## How to submit a job request (manual)

In order to submit a job for processing:

1. Fork this repository.
2. Write the following YAML structure in a file named `dandi_compute_job.yaml`:

```yaml
dandiset: "[six-digit Dandiset ID]"
path: "sub-[subject ID]/ses-[session ID]/[NWB filename].nwb"
run_id: "[unique run ID for this job]"
[optional] config: [upload a new custom config file with the pull request, or specify the known ID for a re-used one]
```

3. Add this file under the `incoming` subdirectory.
4. Raise a pull request against the main repository.
5. Once accepted, the runner on the MIT cluster will pick up the job within ~5 minutes and begin processing.
6. You can see all job IDs and their status in real time at the [Monitor Dashboard](https://github.com/dandi-compute/monitor).
7. If the job was successful, you should find the results under the corresponding subdirectory of Dandiset `001675` under the specified blob and run IDs. If unsuccessful, there should be log files with details stored under the same location. Otherwise, please raise an issue for assistance.
