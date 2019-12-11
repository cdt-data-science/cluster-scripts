# Examples

## `./simple`
Requires no packages other than python3 (which should be installed at 
`/bin/python3` already) and is merely illustrative. The purpose of this example
is to give you the quickest possible **practical** introduction to the
cluster setup, slurm, and running an experiment with our frameword. It
shouldn't take you more than 20 minutes.

If you are on your laptop, remember you don't even need to set up a VPN to
log in to your cluster machine. First ssh to an ssh gateway box, then ssh to
a cluster machine. For example:

```
# Start on a computer connected to any wi-fi you like

ssh s1234567@staff.ssh.inf.ed.ac.uk
# you're now on the staff ssh gateway box, inside the informatics network

ssh cdtcluster
# you're now on the cdtcluster head node
```

More information available here: http://computing.help.inf.ed.ac.uk/external-login


## `./mnist`
Will allow you to test whether you're successfully using a GPU! It's based on
[this pytorch example](https://github.com/pytorch/examples/tree/master/mnist).
It requires that you follow the setup in the README. This will unfortunately
take a couple of hours because it involves:
* fully setting up your bash environment
* and creating a conda virtual enviroment (could take up to an hour
  :upside_down_face:)
* downloading data (~5 mins)

...so grab tea/coffee making paraphernalia. However, once the setup is all done
you can hopefully use this as a basis for your experiments right away.
