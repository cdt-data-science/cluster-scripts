from torchvision import datasets

root = 'data/input'
datasets.MNIST(root, train=True, download=True)
datasets.MNIST(root, train=False, download=True)

