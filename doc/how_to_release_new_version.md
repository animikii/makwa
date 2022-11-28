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
* Distribute new release
  * `gem push makwa` - This will push the new release to rubygems.org.
