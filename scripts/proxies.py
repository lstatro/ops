import argparse
import subprocess
from lib.terraform.builder import OpsTerraformBuilder


def main():
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

    print(options)

    subprocess.run(options)


if __name__ == "__main__":
    main()
