set quiet

TF_ENGINE := "terraform"
TF_BINARY := if TF_ENGINE == "terraform" { "terraform" } else { "tofu" }
INSTALLER_PATH := shell('command -v' + ' apt || command -v brew || command -v choco') # command is already first argument
INSTALLER := shell('basename $1', INSTALLER_PATH)
BREW_PACKAGES := "cosign terraform-docs tflint checkov trivy pre-commit golang"
CHOCOLATEY_PACKAGES := "cosign terraform-docs tflint trivy golang"
TF_VERSION_PATH := "." + TF_BINARY + "-version"
TF_TEST_OPTS := ""
GO_TEST_OPTS := ""
CHECKOV_OPTS := ""
CI := "0"
TERRATEST_EXAMPLES_PATH :=  "examples/*"


check dir ci=CI:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{justfile_dir()}}/{{dir}}
    just tf-checks _install_packages
    just tf-checks _test_documentation
    just tf-checks _test_lint
    just tf-checks _test_security
    just tf-checks _test_validation
    just tf-checks _test_format

_install_packages:
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ "{{INSTALLER}}" = "choco" ]]; then
        choco install {{CHOCOLATEY_PACKAGES}}
    elif [[ "{{INSTALLER}}" = "brew" ]]; then
        brew tap tofuutils/tap
        brew install {{BREW_PACKAGES}}
    else
       echo "Using manager: {{INSTALLER}}. No additional packages need to be installed."
    fi

_test_validation:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{invocation_dir()}}
    {{TF_BINARY}} init -backend=false
    {{TF_BINARY}} validate

# Terraform formatting
_format:
    @{{TF_BINARY}} fmt -recursive {{invocation_dir()}}

_test_format: _format
    @{{TF_BINARY}} fmt -check -recursive {{invocation_dir()}}


# Terraform documentation
_documentation:
    @terraform-docs -c {{invocation_dir()}}/.terraform-docs.yml {{invocation_dir()}}

_test_documentation: _documentation
    @terraform-docs -c {{invocation_dir()}}/.terraform-docs.yml --output-check {{invocation_dir()}}/.

# Terraform lint
_fix_lint_errors:
    @tflint --chdir={{invocation_dir()}} --init && tflint --chdir={{invocation_dir()}} --fix

_test_lint: _fix_lint_errors
    @tflint --chdir={{invocation_dir()}}  --init && tflint --chdir={{invocation_dir()}}

# Terraform security
_test_checkov:
    @checkov --directory {{invocation_dir()}}  {{CHECKOV_OPTS}}

_test_trivy:
    @trivy config {{invocation_dir()}}

_test_security: _test_checkov _test_trivy

#
# Terratest
#
_tests_init:
    go mod init "{{invocation_dir()}}"

_manage_tests_deps:
	cd {{invocation_dir()}} && go mod tidy

_terratest:
    #!/usr/bin/env bash
    set -euxo pipefail
    echo "WARNING! CURRENTLY FAILS."
    cd "{{invocation_dir()}}/terratest"
    just tf-checks _tests_init
    just tf-checks _manage_tests_deps
    TERRATEST_BINARY={{TF_BINARY}} go test -v -timeout 60m {{GO_TEST_OPTS}}

# Terraform Test Framework

test_examples:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd {{invocation_dir()}}
    terratest_examples=$(ls {{ TERRATEST_EXAMPLES_PATH }})
    export TENV_AUTO_INSTALL=true

    for f in $terratest_examples; do
        if [[ -d "$f" && ! -L "$f" ]]; then
            # if we find a directory, test its contents
            echo "Testing examples in $f"
            cd
            {{TF_BINARY}} init -backend=false
            {{TF_BINARY}} test {{TF_TEST_OPTS}}
        fi
    done
