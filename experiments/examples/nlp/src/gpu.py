import torch
import torch.nn as nn
import torch.nn.functional as F
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("--data_path", type=str, required=True, help="Data location")
parser.add_argument("--output_dir", type=str, required=True, help="Output directory")

class MiniModel(nn.Module):
	def __init__(self, input_dim, output_dim):
		super(MiniModel, self).__init__()
		self.layer = torch.nn.Linear(input_dim, output_dim)
	def forward(self, x):
		x = self.layer(x)
		return F.relu(x)


def read_textfile(filepath, encoding="utf-8"):
	with open(filepath, mode="r", encoding=encoding) as fh:
		data = [torch.Tensor([float(l.strip())]).cuda() for l in fh]
	return data

def main(args):
	# Declare model
	model = MiniModel(input_dim=1, output_dim=10)

	# Move model to GPU
	assert torch.cuda.is_available(), "No GPU available. Check your Slurm configuration"
	model = model.cuda()

	# Load data and move to GPU
	data = read_textfile(args.data_path)

	# Forward for each element of data
	# This is not how we would actually do forward processing but demonstrates GPU operation
	for element in data:
		print(model(element))

	# Finally we save this model in the location given in args
	output_location = f"{args.output_dir}/model.th"
	torch.save(model, output_location)

if __name__ == "__main__":
    args = parser.parse_args()
    main(args)
    print("done!")