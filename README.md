     
# bitbucket

A LuCLI module that connects to bitbucket.

It is desgined to run within a bitbucket pipeline using the environment variables provided by bitbucket. You can override these variables by passing them as arguments to the module.

## Usage

```bash
# submit a report to bitbucket (it uses a json with annotations to also submit the annotations)
lucli bitbucket createReport file=report.json 

# Looks for the annotations in the report under the `annotations` 
lucli bitbucket createAnnotations file=report.json
# Get the diff for a pull request , used with the filterAnnotationsInDiff action
lucli bitbucket getPullRequestDiff pullRequestId=123

# return a filtered report with only the annotations that are in the diff
lucli bitbucket filterAnnotationsInDiff reportPath=report.json diffFilePath=diff.txt

```

## Description

This module is aimed to be used at creating reports and annotations in Bitbucket pull requests. It can create reports with annotations based on a JSON report file, fetch pull request diffs, and filter annotations to only those that are relevant to the changes in the pull request.

It works well with the lucli-lint module, since the lucli-lint module can generate reports with annotations in the required format.

