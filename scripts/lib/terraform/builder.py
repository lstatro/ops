from typing import Optional


class OpsTerraformBuilder(object):
    # terraform cli action
    action: Optional[str] = None

    # directory to run tf from
    chdir = None

    # how many DO servers to deploy
    digitalocean_count = None

    # how many Linode servers to delpoy
    linode_count = None

    # global var file location
    var_file = None

    # subprocess options array, gets populated at build time
    options = []

    def __init__(self):
        self.options.append("terraform")
        self.with_var_file()

    def with_var_file(self, var_file="../variables.tfvars"):
        self.var_file = var_file

    def with_tf_action(self, action: str):
        self.action = action
        return self

    def with_digitalocean_count(self, count=0):
        self.digitalocean_count = count
        return self

    def with_linode_count(self, count=0):
        self.linode_count = count
        return self

    def with_tf_chdir(self, chdir):
        self.chdir = chdir
        return self

    def __handle_mutation(self):
        if self.chdir:
            self.options.append(f"-chdir={self.chdir}")

        self.options.append(self.action)

        self.options.append("-auto-approve")

        if self.var_file:
            self.options.extend(["-var-file", self.var_file])

        self.options.extend(
            ["-var", f"digitalocean_count={self.digitalocean_count}"]
        )

        self.options.extend(["-var", f"linode_count={self.linode_count}"])

        return self

    def __handle_plan(self):
        if self.chdir:
            self.options.append(f"-chdir={self.chdir}")

        self.options.append(self.action)

        if self.var_file:
            self.options.extend(["-var-file", self.var_file])

        self.options.extend(
            ["-var", f"digitalocean_count={self.digitalocean_count}"]
        )

        self.options.extend(["-var", f"linode_count={self.linode_count}"])

        return self

    def __handle_validation(self):
        if self.chdir:
            self.options.append(f"-chdir={self.chdir}")

        self.options.append(self.action)

        return self

    def build(self):
        if self.action == "apply" or self.action == "destroy":
            self.__handle_mutation()

        if self.action == "plan":
            self.__handle_plan()

        if self.action == "validate":
            self.__handle_validation()

        return self.options
