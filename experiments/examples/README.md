# Examples

## `./simple`
Requires no packages other than python3 (which should be installed at 
`/bin/python3` already) and is merely illustrative. The purpose of this example
is to give you the quickest possible **practical** introduction to the
cluster setup, slurm, and running an experiment with our frameword. It
shouldn't take you more than 20 minutes.


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
