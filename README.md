# Docker Compose AWS Runner

## Installation

```
brew tap ClearCutCoding/homebrew-tap
brew install docker-compose-aws-runner
```

## Usage

- Ensure the `aws` cli is installed and configured
- Ensure `docker-compose` cli is installed
- Create config in same folder as `docker-compose.yaml` named `docker-compose-aws-runner.cfg`


```
aws.account=1234
aws.region=eu-west-1
aws.profile=xxx-devuser
network=test
```

- Run `docker-compose-aws-runner` from inside the directory with `docker-compose.yaml`

