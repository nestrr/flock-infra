import json
from base64 import b64encode
import argparse

import requests
from sh import bash
from nacl import encoding, public

DOPPLER_SECRET_NAME_IN_ACTIONS = "DOPPLER_PT"
REPO_NAME = "flock-infra"
WORKFLOW_NAME = "rotate-doppler.yaml"
BASE_URL = f'https://api.github.com/repos/nestrr/{REPO_NAME}'


def create_parser():
    new_parser = argparse.ArgumentParser(
        prog='Rotate Doppler Token',
        description='This program rotates the Doppler service token (or uploads it if there is none).'
    )
    new_parser.add_argument("-l", "--layer", choices=['frontend', 'backend'],
                            help='The layer of the stack [frontend/backend]', required=True)
    new_parser.add_argument('-e', "--env-config", choices=['stage', 'prod'], help='The environment config [stage/prod]',
                            required=True)
    new_parser.add_argument('-gt', "--gh-token", help='Your Github token', required=True)
    new_parser.add_argument('-dt', "--dp-token", help='Your Doppler token', required=True)
    return new_parser


def get_headers(token: str):
    headers = {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'Flock',
        'Authorization': f'Bearer {token}'
    }
    return headers


def encrypt(public_key: str, secret_value: str) -> str:
    """
    Encrypt a Unicode string using the public key.
    Credit: https://docs.github.com/en/rest/guides/encrypting-secrets-for-the-rest-api?apiVersion=2022-11-28#example-encrypting-a-secret-using-python
    """
    public_key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder)
    sealed_box = public.SealedBox(public_key)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return b64encode(encrypted).decode("utf-8")


def get_public_key_info(token: str, environment_name: str) -> dict[str]:
    """
    Gets repo public key information.
    :return: A dict as follows:
        {
            key_id: <key id>,
            key: <public key>
        }
    """
    url = f'{BASE_URL}/environments/{environment_name}/secrets/public-key'
    response = requests.get(url, headers=get_headers(token))
    print(response.text)
    response.raise_for_status()
    return response.json()


def upload_personal_token(public_key_details: dict[str], environment_name: str, gh_token: str, dt_token: str):
    """
    Upload personal token to GitHub repository as a secret
    :param public_key_details: repo's public key info
    :param environment_name: Actions environment name
    :param gh_token: GitHub token
    :param dt_token: Doppler token
    """
    public_key_id, public_key = public_key_details['key_id'], public_key_details['key']
    doppler_token = encrypt(public_key, dt_token)
    url = f'{BASE_URL}/environments/{environment_name}/secrets/{DOPPLER_SECRET_NAME_IN_ACTIONS}'
    payload = {
        "encrypted_value": doppler_token,
        "key_id": public_key_id
    }

    response = requests.put(url, data=json.dumps(payload), headers=get_headers(gh_token))
    response.raise_for_status()
    return doppler_token


def is_workflow_enabled(token: str):
    """
    Check if workflow is enabled
    :return: True if workflow state is 'active' else False
    """
    url = f'{BASE_URL}/actions/workflows/{WORKFLOW_NAME}'
    response = requests.get(url, headers=get_headers(token))
    response.raise_for_status()
    workflow = response.json()
    return workflow['state'] == "active"


def dispatch_workflow(layer: str, env_config: str, token: str):
    """
    Upload new token to GitHub repository as a secret
    :param layer: layer (frontend/backend)
    :param env_config: environment (stage/prod)
    """
    url = f'{BASE_URL}/actions/workflows/{WORKFLOW_NAME}/dispatches'
    dispatch_data = {
        'inputs': {
            'layer': layer,
            'env_config': env_config
        },
        'ref': 'main'
    }
    response = requests.post(url, data=json.dumps(dispatch_data), headers=get_headers(token))
    print(response.text)
    response.raise_for_status()


if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()
    if not is_workflow_enabled(args.gh_token):
        print("Error: Enable the workflow in GitHub Actions first. You can do this with the CLI ('gh workflow enable "
              "<workflow-name') or with the website.")
        exit(1)

    environment = f'{args.layer}-{args.env_config}'
    public_key_info = get_public_key_info(args.gh_token, environment)
    upload_personal_token(public_key_info, environment, args.gh_token, args.dp_token)
    dispatch_workflow(args.layer, args.env_config, args.gh_token)

    print("The token rotation process has begun! Next steps: ")
    print("1. Keep an eye on the Doppler rotation workflow on Github Actions. It'll run the Terragrunt unit for "
          "creating and rotating a service token, so watch the output and check that it all went smoothly.")
    print("2. Before the workflow exits, it will revoke the Doppler personal token you're currently using as part of "
          "cleanup. Re-run 'doppler login' in order to get a working Doppler token again.")
