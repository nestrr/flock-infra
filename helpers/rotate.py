import json
from base64 import b64encode
import argparse
from sh import bash
from nacl import encoding, public

DOPPLER_SECRET_NAME_IN_ACTIONS = "DOPPLER_PT"
REPO_NAME = "flock-infra"
WORKFLOW_NAME = "rotate-doppler.yaml"


def create_parser():
    new_parser = argparse.ArgumentParser(
        prog='Rotate Doppler Token',
        description='This program rotates the Doppler service token (or uploads it if there is none).'
    )
    new_parser.add_argument("-l", "--layer", choices=['frontend', 'backend'], help='The layer of the stack [frontend/backend]', required=True)
    new_parser.add_argument('-e', "--env-config", choices=['stage', 'prod'], help='The environment config [stage/prod]', required=True)
    return new_parser


def encrypt(public_key: str, secret_value: str) -> str:
    """
    Encrypt a Unicode string using the public key.
    Credit: https://docs.github.com/en/rest/guides/encrypting-secrets-for-the-rest-api?apiVersion=2022-11-28#example-encrypting-a-secret-using-python
    """
    public_key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder)
    sealed_box = public.SealedBox(public_key)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return b64encode(encrypted).decode("utf-8")


def get_public_key_info() -> dict[str]:
    """
    Gets repo public key information.
    :return: A dict as follows:
        {
            key_id: <key id>,
            key: <public key>
        }
    """
    return json.loads(bash('gh api '
                           '-H "Accept: application/vnd.github+json" '
                           '-H "X-GitHub-Api-Version: 2022-11-28" '
                           f'/repos/{REPO_NAME}/actions/secrets/public-key'))


def upload_personal_token(public_key_details: dict[str], layer: str, env_config: str):
    """
    Upload personal token to GitHub repository as a secret
    :param env_config: Provided env config (stage/prod)
    :param layer: Provided layer (frontend/backend)
    :param public_key_details: repo's public key info
    """
    public_key_id, public_key = public_key_details['key_id'], public_key_details['key']
    token = encrypt(public_key, bash('doppler configure get token --plain'))
    environment = f'{layer}-{env_config}'
    bash('gh api  --method PUT '
         '-H "Accept: application/vnd.github+json" '
         '-H "X-GitHub-Api-Version: 2022-11-28" '
         f'/repos/nestrr/{REPO_NAME}/environments/{environment}/secrets/{DOPPLER_SECRET_NAME_IN_ACTIONS} '
         f'-f "encrypted_value={token}" '
         f'-f "key_id={public_key_id}"')
    return token


def is_workflow_enabled():
    """
    Check if workflow is enabled
    :return: True if workflow state is 'active' else False
    """
    workflow = json.loads(bash(f'gh api \
                                  -H "Accept: application/vnd.github+json" \
                                  -H "X-GitHub-Api-Version: 2022-11-28" \
                                  /repos/nestrr/{REPO_NAME}/actions/workflows/{WORKFLOW_NAME}'))
    return workflow['state'] == "active"


def dispatch_workflow(layer: str, env_config: str):
    """
    Upload new token to GitHub repository as a secret
    :param layer: layer (frontend/backend)
    :param env_config: environment (stage/prod)
    """
    bash(f'gh api --method POST \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          /repos/nestrr/{REPO_NAME}/actions/workflows/{WORKFLOW_NAME}/dispatches \
         -f "inputs[layer]={layer}" \
         -f "inputs[env_config]={env_config}"')


if __name__ == '__main__':
    parser = create_parser()
    if not is_workflow_enabled():
        print("Error: Enable the workflow in GitHub Actions first. You can do this with the CLI ('gh workflow enable "
              "<workflow-name') or with the website.")
        exit(1)

    args = parser.parse_args()
    public_key_info = get_public_key_info()
    upload_personal_token(public_key_info)

    print("The token rotation process has begun! Next steps: ")
    print("1. Keep an eye on the Doppler rotation workflow on Github Actions. It'll run the Terragrunt unit for "
          "creating and rotating a service token, so watch the output and check that it all went smoothly.")
    print("2. Before the workflow exits, it will revoke the Doppler personal token you're currently using as part of "
          "cleanup. Re-run 'doppler login' in order to get a working Doppler token again.")
