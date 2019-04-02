# Setup

Place these scripts in a folder and add that folder to your path e.g.

```{bash}
cd ~
mkdir git
cd git
git clone https://github.com/cdt-data-science/cluster-scripts.git
echo "export PATH=/home/$USER/git/cluster-scripts:\$PATH" >> ~/.bash_profile
source ~/.bash_profile
```

To enable autocompletion of job names/numbers, also source the `job-id-completion.sh` script from your bash_profile.

```{bash}
echo "source /home/$USER/git/cluster-scripts/job-id-completion.sh" >> ~/.bash_profile
source ~/.bash_profile
```

If instead of cloning the repo, you copied the files to a directory manually, make sure they are executable:
```{bash}
chmod u+x {qcat,qhead,get-output-file,qtail,show-past-jobs,qusr,lessnew,watchnew}
```

You should now be able to run the scripts from anywhere when on the cluster.

All the scripts should explain usage when run with 'help' as the argument; for example:
qcat help

The colurs used in the show-past-job script can be changed -- the comments in the script explain how to do so.

# Contributing
Feel free to add any useful scripts you develop.
**Please make sure that any scripts you add print usage information when called with 'help' as the first argument** -- see the current scripts for examples of how to do this.

### Changelog
The log below shows the history before moving to git.
* Update 2017-03-05:
   - Move taskid to seperate column in show-past-jobs; tidy up sort key for show-past-jobs

* Update 2017-02-21:
   - Clean up awk statement in qusr

* Update 2017-02-17:
   - get-output-file should handle $TASK_ID, as long as the user refers to the job as <JOB_ID_PATTERN>.TASK_ID
   - get-output-file makes fewer calld to qstat

* Update 2017-02-16:
   - get-output-file should now handle paths with $TASK_ID, as long as
   the user refers to the job as JOB_NUMBER.TASK_ID
   - Changed the way get-ouput-file grabs the path, hopefully more robust

* Update 2017-02-06:
   - qusr now correctly handles waiting jobs

* Update 2017-02-05:
   - Fix typo in qusr - was not printing last line of qstatus

* Update 2017-02-03:
   - Fix typos in Readme
   - qusr now passes arguments through to qstatus

* Update 2017-02-02:
   - get-output-file can now handel paths with $HOSTNAME

* Update 2017-02-01:
   - get-output-file can now handle (some) paths that are directories

* Update 2017-01-31:
   - qusr script added

* Update 2017-01-30:
   - Includes taskID for array jobs in show-past-jobs
   - the other scripts should now handle a path that contains $TASK_ID in a better way
