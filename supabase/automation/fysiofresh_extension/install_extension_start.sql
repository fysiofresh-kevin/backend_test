CREATE EXTENSION IF NOT EXISTS pg_tle;
SELECT pgtle.install_extension
       (
               'fysiofresh_helper_functions',
               '0.1',
               'Helper functions for dummy data creation and testing purposes',
               $_pg_tle_$
