#!/usr/bin/env python
"""A dummy script for 'training' a model with specified arguments"""
import argparse
import os
import random
from glob import glob


def construct_parser():
    parser = argparse.ArgumentParser()
    
    parser.add_argument('-i', '--input', required=True, help='Path to the '
                        'input data for the model to read')
    parser.add_argument('-o', '--output', required=True, help='Path to the '
                        'directory to write output to')
    parser.add_argument("--lr", type=float, default=1e-4,
                        help="learning rate of adam")
    parser.add_argument("--weight_decay", type=float, default=0.01,
                        help="weight_decay of adam")
    return parser


def main(args):
    print('Totally learning model...yup')
    inpath = args.input
    outpath = args.output 
    lr = args.lr
    wd = args.weight_decay
    print(f'Reading data from {inpath}')
    for path in glob(f'{inpath}/*'):
        print(f'Nommed: {path}')
    print(f"I'm gonna use a learning rate of {lr} and weight decay of {wd}")
    accuracy = random.random()
    print(f'The model accuracy was {accuracy}...very precision, such learn.')
    if not os.path.exists(outpath):
        print(f"{outpath} doesn't exist, creating it for you")
        os.makedirs(outpath)
    print(f'Writing this important information to {outpath}')
    filename = f'expt_{lr}_{wd}.log'
    with open(f'{outpath}/{filename}', 'w') as fh:
        print(accuracy, file=fh)
    print("That's all folks")


if __name__ == '__main__':
    parser = construct_parser()
    args = parser.parse_args()
    main(args)
