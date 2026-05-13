# How to schedule priority jobs on ICF

## Overview of concepts

This is a short guide to scheduling priority jobs on the Informatics
Compute Facility (ICF). ICF has a free tier and a paid-for tier; the
jobs in the paid-for tier have higher priority than the jobs in the
free tier. Higher priority jobs can be run using preemption, see below.

As a user, you will be part of an **account**, a group of users that
are put together for tracking and controlling access to resources. For
example, all students in the same CDT are typically part of the same
account.

Furthermore, you will be part of one or more **quality of service**
(QOS). A QOS is a policy profile that controls priority, resource
limits, and preemption rules. The way ICF is set up, a QOS typically
corresponds to a type of GPU, for example H200 or L40s.

Charging works by the hour; if a job of yours runs for n hours using m
GPUs, then the account you are part of will be charged for n*m GPU
hours. The hours are charged separately by GPU type.

Currently, there are no quotas on GPU hours per user (only per
account), but these will be introduced in the future. However, all GPU
usage is monitored on a by-user basis.

The final concept you need is a **partition**, which is a group of nodes
on the ICF. A user can have access to multiple partitions, and a node
can be part of more than one partition.


## How preemption works

When you submit a priority job, it may need resources (typically GPUs)
that are currently in use by free-tier jobs. In this case, your job
will preempt one or more of those free-tier jobs: they will be
terminated and placed back at the end of the queue, freeing up the
resources for your job.

Conversely, if you submit a free-tier job, be aware that it may be
preempted at any time by a priority job. Any work done by a preempted
job that has not been saved to disk will be lost! So it is good
practice to checkpoint your work regularly so that it can be restarted
without losing too much progress.


## Find out which resources are available to you

Start by obtaining a list of all partitions and nodes on ICF:

`sinfo`

As a research student, you will normally use the `ICF-Research` partition.

Now find out which accounts you are part of and which partitions you
have access to:

`sacctmgr show user $USER withassoc format=user,account%40,partition`

As a research student, you should be part of the `research` account,
which corresponds to the free tier. If you are also a member of a CDT,
a research group, or a project which has its own ICF account, then you
should see one or more additional accounts; these are denoted by
32-digit hex strings.

To find out which QOSs you are associated with use:

`sacctmgr show user $USER withassoc format=user,account%40,qos%85,defaultqos`

You will find that an account can be associated with more than one QOS
(typically corresponding to different GPU types), and that each
account has a default QOS, which is used if no explicit QOS is
specified when running a job. The ID of a QOS is also a 32-digit hex
string. If you are part of a CDT, for example you will see two QOSs,
each associated with a GPU type.

To find out more about the QOS, use:

`sacctmgr show qos format=name%40,priority,maxtrespu%25,maxwall`

This will show you the priority, maximum number of GPUs allowed, and
maximum runtime for each QOS.


## Check how many resources you have used

To find out how many GPU hours you have used (from a certain start
date) use:

`sreport cluster AccountUtilizationByUser start=2026-05-12 -t hours -T gres/gpu`

This gives you a report per account. If you want to get a report for a
specific QOS, use the following:

`sacct --qos=a0465xxx --starttime=2026-05-01 \`\
`  --format=user,account,qos,elapsed,alloctres%85`

where `a0465xxx` is the QOS you want information about.

Note that this command lists individual job records rather than a
single total. To calculate the total GPU hours used, you need to sum
up the GPU hours across all jobs, taking into account the number of
GPUs allocated for each job and the elapsed time.


## Run prioritised jobs

Once you know which resources (accounts and QOSs) are available to
you, you can run jobs that use these resources. For example to run
`job.sh` on account `ee4386xxx` with QOS `a0465xxx` while requesting
two GPUs, use the following command:

`sbatch \`\
`  --partition=ICF-Research \`\
`  --account=ee4386xxx \`\
`  --qos=a0465xxx \`\
`  --gres=gpu:2 \`\
`  job.sh`

Note that the partition should always be `ICF-Research`, as this is
where the priority resources reside.


## More information

You can find more information on how to use the ICF on the [NLP-RR
OpenCourse web site](https://opencourse.inf.ed.ac.uk/nlp-rr/tutorials).
This site includes tutorials, videos, and quick start guide.

There is also a [Github repo with ICF cluster
scripts](https://github.com/cdt-data-science/cluster-scripts).

You can use the [ICF Dashboard](https://icfwebview.inf.ed.ac.uk/) to
monitor the load of the cluster in real-time. Note that you have to be
on the Informatics network for the dashboard to work.
