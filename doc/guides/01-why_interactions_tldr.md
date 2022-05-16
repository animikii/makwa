# Why Should you use Interactions?
## ActiveInteraction

The purpose of Interactions is to encapsulate an app behaviour in a single purpose module so that we can simply and robustly invoke the behaviour in diverse contexts, e.g, controllers, tests, or consoles.

Interactions give you a place to put your business logic. It also helps you write safer code by validating that your inputs conform to your expectations. **If ActiveRecord deals with your nouns, then ActiveInteraction handles your verbs.**

## Benifits of using Interactions

By encapsulating app behaviour you are able to:
- Simply and robustly invoke a behaviour in diverse contexts, e.g., controllers, models, tests, rake tasks, or consoles.
- Clearly document the interface for a business operations. You go to the interactions folder to see all the interesting behavior. And each interaction tells you exactly what inputs it needs, and what it returns.
- Wrap a 3rd party service, then swap it out in a single place as needed. E.g., for testing, or if you want to replace the implementation.

By composing an app's behaviour you are able to:
- Nest interactions very easily because they have standardized interfaces for invocation, input arguments, return values, and error handling.
- Implement complex domain behaviours by composing simple sub tasks into higher level processes.

Using interactions will assist you in handling errors consistently
- They provide good error messages.
- The caller can decide how to deal with unexpected outcomes: raise an exception, display a warning, change the execution flow, or ignore it.

Interactions simplifies testing and debugging complex behaviours
- Complex behaviors can now be tested via unit tests.
- Test data setup is a breeze because now you have a tool for setting up almost every test case.
- You can print every interaction invocation with its inputs, outcome, and return value during runtime to help with debugging.

