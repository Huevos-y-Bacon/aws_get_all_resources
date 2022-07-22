# aws_get_all_resources

- Get all (*taggable*) resources in **all AWS regions** for current account
- Uses resource groups tagging api

**Prerequisites:**

- `jq`
- `aws`
- `awsume`

***If using AWS SSO:***

- All AWS CLI profiles should be for the same SSO instance
- Suggest separating out the profiles into multiple ~/.aws/configs (and credentials should you use keys for some profiles) per SSO instance
- Then symlink to the active file/files

- See also:
  - my gists:
    - [aws_switch_config](https://gist.github.com/Huevos-y-Bacon/b398ed77522611702c049ddbd9e362af)
    - [example_aws_cli_config_for_sso](https://gist.github.com/Huevos-y-Bacon/7d2e6c7de9deff4f0345efa6da06371f)
  - [aws-sso-credential-process](https://pypi.org/project/aws-sso-credential-process/)

**Outputs:**

- **raw json** output from the `aws resourcegroupstaggingapi` cli call
  - `<aws_account_id>-<aws_account_alias>/<region_name>.json`
  - e.g. `112233445566-acmeproduction/us-west-1.json`
- **extracted csv**, with header; stripped of `[^arn:aws:]`
  - `<aws_account_id>-<aws_account_alias>/<region_name>.csv`
  - e.g. `112233445566-acmeproduction/us-west-1.csv`

## Can I run this for all AWS profiles?

- **SOURCE** `everywhere.sh` - `awsume` requires the script to be sourced
- Configured to `awsume` into every profiles prefixed with **`AUDIT`**
