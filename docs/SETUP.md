# Pay Theory iOS SDK Codacy Setup

These are the steps you need to be able to run the test script for test coverage before pushing code changes.

## Homebrew

Make sure [Hombrew](https://docs.brew.sh/Installation) is installed on your mac if it is not.

## Rbenv

Mac OS doesn't give full access to the ruby preinstalled which we will need to install Slather. Rbenv will allow you to manage ruby versions on your Mac.

* Go through [these steps under using package managers](https://github.com/rbenv/rbenv#using-package-managers) to install the tool
* Go through [these steps under installing Ruby versions](https://github.com/rbenv/rbenv#using-package-managers) to install a seperate version of ruby.
* Run `gem env home` to ensure you are installing gems in the correct version of ruby

## Slather

Slather is the tool that generates the coverage report for Codacy. You need to install it by putting this command into your CLI

```ruby
gem install slather
```

## Codacy Token

You will need to follow step 2 in [this article](https://docs.codacy.com/coverage-reporter/) to set up the Codacy token to allow the upload.

## Test Script

Once all these steps have been completed you just need to commit any changes you have to the pay-theory-ios repo and run the test.sh script from the root of the directory.

```ruby
sh test.sh
```

This will run tests and upload Codacy results properly and then push changes to GitHub.