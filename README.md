## AWS ClamAV Layer & a service using it to scan files

This is a proof of concept.  Production deployment not recommended without extensive testing.

```bash
git clone https://github.com/PacGenesis/serverless-clamav-lambda-layer.git
```

Update serverless.yml and change the scanbucket parameter to the name of your bucket

```bash
./build.sh # build layer in a docker container
sls deploy # deploy to aws
./updatepolicy # prevents downloads until scanned
```

## Unit Tests
There's only one unit test for our handler, but to run it you'll need to install the `devDependencies` 

```bash
npm i
npm run test
```
