# Zendesk Search Application
For fun and profit!

## Getting it running

* Prerequisites - you'll need ruby 2.3+ and bundler installed.
* Clone the repo
* Follow these instructions...

```
bundle install
bundle exec rake spec # To run the unit tests
bundle exec zd-search # To run the interactive search shell
```

## How to use it

When starting the zd-search program, you'll be dropped into an interactive shell. Basic readline-style line editing is supported. To see usage information, type `help`.

```
To discover what fields are available to query
    > fields {organization|ticket|user}
To query on a particular object type/field pair
    > search {organization|ticket|user}.FIELD SEARCH_TERM
To exit
    > exit
    or
    > ^D
To see this help again
    > help
```

e.g. to find tickets containing the word "lorem" in the description, type `search ticket.description lorem`.
