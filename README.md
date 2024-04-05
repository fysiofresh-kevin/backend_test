# Running the project

The project is setup using the supabase local development guide:
https://supabase.com/docs/guides/cli/local-development

Before attempting to run the project, please ensure you've logged into your supabase account by running:

> 'npx supabase login'

then to link your project with the live version, run:

> 'npx supabase link --project-ref <project-id>'

once you've linked your project you can start it up by running:

> 'npx supabase start'

setup your database with default data and config run:

> 'npx supabase db reset'

## Prerequisites

- You must have docker installed and running on your machine before attempting to run supabase locally.
- You must have NodeJs installed in order to run via. NPX.

# Steps when developing

information missing

### Starting a new task

- Create a new git branch matching the issue on jira.
- Reset database, avoid mixing tasks.

### Creating Migrations and Making changes

In order to create a migration from scratch run

> npx supabase migrations new {filename}

fill out the migration and run

> npx supabase db reset

this will push the migration to your local instance.

#### Pushing to production

You should never push to production directly, you should commit your work to develop or master, and the automated
pipeline will push it automatically on a successful run.

NOTE: THERE ARE CURRENTLY NO AUTOMATED PIPELINE, THE ABOVE IS THE DREAM SCENARIO!

### Don't forget to test it!

Tests belong in the tests/database folder; all relevant files must be named '<name>.test.sql.'

You have to ensure testing is enabled, and that the dbdev and our own test helper extension is installed.
Installation can be found in the migrations
db_dev: [20240117123215_enable_db_dev.sql](supabase%2Fmigrations%2F20240117123215_enable_db_dev.sql)
fysiofresh_test_helpers: [0001_setup.sql](supabase%2Fmigrations%2F0001_setup.sql)

All files must follow the pattern -

> BEGIN<br>
> CREATE EXTENSION IF NOT EXISTS "basejump-supabase_test_helpers";
>
> CREATE EXTENSION IF NOT EXISTS fysiofresh_helper_functions;
>
> -- Insert test data block
>
> SELECT plan(x);
>
> -- select x tests
>
> ROLLBACK;

Helpful links:

[pgTap](https://pgtap.org/documentation.html)

[testing guide](https://usebasejump.com/blog/testing-on-supabase-with-pgtap)

[test helpers](https://github.com/usebasejump/supabase-test-helpers/tree/main)

[EXTENSION-FUNCTIONS-README.md](supabase%2Fextension_files%2FEXTENSION-FUNCTIONS-README.md)

To run all tests and confirm a working database, run:

> npx supabase test db

To test only specific files, copy them to the supabase/test/work folder and run:

> npx supabase test db supabase/tests/work

Remember to put them back into their respective folders before committing.

### Working with supabase edge functions:

Before engaging with edge-functions please review
their [quickstart guide](https://supabase.com/docs/guides/functions/quickstart)

To run a supabase function locally, you must have supabase running.

> npx supabase start

And an environment file

> SUPABASE_URL=http://localhost:54321<br>
> SUPABASE_ANON_KEY='your-anon-key'

we keep documentation in our postman collections, please review and test them there.

if the functions service isn't running run:

npx supabase functions serve --env-file supabase/.env.local

the --env-file tag is only for mapping the env file if you're trying to run the actual request.

to create a new function locally run

> npx supabase functions new 'function-name'

Remember to test it by adding a test file.<br>
Test files must have the ending "_test.ts" and include one or more
> Deno.test("test case description", test_function);

You can run the test file by the following command:
> deno test --allow-env --env=.env.local

Adding the `--watch` flag allows for a watch mode, where the test will run every time you save a
file. [Documentation](https://docs.deno.com/runtime/manual/getting_started/command_line_interface#watch-mode)

Adding the `--trace-ops` flag will show you the operations that are being executed along with better debugging
information. [Documentation](https://fig.io/manual/deno/test)

Testing only one file or folder, edit the command as follows:
> deno test functions/__tests__/hello_world/ --allow-env --env=.env.local

hint: you can only execute the test in the same directory as your .env.local file :)

### Developing Github Actions

To run Github actions locally for development, the [Act CLI tool](https://github.com/nektos/act) can be used. To run all workflows while emulating Github secrets you can run

```bash
act --secret-file path/to/.env
```
Alternatively, you can emulate different Github triggers like push and pull requests.

### Code reviewing the backend

information missing because we haven't started this procedure yet.

### D.O.D on a task

* Have you written tests / test procedures?
* Do you need to update the seed file?
* Do you need to update confluence?
