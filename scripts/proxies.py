import argparse
import subprocess
import time
import os
from lib.terraform.builder import OpsTerraformBuilder


def main():
    assets_dir = "assets/proxies"
    key_path = os.path.join(assets_dir, "private.key")
    user = "root"
    playbook_path = "ansible/proxies.yml"
    inventory_path = os.path.join(assets_dir, "inventory.ini")

    tf_builder = OpsTerraformBuilder()

    parser = argparse.ArgumentParser(
        description="proxy server deployment and configuration"
    )

    parser.add_argument(
        "-a",
        "--action",
        type=str,
        help="Terraform action to perform",
        choices=["apply", "destroy", "validate", "plan"],
        required=True,
    )

    parser.add_argument(
        "-d", "--do", type=int, help="Digital Ocean server count", default=0
    )

    parser.add_argument(
        "-l", "--lin", type=int, help="Linode server count", default=0
    )

    parser.add_argument(
        "--chdir",
        type=str,
        help="path to terraform folder",
        default="terraform/proxies/",
    )

    args = parser.parse_args()

    tf_builder.with_tf_action(args.action)
    tf_builder.with_linode_count(args.lin)
    tf_builder.with_digitalocean_count(args.do)
    tf_builder.with_tf_chdir(args.chdir)
    options = tf_builder.build()

    print("terraform options", options)

    subprocess.run(options)

    print("sleeping for 10 seconds...")
    # time.sleep(10)
    ansbile_options = [
        "ansible-playbook",
        "-i",
        inventory_path,
        playbook_path,
        "-u",
        user,
        "--private-key",
        key_path,
    ]
    print(ansbile_options)
    subprocess.run(ansbile_options)


if __name__ == "__main__":
    main()
