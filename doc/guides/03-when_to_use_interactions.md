# When to use Interactions

### Some basic guidelines for when to use interactions

* When you have an ActiveRecord mutation that is coupled with additional operations. E.g., creating a user record, then
  sending a welcome email, tracking an analytics event, etc.
* When you want to wrap a 3rd party service or dependency. This could be the Git library to interact with git
  repositories programmatically. It could be the Mailchimp API, the FileSystem or really any API. By wrapping the
  dependency in an interaction, you can stub it for tests and you have to touch a single place only if you need to make
  implementation changes.
* When you compose complex processes from simple operations.
