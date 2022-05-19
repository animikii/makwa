# How to release a new version

* Make changes to the code
  * Update tests as needed
  * Update CHANGELOG.md
  * Commit changes
* Prepare new release
  * Bump version via one of
    * `gem bump --tag --version major`
    * `gem bump --tag --version minor`
    * `gem bump --tag --version patch`
  * The bump command will commit the new version and tag the commit.
* Distribute new release
  * `gem release` - This will push the new release to rubygems.org.
