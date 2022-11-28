# How to release a new version

* Make changes to the code
  * Update tests as needed
  * Update CHANGELOG.md
  * Commit changes
* Prepare new release
  * Assign new version in `lib/makwa/version.rb`
  * Commit the change with "Bump makwa to <version>"
  * Tag the commit of the new version with `v<version>`
  * Push the changes
  * Build the gem with `gem build`
* Distribute new release
  * `gem push makwa-<version>.gem` - This will push the new release to rubygems.org.
