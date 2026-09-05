const String serverBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://192.168.100.11/api',
);

const String serverAdminToken = String.fromEnvironment('API_ADMIN_TOKEN');