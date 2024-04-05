import sys
from create_concatenated_file import concatenate_files
def main():
    # Concatenate seed files
    seed_files_dir = 'seed/unit_testing'
    seed_files = [
        'seed_version.sql',
        'enable_seed_config_functions.sql',
        'permissions.sql',
        'roles.sql',
        'services.sql',
        'auth_users.sql',
        'appointments.sql',
        'invoices.sql',
        'invoice_has_appointments.sql',
        'order_lines.sql',
        'appointments_has_services.sql',
        'drop_seed_config_functions.sql'
    ]
    concatenate_files(seed_files_dir, seed_files, '../seed.sql')

    # Concatenate extension files
    extension_files_dir = 'fysiofresh_extension'
    extension_files = [
        'install_extension_start.sql',
        'seed_user_auth.sql',
        'assign_user_profile.sql',
        'assign_user_role.sql',
        'assign_user_profile_and_role.sql',
        'seed_user.sql',
        'create_appointment.sql',
        'create_service.sql',
        'map_appointment_and_services.sql',
        'create_subscription_for_client.sql',
        'create_invoice_with_subscription.sql',
        'map_invoice_and_appointments.sql',
        'map_role_and_permissions.sql',
        'map_client_and_employee.sql',
        'disable_all_rls_in_public_schema.sql',
        'delete_all_data_in_schemas.sql',
        'install_extension_end.sql'
    ]
    concatenate_files(extension_files_dir, extension_files, '../migrations/0001_setup.sql')

if __name__ == "__main__":
    main()
