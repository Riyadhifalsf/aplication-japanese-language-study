# Safe Repository Export

The source archive received for this task contained local/runtime artifacts.
The distributable archive intentionally excludes:

- `.env` files
- Android signing keystore/private key files
- `node_modules/`
- `.gradle/`
- build outputs
- Python `__pycache__/`
- generated logs where practical

Before committing or publishing:
1. copy secrets into local environment files;
2. use `.env.example` templates;
3. provision signing credentials in CI/secret storage;
4. rotate credentials if any secret was previously committed or shared.
