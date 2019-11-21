import sys
import os
import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import datasets, transforms
from torch.optim.lr_scheduler import StepLR


class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout2d(0.25)
        self.dropout2 = nn.Dropout2d(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output


def train(args, model, device, train_loader, optimizer, epoch):
    model.train()
    train_loss = 0
    correct = 0
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        train_loss += F.nll_loss(output, target, reduction='sum').item()
        pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
        correct += pred.eq(target.view_as(pred)).sum().item()
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        if batch_idx % args.log_interval == 0:
            print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
                epoch, batch_idx * len(data), len(train_loader.dataset),
                100. * batch_idx / len(train_loader), loss.item()))
    
    train_loss /= len(train_loader.dataset)
    accuracy = correct / len(train_loader.dataset)
    return train_loss, accuracy


def test(args, model, device, test_loader):
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, reduction='sum').item()  # sum up batch loss
            pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
        test_loss, correct, len(test_loader.dataset),
        100. * correct / len(test_loader.dataset)))
    
    accuracy =  correct / len(test_loader.dataset)
    return test_loss, accuracy


def construct_parser():
    # Training settings
    parser = argparse.ArgumentParser(description='PyTorch MNIST Example')
    parser.add_argument('--batch-size', type=int, default=64, metavar='N',
                        help='input batch size for training (default: 64)')
    parser.add_argument('--test-batch-size', type=int, default=1000,
                        metavar='N', help='input batch size for testing '
                        '(default: 1000)')
    parser.add_argument('--epochs', type=int, default=14, metavar='N',
                        help='number of epochs to train (default: 10)')
    parser.add_argument('--lr', type=float, default=1.0, metavar='LR',
                        help='learning rate (default: 1.0)')
    parser.add_argument('--gamma', type=float, default=0.7, metavar='M',
                        help='Learning rate step gamma (default: 0.7)')
    parser.add_argument('--no-cuda', action='store_true', default=False,
                        help='disables CUDA training')
    parser.add_argument('--seed', type=int, default=None, metavar='S',
                        help='random seed (default: random number)')
    parser.add_argument('--log-interval', type=int, default=10, metavar='N',
                        help='how many batches to wait before logging '
                        'training status')
    
    parser.add_argument('-i', '--input', required=True, help='Path to the '
                        'input data for the model to read')
    parser.add_argument('-o', '--output', required=True, help='Path to the '
                        'directory to write output to')
    return parser
 

def main(args):
    #TODO: add checkpointing
    use_cuda = not args.no_cuda and torch.cuda.is_available()
    if not args.no_cuda and not use_cuda:
        raise ValueError('You wanted to use cuda but it is not available. '
                         'Check nvidia-smi and your configuration. If you do '
                         'not want to use cuda, pass the --no-cuda flag.')
    device = torch.device("cuda" if use_cuda else "cpu")
    print(f'Using device: {torch.cuda.get_device_name()}')
    
    # For reproducibility:
    #     c.f. https://pytorch.org/docs/stable/notes/randomness.html
    if args.seed is None:
        args.seed = torch.randint(0, 2**32, (1, )).item()
        print(f'You did not set --seed, {args.seed} was chosen')
    torch.manual_seed(args.seed)
    if use_cuda:
        if device.index:
            device_str = f"{device.type}:{device.index}"
        else:
            device_str = f"{device.type}"
        os.environ["CUDA_VISIBLE_DEVICES"] = device_str
        torch.cuda.manual_seed_all(args.seed)
        torch.backends.cudnn.deterministic = True
        # This does make things slower :(
        torch.backends.cudnn.benchmark = False
    
    config_args = [str(vv) for kk, vv in vars(args).items()
                   if kk in ['batch_size', 'lr', 'gamma', 'seed']]
    model_name = '_'.join(config_args)
    
    if not os.path.exists(args.output):
        print(f'{args.output} does not exist, creating...')
        os.makedirs(args.output)

    kwargs = {'num_workers': 1, 'pin_memory': True} if use_cuda else {}
    train_loader = torch.utils.data.DataLoader(
        datasets.MNIST(args.input, train=True, download=True,
                       transform=transforms.Compose([
                           transforms.ToTensor(),
                           transforms.Normalize((0.1307,), (0.3081,))
                       ])),
        batch_size=args.batch_size, shuffle=True, **kwargs)
    test_loader = torch.utils.data.DataLoader(
        datasets.MNIST(args.input, train=False, transform=transforms.Compose([
                           transforms.ToTensor(),
                           transforms.Normalize((0.1307,), (0.3081,))
                       ])),
        batch_size=args.test_batch_size, shuffle=True, **kwargs)

    model = Net().to(device)
    optimizer = optim.Adadelta(model.parameters(), lr=args.lr)
    
    log_fh = open(f'{args.output}/{model_name}.log', 'w')
    print('epoch,trn_loss,trn_acc,vld_loss,vld_acc', file=log_fh)
    scheduler = StepLR(optimizer, step_size=1, gamma=args.gamma)
    best_loss = sys.float_info.max
    for epoch in range(1, args.epochs + 1):
        loss, acc = train(args, model, device, train_loader, optimizer, epoch)
        vld_loss, vld_acc = test(args, model, device, test_loader)
        print(f'{epoch},{loss},{acc},{vld_loss},{vld_acc}', file=log_fh)
        scheduler.step()
        if vld_loss < best_loss:
            best_loss = vld_loss
            torch.save(model.state_dict(),
                       f"{args.output}/{model_name}.best.pt")
        
    torch.save(model.state_dict(), f"{args.output}/{model_name}.final.pt")
    
    log_fh.close()


if __name__ == '__main__':
    parser = construct_parser()
    args = parser.parse_args()
    main(args)
