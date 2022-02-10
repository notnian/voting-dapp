

# Tests

```bash
# docker pull trailofbits/eth-security-toolbox
docker run --rm -it -v "$PWD:/code" trailofbits/eth-security-toolbox
# Static analysis
slither /code/contracts/Voting.sol --solc-remaps @openzeppelin=/code/node_modules/@openzeppelin
# Fuzzing tests
echidna-test /code/contracts/Voting.sol --crytic-args "--solc-remaps @openzeppelin=/code/node_modules/@openzeppelin"
```